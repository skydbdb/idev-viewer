import 'package:flutter/material.dart';

Future<void> infoDialog(BuildContext context, {
  Widget? title, Widget? content
}) async {

  await showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: title,
      content: content,
      actions: <Widget>[
        ElevatedButton(
          child: const Text('확인'),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ],
    ),
  );
}

