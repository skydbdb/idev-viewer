import 'package:flutter/material.dart';

void showLoading(BuildContext context) {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text('loading ...'),
      duration: Duration(seconds: 1),
    ),
  );
}
