import 'package:uuid/uuid.dart';

class Task {
  final String id;
  String title;
  bool isDone;
  DateTime createdAt;

  Task({
    String? id,
    required this.title,
    this.isDone = false,
    DateTime? createdAt,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'isDone': isDone,
        'createdAt': createdAt.toIso8601String(),
      };

  factory Task.fromJson(Map<String, dynamic> json) => Task(
        id: json['id'],
        title: json['title'],
        isDone: json['isDone'] ?? false,
        createdAt: DateTime.parse(json['createdAt']),
      );
}
