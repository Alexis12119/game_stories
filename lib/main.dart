import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:game_stories/controllers/login_controller.dart';
import 'package:game_stories/pages/choose_3d.dart';
import 'package:game_stories/pages/choose_quiz.dart';
import 'package:game_stories/pages/choose_story.dart';
import 'package:game_stories/pages/login.dart';
import 'package:game_stories/pages/admin_login.dart';
import 'package:game_stories/pages/main_menu.dart';
import 'package:game_stories/pages/profile.dart';
import 'package:game_stories/pages/score_list.dart';
import 'package:game_stories/pages/signup.dart';
import 'package:game_stories/pages/teacher_score_view.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeRight,
    DeviceOrientation.landscapeLeft,
  ]);

  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);


  await Supabase.initialize(
    url: 'https://apvjytmedzcouthiinhu.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImFwdmp5dG1lZHpjb3V0aGlpbmh1Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3MjQyMDk4ODUsImV4cCI6MjAzOTc4NTg4NX0.cVBk-gUJ82Z2HFqCel1pHsMNwMsqbSyyX01QelZoudk',
  );

  Get.put(LoginController());

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: '/AdminLogin',
      getPages: [
        GetPage(name: '/', page: () => const MainMenu()),
        GetPage(name: '/ChooseStoryPage', page: () => const ChooseStoryPage()),
        GetPage(name: '/AR', page: () => const Choose3DPage()),
        GetPage(name: '/SignUp', page: () => const SignUp()),
        GetPage(name: '/AdminLogin', page: () => const AdminLogin()),
        GetPage(name: '/Login', page: () => const Login()),
        GetPage(name: '/Profile', page: () => const Profile()),
        GetPage(name: '/ChooseStory', page: () => const ChooseStoryPage()),
        GetPage(name: '/ChooseQuiz', page: () => const ChooseQuiz()),
        GetPage(name: '/Score', page: () => const ScoreList()),
        GetPage(name: '/ScoreTeacherView', page: () => TeacherScoreView()),
      ],
    );
  }
}
