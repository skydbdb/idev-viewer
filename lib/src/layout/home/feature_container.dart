import 'package:flutter/material.dart';

class _FeatureContainer extends StatelessWidget {
  const _FeatureContainer({
    required this.title,
    required this.features,
  });

  final String title;

  final List<_Feature> features;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final lastItem = features.last;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 20),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: MediaQuery.of(context).size.width,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: theme.dialogBackgroundColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Padding(
              padding: const EdgeInsets.all(15),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final feature in features)
                    if (lastItem != feature) ...[
                      feature,
                      const SizedBox(height: 15),
                    ] else
                      feature,
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _Feature extends StatelessWidget {
  const _Feature({
    this.title,
    required this.description,
  });

  final String? title;

  final String description;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Wrap(
      direction: Axis.horizontal,
      children: [
        if (title != null) ...[
          DecoratedBox(
            decoration: BoxDecoration(
              color: theme.secondaryHeaderColor,
              borderRadius: BorderRadius.circular(5),
            ),
            child: Padding(
              padding: const EdgeInsets.all(5),
              child: Text(title!),
            ),
          ),
          const SizedBox(width: 10),
        ],
        Text(description),
      ],
    );
  }
}