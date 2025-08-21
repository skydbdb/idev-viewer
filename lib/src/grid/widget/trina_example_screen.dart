import 'package:flutter/material.dart';

class TrinaExampleScreen extends StatelessWidget {
  final String title;
  final String topTitle;
  final List<Widget> topContents;
  final Widget body;

  const TrinaExampleScreen({
    super.key,
    required this.title,
    required this.topTitle,
    required this.topContents,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  topTitle,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                ...topContents,
              ],
            ),
          ),
          Expanded(child: body),
        ],
      ),
    );
  }
}
