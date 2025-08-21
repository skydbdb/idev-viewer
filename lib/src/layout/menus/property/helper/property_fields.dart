import 'package:flutter/material.dart';
import 'package:idev_v1/src/layout/menus/property/helper/property_content_renderers.dart';
import 'property_constants.dart';

InputDecoration buildInputDecoration({
  String? hintText,
  String? prefixText,
  bool filled = true,
  bool isDense = true,
  bool enabled = true,
  Icon? prefixIcon,
  String? suffixText,
}) {
  return InputDecoration(
    hintText: hintText,
    prefixText: prefixText,
    prefixStyle: const TextStyle(color: kInputPrefixColor),
    filled: filled,
    fillColor: kInputFillColor,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(kInputBorderRadius),
      borderSide: const BorderSide(color: kInputBorderColor),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(kInputBorderRadius),
      borderSide: const BorderSide(color: kInputBorderColor),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(kInputBorderRadius),
      borderSide: const BorderSide(color: kInputFocusedBorderColor),
    ),
    contentPadding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 8.0),
    isDense: isDense,
    enabled: enabled,
    prefixIcon: prefixIcon,
    suffixText: suffixText,
    suffixStyle: const TextStyle(color: kInputPrefixColor),
  );
}

Widget buildStyledTextField({
  required TextEditingController controller,
  required ValueChanged<String> onChanged,
  ValueChanged<String>? onSubmitted,
  String? hintText,
  String? prefixText,
  bool readOnly = false,
  bool enabled = true,
  Icon? prefixIcon,
  String? suffixText,
  TextInputType? keyboardType,
}) {
  return TextField(
    controller: controller,
    onChanged: onChanged,
    onSubmitted: onSubmitted,
    readOnly: readOnly,
    enabled: enabled,
    keyboardType: keyboardType,
    decoration: buildInputDecoration(
      hintText: hintText,
      prefixText: prefixText,
      prefixIcon: prefixIcon,
      suffixText: suffixText,
    ),
  );
}

Widget buildStyledDropdown<T>({
  required T value,
  required List<T> items,
  required ValueChanged<T?> onChanged,
  required BuildContext context,
  String? hintText,
}) {
  // value가 items에 존재하는지 확인
  final validValue = items.contains(value) ? value : null;

  return DropdownButtonFormField<T>(
    value: validValue,
    items: items
        .map(
          (item) => DropdownMenuItem(
            value: item,
            child: Text(item.toString()),
          ),
        )
        .toList(),
    onChanged: onChanged,
    decoration: buildInputDecoration(hintText: hintText),
    isExpanded: true,
  );
}

Widget buildStyledSwitch({
  required bool value,
  required ValueChanged<bool> onChanged,
  required String label,
  required BuildContext context,
}) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(
        label,
        style: value
            ? Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: kInputFocusedBorderColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 16.0,
                )
            : Theme.of(context).textTheme.labelMedium,
      ),
      Transform.scale(
        scale: 0.8,
        child: Switch(
          value: value,
          onChanged: onChanged,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      ),
    ],
  );
}

Widget buildStyledCheckboxList<T>({
  required List<T> selectedValues,
  required List<T> allItems,
  required ValueChanged<List<T>> onChanged,
  required BuildContext context,
  String? hintText,
  int? maxHeight,
}) {
  return Container(
    constraints: BoxConstraints(
      maxHeight: maxHeight?.toDouble() ?? 100,
    ),
    decoration: BoxDecoration(
      border: Border.all(color: kInputBorderColor),
      borderRadius: BorderRadius.circular(kInputBorderRadius),
      color: kInputFillColor,
    ),
    child: ListView.builder(
      shrinkWrap: true,
      itemCount: allItems.length,
      itemBuilder: (context, index) {
        final item = allItems[index];
        final isSelected = selectedValues.contains(item);

        return CheckboxListTile(
          title: Text(
            item.toString(),
            style: const TextStyle(color: Colors.white, fontSize: 14),
          ),
          value: isSelected,
          onChanged: (bool? value) {
            final newSelectedValues = List<T>.from(selectedValues);
            if (value == true) {
              newSelectedValues.add(item);
            } else {
              newSelectedValues.remove(item);
            }
            onChanged(newSelectedValues);
          },
          activeColor: kInputFocusedBorderColor,
          checkColor: Colors.white,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 8.0, vertical: 2.0),
          dense: true,
        );
      },
    ),
  );
}

Widget buildStyledCheckboxListWithTextField({
  required List<Map<String, String>> selectedValues,
  required List<String> allItems,
  required ValueChanged<List<Map<String, String>>> onChanged,
  required BuildContext context,
  String? hintText,
  int? maxHeight,
}) {
  return Container(
    constraints: BoxConstraints(
      maxHeight: maxHeight?.toDouble() ?? 100,
    ),
    decoration: BoxDecoration(
      border: Border.all(color: kInputBorderColor),
      borderRadius: BorderRadius.circular(kInputBorderRadius),
      color: kInputFillColor,
    ),
    child: ListView.builder(
      shrinkWrap: true,
      itemCount: allItems.length,
      itemBuilder: (context, index) {
        final item = allItems[index];
        final isSelected = selectedValues.any((map) => map.keys.first == item);
        final selectedMap = selectedValues.firstWhere(
          (map) => map.keys.first == item,
          orElse: () => {item: item},
        );
        final displayValue = selectedMap.values.first;

        void onChanged0(String newValue) {
          final newSelectedValues =
              List<Map<String, String>>.from(selectedValues);
          final existingIndex =
              newSelectedValues.indexWhere((map) => map.keys.first == item);
          if (existingIndex != -1) {
            newSelectedValues[existingIndex] = {item: newValue};
          } else {
            newSelectedValues.add({item: newValue});
          }
          onChanged(newSelectedValues);
        }

        return CheckboxListTile(
          title: Row(
            children: [
              Expanded(
                flex: 2,
                child: Text(
                  item,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 3,
                child: DynamicTextField(
                  fieldKey: item,
                  initialValue: displayValue,
                  onChanged: onChanged0,
                  onSubmitted: onChanged0,
                  decoration: buildInputDecoration(hintText: item),
                ),
              ),
            ],
          ),
          value: isSelected,
          onChanged: (bool? value) {
            final newSelectedValues =
                List<Map<String, String>>.from(selectedValues);
            if (value == true) {
              if (!newSelectedValues.any((map) => map.keys.first == item)) {
                newSelectedValues.add({item: item});
              }
            } else {
              newSelectedValues.removeWhere((map) => map.keys.first == item);
            }
            onChanged(newSelectedValues);
          },
          activeColor: kInputFocusedBorderColor,
          checkColor: Colors.white,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 8.0, vertical: 2.0),
          dense: true,
        );
      },
    ),
  );
}
