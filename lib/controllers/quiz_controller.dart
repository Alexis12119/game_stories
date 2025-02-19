import 'package:game_stories/model/quiz_set.dart';
import 'package:get/get.dart';

class QuizController extends GetxController {
  RxInt currentQuestionNumber = 0.obs;
  RxInt score = 0.obs;
  RxList<QuizSet> currentQuestion = <QuizSet>[].obs;

  List<QuizSet> ibongAdarnaQuiz = [
    QuizSet(
      questionText: 'Sino ang hari sa simula ng Ibong Adarna?',
      choices: ['Hari Fernando', 'Hari Alfonso', 'Hari Felipe', 'Hari Diego'],
      correctAnswerIndex: 0,
      selectedAnswer: null,
    ),
    QuizSet(
      questionText: 'Ano ang sakit ng hari?',
      choices: ['Sakit sa puso', 'Insomnia', 'ketong', 'Hindi alam'],
      correctAnswerIndex: 3,
      selectedAnswer: null,
    ),
    QuizSet(
      questionText: 'Ano ang mga pangalan ng mga anak ni Haring Fernando?',
      choices: ['Pedro, Diego, at Juan', 'Juan, Felipe, at Diego', 'Pedro, Juan, at Felipe', 'Felipe, Pedro, at Alfonso'],
      correctAnswerIndex: 0,
      selectedAnswer: null,
    ),
    QuizSet(
      questionText: 'Sino ang nagkwento ng kwento ng Ibong Adarna sa hari?',
      choices: ['Isang matanda', 'Isang engkanto', 'Isang mangkukulam', 'Isang anghel'],
      correctAnswerIndex: 0,
      selectedAnswer: null,
    ),
    QuizSet(
      questionText: 'Ano ang unang misyon ng mga prinsipe?',
      choices: [
        'Hanapin ang Ibong Adarna',
        'Iligtas ang isang prinsesa',
        'Sugpuin ang isang dragon',
        'Mag-explore ng mga bagong lugar'
      ],
      correctAnswerIndex: 0,
      selectedAnswer: null,
    ),
    QuizSet(
      questionText: 'Saan nagsimula ang mga prinsipe para hanapin ang Ibong Adarna?',
      choices: ['Bundok Tabor', 'Bundok Sinai', 'Bundok Arayat', 'Bundok Everest'],
      correctAnswerIndex: 2,
      selectedAnswer: null,
    ),
    QuizSet(
      questionText: 'Ano ang kailangan ng mga prinsipe mula sa Ibong Adarna para gumaling ang hari?',
      choices: ['Ang mga balahibo nito', 'Ang awit nito', 'Ang mga luha nito', 'Ang pugad nito'],
      correctAnswerIndex: 1,
      selectedAnswer: null,
    ),
    QuizSet(
      questionText: 'Sino sa mga prinsipe ang pinakamatanda?',
      choices: ['Pedro', 'Diego', 'Juan', 'Silang tatlo ay kambal'],
      correctAnswerIndex: 3,
      selectedAnswer: null,
    ),
    QuizSet(
      questionText: 'Ano ang nangyari kay Prinsipe Pedro nang subukan niyang hulihin ang Ibong Adarna?',
      choices: ['Siya ay nakatulog', 'Siya ay naging bato', 'Siya ay nawala sa daan', 'Nahuli niya ang ibon'],
      correctAnswerIndex: 1,
      selectedAnswer: null,
    ),
    QuizSet(
      questionText: 'Sino ang tumulong kay Prinsipe Pedro pagkatapos siyang maging bato?',
      choices: ['Prinsesa Leonora', 'Isang ermitanyo', 'Isang engkanto', 'Isang matandang babae'],
      correctAnswerIndex: 1,
      selectedAnswer: null,
    ),
  ];

  void resetCurrentItemNumber() {
    currentQuestionNumber.value = 0;
  }

  void resetScore() {
    score.value = 0;
  }
}
