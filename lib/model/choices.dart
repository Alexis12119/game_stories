class Choices {
  final int id;
  final DateTime createdAt;
  final int questionID;
  final String choice;

  Choices({
    required this.id,
    required this.createdAt,
    required this.questionID,
    required this.choice,
  });

  factory Choices.fromJson(Map<String, dynamic> json) {
    return Choices(
      id: json['id'],
      createdAt: DateTime.parse(json['created_at']),
      questionID: json['question'],
      choice: json['choice'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'created_at': createdAt.toIso8601String(),
      'question': questionID,
      'choice': choice,
    };
  }

  @override
  String toString() {
    return 'Choices(id: $id, createdAt: $createdAt, questionID: $questionID, choice: "$choice")';
  }
}
