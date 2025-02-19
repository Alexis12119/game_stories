class QuizSet {
  String questionText;
  final List<String> choices;
  int correctAnswerIndex;
  var selectedAnswer;

  QuizSet({
    required this.questionText,
    required this.choices,
    required this.correctAnswerIndex,
    required this.selectedAnswer,
  });

  // Override the toString() method to print QuizSet details
  @override
  String toString() {
    return 'QuizSet(questionText: $questionText, choices: $choices, correctAnswerIndex: $correctAnswerIndex, selectedAnswer: $selectedAnswer)';
  }
}
