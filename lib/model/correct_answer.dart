class CorrectAnswer {
  final int id;
  final DateTime createdAt;
  final int questionID;
  final int choiceID;

  CorrectAnswer({
    required this.id,
    required this.createdAt,
    required this.questionID,
    required this.choiceID,
  });

  factory CorrectAnswer.fromJson(Map<String, dynamic> json) {
    return CorrectAnswer(
      id: json['id'],
      createdAt: DateTime.parse(json['created_at']),
      questionID: json['question'],
      choiceID: json['choice'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'created_at': createdAt.toIso8601String(),
      'question': questionID,
      'choice': choiceID,
    };
  }

  @override
  String toString() {
    return 'CorrectAnswer(id: $id, createdAt: $createdAt, questionID: $questionID, choiceID: $choiceID)';
  }
}
