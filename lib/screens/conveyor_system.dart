import 'package:convenyor_system/screens/login_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:convenyor_system/services/firebase_service.dart';
import 'package:convenyor_system/Widgets/PieChartCircle.dart'; // Đảm bảo đã import widget PieChartCircle

class ConveyorSystem extends StatefulWidget {
  @override
  _ConveyorSystemState createState() => _ConveyorSystemState();
}

class _ConveyorSystemState extends State<ConveyorSystem> {
  final FirebaseService firebaseService = FirebaseService();
  bool isAutoMode = false;
  Map<String, dynamic> stats = {
    "colors": {"red": 0, "blue": 0, "yellow": 0, "total": 0}
  };
  String _colorDetected = "0xFF000000";

  @override
  void initState() {
    super.initState();
    _listenToAutoMode();
    _listenToStats();
    _listenToColorDetected();
  }

  void _listenToStats() {
    firebaseService.listenToStats().listen((newStats) {
      setState(() {
        stats = newStats;
      });
    });
  }

  void _listenToColorDetected() {
    firebaseService.listenToColorDetected().listen((color) {
      setState(() {
        _colorDetected = color;
      });
    });
  }

  void _listenToAutoMode() {
    firebaseService.listenToModeChanged().listen((isAutoMode) {
      setState(() {
        this.isAutoMode = isAutoMode;
      });
    });
  }

  Future<void> _toggleAutoMode() async {
    setState(() {
      isAutoMode = !isAutoMode;
    });
    await firebaseService.updateAutoMode(isAutoMode);
  }

  // Hàm đăng xuất
  Future<void> _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => LoginScreen()),
    );
  }

  bool isValidColor(String color) {
    try {
      int.parse(color); // Kiểm tra nếu chuỗi có thể chuyển đổi thành màu hợp lệ
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> _runServo(String servo) async {
    if (!isAutoMode) {
      await firebaseService.updateMotor(true);
      await firebaseService.updateServo(servo, true);
      await Future.delayed(Duration(seconds: 2));
      await firebaseService.updateServo(servo, false);
      await Future.delayed(Duration(seconds: 1));
      await firebaseService.updateMotor(false);
    }
  }

  Future<void> _activeMotor() async {
    if (!isAutoMode) {
      await firebaseService.updateMotor(true);
      await Future.delayed(Duration(seconds: 3));
      await firebaseService.updateMotor(false);
    }
  }

  Future<void> _addColor(String color) async {
    await firebaseService.updateStats(color);
  }

  // Chuyển đổi thống kê từ Firebase thành danh sách ColorStats
  List<ColorStats> _getColorStats() {
    var total = stats["total"] ?? 0;
    total = total > 0 ? total : 1;
    var red = (stats["red"] * 100.0 / total) ?? 0;
    var blue = (stats["blue"] * 100.0 / total) ?? 0;
    var yellow = (stats["yellow"] * 100.0 / total) ?? 0;

    // Nếu không có dữ liệu, mặc định red, blue, yellow = 33.33%
    if (red == 0 && blue == 0 && yellow == 0) {
      double defaultValue = 33.3333;
      return [
        ColorStats("0xFFFF0000", stats["red"],
            double.parse(defaultValue.toStringAsFixed(2))),
        ColorStats("0xFF0000FF", stats["blue"],
            double.parse(defaultValue.toStringAsFixed(2))),
        ColorStats("0xFFFFFF00", stats["yellow"],
            double.parse(defaultValue.toStringAsFixed(2))),
      ];
    }

    // Đảm bảo tổng của red, blue, yellow là 100%
    var totalPercentage = red + blue + yellow;
    if (totalPercentage != 100.0) {
      var diff = 100.0 - totalPercentage;
      // Điều chỉnh giá trị để tổng là 100
      red += diff * (red / totalPercentage);
      blue += diff * (blue / totalPercentage);
      yellow += diff * (yellow / totalPercentage);
    }

    // Giới hạn 2 chữ số thập phân
    return [
      ColorStats(
          "0xFFFF0000", stats["red"], double.parse(red.toStringAsFixed(2))),
      ColorStats(
          "0xFF0000FF", stats["blue"], double.parse(blue.toStringAsFixed(2))),
      ColorStats("0xFFFFFF00", stats["yellow"],
          double.parse(yellow.toStringAsFixed(2))),
    ];
  }

  // Hàm reset thống kê
  Future<void> _resetStats() async {
    await firebaseService.resetStats();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            SizedBox(height: 16),
            // Khung widget hiển thị thông tin màu và chế độ
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: Colors.grey[200], // Màu nền của khung
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 5,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center, // Căn giữa cột
                children: [
                  // Hiển thị màu sắc hiện tại và chế độ
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center, // Căn giữa row
                    children: [
                      Text(
                        "Mode: ",
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        isAutoMode ? "Auto" : "Manual", // Trạng thái chế độ
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isAutoMode ? Colors.green : Colors.orange,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),

                  // Hiển thị "Detect Color" khi có màu sắc hợp lệ, nếu không hiển thị thông báo lỗi
                  if (!isAutoMode)
                    Builder(
                      builder: (context) {
                        if (_colorDetected.isNotEmpty) {
                          try {
                            // Nếu có màu sắc hợp lệ, hiển thị Detect Color: và khối màu
                            return Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  "Detect Color: ",
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold),
                                ),
                                Container(
                                  width: 24,
                                  height: 24,
                                  color: Color(int.parse(
                                      _colorDetected)), // Màu sắc hiện tại
                                ),
                              ],
                            );
                          } catch (e) {
                            // Nếu không thể parse màu sắc, hiển thị lỗi
                            return Text(
                              "Can't detect color", // Hiển thị lỗi nếu không parse được
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.red, // Màu chữ đỏ để nổi bật lỗi
                              ),
                            );
                          }
                        } else {
                          // Nếu không có màu sắc, hiển thị lỗi
                          return Text(
                            "Can't detect color", // Hiển thị lỗi nếu không có màu sắc
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.red, // Màu chữ đỏ để nổi bật lỗi
                            ),
                          );
                        }
                      },
                    ),
                ],
              ),
            ),
            SizedBox(height: 16),
            // Hiển thị biểu đồ
            PieChartCircle(
              colorStats: _getColorStats(), // Truyền dữ liệu vào đây
            ),
            SizedBox(height: 32),
            // Tạo một SingleChildScrollView cho các nút điều khiển và các nút khác
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Các nút điều khiển
                    ElevatedButton(
                      onPressed: _toggleAutoMode,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isAutoMode ? Colors.red : Colors.green,
                        padding:
                            EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        textStyle: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      child: Text(isAutoMode
                          ? "Disable Auto Mode"
                          : "Enable Auto Mode"),
                    ),
                    SizedBox(height: 16),
                    // Hiển thị các nút "Detect" chỉ khi không ở chế độ auto
                    if (!isAutoMode) ...[
                      // Nút Detect Red
                      ElevatedButton(
                        onPressed: () {
                          if (isValidColor(_colorDetected)) {
                            _runServo("servo1");
                            _addColor("red");
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content:
                                      Text("Detected color is not valid!")),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          textStyle: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        child: Text("Detect Red"),
                      ),
                      SizedBox(height: 16),
                      // ElevatedButton(
                      //   onPressed: () {
                      //     _runServo("servo1");
                      //     _addColor("red");
                      //   },
                      //   style: ElevatedButton.styleFrom(
                      //     padding: EdgeInsets.symmetric(
                      //         horizontal: 16, vertical: 12),
                      //     textStyle: TextStyle(
                      //         fontSize: 16, fontWeight: FontWeight.bold),
                      //   ),
                      //   child: Text("Force Detect Red"),
                      // ),
                      //SizedBox(height: 16),

                      // Nút Detect Yellow
                      ElevatedButton(
                        onPressed: () {
                          if (isValidColor(_colorDetected)) {
                            _runServo("servo2");
                            _addColor("yellow");
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content:
                                      Text("Detected color is not valid!")),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          textStyle: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        child: Text("Detect Yellow"),
                      ),
                      SizedBox(height: 16),
                      // ElevatedButton(
                      //   onPressed: () {
                      //     _runServo("servo2");
                      //     _addColor("yellow");
                      //   },
                      //   style: ElevatedButton.styleFrom(
                      //     padding: EdgeInsets.symmetric(
                      //         horizontal: 16, vertical: 12),
                      //     textStyle: TextStyle(
                      //         fontSize: 16, fontWeight: FontWeight.bold),
                      //   ),
                      //   child: Text("Force Detect Yellow"),
                      // ),
                      //SizedBox(height: 16),

                      // Nút Detect Blue
                      ElevatedButton(
                        onPressed: () {
                          if (isValidColor(_colorDetected)) {
                            _runServo("servo3");
                            _addColor("blue");
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content:
                                      Text("Detected color is not valid!")),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          textStyle: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        child: Text("Detect Blue"),
                      ),
                      //SizedBox(height: 16),
                      // ElevatedButton(
                      //   onPressed: () {
                      //     _runServo("servo3");
                      //     _addColor("blue");
                      //   },
                      //   style: ElevatedButton.styleFrom(
                      //     padding: EdgeInsets.symmetric(
                      //         horizontal: 16, vertical: 12),
                      //     textStyle: TextStyle(
                      //         fontSize: 16, fontWeight: FontWeight.bold),
                      //   ),
                      //   child: Text("Force Detect Blue"),
                      // ),
                    ],
                    SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _resetStats,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        padding:
                            EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        textStyle: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      child: Text("Reset"),
                    ),
                    SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => _logout(context),
                      style: ElevatedButton.styleFrom(
                        padding:
                            EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        textStyle: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      child: Text("Logout"),
                    )
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
