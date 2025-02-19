class Quiz {
  final int id;
  final DateTime createdAt;
  final String quizTitle;

  Quiz({
    required this.id,
    required this.createdAt,
    required this.quizTitle,
  });

  factory Quiz.fromJson(Map<String, dynamic> json) {
    return Quiz(
      id: json['id'],
      createdAt: DateTime.parse(json['created_at']),
      quizTitle: json['quiz_title'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'created_at': createdAt.toIso8601String(),
      'quiz_title': quizTitle,
    };
  }

  @override
  String toString() {
    return 'Quiz(id: $id, createdAt: $createdAt, storyID: $quizTitle)';
  }
}
