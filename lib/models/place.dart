import 'package:flutter/material.dart';

enum PlaceType {
  restaurant,
  holisticCenter,
  event,
  commerce,
  place;

  static PlaceType fromString(String? v) {
    switch (v) {
      case 'restaurant':
        return PlaceType.restaurant;
      case 'holistic_center':
        return PlaceType.holisticCenter;
      case 'event':
        return PlaceType.event;
      case 'commerce':
        return PlaceType.commerce;
      default:
        return PlaceType.place;
    }
  }

  String get value {
    switch (this) {
      case PlaceType.restaurant:
        return 'restaurant';
      case PlaceType.holisticCenter:
        return 'holistic_center';
      case PlaceType.event:
        return 'event';
      case PlaceType.commerce:
        return 'commerce';
      case PlaceType.place:
        return 'place';
    }
  }

  String get label {
    switch (this) {
      case PlaceType.restaurant:
        return 'Restaurante';
      case PlaceType.holisticCenter:
        return 'Centro Holístico';
      case PlaceType.event:
        return 'Evento';
      case PlaceType.commerce:
        return 'Comercio';
      case PlaceType.place:
        return 'Lugar';
    }
  }

  IconData get icon {
    switch (this) {
      case PlaceType.restaurant:
        return Icons.restaurant;
      case PlaceType.holisticCenter:
        return Icons.self_improvement;
      case PlaceType.event:
        return Icons.event;
      case PlaceType.commerce:
        return Icons.storefront;
      case PlaceType.place:
        return Icons.place;
    }
  }
}

@immutable
class Place {
  const Place({
    required this.id,
    required this.type,
    required this.name,
    this.description,
    this.address,
    this.phone,
    this.imageUrl,
    this.eventDate,
    this.website,
    this.instagram,
    this.facebook,
    this.tiktok,
    required this.createdAt,
  });

  final String id;
  final PlaceType type;
  final String name;
  final String? description;
  final String? address;
  final String? phone;
  final String? imageUrl;
  final DateTime? eventDate;
  final String? website;
  final String? instagram;
  final String? facebook;
  final String? tiktok;
  final DateTime createdAt;

  factory Place.fromJson(Map<String, dynamic> json) {
    return Place(
      id: json['id'] as String,
      type: PlaceType.fromString(json['type'] as String?),
      name: json['name'] as String,
      description: json['description'] as String?,
      address: json['address'] as String?,
      phone: json['phone'] as String?,
      imageUrl: json['image_url'] as String?,
      eventDate: json['event_date'] != null
          ? DateTime.parse(json['event_date'] as String)
          : null,
      website: json['website'] as String?,
      instagram: json['instagram'] as String?,
      facebook: json['facebook'] as String?,
      tiktok: json['tiktok'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Place copyWith({
    String? id,
    PlaceType? type,
    String? name,
    String? description,
    String? address,
    String? phone,
    String? imageUrl,
    DateTime? eventDate,
    String? website,
    String? instagram,
    String? facebook,
    String? tiktok,
    DateTime? createdAt,
  }) {
    return Place(
      id: id ?? this.id,
      type: type ?? this.type,
      name: name ?? this.name,
      description: description ?? this.description,
      address: address ?? this.address,
      phone: phone ?? this.phone,
      imageUrl: imageUrl ?? this.imageUrl,
      eventDate: eventDate ?? this.eventDate,
      website: website ?? this.website,
      instagram: instagram ?? this.instagram,
      facebook: facebook ?? this.facebook,
      tiktok: tiktok ?? this.tiktok,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
