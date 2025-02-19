import 'package:flutter/material.dart';
import 'package:game_stories/const/colors.dart';
import 'package:game_stories/pages/ar.dart';
import 'package:get/get.dart';

class Choose3DPage extends StatelessWidget {
  const Choose3DPage({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, String>> assets = [
      {
        "name": "Haring Fernando",
        "description":
            "Ang Hari ng berbanya na nagkaroon ng misteryosong sakit.",
        "glb": "assets/3dModels/king.glb",
        "coverImage": "assets/hari_3d.jpg",
      },
      {
        "name": "Ibong Adarna",
        "description": "Isang ibon na nakakapagpagaling ng kahit anong sakit",
        "glb": "assets/3dModels/phoenix_king.glb",
        "coverImage": "assets/ibong_adarna_3d.jpg",
      },
    ];

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Stack(
        children: [
          // Background Image
          Positioned.fill(
            child: Image.asset(
              'assets/images/background.png',
              fit: BoxFit.cover,
            ),
          ),
          // Content
          Column(
            children: [
              const SizedBox(height: 60), // Adjust top padding for content
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 40, 20, 40),
                  itemCount: assets.length,
                  scrollDirection: Axis.horizontal,
                  itemBuilder: (context, index) {
                    final modelData = assets[index];
                    final cover = modelData['coverImage'];
                    final name = modelData['name'];
                    final glb = modelData['glb'];

                    return Container(
                      margin: const EdgeInsets.all(8),
                      child: InkWell(
                        onTap: () {
                          if (glb != null) {
                            Get.to(() => AugmentedReality(
                                  model: glb,
                                  modelName: name,
                                  modelDescription: modelData['description']!,
                                ));
                          }
                        },
                        child: Container(
                          margin: const EdgeInsets.all(8),
                          child: Stack(
                            children: [
                              Image.asset(
                                cover!,
                              ),
                              Container(
                                margin: const EdgeInsets.only(top: 8, left: 8),
                                child: Text(
                                  name!,
                                  style: const TextStyle(
                                    color: Colors.black,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
          Positioned(
            top: 10.0,
            left: 10.0,
            child: IconButton(
              onPressed: () {
                Get.back();
              },
              icon: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: Colors.black,
              ),
            ),
          )
        ],
      ),
    );
  }
}
