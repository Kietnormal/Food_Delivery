import 'package:appfoodstore/screen/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Tạo Firebase configuration cho Android
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    return android;
  }

  // Cấu hình Firebase cho Android - ĐÃ ĐIỀN THÔNG TIN TỪ google-services.json
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyA_-8UTTaD45_ghnNbflsr0bNIYosC-5S0',
    appId: '1:382042881166:android:2cef6c86cefacb8d7cdddf',
    messagingSenderId: '382042881166',
    projectId: 'appfood2-bdbac',
    databaseURL: 'https://appfood2-bdbac-default-rtdb.firebaseio.com/',
    storageBucket: 'appfood2-bdbac.firebasestorage.app',
  );
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Khởi tạo Firebase với options
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('Firebase initialized successfully');
  } catch (e) {
    // Nếu lỗi Firebase, vẫn chạy app nhưng báo lỗi
    print('Firebase initialization error: $e');
    print('App will run without Firebase features');
  }

  // Khởi tạo Supabase
  try {
    await Supabase.initialize(
      url: 'https://vlbxfyslradxevxkszte.supabase.co',
      anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZsYnhmeXNscmFkeGV2eGtzenRlIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDg0MzQwODgsImV4cCI6MjA2NDAxMDA4OH0.WtffToDzcmTqXVrQIPwHTb23BaMVZbi5YTiWgSbUgQM',
    );
    print('Supabase initialized successfully');

    // Test Supabase connection
    try {
      final supabase = Supabase.instance.client;
      final buckets = await supabase.storage.listBuckets();
      print('Supabase connection test successful - Found ${buckets.length} buckets');
    } catch (e) {
      print('Supabase connection test failed: $e');
    }

  } catch (e) {
    print('Supabase initialization error: $e');
    print('App will run without image upload features');
  }

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
class OnboardingScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Ẩn status bar và navigation bar để full screen
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Container(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: Container(
                width: double.infinity,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Hiển thị hình ảnh thay vì vẽ
                    Container(
                      width: 120,
                      height: 120,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.asset(
                          'assets/images/chef.jfif', // Đường dẫn đến hình ảnh của bạn
                          width: 120,
                          height: 120,
                          fit: BoxFit.cover,
                          // Xử lý khi không tìm thấy hình ảnh
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                color: Colors.grey[300],
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                Icons.restaurant_menu,
                                size: 60,
                                color: Colors.grey[600],
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    SizedBox(height: 40),
                    Text(
                      'The Food\nDelivery',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(40),
              child: Center(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => LoginScreen()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF5DADE2),
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Bắt đầu',
                        style: TextStyle(fontSize: 16),
                      ),
                      SizedBox(width: 8),
                      Icon(Icons.arrow_forward, size: 16),
                    ],
                  ),
                ),
              ),
            ),
            Container(
              height: 4,
              width: 60,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}