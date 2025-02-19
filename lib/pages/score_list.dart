import 'package:flutter/material.dart';
import 'package:game_stories/controllers/score_controller.dart';
import 'package:get/get.dart';

class ScoreList extends StatelessWidget {
  const ScoreList({super.key});

  @override
  Widget build(BuildContext context) {
    final ScoreController controller = Get.put(ScoreController());

    return Scaffold(
      appBar: AppBar(title: const Text('Your Scores')),
      body: Obx(
        () {
          if (controller.scores.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          return ListView.builder(
            itemCount: controller.scores.length,
            itemBuilder: (context, index) {
              final score = controller.scores[index];
              return ListTile(
                title: Text(score.quizTitle),
                subtitle: Text('Score: ${score.score}'),
              );
            },
          );
        },
      ),
    );
  }
}
