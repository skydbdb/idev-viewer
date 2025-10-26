import 'package:flutter/material.dart';
import 'package:idev_viewer/src/internal/const/code.dart';

import '../../repo/home_repo.dart';

class ScopedIdGenerator {
  static String generateScopedId(String parentId, String itemType) {
    final parent = HomeRepo().getHierarchicalController(parentId);
    if (parent == null) return _generateGlobalId(itemType);

    Set<int> maxId = {0};
    for (var item in parent.controller.innerData) {
      if (isStackItemType(item, itemType)) {
        maxId.add(_extractIdNumber(item.id));
      }
    }
    for (final child in parent.getAllChildren()) {
      for (var item in child.controller.innerData) {
        if (isStackItemType(item, itemType)) {
          maxId.add(_extractIdNumber(item.id));
        }
      }
    }
    final itemType0 = itemType.replaceAll('Stack', '').replaceAll('Item', '');
    final newId =
        '${parentId}_${itemType0}_${maxId.reduce((a, b) => a > b ? a : b) + 1}';
    return newId;
  }

  static String _generateGlobalId(String itemType) {
    Set<int> maxId = {0};
    final homeRepo = HomeRepo();
    for (final controller in homeRepo.hierarchicalControllers.values) {
      for (var item in controller.controller.innerData) {
        if (isStackItemType(item, itemType)) {
          maxId.add(_extractIdNumber(item.id));
        }
      }
    }
    final itemType0 = itemType.replaceAll('Stack', '').replaceAll('Item', '');
    final newId = '${itemType0}_${maxId.reduce((a, b) => a > b ? a : b) + 1}';
    return newId;
  }

  static int _extractIdNumber(String id) {
    try {
      final parts = id.split('_');
      return int.parse(parts.last);
    } catch (e) {
      return 0;
    }
  }
}
