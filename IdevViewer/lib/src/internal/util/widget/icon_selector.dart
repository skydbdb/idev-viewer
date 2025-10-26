import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../const/code.dart';

class IconSelectorDropdown extends StatelessWidget {
  final String value;
  final Function(String) onChanged;

  const IconSelectorDropdown({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      constraints: const BoxConstraints(
        maxHeight: 300,
      ),
      initialValue: value,
      onSelected: onChanged,
      itemBuilder: (context) => [
        // 기본 제공되는 20개 아이콘
        ...icons.take(20).map((icon) => PopupMenuItem<String>(
              value: icon['value'],
              child: Row(
                children: [
                  iconStringToWidget(icon['value']),
                  const SizedBox(width: 8),
                  Expanded(child: Text(icon['label'])),
                ],
              ),
            )),
        // 구분선
        const PopupMenuDivider(),
        // 더보기 옵션
        const PopupMenuItem<String>(
          value: 'show_more',
          child: Row(
            children: [
              Icon(Symbols.grid_view),
              SizedBox(width: 8),
              Text('더 많은 아이콘 보기'),
            ],
          ),
        ),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          children: [
            iconStringToWidget(value),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                icons.firstWhere(
                      (e) => e['value'] == value,
                      orElse: () => {'label': value},
                    )['label'] ??
                    value,
              ),
            ),
            const Icon(Symbols.arrow_drop_down),
          ],
        ),
      ),
    );
  }
}

class IconGridDialog extends StatefulWidget {
  final String initialValue;
  final Function(String) onSelected;

  const IconGridDialog({
    super.key,
    required this.initialValue,
    required this.onSelected,
  });

  @override
  State<IconGridDialog> createState() => _IconGridDialogState();
}

class _IconGridDialogState extends State<IconGridDialog> {
  String? searchQuery;

  List<Map<String, dynamic>> getFilteredIcons() {
    if (searchQuery == null || searchQuery!.isEmpty) {
      return List<Map<String, dynamic>>.from(icons);
    }
    return List<Map<String, dynamic>>.from(icons.where((icon) {
      return icon['label'].toLowerCase().contains(searchQuery!.toLowerCase()) ||
          icon['value'].toLowerCase().contains(searchQuery!.toLowerCase());
    }));
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 600,
        height: 400,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // 검색 바
            TextField(
              decoration: InputDecoration(
                prefixIcon: const Icon(Symbols.search),
                hintText: '아이콘 검색...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  searchQuery = value;
                });
              },
            ),
            const SizedBox(height: 16),
            // 아이콘 그리드
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 6,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: getFilteredIcons().length,
                itemBuilder: (context, index) {
                  final icon = getFilteredIcons()[index];
                  return InkWell(
                    onTap: () {
                      widget.onSelected(icon['value']);
                      Navigator.of(context).pop();
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: widget.initialValue == icon['value']
                              ? Theme.of(context).primaryColor
                              : Colors.grey[300]!,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          iconStringToWidget(icon['value']),
                          const SizedBox(height: 4),
                          Text(
                            icon['label'],
                            style: const TextStyle(fontSize: 12),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            // Material Symbols 링크
            TextButton.icon(
              onPressed: () async {
                final url = Uri.parse(
                    'https://fonts.google.com/icons?icon.set=Material+Symbols');
                if (await canLaunchUrl(url)) {
                  await launchUrl(url);
                }
              },
              icon: const Icon(Symbols.open_in_new),
              label: const Text('Material Symbols 아이콘 목록 보기'),
            ),
          ],
        ),
      ),
    );
  }
}
