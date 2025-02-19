import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:game_stories/controllers/supabase_controller.dart';
import 'student_profile_page.dart';

class StudentListPage extends StatelessWidget {
  const StudentListPage({super.key});

  @override
  Widget build(BuildContext context) {
    final SupaBaseController supaBaseController =
        Get.find<SupaBaseController>();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A2B50), // Navy Blue
        title: const Text(
          "Student Profile",
          style: TextStyle(
              fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        centerTitle: true,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: ClipOval(
            child: Material(
              color: Colors.blue, // Background color
              child: InkWell(
                onTap: () => Get.back(),
                child: const SizedBox(
                  width: 40, // Adjust size as needed
                  height: 40,
                  child: Icon(Icons.arrow_back, color: Colors.white),
                ),
              ),
            ),
          ),
        ),
      ),
      body: FutureBuilder(
        future: supaBaseController.fetchStudents(),
        builder: (context, AsyncSnapshot<List<Map<String, dynamic>>> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }

          final students = snapshot.data ?? [];
          if (students.isEmpty) {
            return const Center(child: Text("No students available"));
          }

          return Column(
            children: [
              // Student List
              Expanded(
                child: ListView.builder(
                  itemCount: students.length,
                  itemBuilder: (context, index) {
                    final student = students[index];

                    return InkWell(
                      onTap: () {
                        Get.to(
                            () => StudentProfilePage(studentId: student['id']));
                      },
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                vertical: 16, horizontal: 12),
                            color: Colors.grey.shade400,
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const CircleAvatar(
                                  backgroundColor: Colors.black,
                                  radius: 18,
                                  child: Icon(Icons.person,
                                      color: Colors.white, size: 18),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "${student['first_name']} ${student['last_name']}",
                                        style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        "Section: ${student['section_name'] ?? 'Unknown'}",
                                        style: const TextStyle(
                                            fontSize: 14,
                                            color: Colors.black,
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                              height: 2, color: Colors.black), // Separator Line
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
