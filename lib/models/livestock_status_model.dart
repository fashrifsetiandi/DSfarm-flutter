
import 'package:flutter/material.dart';

class LivestockStatusModel {
  final String id;
  final String code;
  final String name;
  final String colorHex;
  final String type; // 'active', 'sold', 'deceased', 'culled'
  final String validForGender; // 'male', 'female', 'both'
  final int sortOrder;
  
  const LivestockStatusModel({
    required this.id,
    required this.code,
    required this.name,
    required this.colorHex,
    required this.type,
    this.validForGender = 'both',
    this.sortOrder = 0,
  });

  Color get color {
    try {
      return Color(int.parse(colorHex.replaceAll('#', '0xFF')));
    } catch (_) {
      return Colors.grey;
    }
  }

  bool get isActive => type == 'active';
  bool get isSold => type == 'sold';
  bool get isDeceased => type == 'deceased';
  bool get isCulled => type == 'culled';
  bool get isExited => !isActive;

  factory LivestockStatusModel.fromJson(Map<String, dynamic> json) {
    return LivestockStatusModel(
      id: json['id'] as String,
      code: json['code'] as String,
      name: json['name'] as String,
      colorHex: json['color'] as String? ?? '#CCCCCC',
      type: json['type'] as String? ?? 'active',
      validForGender: json['valid_for_gender'] as String? ?? 'both',
      sortOrder: json['sort_order'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'code': code,
      'name': name,
      'color': colorHex,
      'type': type,
      'valid_for_gender': validForGender,
      'sort_order': sortOrder,
    };
  }
}
