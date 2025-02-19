import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:game_stories/controllers/supabase_controller.dart';

class StudentProfilePage extends StatelessWidget {
  final String studentId;
  const StudentProfilePage({super.key, required this.studentId});

  @override
  Widget build(BuildContext context) {
    final SupaBaseController supaBaseController =
        Get.find<SupaBaseController>();

    return Scaffold(
      backgroundColor: const Color(0xFF1A2B50), // Navy Blue Background
      body: FutureBuilder(
        future: Future.wait([
          supaBaseController.fetchStudentProfile(studentId),
          supaBaseController.fetchStudentScores(studentId)
        ]),
        builder: (context, AsyncSnapshot<List<dynamic>> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError || snapshot.data == null) {
            return const Center(
                child: Text("Error: \${snapshot.error}",
                    style: TextStyle(color: Colors.white)));
          }

          final studentData = snapshot.data![0] as Map<String, dynamic>?;
          final scores = snapshot.data![1] as List<Map<String, dynamic>>;

          if (studentData == null) {
            return const Center(
                child: Text("Student not found",
                    style: TextStyle(color: Colors.white)));
          }

          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 40, // Circle size
                        height: 40,
                        decoration: const BoxDecoration(
                          color: Colors.blue, // Background color
                          shape: BoxShape.circle, // Makes it circular
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.arrow_back,
                              color: Colors.white, size: 24),
                          onPressed: () => Get.back(),
                        ),
                      ),
                      const SizedBox(width: 20),
                      const Center(
                        child: Text(
                          "Student Profile",
                          style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.white),
                        ),
                      )
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Center(
                    child: CircleAvatar(
                      radius: 40,
                      backgroundColor: Colors.white,
                      child: Icon(Icons.person, size: 40, color: Colors.black),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Center(
                    child: Text(
                      "${studentData['first_name']} ${studentData['last_name']}",
                      style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white),
                    ),
                  ),
                  Center(
                    child: Text(
                      "Section: ${studentData['section_name']}",
                      style: const TextStyle(fontSize: 18, color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: ListView.builder(
                      itemCount: scores.length,
                      itemBuilder: (context, index) {
                        final score = scores[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: ExpansionTile(
                            collapsedBackgroundColor: Colors.grey.shade400,
                            backgroundColor: Colors.grey.shade300,
                            title: Text(
                              score['quiz_title'],
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            children: [
                              ListTile(
                                title: const Text("Score"),
                                trailing: Text(
                                  "${score['score']}",
                                  style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
