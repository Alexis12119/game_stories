import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:game_stories/controllers/supabase_controller.dart';
import 'package:game_stories/model/quiz_set.dart';

class EditQuiz extends StatefulWidget {
  final List<QuizSet>? quizSets;

  const EditQuiz({super.key, this.quizSets});

  @override
  State<EditQuiz> createState() => _EditQuizState();
}

class _EditQuizState extends State<EditQuiz> {
  final TextEditingController titleController = TextEditingController();
  late List<QuizSet> quizSetsFinal;
  late List<TextEditingController> questionControllers;
  late List<List<TextEditingController>> choiceControllers;

  @override
  void initState() {
    super.initState();
    quizSetsFinal = widget.quizSets ?? [];
    questionControllers = quizSetsFinal.map((quizSet) => TextEditingController(text: quizSet.questionText)).toList();
    choiceControllers = quizSetsFinal.map((quizSet) {
      return quizSet.choices.map((choice) => TextEditingController(text: choice)).toList();
    }).toList();
  }

  @override
  void dispose() {
    titleController.dispose();
    for (var controller in questionControllers) {
      controller.dispose();
    }
    for (var controllers in choiceControllers) {
      for (var controller in controllers) {
        controller.dispose();
      }
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final supa = Get.put(SupaBaseController());

    return Scaffold(
      backgroundColor: const Color(0xFF1A237E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A237E),
        elevation: 0,
        title: const Text('Create Quiz', style: TextStyle(color: Colors.white, fontSize: 20)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Get.back(),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await supa.uploadQuizData(quizSetsFinal, titleController.text);
              Get.offAllNamed('/');
            },
            child: const Text('Done', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: Obx(() {
        if (supa.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  hintText: 'Quiz Title',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: quizSetsFinal.length,
                itemBuilder: (context, index) {
                  final quizSet = quizSetsFinal[index];
                  final questionController = questionControllers[index];
                  final choiceControllersForQuiz = choiceControllers[index];

                  return Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    color: Colors.white,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Question Details', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () {
                                  setState(() {
                                    quizSetsFinal.removeAt(index);
                                    questionControllers.removeAt(index);
                                    choiceControllers.removeAt(index);
                                  });
                                },
                              ),
                            ],
                          ),
                          TextField(
                            controller: questionController,
                            decoration: const InputDecoration(labelText: 'Question', border: OutlineInputBorder()),
                            onChanged: (value) {
                              quizSet.questionText = value;
                            },
                          ),
                          const SizedBox(height: 8),
                          ...List.generate(
                            4,
                            (choiceIndex) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: TextField(
                                controller: choiceControllersForQuiz[choiceIndex],
                                decoration: InputDecoration(labelText: 'Choice ${choiceIndex + 1}', border: const OutlineInputBorder()),
                                onChanged: (value) {
                                  quizSet.choices[choiceIndex] = value;
                                },
                              ),
                            ),
                          ),
                          DropdownButtonFormField<String>(
                            value: quizSet.choices[quizSet.correctAnswerIndex],
                            items: quizSet.choices.map((choice) {
                              return DropdownMenuItem<String>(
                                value: choice,
                                child: Text(choice),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                quizSet.correctAnswerIndex = quizSet.choices.indexOf(value!);
                              });
                            },
                            decoration: const InputDecoration(labelText: 'Correct Answer', border: OutlineInputBorder()),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      }),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          setState(() {
            quizSetsFinal.add(
              QuizSet(
                questionText: 'New Question',
                choices: ['Choice 1', 'Choice 2', 'Choice 3', 'Choice 4'],
                correctAnswerIndex: 0,
                selectedAnswer: null,
              ),
            );
            questionControllers.add(TextEditingController(text: 'New Question'));
            choiceControllers.add([
              TextEditingController(text: 'Choice 1'),
              TextEditingController(text: 'Choice 2'),
              TextEditingController(text: 'Choice 3'),
              TextEditingController(text: 'Choice 4'),
            ]);
          });
        },
        backgroundColor: Colors.blue,
        child: const Icon(Icons.add),
      ),
    );
  }
}
