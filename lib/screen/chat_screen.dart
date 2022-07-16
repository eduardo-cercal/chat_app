import 'dart:io';
import 'package:chat/chat_message.dart';
import 'package:chat/text_composer.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({Key? key}) : super(key: key);

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final GoogleSignIn googleSignIn = GoogleSignIn();
  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();
  User? currentUser;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    FirebaseAuth.instance.authStateChanges().listen((user) {
      setState(() {
        currentUser = user;
      });
    });
  }

  Future<User?> getUser() async {
    if (currentUser != null) return currentUser;
    try {
      final GoogleSignInAccount? googleSignInAccount =
          await googleSignIn.signIn();
      final GoogleSignInAuthentication googleSignInAuthentication =
          await googleSignInAccount!.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        idToken: googleSignInAuthentication.idToken,
        accessToken: googleSignInAuthentication.accessToken,
      );
      final UserCredential authResult =
          await FirebaseAuth.instance.signInWithCredential(credential);

      final User? user = authResult.user;

      return user!;
    } catch (error) {
      return null;
    }
  }

  void sendMessage({String? text, File? imgFile}) async {
    final User? user = await getUser();

    if (user == null) {
      scaffoldKey.currentState!.showSnackBar(const SnackBar(
        content: Text("Não foi possivel fazer login. Tente novamente!"),
        backgroundColor: Colors.red,
      ));
    }

    Map<String, dynamic> data = {
      "uid": user!.uid,
      "senderName": user.displayName,
      "senderPhotoUrl": user.photoURL,
      "time": Timestamp.now(),
    };
    if (imgFile != null) {
      UploadTask task = FirebaseStorage.instance
          .ref()
          .child(user.uid + DateTime.now().microsecondsSinceEpoch.toString())
          .putFile(imgFile);
      setState(() {
        isLoading = true;
      });

      TaskSnapshot taskSnapshot = await task.whenComplete(() => null);
      String url = await taskSnapshot.ref.getDownloadURL();
      data["imgUrl"] = url;
      setState(() {
        isLoading = false;
      });
    }

    if (text != null) {
      data["text"] = text;
    }

    FirebaseFirestore.instance.collection("message").add(data);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        key: scaffoldKey,
        appBar: AppBar(
          title: Text(currentUser != null
              ? "Hello, ${currentUser!.displayName}"
              : "Chat App"),
          centerTitle: true,
          elevation: 0,
          actions: [
            currentUser != null
                ? IconButton(
                    onPressed: () {
                      FirebaseAuth.instance.signOut();
                      googleSignIn.signOut();
                      scaffoldKey.currentState!.showSnackBar(const SnackBar(
                        content: Text("Você saiu com sucesso!"),
                      ));
                    },
                    icon: const Icon(Icons.exit_to_app))
                : Container(),
          ],
        ),
        body: Column(
          children: [
            Expanded(
                child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection("message")
                  .orderBy("time")
                  .snapshots(),
              builder: (context, snapshot) {
                switch (snapshot.connectionState) {
                  case ConnectionState.none:
                  case ConnectionState.waiting:
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  default:
                    List<DocumentSnapshot> documents =
                        snapshot.data!.docs.reversed.toList();
                    return ListView.builder(
                      itemBuilder: (context, index) {
                        return ChatMessage(
                            documents[index].get("uid") == currentUser?.uid,
                            documents[index].data() as Map<String, dynamic>);
                      },
                      itemCount: documents.length,
                      reverse: true,
                    );
                }
              },
            )),
            isLoading ? const LinearProgressIndicator() : Container(),
            TextComposer(sendMessage),
          ],
        ));
  }
}
