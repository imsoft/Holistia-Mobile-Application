import 'package:flutter/foundation.dart';

@immutable
class CheckIn {
  const CheckIn({
    required this.id,
    required this.challengeId,
    required this.userId,
    required this.date,
    this.value,
    this.note,
    this.imageUrls = const [],
    required this.createdAt,
  });

  final String id;
  final String challengeId;
  final String userId;
  final DateTime date;
  final num? value;
  final String? note;

  /// Lista de URLs de imágenes (vacía si no hay ninguna). Soporta hasta 6.
  final List<String> imageUrls;

  final DateTime createdAt;

  factory CheckIn.fromJson(Map<String, dynamic> json) {
    // Retrocompatibilidad: leer de image_urls (nuevo) o image_url (viejo).
    final rawUrls =
        (json['image_urls'] as List<dynamic>?)?.cast<String>() ?? [];
    final legacyUrl = json['image_url'] as String?;
    final imageUrls = rawUrls.isNotEmpty
        ? rawUrls
        : (legacyUrl != null && legacyUrl.isNotEmpty ? [legacyUrl] : <String>[]);

    return CheckIn(
      id: json['id'] as String,
      challengeId: json['challenge_id'] as String,
      userId: json['user_id'] as String,
      date: DateTime.parse(json['date'] as String),
      value: json['value'] != null ? (json['value'] as num) : null,
      note: json['note'] as String?,
      imageUrls: imageUrls,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'challenge_id': challengeId,
      'user_id': userId,
      'date': date.toIso8601String().split('T').first,
      'value': value,
      'note': note,
      'image_urls': imageUrls,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
