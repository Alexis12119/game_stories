import 'package:flutter/material.dart';
import 'package:game_stories/controllers/login_controller.dart';
import 'package:get/get.dart';

class Profile extends StatelessWidget {
  const Profile({super.key});

  @override
  Widget build(BuildContext context) {
    LoginController loginController = Get.put(LoginController());

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
      ),
      body: Center(
        child: Text("${loginController.user?.id} is Logged in"),
      ),
    );
  }
}
