import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class TextComposer extends StatefulWidget {
  TextComposer(this.sendMessage, {Key? key}) : super(key: key);

  final Function({String? text,File? imgFile}) sendMessage;

  @override
  _TextComposerState createState() => _TextComposerState();
}

class _TextComposerState extends State<TextComposer> {
  bool isComposing = false;

  final TextEditingController controller = TextEditingController();
  final picker = ImagePicker();

  void sendAndReset(String text) {
    widget.sendMessage(text: text);
    controller.clear();
    setState(() {
      isComposing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          IconButton(
            onPressed: () async {
              final imgPicked= await picker.pickImage(source: ImageSource.camera);
              if(imgPicked==null) return;
              File imgFile=File(imgPicked.path);
              widget.sendMessage(imgFile: imgFile);
            },
            icon: const Icon(Icons.photo_camera),
          ),
          Expanded(
            child: TextField(
              controller: controller,
              decoration: const InputDecoration.collapsed(
                  hintText: "Enviar uma mensagem"),
              onChanged: (text) {
                setState(() {
                  isComposing = text.isNotEmpty;
                });
              },
              onSubmitted: (text) {
                sendAndReset(text);
              },
            ),
          ),
          IconButton(
            onPressed: isComposing
                ? () {
                    sendAndReset(controller.text);
                  }
                : null,
            icon: const Icon(Icons.send),
          ),
        ],
      ),
    );
  }
}
