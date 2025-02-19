class Question {
  final int id;
  final DateTime createdAt;
  final int quizID;
  final String text;

  Question({
    required this.id,
    required this.createdAt,
    required this.quizID,
    required this.text,
  });

  factory Question.fromJson(Map<String, dynamic> json) {
    return Question(
      id: json['id'],
      createdAt: DateTime.parse(json['created_at']),
      quizID: json['quiz'],
      text: json['text'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'created_at': createdAt.toIso8601String(),
      'quiz': quizID,
      'text': text,
    };
  }

  @override
  String toString() {
    return 'Question(id: $id, createdAt: $createdAt, quizID: $quizID, text: "$text")';
  }
}
