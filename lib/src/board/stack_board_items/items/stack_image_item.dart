import 'package:flutter/material.dart';
import '/src/board/helpers.dart';
import '/src/board/core/stack_board_item/stack_item.dart';
import '/src/board/core/stack_board_item/stack_item_content.dart';
import '/src/board/core/stack_board_item/stack_item_status.dart';
import '/src/board/widget_style_extension/ex_offset.dart';
import '/src/board/widget_style_extension/ex_size.dart';
import 'package:equatable/equatable.dart';

class ImageItemContent extends Equatable implements StackItemContent {
  const ImageItemContent({
    this.url,
    this.assetName,
    this.color,
    this.colorBlendMode,
    this.fit = BoxFit.scaleDown,
    this.repeat = ImageRepeat.noRepeat,
    // this.width,
    // this.height,
    // this.semanticLabel,
    // this.matchTextDirection = false,
    // this.gaplessPlayback = false,
    // this.isAntiAlias = false,
    // this.filterQuality = FilterQuality.low,
    // this.excludeFromSemantics = false,
  });

  factory ImageItemContent.fromJson(Map<String, dynamic> json) {
    return ImageItemContent(
      url: asNullT<String>(json['url']),
      assetName: asNullT<String>(json['assetName']),
      color: asNullT<String>(json['color']),
      colorBlendMode: json['colorBlendMode'] != null
          ? BlendMode.values.byName(json['colorBlendMode'])
          : BlendMode.clear,
      fit: json['fit'] != null
          ? BoxFit.values.byName(json['fit'])
          : BoxFit.scaleDown,
      repeat: json['repeat'] != null
          ? ImageRepeat.values.byName(json['repeat'])
          : ImageRepeat.noRepeat,
      // width: asNullT<double>(json['width']),
      // height: asNullT<double>(json['height']),
      // semanticLabel: asNullT<String>(json['semanticLabel']),
      // matchTextDirection: asNullT<bool>(json['matchTextDirection']) ?? false,
      // gaplessPlayback: asNullT<bool>(json['gaplessPlayback']) ?? false,
      // isAntiAlias: asNullT<bool>(json['isAntiAlias']) ?? true,
      // filterQuality: json['filterQuality'] != null
      //     ? FilterQuality.values[asT<int>(json['filterQuality'])]
      //     : FilterQuality.high,
      //   excludeFromSemantics:
      // asNullT<bool>(json['excludeFromSemantics']) ?? false,
    );
  }

  final String? url;
  final String? assetName;
  final String? color;
  final BlendMode? colorBlendMode;
  final BoxFit fit;
  final ImageRepeat repeat;
  // final double? width;
  // final double? height;
  // final String? semanticLabel;
  // final bool matchTextDirection;
  // final bool gaplessPlayback;
  // final bool isAntiAlias;
  // final FilterQuality filterQuality;
  // final bool excludeFromSemantics;

  ImageProvider get image {
    if (url != null && url!.isNotEmpty) {
      return NetworkImage(url!);
    } else if (assetName != null && assetName!.isNotEmpty) {
      return AssetImage(assetName!);
    } else {
      throw Exception('url과 assetName 중 하나는 반드시 필요합니다');
    }
  }

  ImageItemContent copyWith({
    String? url,
    String? assetName,
    String? color,
    BlendMode? colorBlendMode,
    BoxFit? fit,
    ImageRepeat? repeat,
    // double? width,
    // double? height,
    // String? semanticLabel,
    // bool? matchTextDirection,
    // bool? gaplessPlayback,
    // bool? isAntiAlias,
    // FilterQuality? filterQuality,
    // bool? excludeFromSemantics,
  }) {
    return ImageItemContent(
      url: url ?? this.url,
      assetName: assetName ?? this.assetName,
      color: color ?? this.color,
      colorBlendMode: colorBlendMode ?? this.colorBlendMode,
      fit: fit ?? this.fit,
      repeat: repeat ?? this.repeat,
      // width: width ?? this.width,
      // height: height ?? this.height,
      // semanticLabel: semanticLabel ?? this.semanticLabel,
      // matchTextDirection: matchTextDirection ?? this.matchTextDirection,
      // gaplessPlayback: gaplessPlayback ?? this.gaplessPlayback,
      // isAntiAlias: isAntiAlias ?? this.isAntiAlias,
      // filterQuality: filterQuality ?? this.filterQuality,
      // excludeFromSemantics: excludeFromSemantics ?? this.excludeFromSemantics,
    );
  }

  ImageItemContent setRes({String? url, String? assetName}) {
    return copyWith(url: url, assetName: assetName);
  }

  @override
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      if (url != null) 'url': url,
      if (assetName != null) 'assetName': assetName,
      if (color != null) 'color': color, // color?.value,
      if (colorBlendMode != null) 'colorBlendMode': colorBlendMode?.name,
      if (fit != BoxFit.cover) 'fit': fit.name,
      if (repeat != ImageRepeat.noRepeat) 'repeat': repeat.name,
      // if (width != null) 'width': width,
      // if (height != null) 'height': height,
      // if (semanticLabel != null) 'semanticLabel': semanticLabel,
      // if (matchTextDirection) 'matchTextDirection': matchTextDirection,
      // if (gaplessPlayback) 'gaplessPlayback': gaplessPlayback,
      // if (isAntiAlias) 'isAntiAlias': isAntiAlias,
      // if (filterQuality != FilterQuality.low)
      //   'filterQuality': filterQuality.index,
      // if (excludeFromSemantics) 'excludeFromSemantics': excludeFromSemantics,
    };
  }

  @override
  List<Object?> get props => [
        url,
        assetName,
        color,
        colorBlendMode,
        fit,
        repeat,
      ];
}

class StackImageItem extends StackItem<ImageItemContent> {
  StackImageItem({
    super.content,
    required super.boardId,
    super.id,
    super.angle = null,
    required super.size,
    super.offset,
    super.lockZOrder = null,
    super.dock = null,
    super.permission,
    super.padding,
    super.status = null,
    super.theme,
  });

  factory StackImageItem.fromJson(Map<String, dynamic> data) {
    final paddingJson = data['padding'];
    EdgeInsets padding;
    if (paddingJson is Map) {
      padding = EdgeInsets.fromLTRB(
        (paddingJson['left'] ?? 0).toDouble(),
        (paddingJson['top'] ?? 0).toDouble(),
        (paddingJson['right'] ?? 0).toDouble(),
        (paddingJson['bottom'] ?? 0).toDouble(),
      );
    } else if (paddingJson is num) {
      padding = EdgeInsets.all(paddingJson.toDouble());
    } else {
      padding = EdgeInsets.zero;
    }
    return StackImageItem(
      boardId: asT<String>(data['boardId']),
      id: asT<String>(data['id']),
      angle: asT<double>(data['angle']),
      size: jsonToSize(asMap(data['size'])),
      offset:
          data['offset'] == null ? null : jsonToOffset(asMap(data['offset'])),
      padding: padding,
      status: StackItemStatus.values[data['status'] as int],
      lockZOrder: asNullT<bool>(data['lockZOrder']) ?? false,
      dock: asNullT<bool>(data['dock']) ?? false,
      permission: data['permission'] as String,
      theme: data['theme'] as String?,
      content: ImageItemContent.fromJson(asMap(data['content'])),
    );
  }

  void setUrl(String url) {
    content?.setRes(url: url);
  }

  void setAssetName(String assetName) {
    content?.setRes(assetName: assetName);
  }

  @override
  StackImageItem copyWith({
    String? boardId,
    String? id,
    double? angle,
    Size? size,
    Offset? offset,
    EdgeInsets? padding,
    StackItemStatus? status,
    bool? lockZOrder,
    bool? dock,
    String? permission,
    String? theme,
    ImageItemContent? content,
  }) {
    return StackImageItem(
      boardId: boardId ?? this.boardId,
      id: id ?? this.id,
      angle: angle ?? this.angle,
      size: size ?? this.size,
      offset: offset ?? this.offset,
      padding: padding ?? this.padding,
      status: status ?? this.status,
      lockZOrder: lockZOrder ?? this.lockZOrder,
      dock: dock ?? this.dock,
      permission: permission ?? this.permission,
      theme: theme ?? this.theme,
      content: content ?? this.content,
    );
  }
}
