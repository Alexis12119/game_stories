import 'package:flutter/material.dart';
import 'package:game_stories/controllers/login_controller.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SignUp extends StatelessWidget {
  const SignUp({super.key});

  @override
  Widget build(BuildContext context) {
    LoginController loginController = Get.put(LoginController());

    TextEditingController usernameFieldController = TextEditingController();
    TextEditingController firstNameFieldController = TextEditingController();
    TextEditingController lastNameFieldController = TextEditingController();
    TextEditingController emailFieldController = TextEditingController();
    TextEditingController passwordFieldController = TextEditingController();

    RxString selectedSectionId = ''.obs;
    RxList<Map<String, dynamic>> sections = <Map<String, dynamic>>[].obs;

    /// Fetch Sections from Supabase
    Future<void> fetchSections() async {
      try {
        final response = await Supabase.instance.client
            .from('section')
            .select('id, name');

        sections.assignAll(List<Map<String, dynamic>>.from(response));
      } catch (e) {
        Get.snackbar('Error', 'Failed to load sections');
      }
    }

    fetchSections(); // Load sections on widget build

    return Scaffold(
      appBar: AppBar(),
      body: Obx(
        () {
          if (loginController.isLoading.value) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          return Padding(
            padding: const EdgeInsets.all(8.0),
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // Username Field
                  TextFormField(
                    controller: usernameFieldController,
                    decoration: const InputDecoration(
                      hintText: 'Username',
                      labelText: 'Username',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(8)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8.0),

                  // First Name Field
                  TextFormField(
                    controller: firstNameFieldController,
                    decoration: const InputDecoration(
                      hintText: 'First Name',
                      labelText: 'First Name',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(8)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8.0),

                  // Last Name Field
                  TextFormField(
                    controller: lastNameFieldController,
                    decoration: const InputDecoration(
                      hintText: 'Last Name',
                      labelText: 'Last Name',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(8)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8.0),

                  // Email Field
                  TextFormField(
                    controller: emailFieldController,
                    decoration: const InputDecoration(
                      hintText: 'Email',
                      labelText: 'Email',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(8)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8.0),

                  // Password Field
                  TextFormField(
                    controller: passwordFieldController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      hintText: 'Password',
                      labelText: 'Password',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(8)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8.0),

                  // Dropdown for Selecting Section
                  Obx(() {
                    return DropdownButtonFormField<String>(
                      value: selectedSectionId.value.isNotEmpty
                          ? selectedSectionId.value
                          : null,
                      hint: const Text("Select Section"),
                      items: sections.map((section) {
                        return DropdownMenuItem<String>(
                          value: section['id'].toString(),
                          child: Text(section['name']),
                        );
                      }).toList(),
                      onChanged: (value) {
                        selectedSectionId.value = value!;
                      },
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(8)),
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 12.0),

                  // Sign Up Button
                  TextButton(
                    onPressed: () {
                      if (selectedSectionId.value.isEmpty) {
                        Get.snackbar('Error', 'Please select a section');
                        return;
                      }

                      loginController.registerNewUser(
                        emailFieldController.text.trim(),
                        passwordFieldController.text.trim(),
                        usernameFieldController.text.trim(),
                        firstNameFieldController.text.trim(),
                        lastNameFieldController.text.trim(),
                        selectedSectionId.value,
                      );
                    },
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.blue, // Blue background
                      padding: const EdgeInsets.symmetric(
                          vertical: 12.0, horizontal: 20.0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8), // Rounded corners
                      ),
                    ),
                    child: const Text(
                      'Sign Up',
                      style: TextStyle(
                        color: Colors.white, // White text color
                        fontSize: 18, // Bold size 18
                        fontWeight: FontWeight.bold, // Bold text
                      ),
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
