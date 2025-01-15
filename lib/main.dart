import 'package:convenyor_system/screens/conveyor_system.dart';
import 'package:convenyor_system/screens/login_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (kIsWeb) {
    await Firebase.initializeApp(
        options: FirebaseOptions(
            apiKey: "AIzaSyBWw__sRiWmXWCjflNDJO_XSJgk1bBXauQ",
            authDomain: "convenyorsystem.firebaseapp.com",
            databaseURL:
                "https://convenyorsystem-default-rtdb.asia-southeast1.firebasedatabase.app",
            projectId: "convenyorsystem",
            storageBucket: "convenyorsystem.firebasestorage.app",
            messagingSenderId: "1009422359876",
            appId: "1:1009422359876:web:2c1479e52aac866d780b11",
            measurementId: "G-ZDJEETZV3Y")); // Khởi tạo Firebase
  }else {
    await Firebase.initializeApp(); // Khởi tạo Firebase
  }
  runApp(MyApp());
}



class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Firebase Login',
      home: AuthGate(),
    );
  }
}

class AuthGate extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<User?>(
      future: FirebaseAuth.instance.authStateChanges().first,
      builder: (context, snapshot) {
        // Kiểm tra trạng thái đăng nhập
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        // Nếu người dùng đã đăng nhập, chuyển đến ConveyorSystem
        if (snapshot.hasData) {
          return ConveyorSystem();
        }

        // Nếu người dùng chưa đăng nhập, chuyển đến màn hình đăng nhập
        return LoginScreen();
      },
    );
  }
}