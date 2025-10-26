import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:idev_viewer/src/internal/theme/themes.dart';

Widget _layoutBuilder(
    BuildContext context, List<Color> colors, PickerItem child) {
  return SizedBox(
    width: 200,
    height: 40,
    child: GridView.count(
      childAspectRatio: 3,
      crossAxisCount: 1,
      children: [
        for (Color color in colors)
          Stack(
            fit: StackFit.expand,
            children: [
              child(color),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    themes.entries.where((e) => e.value == color).first.key,
                    style: TextStyle(
                        fontSize: 24,
                        color: useWhiteForeground(color)
                            ? Colors.white
                            : Colors.black),
                  ),
                ],
              ),
            ],
          )
      ],
    ),
  );
}

Widget _itemBuilder(
    Color color, bool isCurrentColor, void Function() changeColor) {
  return Container(
    margin: const EdgeInsets.all(7),
    decoration: BoxDecoration(
      shape: BoxShape.rectangle,
      color: color,
      boxShadow: [
        BoxShadow(
            color: color.withOpacity(0.8),
            offset: const Offset(1, 2),
            blurRadius: 5)
      ],
    ),
    child: Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: changeColor,
        borderRadius: BorderRadius.circular(5),
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 210),
          opacity: isCurrentColor ? 1 : 0,
          child: Icon(Icons.done,
              color: useWhiteForeground(color) ? Colors.white : Colors.black),
        ),
      ),
    ),
  );
}

Future<String> colorDialog(BuildContext context, String title) async {
  Color pickerColor = themes.values.first;

  final result = await showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: SingleChildScrollView(
        child: SizedBox(
          height: 300,
          child: BlockPicker(
              pickerColor: pickerColor,
              onColorChanged: (changeColor) {
                print('changeColor-->$changeColor');
                pickerColor = changeColor;
              },
              availableColors: themes.values.toList(),
              layoutBuilder: _layoutBuilder,
              itemBuilder: _itemBuilder),
        ),
      ),
      actions: <Widget>[
        ElevatedButton(
          child: const Text('확인'),
          onPressed: () {
            final theme =
                themes.entries.firstWhere((e) => e.value == pickerColor).key;
            Navigator.of(context).pop(theme);
          },
        ),
      ],
    ),
  );

  return result;
}
