// ignore_for_file: avoid_print

import 'package:get/get.dart';

class PageViewerController extends GetxController {
  var pageSelected = 0.obs;

  final List<String> ibongAdarna = [
    'assets/images/ibong_adarna/aralin_1.gif',
    'assets/images/ibong_adarna/aralin_2.gif',
    'assets/images/ibong_adarna/aralin_3.gif',
    'assets/images/ibong_adarna/aralin_4.gif',
    'assets/images/ibong_adarna/aralin_5.gif',
    'assets/images/ibong_adarna/aralin_6.gif',
    'assets/images/ibong_adarna/aralin_7.gif',
  ];

  final List<Map<String, dynamic>> contents = [
    {
      'chapter': '1',
      'mode': 'image',
      'value': [
        'assets/images/ibong_adarna/aralin_1.gif',
        'assets/images/ibong_adarna/aralin_2.gif',
      ],
    },
    {
      'chapter': '2',
      'mode': 'image',
      'value': [
        'assets/images/ibong_adarna/aralin_3.gif',
        'assets/images/ibong_adarna/aralin_4.gif',
      ]
    },
    {
      'chapter': '3',
      'mode': 'image',
      'value': [
        'assets/images/ibong_adarna/aralin_5.gif',
        'assets/images/ibong_adarna/aralin_6.gif',
        'assets/images/ibong_adarna/aralin_7.gif',
      ]
    },
  ];

  RxList<String> chosenStory = <String>[].obs;

  List<String>? getValuesByChapter(String chapterId) {
    try {
      final chapter = contents.firstWhere((chapter) => chapter['chapter'] == chapterId);
      chosenStory.value = chapter['value'] as List<String>;
      return chapter['value'] as List<String>;
    } catch (e) {
      print('Chapter not found: $chapterId');
      return null;
    }
  }

  void nextPage() {
    pageSelected.value++;
  }

  void previousPage() {
    pageSelected.value--;
  }
}
