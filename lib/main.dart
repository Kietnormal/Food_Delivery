// Tạo Firebase configuration cho Android
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    return android;
  }

  // Cấu hình Firebase cho Android - ĐÃ ĐIỀN THÔNG TIN TỪ google-services.json
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Khởi tạo Firebase với options

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Food Delivery App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'SF Pro Display',
      ),
      home: OnboardingScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

// Màn hình giới thiệu
