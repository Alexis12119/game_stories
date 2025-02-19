// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LoginController extends GetxController {
  final SupabaseClient supabase = Supabase.instance.client;
  Session? session;
  User? user;

  RxBool isLoading = false.obs;
  RxBool isUserLoggedIn = false.obs;
  RxBool isUserTeacher = false.obs;

  void checkUserLoggedIn() {
    session = supabase.auth.currentSession;
    user = supabase.auth.currentUser;

    if (user?.id == 'fcc18a1e-8f4f-4bb3-906a-c1c3a1a9d899' ||
        user?.id == '975b4a4f-0238-4423-b74a-1aab1eaea35c') {
      isUserTeacher.value = true;
    }

    if (isUserTeacher.value) {
      isUserLoggedIn.value = session != null && user != null;
      print('Teacher logged in');
    } else {
      isUserLoggedIn.value = session != null && user != null;
      print('User logged in $isUserLoggedIn');
    }
  }

  Future<void> registerNewUser(String email, String password, String username,
      String firstName, String lastName, String sectionId) async {
    try {
      isLoading.value = true;
      await supabase.auth.signUp(
        email: email,
        password: password,
        data: {
          'username': username,
          'first_name': firstName,
          'last_name': lastName,
          'section_id': sectionId,
        },
      );

      await Get.offAllNamed('/');
      isLoading.value = false;
    } catch (e) {
      print('Error siunging in user: $e');
      Get.defaultDialog(
        title: 'Sign Up Error',
        content: Column(
          children: [
            Text(
              'An error occurred while logging in. $e',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 10),
          ],
        ),
        confirm: TextButton(
          onPressed: () => Get.back(),
          child: const Text('OK'),
        ),
      );
    } finally {
      isLoading.value = false;
    }
  }

  void signInUserUsingPasswordTeacher(String email, String password) async {
    try {
      isLoading.value = true;

      await supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      checkUserLoggedIn();

      if(isUserTeacher.value) {
      await Get.offAllNamed('/ChooseQuiz');
      } else {
        throw Exception('User not Found');
      }


      isLoading.value = false;
    } catch (e) {
      // print('Error siunging in user: $e');
      Get.defaultDialog(
        title: 'Login Error',
        content: const Column(
          children: [
            Text(
              'An error occurred while logging in.',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 10),
          ],
        ),
        confirm: TextButton(
          onPressed: () => Get.back(),
          child: const Text('OK'),
        ),
      );
    } finally {
      isLoading.value = false;
    }
  }

  void signInUserUsingPassword(String email, String password) async {
    try {
      isLoading.value = true;

      await supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      checkUserLoggedIn();

      if (!isUserTeacher.value) {
        await Get.offAllNamed('/');
      } else {
        throw Exception('User not Found');
      }

      isLoading.value = false;
    } catch (e) {
      // print('Error siunging in user: $e');
      Get.defaultDialog(
        title: 'Login Error',
        content: const Column(
          children: [
            Text(
              'An error occurred while logging in.',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 10),
          ],
        ),
        confirm: TextButton(
          onPressed: () => Get.back(),
          child: const Text('OK'),
        ),
      );
    } finally {
      isLoading.value = false;
    }
  }

  void signOut() async {
    try {
      isLoading.value = true;
      isUserTeacher.value = false;
      await supabase.auth.signOut();
      isLoading.value = false;
    } catch (e) {
      print('Error siunging in user: $e');
    } finally {
      isLoading.value = false;
    }
  }
}
