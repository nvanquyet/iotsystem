import 'package:convenyor_system/config.dart';
import 'package:firebase_database/firebase_database.dart';
enum ColorLimit { none, blue, red, yellow }
class FirebaseService {
  final DatabaseReference dbRef = FirebaseDatabase.instance.ref();

  // Cập nhật chế độ AutoMode
  Future<void> updateAutoMode(bool autoMode) async {
    try {
      await dbRef.child('autoMode').set(autoMode);
    } catch (e) {
      print("Error updating autoMode: $e");
    }
  }

  String colorLimitToString(ColorLimit color) {
    return color.name; // Nếu bạn dùng Dart 2.15 trở lên
  }

  Future<void> updateColorLimit(ColorLimit color, int newValue) async {
  try {
    final colorKey = colorLimitToString(color);
    await dbRef.child('limits').child(colorKey).set(newValue);
    print("Updated $colorKey limit to $newValue");
  } catch (e) {
    print("Error updating $color limit: $e");
  }
}


  // Cập nhật trạng thái của motor
  Future<void> updateServo(String servo, bool status) async {
    try {
      await dbRef.child('devices/servoes/$servo').set(status);
    } catch (e) {
      print("Error updating servo: $e");
    }
  }

  Future<void> updateMotor(bool status) async {
    try {
      await dbRef.child('devices/motor').set(status);
    } catch (e) {
      print("Error updating motor: $e");
    }
  }

  Future<void> updateStats(String color) async {
    try {
      final colorPath = 'colors/$color';
      final totalPath = 'colors/total';

      // Thực hiện các thay đổi không đồng thời
      final colorRef = dbRef.child(colorPath);
      final totalRef = dbRef.child(totalPath);

      final colorSnapshot = await colorRef.get();
      final totalSnapshot = await totalRef.get();

      final colorValue = (colorSnapshot.value ?? 0) as int;
      final totalValue = (totalSnapshot.value ?? 0) as int;

      await colorRef.set(colorValue + 1);
      await totalRef.set(totalValue + 1);
    } catch (e) {
      print("Error updating stats: $e");
    }
  }
  // Cập nhật trạng thái không phát hiện màu sắc
  Future<void> resetCurrentColor(String colorKey) async {
    await dbRef.child('colors/current/$colorKey').set(0);
    print("Reset current color $colorKey to 0");
  }

  Future<void> updateCurrentColor(String colorKey, int newValue) async {
    try {
      await dbRef.child('colors/current/$colorKey').set(newValue);
      print("Updated current color $colorKey to $newValue");
    } catch (e) {
      print("Error updating current color: $e");
    }
  }
  // Thêm hàm reset thống kê
  Future<void> resetStats() async {
      await dbRef.child('colors').set({
      'red': Config.defaultValue,
      'blue': Config.defaultValue,
      'yellow': Config.defaultValue,
      'total': Config.defaultValue,
      'notDetect': false,
      'current': {
        'red': Config.defaultValue,
        'blue': Config.defaultValue,
        'yellow': Config.defaultValue,
      }
    });
    await dbRef.child('limits').set({
      'red': Config.defaultLimit,
      'blue': Config.defaultLimit,
      'yellow': Config.defaultLimit});
    
    print("Reset Successfully");
  }

  // Lắng nghe thay đổi thống kê
  Stream<Map<String, dynamic>> listenToStats() {
    return dbRef.child('colors').onValue.map((event) {
      final data = event.snapshot.value as Map?;
      return {
        "red": data?['red'] ?? 0,
        "blue": data?['blue'] ?? 0,
        "yellow": data?['yellow'] ?? 0,
        "total": data?['total'] ?? 0,
      };
    });
  }

  Stream<String> listenToColorDetected() {
    var colorRef = dbRef.child("sensor/colorDetected");
    return colorRef.onValue.map((event) {
      // Kiểm tra nếu có dữ liệu và trả về màu sắc
      if (event.snapshot.value != null) {
        // Dữ liệu màu sắc sẽ là một chuỗi (ví dụ: "0xFF123456")
        return event.snapshot.value.toString();
      } else {
        return ''; // Trả về chuỗi rỗng nếu không có màu sắc
      }
    });
  }

  Stream<bool> listenToModeChanged() {
    var ref = dbRef.child("autoMode");
    return ref.onValue.map((event) {
      if (event.snapshot.value != null) {
        return event.snapshot.value == true;
      } else {
        return false;
      }
    });
  }

  Stream<Map<String, dynamic>> listenToCurrent() {
    return dbRef.child('colors/current').onValue.map((event) {
      final data = event.snapshot.value as Map?;
      if (data == null) return {};
      return data.map((key, value) => MapEntry(key.toString(), value ?? 0));
    });
  }
  
  Stream<Map<String, dynamic>> listenToLimitStats() {
     return dbRef.child('limits').onValue.map((event) {
      final data = event.snapshot.value as Map?;
      return {
        "red": data?['red'] ?? 0,
        "blue": data?['blue'] ?? 0,
        "yellow": data?['yellow'] ?? 0
      };
    });
  }


}
