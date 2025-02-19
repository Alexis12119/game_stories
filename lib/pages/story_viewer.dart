import 'package:flutter/material.dart';
import 'package:get/get.dart';

class StoryViewer extends StatelessWidget {
  final List<String> story;
  final RxInt pageSelected;
  final Function() nextPage;
  final Function() previousPage;

  const StoryViewer({
    super.key,
    required this.story,
    required this.pageSelected,
    required this.nextPage,
    required this.previousPage,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Obx(() {
            return Row(
              children: [
                Expanded(
                  child: Image.asset(story[pageSelected.value]),
                ),
              ],
            );
          }),
          Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  IconButton(
                    onPressed: () {
                      Get.back();
                    },
                    icon: const Icon(
                      Icons.exit_to_app,
                      size: 40.0,
                    ),
                  ),
                ],
              ),
              Expanded(child: Container()),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    onPressed: () {
                      pageSelected.value <= 0 ? null : previousPage.call();
                    },
                    icon: const Icon(
                      Icons.arrow_circle_left_rounded,
                      size: 40.0,
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      if (pageSelected.value + 1 == story.length) {
                        Navigator.pop(context);
                        pageSelected.value = 0;
                      } else {
                        nextPage.call();
                      }
                    },
                    icon: const Icon(
                      Icons.arrow_circle_right_sharp,
                      size: 40.0,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
