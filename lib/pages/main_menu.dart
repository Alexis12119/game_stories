// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:game_stories/const/colors.dart';
import 'package:game_stories/controllers/login_controller.dart';
import 'package:get/get.dart';

class MainMenu extends StatelessWidget {
  const MainMenu({super.key});

  @override
  Widget build(BuildContext context) {
    LoginController loginController = Get.find();

    loginController.checkUserLoggedIn();

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/background.png',
              fit: BoxFit.cover,
            ),
          ),
          SizedBox(
            width: double.infinity,
            height: double.infinity,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  InkWell(
                    onTap: () {
                      Get.toNamed('/ChooseStory');
                    },
                    child: Container(
                      margin: const EdgeInsets.fromLTRB(10, 20, 10, 20),
                      width: 180,
                      height: 300,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Colors.white,
                          width: 4,
                        ),
                        borderRadius:
                            const BorderRadius.all(Radius.circular(12)),
                        image: const DecorationImage(
                          image: NetworkImage(
                              'https://images.theconversation.com/files/45159/original/rptgtpxd-1396254731.jpg?ixlib=rb-4.1.0&q=45&auto=format&w=1356&h=668&fit=crop'),
                          fit: BoxFit.cover,
                        ),
                      ),
                      child: const Center(
                        child: Text(
                          'Stories',
                          style: TextStyle(
                            color: componentColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Visibility(
                    visible: loginController.isUserLoggedIn.value,
                    child: InkWell(
                      onTap: () {
                        Get.toNamed('/ChooseQuiz');
                      },
                      child: Container(
                        margin: const EdgeInsets.fromLTRB(10, 20, 10, 20),
                        width: 180,
                        height: 300,
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Colors.white,
                            width: 4,
                          ),
                          borderRadius:
                              const BorderRadius.all(Radius.circular(12)),
                          image: const DecorationImage(
                            image: NetworkImage(
                                'https://www.rathinamcollege.edu.in/wp-content/uploads/2021/02/exam-rules.png'),
                            fit: BoxFit.cover,
                          ),
                        ),
                        child: const Center(
                          child: Text(
                            'Quiz',
                            style: TextStyle(
                              color: componentColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: () {
                      Get.toNamed('/AR');
                    },
                    child: Container(
                      margin: const EdgeInsets.fromLTRB(10, 20, 10, 20),
                      width: 180,
                      height: 300,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Colors.white,
                          width: 4,
                        ),
                        borderRadius:
                            const BorderRadius.all(Radius.circular(12)),
                        image: const DecorationImage(
                          image: NetworkImage(
                              'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcTt-NjikX3VDHZ-4sVytJWmyicEIE_nKhgotw&s'),
                          fit: BoxFit.cover,
                        ),
                      ),
                      child: const Center(
                        child: Text(
                          'AR',
                          style: TextStyle(
                            color: componentColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Visibility(
                    visible: loginController.isUserLoggedIn.value,
                    child: InkWell(
                      onTap: () {
                        loginController.isUserTeacher.value
                            ? Get.toNamed('/ScoreTeacherView')
                            : Get.toNamed('/Score');
                      },
                      child: Container(
                        margin: const EdgeInsets.fromLTRB(10, 20, 10, 20),
                        width: 180,
                        height: 300,
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Colors.white,
                            width: 4,
                          ),
                          borderRadius:
                              const BorderRadius.all(Radius.circular(12)),
                          image: const DecorationImage(
                            image: NetworkImage(
                                'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQ1wf3N6KBjFYCHX7Uyb0AAdAt2O7eUyi9Pug&s'),
                            fit: BoxFit.cover,
                          ),
                        ),
                        child: const Center(
                          child: Text(
                            'Score',
                            style: TextStyle(
                              color: componentColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Visibility(
                    visible: loginController.isUserLoggedIn.value,
                    child: InkWell(
                      onTap: () {
                        loginController.signOut();
                        Get.offAllNamed('/');
                      },
                      child: Container(
                        margin: const EdgeInsets.fromLTRB(10, 20, 10, 20),
                        width: 180,
                        height: 300,
                        color: componentColor,
                        child: const Center(
                          child: Text(
                            'Logout',
                            style: TextStyle(
                              color: blackText,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Visibility(
                    visible: loginController.isUserTeacher.value,
                    child: InkWell(
                      onTap: () {
                        Get.toNamed('/SignUp');
                      },
                      child: Container(
                        margin: const EdgeInsets.fromLTRB(10, 20, 10, 20),
                        width: 180,
                        height: 300,
                        color: componentColor,
                        child: const Center(
                          child: Text(
                            'Create Account',
                            style: TextStyle(
                              color: blackText,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Visibility(
                    visible: !loginController.isUserLoggedIn.value,
                    child: InkWell(
                      onTap: () {
                        if (loginController.isUserTeacher.value) {
                          Get.toNamed('/AdminLogin');
                        } else {
                          Get.toNamed('/Login');
                        }
                      },
                      child: Container(
                        margin: const EdgeInsets.fromLTRB(10, 20, 10, 20),
                        width: 180,
                        height: 300,
                        color: componentColor,
                        child: const Center(
                          child: Text(
                            'Login',
                            style: TextStyle(
                              color: blackText,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
