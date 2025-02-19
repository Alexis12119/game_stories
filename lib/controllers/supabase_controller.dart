// ignore_for_file: unnecessary_null_comparison, avoid_print

import 'package:flutter/widgets.dart';
import 'package:game_stories/controllers/quiz_controller.dart';
import 'package:game_stories/model/choices.dart';
import 'package:game_stories/model/correct_answer.dart';
import 'package:game_stories/model/question.dart';
import 'package:game_stories/model/quiz.dart';
import 'package:game_stories/model/quiz_set.dart';
import 'package:game_stories/model/story.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupaBaseController extends GetxController {
  final SupabaseClient supabase = Supabase.instance.client;

  var isLoading = true.obs;
  var score = 0.obs;
  var storiesMap = <int, Map<String, dynamic>>{}.obs;

  Future<List<Map<String, dynamic>>> fetchStudents() async {
    final response = await supabase
        .from('profiles')
        .select('id, first_name, last_name, section_id, section(name)')
        .order('first_name', ascending: true);

      return response.map((student) {
        return {
          'id': student['id'],
          'first_name': student['first_name'],
          'last_name': student['last_name'],
          'section_name': student['section']['name'] ?? 'N/A',
        };
      }).toList();
  }

  Future<Map<String, dynamic>?> fetchStudentProfile(String studentId) async {
    final response = await supabase
        .from('profiles')
        .select('id, first_name, last_name, section(name)')
        .eq('id', studentId)
        .single();

    if (response != null) {
      return {
        'id': response['id'],
        'first_name': response['first_name'],
        'last_name': response['last_name'],
        'section_name': response['section']['name'] ?? 'N/A',
      };
    }
    return null;
  }

  Future<List<Map<String, dynamic>>> fetchStudentScores(
      String studentId) async {
    final response = await supabase
        .from('scores')
        .select('score, quiz(quiz_title)')
        .eq('user', studentId)
        .order('created_at', ascending: false);

    return response.map((scoreData) {
      return {
        'score': scoreData['score'],
        'quiz_title': scoreData['quiz']['quiz_title'] ?? 'Unknown Quiz',
      };
    }).toList();
  }

  Future<Map<String, dynamic>> fetchProfile() async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not logged in');

      final profile = await supabase
          .from('profiles')
          .select('*, sections:section_id(name)')
          .eq('id', userId)
          .single();

      return {
        'first_name': profile['first_name'],
        'last_name': profile['last_name'],
        'section_name': profile['sections']?['name'],
      };
    } catch (e) {
      print('Error fetching profile: $e');
      rethrow;
    }
  }

  late RxList<Question> questions = <Question>[].obs;
  late RxList<Story> stories = <Story>[].obs;
  late RxList<Quiz> quizzes = <Quiz>[].obs;
  late RxList<Choices> choices = <Choices>[].obs;
  late RxList<CorrectAnswer> correctAnswer = <CorrectAnswer>[].obs;
  var chaptersAndQuizzes = <Map<String, dynamic>>[].obs;
  final chaptersAndQuizzesId = 'chaptersAndQuizzes'.obs;

  late RxList<QuizSet> quizSet = <QuizSet>[].obs;

  final _prefs = SharedPreferences.getInstance();
  @override
  void onInit() {
    super.onInit();
    fetchStoryLocal();
  }

  Future<void> deleteQuiz(int quizId) async {
    final supabase = Supabase.instance.client;

    try {
      isLoading.value = true;
      final response = await supabase
          .from('quiz') // Table name in Supabase
          .delete() // Perform delete operation
          .eq('id', quizId);

      if (response.error != null) {
        throw Exception('Failed to delete quiz: ${response.error?.message}');
      }

      print('Quiz with ID $quizId deleted successfully');
    } catch (error) {
      print('Error deleting quiz: $error');
      Get.snackbar('Error', error.toString());
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> uploadQuizData(List<QuizSet> quizSets, String quizTitle) async {
    final supabase = Supabase.instance.client;

    try {
      // Step 1: Insert quiz title into the `quiz` table
      final quizResponse = await supabase
          .from('quiz')
          .insert({
            'quiz_title': quizTitle,
          })
          .select('id')
          .single();
      print('Quiz response: $quizResponse');

      final quizID = quizResponse['id'];

      // Step 2: For each quiz set, insert questions, choices, and correct answers
      for (var quizSet in quizSets) {
        // Insert question
        final questionResponse = await supabase
            .from('question')
            .insert({
              'quiz': quizID,
              'text': quizSet.questionText,
            })
            .select('id')
            .single();

        final questionID = questionResponse['id'];

        // Step 3: Insert choices for the question
        List<Map<String, dynamic>> choicesData = [];
        for (int i = 0; i < quizSet.choices.length; i++) {
          choicesData.add({
            'question': questionID,
            'choice': quizSet.choices[i],
          });
        }

        final choicesResponse =
            await supabase.from('choices').insert(choicesData).select('id');

        // Step 4: Insert the correct answer into the `correct_answers` table
        int correctAnswerID = choicesResponse[quizSet.correctAnswerIndex]['id'];

        await supabase.from('correct_answers').insert({
          'question': questionID,
          'choice': correctAnswerID,
        });
      }

      // All data uploaded successfully
      print('Quiz data uploaded successfully');
    } catch (e) {
      // Handle any errors that occur during uploading
      Get.snackbar('Error', 'Failed to upload quiz data: $e');
    } finally {
      isLoading.value = false;
    }
  }

  void updateQuizSet(RxList<QuizSet> newQuizSet) {
    quizSet = newQuizSet;
  }

  Future<void> addScore(int score, String userId, int quizId) async {
    print('Score: $score');
    print('User ID: $userId');
    print('Quiz ID: $quizId');
    try {
      final response = await supabase.from('scores').insert({
        'score': score,
        'user': userId,
        'quiz': quizId,
      });

      if (response.error != null) {
        print('Error inserting score: ${response.error!.message}');
      } else {
        print('Score added successfully');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> fetchChaptersAndQuizzes({int? storyId}) async {
    try {
      isLoading(true);
      // Build the query for chapters
      final chaptersQuery =
          supabase.from('chapters').select('id, title, story_id');

      // If storyId is provided, filter chapters by story_id
      if (storyId != null) {
        chaptersQuery.eq('story_id', storyId);
      }

      // Fetch chapters
      final chaptersResponse = await chaptersQuery;
      debugPrint(chaptersResponse.toString(), wrapWidth: 1024 * 10);

      // Fetch quizzes
      final quizzesResponse =
          await supabase.from('quiz').select('id, quiz_title, chapter');

      if (chaptersResponse != null && quizzesResponse != null) {
        // Map chapters with their quizzes
        final List<Map<String, dynamic>> combinedList = [];

        for (var chapter in chaptersResponse) {
          final chapterId = chapter['id'];

          // Filter quizzes belonging to this chapter
          final chapterQuizzes = quizzesResponse
              .where((quiz) => quiz['chapter'] == chapterId)
              .toList();

          combinedList.add({
            'chapter': chapter,
            'quizzes': chapterQuizzes,
          });
        }

        chaptersAndQuizzes.value = combinedList;
      }
    } catch (error) {
      print("Error fetching chapters and quizzes: $error");
    } finally {
      isLoading(false);
    }
  }

  Future<void> fetchChaptersAndQuizzesLocal({int? storyId}) async {
    try {
      isLoading(true);

      // Hardcoded chapters data
      final chaptersResponse = [
        {
          'id': 1,
          'title': 'Episode 1',
          'story_id': 1,
          'video': 'assets/videos/ep1.mp4',
        },
        {
          'id': 2,
          'title': 'Episode 2',
          'story_id': 1,
          'video': 'assets/videos/ep2.mp4',
        },
        {
          'id': 3,
          'title': 'Episode 3',
          'story_id': 1,
          'video': 'assets/videos/ep3.mp4',
        },
        {
          'id': 4,
          'title': 'Episode 4',
          'story_id': 1,
          'video': 'assets/videos/ep4.mp4',
        },
        {
          'id': 5,
          'title': 'Episode 5',
          'story_id': 1,
          'video': 'assets/videos/ep5.mp4',
        },
        {
          'id': 6,
          'title': 'Episode 6',
          'story_id': 1,
          'video': 'assets/videos/ep6.mp4',
        },
        {
          'id': 7,
          'title': 'Episode 7',
          'story_id': 1,
          'video': 'assets/videos/ep7.mp4',
        },
        {
          'id': 8,
          'title': 'Episode 8',
          'story_id': 1,
          'video': 'assets/videos/ep8.mp4',
        },
        {
          'id': 9,
          'title': 'Episode 9',
          'story_id': 1,
          'video': 'assets/videos/ep9.mp4',
        },
        {
          'id': 10,
          'title': 'Episode 10',
          'story_id': 1,
          'video': 'assets/videos/ep10.mp4',
        },
        {
          'id': 11,
          'title': 'Episode 11',
          'story_id': 1,
          'video': 'assets/videos/ep11.mp4',
        },
        {
          'id': 12,
          'title': 'Episode 12',
          'story_id': 1,
          'video': 'assets/videos/ep12.mp4',
        },
        {
          'id': 13,
          'title': 'Episode 13',
          'story_id': 1,
          'video': 'assets/videos/ep13.mp4',
        },
        {
          'id': 14,
          'title': 'Episode 14',
          'story_id': 1,
          'video': 'assets/videos/ep14.mp4',
        },
        {
          'id': 15,
          'title': 'Episode 15',
          'story_id': 1,
          'video': 'assets/videos/ep15.mp4',
        },
        {
          'id': 16,
          'title': 'Episode 16',
          'story_id': 1,
          'video': 'assets/videos/ep16.mp4',
        },
        {
          'id': 17,
          'title': 'Episode 17',
          'story_id': 1,
          'video': 'assets/videos/ep17.mp4',
        },
        {
          'id': 18,
          'title': 'Episode 18',
          'story_id': 1,
          'video': 'assets/videos/ep18.mp4',
        },
        {
          'id': 98,
          'title': 'Alamat ng Tikbalang',
          'story_id': 3,
          'video': 'assets/videos/aswang.mp4',
        },
        {
          'id': 99,
          'title': 'Alamat ng Tikbalang',
          'story_id': 2,
          'video': 'assets/videos/alamat_ng_tikbalang.mp4',
        },
      ];

      // Hardcoded quizzes data
      final quizzesResponse = [
        {'id': 1, 'quiz_title': 'Quiz 1', 'chapter': 1},
        {'id': 2, 'quiz_title': 'Quiz 2', 'chapter': 2},
        {'id': 3, 'quiz_title': 'Quiz 3', 'chapter': 3},
        {'id': 4, 'quiz_title': 'Quiz 4', 'chapter': 4},
        {'id': 5, 'quiz_title': 'Quiz 5', 'chapter': 5},
        {'id': 6, 'quiz_title': 'Quiz 6', 'chapter': 6},
        {'id': 7, 'quiz_title': 'Quiz 7', 'chapter': 7},
        {'id': 8, 'quiz_title': 'Quiz 8', 'chapter': 8},
        {'id': 9, 'quiz_title': 'Quiz 9', 'chapter': 9},
        {'id': 10, 'quiz_title': 'Quiz 10', 'chapter': 10},
        {'id': 11, 'quiz_title': 'Quiz 11', 'chapter': 11},
        {'id': 12, 'quiz_title': 'Quiz 12', 'chapter': 12},
        {'id': 13, 'quiz_title': 'Quiz 13', 'chapter': 13},
        {'id': 14, 'quiz_title': 'Quiz 14', 'chapter': 14},
        {'id': 15, 'quiz_title': 'Quiz 15', 'chapter': 15},
        {'id': 16, 'quiz_title': 'Quiz 16', 'chapter': 16},
        {'id': 17, 'quiz_title': 'Quiz 17', 'chapter': 17},
        {'id': 18, 'quiz_title': 'Quiz 18', 'chapter': 18},
        // {'id': 98, 'quiz_title': 'Quiz 1', 'chapter': 98},
        // {'id': 99, 'quiz_title': 'Quiz 1', 'chapter': 99},
      ];

      // Filter chapters based on storyId if provided
      final filteredChapters = storyId != null
          ? chaptersResponse
              .where((chapter) => chapter['story_id'] == storyId)
              .toList()
          : chaptersResponse;

      int? lowestChapterId = storyId != null
          ? filteredChapters
              .map((chapter) => chapter['id'] as int)
              .reduce((a, b) => a < b ? a : b)
          : null;

      debugPrint('Lowest Chapter ID for story $storyId: $lowestChapterId');

      // Map chapters with their quizzes
      final List<Map<String, dynamic>> combinedList = [];

      for (var chapter in filteredChapters) {
        final chapterId = chapter['id'];

        // Filter quizzes belonging to this chapter
        final chapterQuizzes = quizzesResponse
            .where((quiz) => quiz['chapter'] == chapterId)
            .toList();

        debugPrint('Chapter ID: $chapterId');
        debugPrint('Chapter Quizzes: $chapterQuizzes');

        // Get progress from SharedPreferences
        final prefs = await _prefs;
        final progressKey = 'story${storyId}_progress';
        print('Progress Key: $progressKey');

        int progress = prefs.getInt(progressKey) ?? lowestChapterId ?? 1;

        // Check if chapter is locked or unlocked based on progress
        bool isChapterLocked = (chapterId as int) > progress;
        print('Chapter is locked: $isChapterLocked');
        print('Progress: $progress');

        combinedList.add({
          'chapter': chapter,
          'quizzes': chapterQuizzes,
          'isLocked': isChapterLocked, // Add isLocked status
        });
      }

      // Assign the combined list manually
      chaptersAndQuizzes.value = combinedList;
    } catch (error) {
      print("Error fetching chapters and quizzes: $error");
    } finally {
      isLoading(false);
    }
  }

  Future<void> updateProgress(int storyId, int chapterId) async {
    final prefs = await _prefs;
    final progressKey = 'story${storyId}_progress';

    print('Progress key: $progressKey');

    // If chapterId is greater than current progress, update the progress
    int currentProgress = prefs.getInt(progressKey) ?? 1;
    if (chapterId == currentProgress) {
      await prefs.setInt(progressKey, chapterId + 1);
      print('Updated progress $currentProgress');

      // !!! KEY CHANGE !!!  Rebuild the list
      await fetchChaptersAndQuizzesLocal(storyId: storyId);

      update([chaptersAndQuizzesId]);
    }
  }

  Future<void> insertData() async {
    await supabase.from('correct_answers').insert([
      {'question': 2, 'choice': 8},
      {'question': 3, 'choice': 9},
      {'question': 4, 'choice': 13},
      {'question': 5, 'choice': 17},
      {'question': 6, 'choice': 23},
      {'question': 7, 'choice': 26},
      {'question': 8, 'choice': 32},
      {'question': 9, 'choice': 34},
      {'question': 10, 'choice': 38},
    ]);
  }

  Future<void> fetchQuestionViaQuizID(int? quizID) async {
    try {
      isLoading(true);

      // Build the query depending on whether quizID is null
      final query = quizID == null
          ? supabase.from('question').select('*')
          : supabase.from('question').select('*').eq('quiz', quizID);

      // Execute the query
      final response = await query;

      // Check if the response is not null
      if (response != null && response.isNotEmpty) {
        // Map the received JSON to a list of Question objects
        questions.value = (response as List<dynamic>)
            .map((json) => Question.fromJson(json as Map<String, dynamic>))
            .toList();

        // Optional: Print or log the list of questions fetched
        // print('Questions fetched: ${questions.value}');
      } else {
        // Display an error if no data is found
        Get.snackbar('Error', 'Failed to fetch data');
      }
    } catch (e) {
      // Show the error in case of an exception
      Get.snackbar('Error', e.toString());
    } finally {
      // Turn off loading indicator
      isLoading(false);
    }
  }

  Future<void> fetchQuiz() async {
    try {
      isLoading(true);

      // final query = id == null ? supabase.from('quiz').select('*') : supabase.from('quiz').select('*').eq('story', id);
      final query = supabase.from('quiz').select('*');

      final response = await query;

      if (response != null) {
        quizzes.value = (response as List<dynamic>)
            .map((json) => Quiz.fromJson(json as Map<String, dynamic>))
            .toList();
        // print('Quiz fetched: ${quizzes.value}');
      } else {
        Get.snackbar('Error', 'Failed to fetch data');
      }
    } catch (e) {
      Get.snackbar('Error', e.toString());
    } finally {
      isLoading(false);
    }
  }

  void fetchStoryLocal() {
    final response = [
      {
        "id": 1,
        "created_at": "2024-09-29T08:05:06.789301+00:00",
        "story_title": "Ibong Adarna",
        "cover": "assets/ibong-adarna-cover.jpeg",
      },
      {
        "id": 2,
        "created_at": "2024-09-29T08:05:25.361706+00:00",
        "story_title": "Alamat ng Tikbalang",
        "cover": "assets/alamat-ng-tikbalang-cover.jpg",
      },
      {
        "id": 3,
        "created_at": "2024-09-29T08:05:25.361706+00:00",
        "story_title": "Alamat ng Aswang",
        "cover": "assets/aswang.jpg",
      }
    ];

    // Populate storiesMap
    for (var item in response) {
      storiesMap[item['id'] as int] = {
        'story_title': item['story_title'],
        'created_at': item['created_at'],
        'cover': item['cover'],
      };
    }
  }

  Future<void> fetchStory() async {
    print('story called');
    try {
      isLoading(true);
      final query = supabase.from('stories').select('*');
      final response = await query;

      if (response != null) {
        // Store the fetched data directly in a map
        storiesMap.value = {
          for (var story in response)
            story['id']:
                story, // Map the 'id' to the story data
        };

        print(
            'Fetched Stories: $storiesMap'); // Print the map of fetched stories
      } else {
        Get.snackbar('Error', 'Failed to fetch data');
      }
    } catch (e) {
      Get.snackbar('Error', e.toString());
    } finally {
      isLoading(false);
    }
  }

  Future<void> fetchChoicesViaQuestionID(int questionID) async {
    try {
      isLoading(true);

      // Build the query depending on whether questionID is null
      final query = questionID == null
          ? supabase.from('choice').select('*')
          : supabase.from('choices').select('*').eq('question', questionID);

      // Execute the query and print the raw response
      final response = await query;
      // print('Raw choices response: $response');

      // Check if the response is not null and not empty
      if (response != null && response.isNotEmpty) {
        // Map the response to the Choices model
        choices.value = (response as List<dynamic>)
            .map((json) => Choices.fromJson(json as Map<String, dynamic>))
            .toList();
        // print('Mapped Choices: ${choices.value}');
      } else {
        Get.snackbar('Error', 'No choices found for the question.');
      }
    } catch (e) {
      Get.snackbar('Error', e.toString());
    } finally {
      isLoading(false);
    }
  }

  Future<void> fetchCorrectAnswerViaQuestionID(int questionID) async {
    try {
      isLoading(true);

      final query = questionID == null
          ? supabase.from('correct_answers').select('*')
          : supabase
              .from('correct_answers')
              .select('*')
              .eq('question', questionID);

      final response = await query;

      if (response != null) {
        correctAnswer.value = (response as List<dynamic>)
            .map((json) => CorrectAnswer.fromJson(json as Map<String, dynamic>))
            .toList();
        // print('Correct answers fetched: ${correctAnswer.value}');
      } else {
        Get.snackbar('Error', 'Failed to fetch data');
      }
    } catch (e) {
      Get.snackbar('Error', e.toString());
    } finally {
      isLoading(false);
    }
  }

  Future<void> populateQuizSet(int quizID) async {
    try {
      // Start loading
      isLoading(true);

      // Step 1: Fetch questions by quizID
      await fetchQuestionViaQuizID(quizID);
      // print('Questions: $questions');

      // Clear the previous quiz set
      quizSet.clear();

      // Step 2: For each question, fetch choices and correct answer
      for (var question in questions) {
        try {
          // print('\n');
          // print('Question ID current: ${question.id}');
          await fetchChoicesViaQuestionID(question.id);
          // print('Choices: $choices');

          // Get the list of choice texts
          List<String> choiceTexts =
              choices.map((choice) => choice.choice).toList();
          // print('Choices text: $choiceTexts');

          // Step 3: Fetch correct answer based on questionID
          await fetchCorrectAnswerViaQuestionID(question.id);

          // print('Correct answer: ${correctAnswer}');

          if (correctAnswer.isNotEmpty) {
            // Find the correct answer's index in the choices list by comparing choice IDs
            int correctAnswerIndex = -1;
            for (int i = 0; i < choices.length; i++) {
              if (choices[i].id == correctAnswer.first.choiceID) {
                correctAnswerIndex = i;
                break;
              }
            }

            // If the correct answer is not found, log it
            if (correctAnswerIndex == -1) {
              // print('Correct answer not found in choices for question ID: ${question.id}');
            } else {
              // print('Correct answer index: $correctAnswerIndex');
            }

            // Step 4: Create a QuizSet object and add it to the list
            QuizSet quizItem = QuizSet(
              questionText: question.text,
              choices: choiceTexts,
              correctAnswerIndex: correctAnswerIndex,
              selectedAnswer:
                  null, // This will be populated later during user interaction
            );

            quizSet.add(quizItem);
            QuizController().currentQuestion.add(quizItem);
          } else {
            // print('No correct answer found for question ID: ${question.id}');
          }
        } catch (e) {
          Get.snackbar('Error', e.toString());
        }
      }

      // debugPrint('Quiz Set populated: ${quizSet.toString()}');
    } catch (e) {
      // Handle any errors that occur during fetching and processing
      Get.snackbar('Error', e.toString());
    } finally {
      // Stop loading
      isLoading(false);
    }
  }

  Future<void> populateQuizLocal(int chapterId) async {
    try {
      // Start loading
      isLoading(true);

      List<QuizSet> chapterQuizSet = [];

      // Example chapter quizzes, replace with your actual data if necessary
      // Replace this part with your actual data source or logic
      Map<int, List<QuizSet>> chapterQuizzes = {
        1: [
          QuizSet(
            questionText: "Ano ang pangalan ng hari sa kwento?",
            choices: [
              "Hari Solomon",
              "Hari Fernando",
              "Hari David",
              "Hari Miguel"
            ],
            correctAnswerIndex: 0,
            selectedAnswer: null,
          ),
          QuizSet(
            questionText: "Ilang anak ang mayroon ang hari?",
            choices: ["Isa", "Dalawa", "Tatlo", "Apat"],
            correctAnswerIndex: 2,
            selectedAnswer: null,
          ),
          QuizSet(
            questionText: "Ano ang pangalan ng bunso ng hari?",
            choices: ["Don Pedro", "Don Juan", "Don Diego", "Don Luis"],
            correctAnswerIndex: 1,
            selectedAnswer: null,
          ),
          QuizSet(
            questionText: "Ano ang napanaginipan ng hari?",
            choices: [
              "Siya ay naglalakbay",
              "Siya ay nagkasakit at namatay",
              "Siya ay nagwagi sa labanan",
              "Siya ay nagkaroon ng kayamanan"
            ],
            correctAnswerIndex: 1,
            selectedAnswer: null,
          ),
          QuizSet(
            questionText:
                "Ano ang naramdaman ng hari nang magising siya mula sa panaginip?",
            choices: [
              "Kaligayahan",
              "Takot at pag-aalala",
              "Pagkainip",
              "Pagkagalit"
            ],
            correctAnswerIndex: 1,
            selectedAnswer: null,
          ),
          QuizSet(
            questionText:
                "Ano ang pangalan ng ibon na iminungkahi ng doktor na makagagamot sa sakit ng hari?",
            choices: [
              "Ibong Adarna",
              "Ibong Maya",
              "Ibong Pugo",
              "Ibong Lawin"
            ],
            correctAnswerIndex: 0,
            selectedAnswer: null,
          ),
          QuizSet(
            questionText: "Paano nakaapekto ang awit ng ibon sa sakit ng hari?",
            choices: [
              "Nagpalala sa sakit",
              "Nagpagaling sa sakit",
              "Wala itong epekto",
              "Nagbigay ng kalungkutan"
            ],
            correctAnswerIndex: 1,
            selectedAnswer: null,
          ),
          QuizSet(
            questionText: "Ano ang sakit ng hari?",
            choices: [
              "Ubo",
              "Misteryosong karamdaman",
              "Lagnat",
              "Sakit sa tiyan"
            ],
            correctAnswerIndex: 1,
            selectedAnswer: null,
          ),
          QuizSet(
            questionText: "Ano ang mungkahi ng doktor upang gamutin ang hari?",
            choices: [
              "Uminom ng gamot",
              "Magpahinga",
              "Hanapin ang Ibong Adarna",
              "Kumain ng masustansyang pagkain"
            ],
            correctAnswerIndex: 2,
            selectedAnswer: null,
          ),
          QuizSet(
            questionText: "Ano ang pangalan ng asawa ng hari?",
            choices: [
              "Reyna Isabela",
              "Reyna Valeriana",
              "Reyna Maria",
              "Reyna Sofia"
            ],
            correctAnswerIndex: 0,
            selectedAnswer: null,
          ),
        ],
        2: [
          QuizSet(
            questionText: "Ano ang kwento tungkol sa?",
            choices: [
              "Isang prinsipe na naglalakbay sa ibang kaharian",
              "Tatlong prinsipe na naghahanap ng Ibong Adarna",
              "Isang hari na naghanap ng kayamanan",
              "Isang ibon na naglalakbay sa buong mundo"
            ],
            correctAnswerIndex: 1,
            selectedAnswer: null,
          ),
          QuizSet(
            questionText: "Sino si Don Pedro?",
            choices: [
              "Ang bunso sa tatlong prinsipe",
              "Ang panganay na anak ng hari",
              "Ang kaibigan ni Don Juan",
              "Ang tagapangalaga ng kaharian"
            ],
            correctAnswerIndex: 1,
            selectedAnswer: null,
          ),
          QuizSet(
            questionText: "Ano ang nangyari sa kabayo ni Don Pedro?",
            choices: [
              "Naging masigla ito",
              "Namatay ito sa gitna ng paglalakbay",
              "Nawala ito sa gubat",
              "Nakilala ito ng Ibong Adarna"
            ],
            correctAnswerIndex: 1,
            selectedAnswer: null,
          ),
          QuizSet(
            questionText: "Anong uri ng puno ang natagpuan ni Don Pedro?",
            choices: [
              "Puno ng mangga",
              "Puno ng kawayan na may kakaibang katangian",
              "Puno ng saging",
              "Puno ng niyog"
            ],
            correctAnswerIndex: 1,
            selectedAnswer: null,
          ),
          QuizSet(
            questionText: "Paano naging bato si Don Pedro?",
            choices: [
              "Dahil sa kanyang kabutihan",
              "Dahil sa pagseselos at galit kay Don Juan",
              "Dahil sa kanyang katapangan",
              "Dahil sa kanyang talino"
            ],
            correctAnswerIndex: 1,
            selectedAnswer: null,
          ),
          QuizSet(
            questionText: "Ano ang katangian ni Don Pedro?",
            choices: [
              "Mapagbigay at matulungin",
              "Mainggitin, mapaghiganti, at mayabang",
              "Mahiyain at tahimik",
              "Matalino at masipag"
            ],
            correctAnswerIndex: 1,
            selectedAnswer: null,
          ),
          QuizSet(
            questionText:
                "Bakit ipinadala ng ama si Don Pedro sa isang misyon?",
            choices: [
              "Upang makilala ang ibang kaharian",
              "Upang hanapin ang Ibong Adarna na makapagpapagaling sa kanyang sakit",
              "Upang maghanap ng kayamanan",
              "Upang maging hari"
            ],
            correctAnswerIndex: 1,
            selectedAnswer: null,
          ),
          QuizSet(
            questionText:
                "Ano ang naramdaman ni Don Pedro nang mamatay ang kanyang kabayo?",
            choices: [
              "Natuwa siya",
              "Nalungkot at nagalit",
              "Walang pakialam",
              "Naging masaya siya"
            ],
            correctAnswerIndex: 1,
            selectedAnswer: null,
          ),
          QuizSet(
            questionText:
                "Ano ang naramdaman ni Don Diego tungkol sa sitwasyon ni Don Pedro?",
            choices: [
              "Nagmakaawa at nag-alala, ngunit may pagdududa",
              "Nagsaya at nagdiwang",
              "Walang pakialam",
              "Naging masaya para kay Don Pedro"
            ],
            correctAnswerIndex: 0,
            selectedAnswer: null,
          ),
          QuizSet(
            questionText: "Paano kumilos ang Ibong Adarna kay Don Pedro?",
            choices: [
              "Nagbigay ng tulong at suporta",
              "Nagpakita ng malasakit",
              "Nagbigay ng mga pagsubok at nagpatunay sa kanyang mga pagkakamali",
              "Naging kaibigan niya"
            ],
            correctAnswerIndex: 2,
            selectedAnswer: null,
          ),
        ],
        3: [
          QuizSet(
            questionText: "Ano ang pangalan ng prinsipe?",
            choices: ["Don Pedro", "Don Juan", "Don Diego", "Don Carlos"],
            correctAnswerIndex: 1,
            selectedAnswer: null,
          ),
          QuizSet(
            questionText: "Ano ang pangalan ng ibon?",
            choices: [
              "Ibong Adarna",
              "Ibong Maya",
              "Ibong Pugo",
              "Ibong Lawin"
            ],
            correctAnswerIndex: 0,
            selectedAnswer: null,
          ),
          QuizSet(
            questionText: "Bakit kailangan ng prinsipe na hanapin ang ibon?",
            choices: [
              "Upang makahanap ng kayamanan",
              "Upang pagalingin ang kanyang amang hari",
              "Upang makilala sa buong kaharian",
              "Upang makuha ang puso ng isang prinsesa"
            ],
            correctAnswerIndex: 1,
            selectedAnswer: null,
          ),
          QuizSet(
            questionText: "Ano ang payo ng matandang tao sa prinsipe?",
            choices: [
              "Maging matalino at mabilis",
              "Maging matiyaga at huwag mawalan ng pag-asa",
              "Maging mapagmatyag at maingat",
              "Maging malakas at matatag"
            ],
            correctAnswerIndex: 1,
            selectedAnswer: null,
          ),
          QuizSet(
            questionText: "Ano ang layunin ng gintong sinulid?",
            choices: [
              "Upang ipakita ang daan patungo sa kayamanan",
              "Upang tumulong sa prinsipe na makahanap ng tamang daan patungo sa Ibong Adarna",
              "Upang makilala ang mga kaibigan",
              "Upang ipakita ang mga panganib sa daan"
            ],
            correctAnswerIndex: 1,
            selectedAnswer: null,
          ),
          QuizSet(
            questionText:
                "Ano ang sinabi ng ermitanyo sa prinsipe tungkol sa pag-awit ng ibon?",
            choices: [
              "Ang Ibong Adarna ay umaawit ng isang awit lamang",
              "Ang Ibong Adarna ay umaawit ng pitong awit na may iba’t ibang kahulugan at epekto",
              "Ang Ibong Adarna ay hindi umaawit",
              "Ang Ibong Adarna ay umaawit ng mga awit ng pag-ibig"
            ],
            correctAnswerIndex: 1,
            selectedAnswer: null,
          ),
          QuizSet(
            questionText:
                "Ano ang nangyayari sa ibon kapag umaawit ito ng pitong awit?",
            choices: [
              "Nagiging masaya ang lahat ng nakikinig at nawawala ang mga sakit",
              "Nawawala ang ibon",
              "Nagiging malungkot ang lahat",
              "Nagiging masama ang panahon"
            ],
            correctAnswerIndex: 0,
            selectedAnswer: null,
          ),
          QuizSet(
            questionText:
                "Paano malalaman ng prinsipe kung kailan umaawit ang ibon?",
            choices: [
              "Sa pamamagitan ng pagdinig sa mga tao",
              "Sa pamamagitan ng pagsunod sa gintong sinulid",
              "Sa pamamagitan ng pagtingin sa mga bituin",
              "Sa pamamagitan ng pagtanong sa mga hayop"
            ],
            correctAnswerIndex: 1,
            selectedAnswer: null,
          ),
          QuizSet(
            questionText: "Ano ang babala ng ermitanyo sa prinsipe?",
            choices: [
              "Maging maingat sa mga pagsubok at mga kaaway",
              "Huwag makinig sa sinuman",
              "Maging mabilis sa kanyang paglalakbay",
              "Huwag umalis sa kanyang tahanan"
            ],
            correctAnswerIndex: 0,
            selectedAnswer: null,
          ),
          QuizSet(
            questionText:
                "Ano ang kailangan gawin ng prinsipe upang mahuli ang ibon?",
            choices: [
              "Maging matalino at maingat sa kanyang mga hakbang",
              "Maging malakas at matatag",
              "Maging mabilis at walang pag-iisip",
              "Maging mapagmatyag at maghintay"
            ],
            correctAnswerIndex: 0,
            selectedAnswer: null,
          ),
        ],
        4: [
          QuizSet(
            questionText: "Saan pumunta si Don Juan?",
            choices: [
              "Bundok ng Banahaw",
              "Bundok ng Arayat",
              "Bundok ng Pulag",
              "Bundok ng Mayon"
            ],
            correctAnswerIndex: 0,
            selectedAnswer: null,
          ),
          QuizSet(
            questionText: "Ano ang ugali ng Adarna?",
            choices: [
              "Mapaglaro at mahirap hulihin",
              "Mahiyain at tahimik",
              "Masungit at mapaghiganti",
              "Madaldal at masaya"
            ],
            correctAnswerIndex: 0,
            selectedAnswer: null,
          ),
          QuizSet(
            questionText: "Ano ang ginawa ni Don Juan nang matulog siya?",
            choices: [
              "Nakatulog ng mahimbing",
              "Napanaginipan ang mga awit ng Ibong Adarna",
              "Nagdasal",
              "Nag-aral"
            ],
            correctAnswerIndex: 1,
            selectedAnswer: null,
          ),
          QuizSet(
            questionText: "Ano ang ginawa ng dalawang kapatid ni Don Juan?",
            choices: [
              "Tinulungan si Don Juan",
              "Nagsabwatan upang ipahamak si Don Juan",
              "Naglakbay kasama si Don Juan",
              "Nag-aral ng mabuti"
            ],
            correctAnswerIndex: 1,
            selectedAnswer: null,
          ),
          QuizSet(
            questionText: "Ano ang utos ng ermitanyo kay Don Juan?",
            choices: [
              "Maging matatag at huwag mawalan ng pag-asa",
              "Uminom ng gamot",
              "Magpahinga at huwag maglakbay",
              "Maghanap ng kayamanan"
            ],
            correctAnswerIndex: 0,
            selectedAnswer: null,
          ),
          QuizSet(
            questionText:
                "Ano ang ginawa ni Don Juan sa mga utos ng ermitanyo?",
            choices: [
              "Tinanggihan ang mga utos",
              "Sumunod sa mga utos nang may katapatan",
              "Nagalit sa ermitanyo",
              "Nakalimutan ang mga utos"
            ],
            correctAnswerIndex: 1,
            selectedAnswer: null,
          ),
          QuizSet(
            questionText: "Bakit hindi kumakanta ang Adarna?",
            choices: [
              "Dahil ito ay natatakot",
              "Dahil ito ay nasa ilalim ng isang sumpa",
              "Dahil ito ay pagod",
              "Dahil ito ay naguguluhan"
            ],
            correctAnswerIndex: 1,
            selectedAnswer: null,
          ),
          QuizSet(
            questionText: "Sino ang nagpakasakit para sa kanyang ama?",
            choices: ["Don Pedro", "Don Diego", "Don Juan", "Ang ermitanyo"],
            correctAnswerIndex: 2,
            selectedAnswer: null,
          ),
          QuizSet(
            questionText: "Ano ang dahilan kung bakit naparusahan si Don Juan?",
            choices: [
              "Dahil sa kanyang katapatan",
              "Dahil sa pagseselos at inggit ng kanyang mga kapatid",
              "Dahil sa kanyang kasalanan",
              "Dahil sa kanyang katamaran"
            ],
            correctAnswerIndex: 1,
            selectedAnswer: null,
          ),
          QuizSet(
            questionText: "Ano ang nangyari sa dalawang kapatid ni Don Juan?",
            choices: [
              "Sila ay pinarangalan",
              "Sila ay naparusahan sa kanilang mga maling gawain",
              "Sila ay naging matagumpay",
              "Sila ay naglakbay sa ibang bayan"
            ],
            correctAnswerIndex: 1,
            selectedAnswer: null,
          ),
        ],
        5: [
          QuizSet(
            questionText: "Ano ang nangyari sa hari matapos siyang kumanta?",
            choices: [
              "Siya ay nakatulog.",
              "Siya ay tumayo at umalis.",
              "Siya ay nagkasakit."
            ],
            correctAnswerIndex: 0,
            selectedAnswer: null,
          ),
          QuizSet(
            questionText:
                "Anong parusa ang ibinigay ng hari sa dalawang lalaki?",
            choices: [
              "Sila ay hinatulan ng kamatayan.",
              "Sila ay ipinasok sa bilangguan.",
              "Sila ay pinalayas."
            ],
            correctAnswerIndex: 2,
            selectedAnswer: null,
          ),
          QuizSet(
            questionText:
                "Ano ang sinabi ng anak ng hari sa kanyang ama matapos niyang hatulan ang dalawang lalaki?",
            choices: [
              "Ama, patawarin mo ang mga lalaking ito dahil sila ay walang sala.",
              "Ama, ako ay pupunta at hahanapin ang ibong Adarna para sa iyo.",
              "Ama, hayaan mong dalhin ko ang ibong Adarna upang hanapin ang aking nawawalang kapatid."
            ],
            correctAnswerIndex: 1,
            selectedAnswer: null,
          ),
          QuizSet(
            questionText: "Ano ang naramdaman ng hari tungkol sa ibong Adarna?",
            choices: [
              "Natatakot ang hari sa ibon.",
              "Humanga ang hari sa pag-awit ng ibon.",
              "Nag-aalala ang hari tungkol sa ibon."
            ],
            correctAnswerIndex: 1,
            selectedAnswer: null,
          ),
          QuizSet(
            questionText:
                "Ano ang ginawa ng mga nakatatandang anak ng hari tuwing gabi upang protektahan ang ibong Adarna?",
            choices: [
              "Sila ay nagpalitan sa pagbabantay sa ibon.",
              "Ipinapasok nila ang ibon sa isang espesyal na silid.",
              "Naghahanap sila ng mga guwardiya upang protektahan ang ibon."
            ],
            correctAnswerIndex: 0,
            selectedAnswer: null,
          ),
          QuizSet(
            questionText:
                "Ano ang ginawa ni Don Juan upang subukang hanapin ang kanyang kapatid na si Don Pedro?",
            choices: [
              "Siya ay naglakbay sa maraming iba’t ibang bansa.",
              "Siya ay kumonsulta sa mga matatalinong tao at mga mangkukulam.",
              "Siya ay umakyat sa isang balon."
            ],
            correctAnswerIndex: 2,
            selectedAnswer: null,
          ),
          QuizSet(
            questionText: "Ano ang natagpuan ni Don Juan sa balon?",
            choices: [
              "Nakakita siya ng isang higante at isang magandang prinsesa.",
              "Nakakita siya ng isang lihim na daan patungo sa ibang mundo.",
              "Nakakita siya ng isang kayamanan."
            ],
            correctAnswerIndex: 0,
            selectedAnswer: null,
          ),
          QuizSet(
            questionText:
                "Ano ang ginawa ni Don Juan upang makuha ang ibong Adarna?",
            choices: [
              "Siya ay nagdala ng mga bitag.",
              "Siya ay nagdasal sa mga diyos.",
              "Siya ay nagpakita ng kabutihan sa ibon."
            ],
            correctAnswerIndex: 2,
            selectedAnswer: null,
          ),
          QuizSet(
            questionText: "Bakit nagalit si Don Pedro kay Don Juan?",
            choices: [
              "Dahil siya ay naiinggit sa tagumpay ni Don Juan.",
              "Dahil hindi siya pinansin ni Don Juan.",
              "Dahil siya ay nainggit sa pagmamahal ng kanilang ama kay Don Juan."
            ],
            correctAnswerIndex: 0,
            selectedAnswer: null,
          ),
          QuizSet(
            questionText: "Ano ang nangyari sa huli kay Don Juan?",
            choices: [
              "Siya ay naging hari.",
              "Siya ay naglakbay sa ibang mundo.",
              "Siya ay nagpakasal sa prinsesa."
            ],
            correctAnswerIndex: 0,
            selectedAnswer: null,
          ),
        ],
        6: [
          QuizSet(
            questionText:
                "Ano ang naramdaman ng prinsesa nang makita si Don Juan?",
            choices: ["A) Nabigla", "B) Natuwa", "C) Nalungkot", "D) Nagalit"],
            correctAnswerIndex: 0,
            selectedAnswer: null,
          ),
          QuizSet(
            questionText:
                "Ano ang sinabi ng prinsesa kay Don Juan tungkol sa serpiyente?",
            choices: [
              "A) Walang salang mamamatay",
              "B) Hindi mamamatay",
              "C) Maaaring mamamatay",
              "D) Hindi alam"
            ],
            correctAnswerIndex: 0,
            selectedAnswer: null,
          ),
          QuizSet(
            questionText:
                "Ano ang naramdaman ng prinsesa sa sinabi ni Don Juan?",
            choices: ["A) Masawi", "B) Natuwa", "C) Nalungkot", "D) Nagalit"],
            correctAnswerIndex: 0,
            selectedAnswer: null,
          ),
          QuizSet(
            questionText:
                "Ano ang dahilan ni Don Juan sa pagsisinungaling sa prinsesa?",
            choices: [
              "A) Pagsinta",
              "B) Pagmamahal",
              "C) Pag-iingat",
              "D) Pag-iwas"
            ],
            correctAnswerIndex: 0,
            selectedAnswer: null,
          ),
          QuizSet(
            questionText: "Ano ang lihim na tahanan ng prinsesa?",
            choices: [
              "A) Sa liblib ng kabundukan",
              "B) Sa lungsod",
              "C) Sa dagat",
              "D) Sa kagubatan"
            ],
            correctAnswerIndex: 0,
            selectedAnswer: null,
          ),
          QuizSet(
            questionText: "Ano ang ginawa ng prinsesa ng gabing kalaliman?",
            choices: [
              "A) Nanghihimlay",
              "B) Naglaro",
              "C) Nagbasa",
              "D) Nag-ayos"
            ],
            correctAnswerIndex: 0,
            selectedAnswer: null,
          ),
          QuizSet(
            questionText: "Sino ang gumising sa prinsesa?",
            choices: [
              "A) Panaginip",
              "B) Don Juan",
              "C) Ang hari",
              "D) Ang reyna"
            ],
            correctAnswerIndex: 0,
            selectedAnswer: null,
          ),
          QuizSet(
            questionText: "Sino ang talagang lunas sa dalita ng prinsesa?",
            choices: [
              "A) Si Leonora",
              "B) Si Don Juan",
              "C) Ang hari",
              "D) Ang reyna"
            ],
            correctAnswerIndex: 0,
            selectedAnswer: null,
          ),
          QuizSet(
            questionText:
                "Saan nakapagpasya si Don Juan na ialay ang kanyang sarili para sa prinsesa?",
            choices: [
              "A) Sa ulus ng serpiyente",
              "B) Sa lungsod",
              "C) Sa dagat",
              "D) Sa kagubatan"
            ],
            correctAnswerIndex: 0,
            selectedAnswer: null,
          ),
          QuizSet(
            questionText:
                "Ano ang ginawa ng hari matapos magising sa bangungot?",
            choices: [
              "A) Nalungkot at nagdalamhati",
              "B) Natuwa",
              "C) Nagalit",
              "D) Nag-ayos"
            ],
            correctAnswerIndex: 0,
            selectedAnswer: null,
          ),
        ],

        7: [
          QuizSet(
            questionText:
                "Ano ang nangyari sa katawan ng prinsipe matapos siyang kagatin ng lobo?",
            choices: [
              "Nagka-sakit ang prinsipe",
              "Nagka-pasa ang prinsipe",
              "Nalason ang prinsipe",
              "Nagka-sugat ang prinsipe"
            ],
            correctAnswerIndex: 2,
            selectedAnswer: null,
          ),
          QuizSet(
            questionText:
                "Sino ang nakakita sa prinsipe habang siya ay nagpapahinga sa puno?",
            choices: ["Lobo", "Adarna", "Leonora", "Don Juan"],
            correctAnswerIndex: 1,
            selectedAnswer: null,
          ),
          QuizSet(
            questionText: "Ano ang sinabi ng Adarna sa prinsipe?",
            choices: [
              "Hanapin ang tatlong magkakapatid",
              "Huwag kalimutan ang Leonora",
              "Pumunta sa kaharian ng mga kristal",
              "Lahat ng nabanggit"
            ],
            correctAnswerIndex: 3,
            selectedAnswer: null,
          ),
          QuizSet(
            questionText: "Bakit nalulumbay ang Leonora?",
            choices: [
              "Nag-aalala siya kay Don Juan",
              "Namatay ang kanyang mga magulang",
              "Iniwan siya ni Don Juan",
              "Nawala ang kanyang singsing"
            ],
            correctAnswerIndex: 0,
            selectedAnswer: null,
          ),
          QuizSet(
            questionText: "Ano ang sinabi ng Leonora kay Don Juan?",
            choices: [
              "Hahanap siya ng ibang lalaki",
              "Babalik siya sa kanyang mga magulang",
              "Hihintayin niya si Don Juan",
              "Susundan niya si Don Juan"
            ],
            correctAnswerIndex: 2,
            selectedAnswer: null,
          ),
          QuizSet(
            questionText: "Saan pupunta si Don Juan?",
            choices: [
              "Sa kaharian ng mga kristal",
              "Sa bahay ni Leonora",
              "Sa gubat",
              "Sa bahay ng tatlong magkakapatid"
            ],
            correctAnswerIndex: 0,
            selectedAnswer: null,
          ),
          QuizSet(
            questionText: "Ilang magkakapatid ang nag-aagawan sa mga hiyas?",
            choices: ["Dalawa", "Tatlo", "Apat", "Lima"],
            correctAnswerIndex: 1,
            selectedAnswer: null,
          ),
          QuizSet(
            questionText:
                "Sino ang babaeng pinili ni Don Juan mula sa tatlong magkakapatid?",
            choices: ["Maria Blancanang", "Leonora", "Adarna", "Don Juan"],
            correctAnswerIndex: 0,
            selectedAnswer: null,
          ),
          QuizSet(
            questionText:
                "Ano ang ginawa ni Don Juan upang makuha ang tiwala ng mga tao sa kaharian?",
            choices: [
              "Nagbigay siya ng mga regalo",
              "Nagsalita siya ng maganda",
              "Tumulong siya sa mga tao",
              "Nagpakita siya ng lakas"
            ],
            correctAnswerIndex: 2,
            selectedAnswer: null,
          ),
          QuizSet(
            questionText: "Ano ang naging kapalaran ng prinsipe sa huli?",
            choices: [
              "Naging hari siya",
              "Namatay siya",
              "Naging tagapagtanggol siya",
              "Umalis siya sa kaharian"
            ],
            correctAnswerIndex: 0,
            selectedAnswer: null,
          ),
        ],
        8: [
          QuizSet(
            questionText: "Ano ang sinabi ng ermitanyo sa prinsipe?",
            choices: [
              "Humanap ng isang matandang nakatira sa isang bundok",
              "Humingi ng awa sa isang matandang nakatira sa isang bundok",
              "Maglakbay sa isang bundok at hanapin ang isang matanda"
            ],
            correctAnswerIndex: 2,
            selectedAnswer: null,
          ),
          QuizSet(
            questionText:
                "Ano ang nararamdaman ng prinsipe sa simula ng video?",
            choices: ["Masaya", "Malungkot", "Naguguluhan"],
            correctAnswerIndex: 2,
            selectedAnswer: null,
          ),
          QuizSet(
            questionText: "Ano ang pangalan ng prinsipe?",
            choices: ["Don Juan", "Don Pedro", "Leonora"],
            correctAnswerIndex: 0,
            selectedAnswer: null,
          ),
          QuizSet(
            questionText: "Ano ang pangalan ng prinsesa?",
            choices: ["Don Juan", "Don Pedro", "Leonora"],
            correctAnswerIndex: 2,
            selectedAnswer: null,
          ),
          QuizSet(
            questionText: "Ano ang nakikita ng ermitanyo?",
            choices: [
              "Isang ibong nakatira sa bundok",
              "Isang ibon na naglalakad sa bundok",
              "Isang ibon na lumilipad sa bundok"
            ],
            correctAnswerIndex: 2,
            selectedAnswer: null,
          ),
          QuizSet(
            questionText: "Ano ang pangalan ng ibong nakita ng ermitanyo?",
            choices: ["Agila", "Kalapati", "Lawin"],
            correctAnswerIndex: 0,
            selectedAnswer: null,
          ),
          QuizSet(
            questionText: "Ano ang tinatanong ng ermitanyo sa ibon?",
            choices: [
              "Alam ba nito kung saan ang kaharian ng Kristales",
              "Ano ang itsura ng kaharian ng Kristales",
              "May tao bang nakatira sa kaharian ng Kristales"
            ],
            correctAnswerIndex: 0,
            selectedAnswer: null,
          ),
          QuizSet(
            questionText: "Ano ang sinabi ng ibon bilang sagot sa ermitanyo?",
            choices: [
              "Ang kaharian ng Kristales ay nasa bundok",
              "Ang kaharian ng Kristales ay nasa ilalim ng lupa",
              "Ang kaharian ng Kristales ay nasa gitna ng gubat"
            ],
            correctAnswerIndex: 0,
            selectedAnswer: null,
          ),
          QuizSet(
            questionText:
                "Ano ang ginawa ng prinsipe pagkatapos marinig ang sagot ng ibon?",
            choices: [
              "Nagpasya siyang maglakbay patungo sa kaharian",
              "Umuwi siya sa kanyang palasyo",
              "Nagtanong siya sa ibang tao"
            ],
            correctAnswerIndex: 0,
            selectedAnswer: null,
          ),
          QuizSet(
            questionText:
                "Ano ang natutunan ng prinsipe sa kanyang paglalakbay?",
            choices: [
              "Ang halaga ng pagkakaibigan",
              "Ang kahalagahan ng pamilya",
              "Ang kahalagahan ng pagtulong sa kapwa"
            ],
            correctAnswerIndex: 0,
            selectedAnswer: null,
          ),
        ],
        9: [
          QuizSet(
            questionText: "Ano ang ginawa ng ermitanyo sa prinsipe?",
            choices: [
              "Pinagalitan siya",
              "Pinagluto siya ng masasarap na pagkain",
              "Pinagsuot ng damit",
              "Pinagpalipad siya sa isang agila"
            ],
            correctAnswerIndex: 3,
            selectedAnswer: null,
          ),
          QuizSet(
            questionText: "Saan dinala ng agila ang prinsipe?",
            choices: [
              "Sa isang batis o batis",
              "Sa bahay ng ermitanyo",
              "Sa isang malaking puno",
              "Sa kaharian ng mga engkanto"
            ],
            correctAnswerIndex: 0,
            selectedAnswer: null,
          ),
          QuizSet(
            questionText: "Sino ang babaeng nakita ng prinsipe sa batis?",
            choices: [
              "Ang kanyang ina",
              "Ang prinsesa",
              "Isang diwata",
              "Isang mangkukulam"
            ],
            correctAnswerIndex: 1,
            selectedAnswer: null,
          ),
          QuizSet(
            questionText:
                "Ano ang reaksyon ng prinsesa ng makita niya ang prinsipe?",
            choices: [
              "Natuwa siya",
              "Nagulat siya",
              "Nagalit siya",
              "Nagalit siya pero nagawa niyang ipagtapat ang kanyang pag-ibig"
            ],
            correctAnswerIndex: 3,
            selectedAnswer: null,
          ),
          QuizSet(
            questionText: "Ano ang nakita ng prinsipe sa paligid ng batis?",
            choices: [
              "Mga bato na nakaayos sa isang hanay",
              "Mga punong kahoy na nagtataasan",
              "Isang malaking palasyo",
              "Mga nakakatakot na hayop"
            ],
            correctAnswerIndex: 0,
            selectedAnswer: null,
          ),
          QuizSet(
            questionText: "Ano ang sinabi ng prinsesa tungkol sa mga bato?",
            choices: [
              "Ang mga ito ay mga diyos",
              "Ang mga ito ay mga alaala ng kanyang mga magulang",
              "Ang mga ito ay representasyon ng mga taong naparusahan",
              "Ang mga ito ay mga magic na bato"
            ],
            correctAnswerIndex: 2,
            selectedAnswer: null,
          ),
          QuizSet(
            questionText:
                "Sino ang naglagay ng parusa sa mga taong naging bato?",
            choices: [
              "Ang hari, ama ng prinsesa",
              "Ang ermitanyo",
              "Ang agila",
              "Ang mga diwata"
            ],
            correctAnswerIndex: 0,
            selectedAnswer: null,
          ),
          QuizSet(
            questionText:
                "Ano ang ginawa ng prinsipe upang matulungan ang prinsesa?",
            choices: [
              "Nagbigay siya ng regalo",
              "Tinulungan niyang maalis ang parusa",
              "Nagdasal siya para sa kanya",
              "Umuwi siya sa kanyang kaharian"
            ],
            correctAnswerIndex: 1,
            selectedAnswer: null,
          ),
          QuizSet(
            questionText:
                "Ano ang naging resulta ng pagtulong ng prinsipe sa prinsesa?",
            choices: [
              "Naging magkaibigan sila",
              "Naging masaya ang prinsesa",
              "Nabalik ang mga tao sa kanilang normal na anyo",
              "Nawala ang agila"
            ],
            correctAnswerIndex: 2,
            selectedAnswer: null,
          ),
          QuizSet(
            questionText:
                "Ano ang natutunan ng prinsipe mula sa kanyang karanasan?",
            choices: [
              "Ang halaga ng kayamanan",
              "Ang kahalagahan ng pagmamahal at sakripisyo",
              "Ang kapangyarihan ng mga diyos",
              "Ang kahalagahan ng pagiging matalino"
            ],
            correctAnswerIndex: 1,
            selectedAnswer: null,
          ),
        ],
        10: [
          QuizSet(
            questionText: "Ano ang sinabi ni Don Juan sa hari?",
            choices: [
              "“Bayan ninyo ay nasapit sa taas po ng pag-ibig, pusong lumagi sa hapis ang hanap ay isang langit”",
              "“Sa gabing ito rin naman ay gagawin mong tinapay sa hapag ko’y magigising pagkain ko sa agahan”",
              "“Iyan po’y di papasaan, ang hintay ko’y pag-utusan ng aking makakayanan”"
            ],
            correctAnswerIndex: 0,
            selectedAnswer: null,
          ),
          QuizSet(
            questionText: "Ano ang ipinakita ni Don Juan sa hari?",
            choices: [
              "Isang buto ng trigo",
              "Isang buto ng mangga",
              "Isang buto ng papaya"
            ],
            correctAnswerIndex: 0,
            selectedAnswer: null,
          ),
          QuizSet(
            questionText: "Saan itinanim ni Don Juan ang trigo?",
            choices: [
              "Sa isang burol",
              "Sa isang kagubatan",
              "Sa isang damuhan"
            ],
            correctAnswerIndex: 0,
            selectedAnswer: null,
          ),
          QuizSet(
            questionText: "Sino ang nakita sa tabi ni Don Juan sa gabi?",
            choices: ["Ang hari", "Ang prinsipe", "Ang prinsesa"],
            correctAnswerIndex: 2,
            selectedAnswer: null,
          ),
          QuizSet(
            questionText: "Ano ang dala ng prinsesa?",
            choices: ["Isang ilaw", "Isang espada", "Isang bulaklak"],
            correctAnswerIndex: 0,
            selectedAnswer: null,
          ),
          QuizSet(
            questionText: "Sino ang nagising nang makita ang tinapay sa hapag?",
            choices: ["Ang hari", "Ang prinsipe", "Ang prinsesa"],
            correctAnswerIndex: 0,
            selectedAnswer: null,
          ),
          QuizSet(
            questionText: "Ano ang nakita ng hari sa prasko?",
            choices: [
              "Isang grupo ng ibon",
              "Isang grupo ng tao",
              "Isang grupo ng hayop"
            ],
            correctAnswerIndex: 1,
            selectedAnswer: null,
          ),
          QuizSet(
            questionText: "Bakit nagalit ang prinsesa?",
            choices: [
              "Dahil tinanggal ni Don Juan ang prasko sa tubig",
              "Dahil hindi na napansin ng hari ang kanyang presko",
              "Dahil nawala ang kanyang ilaw"
            ],
            correctAnswerIndex: 1,
            selectedAnswer: null,
          ),
          QuizSet(
            questionText: "Ano ang ginawa ni Don Juan matapos ang insidente?",
            choices: [
              "Umalis siya sa palasyo",
              "Nagdasal siya",
              "Nagtago siya"
            ],
            correctAnswerIndex: 0,
            selectedAnswer: null,
          ),
          QuizSet(
            questionText: "Ano ang naging reaksyon ng hari sa mga nangyari?",
            choices: ["Siya ay natuwa", "Siya ay nagalit", "Siya ay nag-alala"],
            correctAnswerIndex: 1,
            selectedAnswer: null,
          ),
        ],
        11: [
          QuizSet(
            questionText: "Ano ang pangalan ng hari?",
            choices: ["Don Juan", "Haring Salermo", "Donya Maria"],
            correctAnswerIndex: 2,
            selectedAnswer: null,
          ),
          QuizSet(
            questionText: "Ano ang hiling ng hari kay Don Juan?",
            choices: [
              "Makita ang mga simboryo ng kastilyo",
              "Hanapin ang kanyang anak",
              "Ilipat ang bundok"
            ],
            correctAnswerIndex: 2,
            selectedAnswer: null,
          ),
          QuizSet(
            questionText:
                "Ano ang nararamdaman ni Donya Maria nang malaman niya ang utos ng kanyang ama?",
            choices: ["Masaya", "Nag-aalala", "Malungkot"],
            correctAnswerIndex: 1,
            selectedAnswer: null,
          ),
          QuizSet(
            questionText: "Ano ang ibig sabihin ng 'mabusog'?",
            choices: ["Malaki", "Mataba", "Mayaman"],
            correctAnswerIndex: 2,
            selectedAnswer: null,
          ),
          QuizSet(
            questionText:
                "Ano ang tawag sa bundok na kailangang ilipat ni Don Juan?",
            choices: [
              "Matabang Bundok",
              "Bundok ng Salermo",
              "Mayamang Bundok"
            ],
            correctAnswerIndex: 2,
            selectedAnswer: null,
          ),
          QuizSet(
            questionText: "Saan matatagpuan ang Mayamang Bundok?",
            choices: [
              "Sa gitna ng dagat",
              "Sa loob ng kagubatan",
              "Sa itaas ng kastilyo"
            ],
            correctAnswerIndex: 0,
            selectedAnswer: null,
          ),
          QuizSet(
            questionText: "Ano ang gagawin ni Don Juan sa Mayamang Bundok?",
            choices: [
              "Itatayo ito sa gitna ng dagat",
              "Ipapauwi ito sa kastilyo",
              "Ibabaon ito sa lupa"
            ],
            correctAnswerIndex: 0,
            selectedAnswer: null,
          ),
          QuizSet(
            questionText: "Saan ginawa ni Don Juan ang paglalakad?",
            choices: ["Sa dalampasigan", "Sa kagubatan", "Sa palasyo"],
            correctAnswerIndex: 0,
            selectedAnswer: null,
          ),
          QuizSet(
            questionText: "Sino ang nakitang maglalakad ni Haring Salermo?",
            choices: ["Don Juan", "Donya Maria", "Mga kawal"],
            correctAnswerIndex: 2,
            selectedAnswer: null,
          ),
          QuizSet(
            questionText: "Sino ang nagising sa pagkagising ng hari?",
            choices: ["Mga hayop", "Mga kawal", "Don Juan"],
            correctAnswerIndex: 2,
            selectedAnswer: null,
          ),
        ],
        12: [
          QuizSet(
            questionText: "Ano ang pangalan ng lalaking nasa video?",
            choices: ["Don Juan", "Hari", "Prinsesa", "Don Juan"],
            correctAnswerIndex: 3,
            selectedAnswer: null,
          ),
          QuizSet(
            questionText: "Ano ang utos ng hari sa lalaki?",
            choices: [
              "Maglakad sa gubat",
              "Hanapin ang nawawalang singsing",
              "Maglayag sa dagat",
              "Sakayin ang kabayo"
            ],
            correctAnswerIndex: 1,
            selectedAnswer: null,
          ),
          QuizSet(
            questionText: "Saan nagpunta ang lalaki at babae?",
            choices: ["Gubat", "Ilog", "Dagat", "Bundok"],
            correctAnswerIndex: 2,
            selectedAnswer: null,
          ),
          QuizSet(
            questionText: "Ano ang ginamit nilang sasakyan?",
            choices: ["Bangka", "Batiya", "Kalesa", "Kariton"],
            correctAnswerIndex: 1,
            selectedAnswer: null,
          ),
          QuizSet(
            questionText:
                "Ano ang nangyari sa babae nang mahulog siya sa tubig?",
            choices: ["Nalunod", "Nawala", "Naging isda", "Namatay"],
            correctAnswerIndex: 2,
            selectedAnswer: null,
          ),
          QuizSet(
            questionText: "Ano ang nakuha ng lalaki sa isda?",
            choices: ["Singsing ng hari", "Ginto", "Singsing ng hari", "Bato"],
            correctAnswerIndex: 2,
            selectedAnswer: null,
          ),
          QuizSet(
            questionText:
                "Ano ang ibinigay ng babae sa lalaki bilang tanda ng kanilang pagkikilala?",
            choices: [
              "Dalingi ng kanyang kamay",
              "Isang singsing",
              "Isang larawan",
              "Isang sulat"
            ],
            correctAnswerIndex: 0,
            selectedAnswer: null,
          ),
          QuizSet(
            questionText: "Ano ang nangyari sa kabayo nang umaga?",
            choices: [
              "Naglakad ng maayos",
              "Tumakbo ng mabilis at umiyak",
              "Sumugod sa lalaki",
              "Namatay"
            ],
            correctAnswerIndex: 1,
            selectedAnswer: null,
          ),
          QuizSet(
            questionText:
                "Ano ang sinabi ng prinsesa sa lalaki tungkol sa kabayo?",
            choices: [
              "Huwag itong sakayin",
              "Ingat sa pagsakay",
              "Huwag itong pakainin",
              "Patayin ang kabayo"
            ],
            correctAnswerIndex: 1,
            selectedAnswer: null,
          ),
          QuizSet(
            questionText: "Ano ang gawa ng lalaki sa kabayo?",
            choices: ["Pinatay", "Sinakay", "Tinakbo", "Ipinagpalit"],
            correctAnswerIndex: 1,
            selectedAnswer: null,
          ),
        ],
        13: [
          QuizSet(
            questionText: "Saan naganap ang unang bahagi ng kuwento?",
            choices: [
              "Sa isang gubat",
              "Sa isang palasyo",
              "Sa isang barko",
              "Sa isang bahay"
            ],
            correctAnswerIndex: 1,
            selectedAnswer: null,
          ),
          QuizSet(
            questionText: "Sino ang dalawang tao sa unang bahagi ng kuwento?",
            choices: [
              "Isang hari at isang reyna",
              "Isang hari at isang prinsipe",
              "Isang prinsipe at isang prinsesa",
              "Isang hari at isang manggagamot"
            ],
            correctAnswerIndex: 1,
            selectedAnswer: null,
          ),
          QuizSet(
            questionText: "Ano ang ginawa ng hari para subukin ang prinsipe?",
            choices: [
              "Ipinapasyal siya sa kagubatan",
              "Ipinapasukat ang isang singsing",
              "Ipinapasulat ang isang liham",
              "Ipinapili siya ng tatlong pinto"
            ],
            correctAnswerIndex: 3,
            selectedAnswer: null,
          ),
          QuizSet(
            questionText: "Ano ang nasa loob ng piniling pinto ng prinsipe?",
            choices: [
              "Isang mahalagang kayamanan",
              "Ang prinsesa",
              "Isang mabangis na hayop",
              "Isang nakakatakot na nilalang"
            ],
            correctAnswerIndex: 1,
            selectedAnswer: null,
          ),
          QuizSet(
            questionText:
                "Saan patungo ang prinsipe at prinsesa matapos silang tumakas?",
            choices: [
              "Sa isang malayo at maaliwalas na lugar",
              "Sa isang isla kung saan walang tao",
              "Sa kaharian ng Berbanya",
              "Sa kabundukan kung saan nakatira ang mga duwende"
            ],
            correctAnswerIndex: 2,
            selectedAnswer: null,
          ),
          QuizSet(
            questionText:
                "Ano ang ginawa ng prinsesa para maiwasan ang paghabol ng hari?",
            choices: [
              "Nagpalit siya ng anyo",
              "Gumamit siya ng mahikal na kapangyarihan",
              "Nagtago sila sa ilalim ng lupa",
              "Naglakbay sila sa dagat"
            ],
            correctAnswerIndex: 1,
            selectedAnswer: null,
          ),
          QuizSet(
            questionText: "Ano ang sinabi ng hari sa kanyang kabayo?",
            choices: [
              "Sundan mo sila!",
              "Magpahinga ka muna.",
              "Bumalik tayo sa palasyo."
            ],
            correctAnswerIndex: 0,
            selectedAnswer: null,
          ),
          QuizSet(
            questionText:
                "Ano ang naging reaksyon ng prinsipe nang makita ang prinsesa?",
            choices: [
              "Nagtaka siya",
              "Natuwa siya",
              "Nagalit siya",
              "Natakot siya"
            ],
            correctAnswerIndex: 1,
            selectedAnswer: null,
          ),
          QuizSet(
            questionText:
                "Ano ang naging dahilan ng hidwaan sa pagitan ng hari at prinsipe?",
            choices: [
              "Ang kayamanan",
              "Ang pag-ibig sa prinsesa",
              "Ang kapangyarihan",
              "Ang pagkakaibigan"
            ],
            correctAnswerIndex: 1,
            selectedAnswer: null,
          ),
          QuizSet(
            questionText: "Ano ang natutunan ng prinsipe sa kanyang karanasan?",
            choices: [
              "Ang halaga ng kayamanan",
              "Ang kahalagahan ng pamilya",
              "Ang tunay na pag-ibig at sakripisyo",
              "Ang kapangyarihan ng mahika"
            ],
            correctAnswerIndex: 2,
            selectedAnswer: null,
          ),
        ],
        14: [
          QuizSet(
            questionText: "Sino ang nagdumugang na sumalubong kay Don Juan?",
            choices: [
              "Leonora",
              "Donya Maria",
              "Ang hari at reyna",
              "Ang buong kaharian"
            ],
            correctAnswerIndex: 2,
            selectedAnswer: null,
          ),
          QuizSet(
            questionText:
                "Ano ang ginawa ni Leonora para maparusahan siya ng hari?",
            choices: [
              "Nagnakaw ng singsing",
              "Nagpakasal ng hindi nagpapaalam",
              "Nagsinungaling sa hari",
              "Nagalit sa hari"
            ],
            correctAnswerIndex: 1,
            selectedAnswer: null,
          ),
          QuizSet(
            questionText: "Ilang taon na nagdurusa si Leonora?",
            choices: ["5 taon", "7 taon", "10 taon", "12 taon"],
            correctAnswerIndex: 1,
            selectedAnswer: null,
          ),
          QuizSet(
            questionText:
                "Ano ang sinabi ni Leonora sa hari bago siya pakasalan ni Don Juan?",
            choices: [
              "“Salamat sa pagpatawad sa akin”",
              "“Mahal na hari, patayin mo na ako”",
              "“Pakasal mo na lang ako sa ibang lalaki”",
              "“Mahal na Hari, patawad sa gawa kong hindi dapat”"
            ],
            correctAnswerIndex: 3,
            selectedAnswer: null,
          ),
          QuizSet(
            questionText: "Ano ang ipinagtapat ng hari sa lahat?",
            choices: [
              "Ang pagmamahal niya kay Leonora",
              "Ang pangungulila niya sa kanyang anak",
              "Ang pagiging mabait ng kanyang anak",
              "Ang pangarap niya para kay Don Juan"
            ],
            correctAnswerIndex: 1,
            selectedAnswer: null,
          ),
          QuizSet(
            questionText:
                "Ilang kabayo ang nakasabit sa karwahe na sinakyan ni Don Juan at Leonora?",
            choices: [
              "4 na kabayo",
              "6 na kabayo",
              "8 na kabayo",
              "10 na kabayo"
            ],
            correctAnswerIndex: 1,
            selectedAnswer: null,
          ),
          QuizSet(
            questionText:
                "Sino ang nagplano para magkasama si Don Juan at Leonora?",
            choices: [
              "Ang hari",
              "Donya Maria",
              "Ang mga manggagawa",
              "Ang mga kaibigan ni Don Juan"
            ],
            correctAnswerIndex: 0,
            selectedAnswer: null,
          ),
          QuizSet(
            questionText:
                "Ano ang naging reaksyon ni Don Juan nang malaman niyang si Leonora ay pinabayaan ng hari?",
            choices: [
              "Nagalit siya",
              "Naging malungkot siya",
              "Nagsaya siya",
              "Walang pakialam"
            ],
            correctAnswerIndex: 1,
            selectedAnswer: null,
          ),
          QuizSet(
            questionText: "Ano ang ipinangako ni Don Juan kay Leonora?",
            choices: [
              "Na hindi siya iiwan",
              "Na magiging hari siya",
              "Na bibigyan siya ng kayamanan",
              "Na magiging masaya sila"
            ],
            correctAnswerIndex: 0,
            selectedAnswer: null,
          ),
          QuizSet(
            questionText: "Ano ang naging huling desisyon ni Leonora?",
            choices: [
              "Umalis sa kaharian",
              "Magpakasal kay Don Juan",
              "Magsimula ng bagong buhay",
              "Maghiganti sa hari"
            ],
            correctAnswerIndex: 1,
            selectedAnswer: null,
          ),
        ],
        15: [
          QuizSet(
            questionText:
                "Ano ang ginawa ni Donya Maria at Don Juan matapos ang kasal?",
            choices: [
              "Nagbakasyon",
              "Nagbalik sa kahariang pugad nila ng suyuan",
              "Nag-aral sa ibang bansa",
              "Nag-abroad"
            ],
            correctAnswerIndex: 1,
            selectedAnswer: null,
          ),
          QuizSet(
            questionText:
                "Ano ang nangyari sa kahariang pinamumunuan ni Donya Maria at Don Juan noong 1693?",
            choices: [
              "Nagkaroon ng digmaan.",
              "Namatay ang mga kamag-anak ng hari.",
              "Nagkaroon ng malakas na lindol.",
              "Na-banta ng mga tulisan."
            ],
            correctAnswerIndex: 1,
            selectedAnswer: null,
          ),
          QuizSet(
            questionText: "Sino ang namatay noong 1693?",
            choices: [
              "Ang mga magulang ni Don Juan",
              "Ang kapatid ni Donya Maria",
              "Ang mga magulang ni Donya Maria",
              "Ang kapatid ni Don Juan at ang mga magulang ni Donya Maria"
            ],
            correctAnswerIndex: 3,
            selectedAnswer: null,
          ),
          QuizSet(
            questionText: "Ano ang nangyari kay Don Juan noong 1704?",
            choices: [
              "Naging hari na siya.",
              "Naging isang manggagamot.",
              "Naging bayani ng bayan.",
              "Naging isang magaling na mangangalakal."
            ],
            correctAnswerIndex: 0,
            selectedAnswer: null,
          ),
          QuizSet(
            questionText: "Ano ang nangyari kay Donya Maria noong 1704?",
            choices: [
              "Naging reyna na siya.",
              "Nagkaroon ng anak.",
              "Naging isang pintor.",
              "Nag-asawa ng iba."
            ],
            correctAnswerIndex: 0,
            selectedAnswer: null,
          ),
          QuizSet(
            questionText:
                "Ano ang nangyari sa kaharian dahil sa pamumuno ni Don Juan?",
            choices: [
              "Nagkaroon ng kaguluhan.",
              "Nagkaroon ng taggutom.",
              "Naging maunlad at mapayapa.",
              "Nagkaroon ng digmaan."
            ],
            correctAnswerIndex: 2,
            selectedAnswer: null,
          ),
          QuizSet(
            questionText:
                "Ano ang ginawa ni Don Juan upang mapanatili ang kapayapaan sa kaharian?",
            choices: [
              "Naglagay ng mga sundalo sa buong kaharian.",
              "Nagtayo ng mga kalsada at tulay.",
              "Nagbigay ng libreng edukasyon at pangangalaga sa kalusugan.",
              "Naglagay ng mga batas at regulasyon."
            ],
            correctAnswerIndex: 2,
            selectedAnswer: null,
          ),
          QuizSet(
            questionText:
                "Ano ang nangyari sa kaharian matapos ang paghahari ni Don Juan?",
            choices: [
              "Nagkaroon ng kaguluhan at digmaan.",
              "Nagkaroon ng taggutom at kahirapan.",
              "Naging maunlad at mapayapa pa rin.",
              "Nagkaroon ng malakas na lindol."
            ],
            correctAnswerIndex: 2,
            selectedAnswer: null,
          ),
          QuizSet(
            questionText: "Sino ang naging kahalili ni Don Juan sa paghahari?",
            choices: [
              "Ang anak ni Don Juan.",
              "Ang kapatid ni Don Juan.",
              "Ang pinsan ni Don Juan.",
              "Ang isang maharlikang pamilya."
            ],
            correctAnswerIndex: 0,
            selectedAnswer: null,
          ),
          QuizSet(
            questionText:
                "Ano ang nangyari sa kaharian sa ilalim ng pamumuno ng anak ni Don Juan?",
            choices: [
              "Nagkaroon ng kaguluhan at digmaan.",
              "Nagkaroon ng taggutom at kahirapan.",
              "Naging maunlad at mapayapa pa rin.",
              "Nagkaroon ng malakas na lindol."
            ],
            correctAnswerIndex: 2,
            selectedAnswer: null,
          ),
        ],
        16: [
          QuizSet(
            questionText:
                "Ano ang ginawa ni Donya Maria at Don Juan matapos ang kasal?",
            choices: [
              "Nagbakasyon",
              "Nagbalik sa kahariang pugad nila ng suyuan",
              "Nag-aral sa ibang bansa",
              "Nag-abroad"
            ],
            correctAnswerIndex: 1,
            selectedAnswer: null,
          ),
          QuizSet(
            questionText:
                "Ano ang nangyari sa kahariang pinamumunuan ni Donya Maria at Don Juan noong 1693?",
            choices: [
              "Nagkaroon ng digmaan.",
              "Namatay ang mga kamag-anak ng hari.",
              "Nagkaroon ng malakas na lindol.",
              "Na-banta ng mga tulisan."
            ],
            correctAnswerIndex: 1,
            selectedAnswer: null,
          ),
          QuizSet(
            questionText: "Sino ang namatay noong 1693?",
            choices: [
              "Ang mga magulang ni Don Juan",
              "Ang kapatid ni Donya Maria",
              "Ang mga magulang ni Donya Maria",
              "Ang kapatid ni Don Juan at ang mga magulang ni Donya Maria"
            ],
            correctAnswerIndex: 3,
            selectedAnswer: null,
          ),
          QuizSet(
            questionText: "Ano ang nangyari kay Don Juan noong 1704?",
            choices: [
              "Naging hari na siya.",
              "Naging isang manggagamot.",
              "Naging bayani ng bayan.",
              "Naging isang magaling na mangangalakal."
            ],
            correctAnswerIndex: 0,
            selectedAnswer: null,
          ),
          QuizSet(
            questionText: "Ano ang nangyari kay Donya Maria noong 1704?",
            choices: [
              "Naging reyna na siya.",
              "Nagkaroon ng anak.",
              "Naging isang pintor.",
              "Nag-asawa ng iba."
            ],
            correctAnswerIndex: 0,
            selectedAnswer: null,
          ),
          QuizSet(
            questionText:
                "Ano ang nangyari sa kaharian dahil sa pamumuno ni Don Juan?",
            choices: [
              "Nagkaroon ng kaguluhan.",
              "Nagkaroon ng taggutom.",
              "Naging maunlad at mapayapa.",
              "Nagkaroon ng digmaan."
            ],
            correctAnswerIndex: 2,
            selectedAnswer: null,
          ),
          QuizSet(
            questionText:
                "Ano ang ginawa ni Don Juan upang mapanatili ang kapayapaan sa kaharian?",
            choices: [
              "Naglagay ng mga sundalo sa buong kaharian.",
              "Nagtayo ng mga kalsada at tulay.",
              "Nagbigay ng libreng edukasyon at pangangalaga sa kalusugan.",
              "Naglagay ng mga batas at regulasyon."
            ],
            correctAnswerIndex: 2,
            selectedAnswer: null,
          ),
          QuizSet(
            questionText:
                "Ano ang nangyari sa kaharian matapos ang paghahari ni Don Juan?",
            choices: [
              "Nagkaroon ng kaguluhan at digmaan.",
              "Nagkaroon ng taggutom at kahirapan.",
              "Naging maunlad at mapayapa pa rin.",
              "Nagkaroon ng malakas na lindol."
            ],
            correctAnswerIndex: 2,
            selectedAnswer: null,
          ),
          QuizSet(
            questionText: "Sino ang naging kahalili ni Don Juan sa paghahari?",
            choices: [
              "Ang anak ni Don Juan.",
              "Ang kapatid ni Don Juan.",
              "Ang pinsan ni Don Juan.",
              "Ang isang maharlikang pamilya."
            ],
            correctAnswerIndex: 0,
            selectedAnswer: null,
          ),
          QuizSet(
            questionText:
                "Ano ang nangyari sa kaharian sa ilalim ng pamumuno ng anak ni Don Juan?",
            choices: [
              "Nagkaroon ng kaguluhan at digmaan.",
              "Nagkaroon ng taggutom at kahirapan.",
              "Naging maunlad at mapayapa pa rin.",
              "Nagkaroon ng malakas na lindol."
            ],
            correctAnswerIndex: 2,
            selectedAnswer: null,
          ),
        ],

        17: [
          QuizSet(
            questionText: "Anong uri ng media ang video?",
            choices: ["Teksto", "Larawan", "Audio", "Multimedyang"],
            correctAnswerIndex: 3,
            selectedAnswer: null,
          ),
          QuizSet(
            questionText: "Anong ginagamit sa paggawa ng video?",
            choices: ["Kamera", "Mikropono", "Ilaw", "Lahat ng ito"],
            correctAnswerIndex: 3,
            selectedAnswer: null,
          ),
          QuizSet(
            questionText: "Anong proseso ang ginagawa sa pag-edit ng video?",
            choices: [
              "Pagkuha ng larawan",
              "Pag-record ng audio",
              "Pagdagdag ng mga epekto",
              "Lahat ng ito"
            ],
            correctAnswerIndex: 3,
            selectedAnswer: null,
          ),
          QuizSet(
            questionText: "Anong software ang ginagamit sa pag-edit ng video?",
            choices: [
              "Adobe Premiere",
              "Final Cut Pro",
              "DaVinci Resolve",
              "Lahat ng ito"
            ],
            correctAnswerIndex: 3,
            selectedAnswer: null,
          ),
          QuizSet(
            questionText: "Anong uri ng video ang ginagawa sa mga pelikula?",
            choices: [
              "Dokumentaryo",
              "Musik video",
              "Pelikulang pang-nobela",
              "Lahat ng ito"
            ],
            correctAnswerIndex: 2,
            selectedAnswer: null,
          ),
          QuizSet(
            questionText: "Anong ginagamit sa pagpapakita ng video?",
            choices: ["Telebisyon", "Kompyuter", "Tablet", "Lahat ng ito"],
            correctAnswerIndex: 3,
            selectedAnswer: null,
          ),
          QuizSet(
            questionText: "Anong uri ng video ang ginagawa sa mga balita?",
            choices: ["Dokumentaryo", "Musik video", "Balita", "Lahat ng ito"],
            correctAnswerIndex: 2,
            selectedAnswer: null,
          ),
          QuizSet(
            questionText: "Anong proseso ang ginagawa sa pag-upload ng video?",
            choices: [
              "Pagkuha ng larawan",
              "Pag-record ng audio",
              "Pagdagdag ng mga epekto",
              "Pag-upload sa internet"
            ],
            correctAnswerIndex: 3,
            selectedAnswer: null,
          ),
          QuizSet(
            questionText: "Anong uri ng video ang ginagawa sa mga tutorial?",
            choices: [
              "Dokumentaryo",
              "Musik video",
              "Tutorial",
              "Lahat ng ito"
            ],
            correctAnswerIndex: 2,
            selectedAnswer: null,
          ),
          QuizSet(
            questionText:
                "Anong ginagamit sa pagpapakita ng video sa mga social media?",
            choices: ["Facebook", "Instagram", "YouTube", "Lahat ng ito"],
            correctAnswerIndex: 3,
            selectedAnswer: null,
          ),
        ],
        18: [
          QuizSet(
            questionText:
                "Ano ang ginawa ni Donya Maria at Don Juan matapos ang kasal?",
            choices: [
              "Nagbakasyon",
              "Nagbalik sa kahariang pugad nila ng suyuan",
              "Nag-aral sa ibang bansa",
              "Nag-abroad"
            ],
            correctAnswerIndex: 1,
            selectedAnswer: null,
          ),
          QuizSet(
            questionText:
                "Ano ang nangyari sa kahariang pinamumunuan ni Donya Maria at Don Juan noong 1693?",
            choices: [
              "Nagkaroon ng digmaan.",
              "Namatay ang mga kamag-anak ng hari.",
              "Nagkaroon ng malakas na lindol.",
              "Na-banta ng mga tulisan."
            ],
            correctAnswerIndex: 1,
            selectedAnswer: null,
          ),
          QuizSet(
            questionText: "Sino ang namatay noong 1693?",
            choices: [
              "Ang mga magulang ni Don Juan",
              "Ang kapatid ni Donya Maria",
              "Ang mga magulang ni Donya Maria",
              "Ang kapatid ni Don Juan at ang mga magulang ni Donya Maria"
            ],
            correctAnswerIndex: 3,
            selectedAnswer: null,
          ),
          QuizSet(
            questionText: "Ano ang nangyari kay Don Juan noong 1704?",
            choices: [
              "Naging hari na siya.",
              "Naging isang manggagamot.",
              "Naging bayani ng bayan.",
              "Naging isang magaling na mangangalakal."
            ],
            correctAnswerIndex: 0,
            selectedAnswer: null,
          ),
          QuizSet(
            questionText: "Ano ang nangyari kay Donya Maria noong 1704?",
            choices: [
              "Naging reyna na siya.",
              "Nagkaroon ng anak.",
              "Naging isang pintor.",
              "Nag-asawa ng iba."
            ],
            correctAnswerIndex: 0,
            selectedAnswer: null,
          ),
          QuizSet(
            questionText:
                "Ano ang nangyari sa kaharian dahil sa pamumuno ni Don Juan?",
            choices: [
              "Nagkaroon ng kaguluhan.",
              "Nagkaroon ng taggutom.",
              "Naging maunlad at mapayapa.",
              "Nagkaroon ng digmaan."
            ],
            correctAnswerIndex: 2,
            selectedAnswer: null,
          ),
          QuizSet(
            questionText:
                "Ano ang ginawa ni Don Juan upang mapanatili ang kapayapaan sa kaharian?",
            choices: [
              "Naglagay ng mga sundalo sa buong kaharian.",
              "Nagtayo ng mga kalsada at tulay.",
              "Nagbigay ng libreng edukasyon at pangangalaga sa kalusugan.",
              "Naglagay ng mga batas at regulasyon."
            ],
            correctAnswerIndex: 2,
            selectedAnswer: null,
          ),
          QuizSet(
            questionText:
                "Ano ang nangyari sa kaharian matapos ang paghahari ni Don Juan?",
            choices: [
              "Nagkaroon ng kaguluhan at digmaan.",
              "Nagkaroon ng taggutom at kahirapan.",
              "Naging maunlad at mapayapa pa rin.",
              "Nagkaroon ng malakas na lindol."
            ],
            correctAnswerIndex: 2,
            selectedAnswer: null,
          ),
          QuizSet(
            questionText: "Sino ang naging kahalili ni Don Juan sa paghahari?",
            choices: [
              "Ang anak ni Don Juan.",
              "Ang kapatid ni Don Juan.",
              "Ang pinsan ni Don Juan.",
              "Ang isang maharlikang pamilya."
            ],
            correctAnswerIndex: 0,
            selectedAnswer: null,
          ),
          QuizSet(
            questionText:
                "Ano ang nangyari sa kaharian sa ilalim ng pamumuno ng anak ni Don Juan?",
            choices: [
              "Nagkaroon ng kaguluhan at digmaan.",
              "Nagkaroon ng taggutom at kahirapan.",
              "Naging maunlad at mapayapa pa rin.",
              "Nagkaroon ng malakas na lindol."
            ],
            correctAnswerIndex: 2,
            selectedAnswer: null,
          ),
        ],
        98: [
          QuizSet(
            questionText:
                "Ano ang ginawa ni Donya Maria at Don Juan matapos ang kasal?",
            choices: [
              "Nagbakasyon",
              "Nagbalik sa kahariang pugad nila ng suyuan",
              "Nag-aral sa ibang bansa",
              "Nag-abroad"
            ],
            correctAnswerIndex: 1,
            selectedAnswer: null,
          ),
          QuizSet(
            questionText:
                "Ano ang nangyari sa kahariang pinamumunuan ni Donya Maria at Don Juan noong 1693?",
            choices: [
              "Nagkaroon ng digmaan.",
              "Namatay ang mga kamag-anak ng hari.",
              "Nagkaroon ng malakas na lindol.",
              "Na-banta ng mga tulisan."
            ],
            correctAnswerIndex: 1,
            selectedAnswer: null,
          ),
          QuizSet(
            questionText: "Sino ang namatay noong 1693?",
            choices: [
              "Ang mga magulang ni Don Juan",
              "Ang kapatid ni Donya Maria",
              "Ang mga magulang ni Donya Maria",
              "Ang kapatid ni Don Juan at ang mga magulang ni Donya Maria"
            ],
            correctAnswerIndex: 3,
            selectedAnswer: null,
          ),
          QuizSet(
            questionText: "Ano ang nangyari kay Don Juan noong 1704?",
            choices: [
              "Naging hari na siya.",
              "Naging isang manggagamot.",
              "Naging bayani ng bayan.",
              "Naging isang magaling na mangangalakal."
            ],
            correctAnswerIndex: 0,
            selectedAnswer: null,
          ),
          QuizSet(
            questionText: "Ano ang nangyari kay Donya Maria noong 1704?",
            choices: [
              "Naging reyna na siya.",
              "Nagkaroon ng anak.",
              "Naging isang pintor.",
              "Nag-asawa ng iba."
            ],
            correctAnswerIndex: 0,
            selectedAnswer: null,
          ),
          QuizSet(
            questionText:
                "Ano ang nangyari sa kaharian dahil sa pamumuno ni Don Juan?",
            choices: [
              "Nagkaroon ng kaguluhan.",
              "Nagkaroon ng taggutom.",
              "Naging maunlad at mapayapa.",
              "Nagkaroon ng digmaan."
            ],
            correctAnswerIndex: 2,
            selectedAnswer: null,
          ),
          QuizSet(
            questionText:
                "Ano ang ginawa ni Don Juan upang mapanatili ang kapayapaan sa kaharian?",
            choices: [
              "Naglagay ng mga sundalo sa buong kaharian.",
              "Nagtayo ng mga kalsada at tulay.",
              "Nagbigay ng libreng edukasyon at pangangalaga sa kalusugan.",
              "Naglagay ng mga batas at regulasyon."
            ],
            correctAnswerIndex: 2,
            selectedAnswer: null,
          ),
          QuizSet(
            questionText:
                "Ano ang nangyari sa kaharian matapos ang paghahari ni Don Juan?",
            choices: [
              "Nagkaroon ng kaguluhan at digmaan.",
              "Nagkaroon ng taggutom at kahirapan.",
              "Naging maunlad at mapayapa pa rin.",
              "Nagkaroon ng malakas na lindol."
            ],
            correctAnswerIndex: 2,
            selectedAnswer: null,
          ),
          QuizSet(
            questionText: "Sino ang naging kahalili ni Don Juan sa paghahari?",
            choices: [
              "Ang anak ni Don Juan.",
              "Ang kapatid ni Don Juan.",
              "Ang pinsan ni Don Juan.",
              "Ang isang maharlikang pamilya."
            ],
            correctAnswerIndex: 0,
            selectedAnswer: null,
          ),
          QuizSet(
            questionText:
                "Ano ang nangyari sa kaharian sa ilalim ng pamumuno ng anak ni Don Juan?",
            choices: [
              "Nagkaroon ng kaguluhan at digmaan.",
              "Nagkaroon ng taggutom at kahirapan.",
              "Naging maunlad at mapayapa pa rin.",
              "Nagkaroon ng malakas na lindol."
            ],
            correctAnswerIndex: 2,
            selectedAnswer: null,
          ),
        ],

        99: [
          QuizSet(
            questionText:
                "Ano ang ginawa ni Donya Maria at Don Juan matapos ang kasal?",
            choices: [
              "Nagbakasyon",
              "Nagbalik sa kahariang pugad nila ng suyuan",
              "Nag-aral sa ibang bansa",
              "Nag-abroad"
            ],
            correctAnswerIndex: 1,
            selectedAnswer: null,
          ),
          QuizSet(
            questionText:
                "Ano ang nangyari sa kahariang pinamumunuan ni Donya Maria at Don Juan noong 1693?",
            choices: [
              "Nagkaroon ng digmaan.",
              "Namatay ang mga kamag-anak ng hari.",
              "Nagkaroon ng malakas na lindol.",
              "Na-banta ng mga tulisan."
            ],
            correctAnswerIndex: 1,
            selectedAnswer: null,
          ),
          QuizSet(
            questionText: "Sino ang namatay noong 1693?",
            choices: [
              "Ang mga magulang ni Don Juan",
              "Ang kapatid ni Donya Maria",
              "Ang mga magulang ni Donya Maria",
              "Ang kapatid ni Don Juan at ang mga magulang ni Donya Maria"
            ],
            correctAnswerIndex: 3,
            selectedAnswer: null,
          ),
          QuizSet(
            questionText: "Ano ang nangyari kay Don Juan noong 1704?",
            choices: [
              "Naging hari na siya.",
              "Naging isang manggagamot.",
              "Naging bayani ng bayan.",
              "Naging isang magaling na mangangalakal."
            ],
            correctAnswerIndex: 0,
            selectedAnswer: null,
          ),
          QuizSet(
            questionText: "Ano ang nangyari kay Donya Maria noong 1704?",
            choices: [
              "Naging reyna na siya.",
              "Nagkaroon ng anak.",
              "Naging isang pintor.",
              "Nag-asawa ng iba."
            ],
            correctAnswerIndex: 0,
            selectedAnswer: null,
          ),
          QuizSet(
            questionText:
                "Ano ang nangyari sa kaharian dahil sa pamumuno ni Don Juan?",
            choices: [
              "Nagkaroon ng kaguluhan.",
              "Nagkaroon ng taggutom.",
              "Naging maunlad at mapayapa.",
              "Nagkaroon ng digmaan."
            ],
            correctAnswerIndex: 2,
            selectedAnswer: null,
          ),
          QuizSet(
            questionText:
                "Ano ang ginawa ni Don Juan upang mapanatili ang kapayapaan sa kaharian?",
            choices: [
              "Naglagay ng mga sundalo sa buong kaharian.",
              "Nagtayo ng mga kalsada at tulay.",
              "Nagbigay ng libreng edukasyon at pangangalaga sa kalusugan.",
              "Naglagay ng mga batas at regulasyon."
            ],
            correctAnswerIndex: 2,
            selectedAnswer: null,
          ),
          QuizSet(
            questionText:
                "Ano ang nangyari sa kaharian matapos ang paghahari ni Don Juan?",
            choices: [
              "Nagkaroon ng kaguluhan at digmaan.",
              "Nagkaroon ng taggutom at kahirapan.",
              "Naging maunlad at mapayapa pa rin.",
              "Nagkaroon ng malakas na lindol."
            ],
            correctAnswerIndex: 2,
            selectedAnswer: null,
          ),
          QuizSet(
            questionText: "Sino ang naging kahalili ni Don Juan sa paghahari?",
            choices: [
              "Ang anak ni Don Juan.",
              "Ang kapatid ni Don Juan.",
              "Ang pinsan ni Don Juan.",
              "Ang isang maharlikang pamilya."
            ],
            correctAnswerIndex: 0,
            selectedAnswer: null,
          ),
          QuizSet(
            questionText:
                "Ano ang nangyari sa kaharian sa ilalim ng pamumuno ng anak ni Don Juan?",
            choices: [
              "Nagkaroon ng kaguluhan at digmaan.",
              "Nagkaroon ng taggutom at kahirapan.",
              "Naging maunlad at mapayapa pa rin.",
              "Nagkaroon ng malakas na lindol."
            ],
            correctAnswerIndex: 2,
            selectedAnswer: null,
          ),
        ]
        // Add other chapters as needed
      };

      // Fetch quizzes for the given chapterId
      if (chapterQuizzes.containsKey(chapterId)) {
        chapterQuizSet = chapterQuizzes[chapterId]!;
      } else {
        Get.snackbar('Error', 'No quizzes found for chapter ID: $chapterId');
        return;
      }

      // Step 2: Clear the previous quiz set
      quizSet.clear();

      // Step 3: Add the quizzes from the chapter to the quizSet
      for (var quiz in chapterQuizSet) {
        quizSet.add(quiz);
        QuizController().currentQuestion.add(quiz);
      }

      debugPrint(
          'Quiz Set populated for chapter $chapterId: ${quizSet.toString()}');
    } catch (e) {
      // Handle any errors that occur during processing
      Get.snackbar('Error', e.toString());
    } finally {
      // Stop loading
      isLoading(false);
    }
  }
}
