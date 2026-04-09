import 'package:cloud_firestore/cloud_firestore.dart';

class ProgramModel {
  final String id;
  final String coachId;
  final String title;
  final String description;
  final String duration; // e.g. "90 days"
  final DateTime createdAt;
  final String? previewImageUrl;
  final List<String> tags;
  final String status; // 'active', 'inactive'

  ProgramModel({
    required this.id,
    required this.coachId,
    required this.title,
    required this.description,
    required this.duration,
    required this.createdAt,
    this.previewImageUrl,
    this.tags = const [],
    this.status = 'active',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'coachId': coachId,
      'title': title,
      'description': description,
      'duration': duration,
      'createdAt': Timestamp.fromDate(createdAt),
      'previewImageUrl': previewImageUrl,
      'tags': tags,
      'status': status,
    };
  }

  factory ProgramModel.fromMap(Map<String, dynamic> map) {
    return ProgramModel(
      id: map['id'] ?? '',
      coachId: map['coachId'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      duration: map['duration'] ?? '',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      previewImageUrl: map['previewImageUrl'],
      tags: List<String>.from(map['tags'] ?? []),
      status: map['status'] ?? 'active',
    );
  }

  ProgramModel copyWith({
    String? title,
    String? description,
    String? duration,
    String? previewImageUrl,
    List<String>? tags,
    String? status,
  }) {
    return ProgramModel(
      id: id,
      coachId: coachId,
      title: title ?? this.title,
      description: description ?? this.description,
      duration: duration ?? this.duration,
      createdAt: createdAt,
      previewImageUrl: previewImageUrl ?? this.previewImageUrl,
      tags: tags ?? this.tags,
      status: status ?? this.status,
    );
  }
}
