import 'package:convenyor_system/Widgets/EnhancedStatsChart.dart';
import 'package:convenyor_system/config.dart';
import 'package:convenyor_system/screens/login_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:convenyor_system/services/firebase_service.dart';
import 'package:convenyor_system/Widgets/PieChartCircle.dart' show ColorStats, PieChartCircle;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class ConveyorSystem extends StatefulWidget {
  const ConveyorSystem({Key? key}) : super(key: key);

  @override
  _ConveyorSystemState createState() => _ConveyorSystemState();
}

class _ConveyorSystemState extends State<ConveyorSystem> {

// ========================= Variable =======================
  final FirebaseService _firebaseService = FirebaseService();
  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();
  
  // Data structure
  bool _isAutoMode = false;
  String _colorDetected = "0xFF000000";

// ======================= Mapping =========================
 
 // Mapping for color keys
  final Map<ColorLimit, String> colorKeyMap = {
    ColorLimit.red: "red",
    ColorLimit.blue: "blue",
    ColorLimit.yellow: "yellow",
  };
  
  Map<String, dynamic> _stats = {
    "red": Config.defaultValue, 
    "blue": Config.defaultValue, 
    "yellow": Config.defaultValue,
    "total": Config.defaultValue,
  };

  Map<String, dynamic> _currentStats = {
    "red": Config.defaultValue, 
    "blue": Config.defaultValue, 
    "yellow": Config.defaultValue,
  };

  Map<String, dynamic> _limitStats = {
    "red": Config.defaultLimit, 
    "blue": Config.defaultLimit, 
    "yellow": Config.defaultLimit
  };
  
  final Map<String, TextEditingController> _limitControllers = {
    "red": TextEditingController(text: Config.defaultLimit.toString()),
    "blue": TextEditingController(text: Config.defaultLimit.toString()),
    "yellow": TextEditingController(text: Config.defaultLimit.toString()),
  };

  // Color information definitions
  final Map<ColorLimit, ColorInfo> _colorInfo = {
    ColorLimit.red: ColorInfo(
      name: "Đỏ",
      color: Colors.red,
      servo: "servo1",
      colorCode: "0xFFFF0000",
    ),
    ColorLimit.blue: ColorInfo(
      name: "Xanh dương",
      color: Colors.blue,
      servo: "servo3",
      colorCode: "0xFF0000FF",
    ),
    ColorLimit.yellow: ColorInfo(
      name: "Vàng",
      color: Colors.yellow,
      servo: "servo2",
      colorCode: "0xFFFFFF00",
    ),
  };

// ======================= State Life Circle =========================
  @override
  void initState() {
    super.initState();
    _setupListeners();
    _initializeNotifications();
  }

  @override
  void dispose() {
    _disposeControllers();
    super.dispose();
  }


// ======================= Notification =========================
  // Initialize notifications
  Future<void> _initializeNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await _notificationsPlugin.initialize(
      initializationSettings,
    );
  }

  // Show notification when limits are reached in auto mode
  Future<void> _showLimitNotification(String colorName) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'limit_reached_channel',
      'Limit Reached Notifications',
      importance: Importance.max,
      priority: Priority.high,
    );

    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    await _notificationsPlugin.show(
      0,
      'Cảnh báo giới hạn màu',
      'Màu $colorName đã đạt giới hạn tối đa. Vui lòng kiểm tra hệ thống!',
      platformChannelSpecifics,
    );
  }

  // Set up listeners
  void _setupListeners() {
    _listenToAutoMode();
    _listenToStats();
    _listenToColorDetected();
    _listenToCurrentColors();
    _listenToLimitColors();
  }



// ======================= Listenning =========================
  void _listenToCurrentColors() {
    _firebaseService.listenToCurrent().listen((data) {
      setState(() {
        _currentStats = data;
        _updateLimitControllers();
      });
    });
  }

  void _listenToColorDetected() {
    _firebaseService.listenToColorDetected().listen((color) {
      setState(() {
        _colorDetected = color;
      });
    });
  }

  void _listenToAutoMode() {
    _firebaseService.listenToModeChanged().listen((isAutoMode) {
      setState(() {
        _isAutoMode = isAutoMode;
      });
    });
  }

  void _listenToStats() {
    _firebaseService.listenToStats().listen((newStats) {
      setState(() {
        _stats = newStats;
        _updateLimitControllers();
      });
    });
  }
 void _listenToLimitColors() {
     _firebaseService.listenToLimitStats().listen((newStats) {
      setState(() {
        _limitStats = newStats;
        _updateLimitControllers();
      });
    });
  }

// ======================= Limit Value Control =========================
  void _disposeControllers() {
    _limitControllers.forEach((key, controller) {
      controller.dispose();
    });
  }

  void _updateLimitControllers() {
    if(_isAutoMode){
      for (final colorKey in ["red", "blue", "yellow"]) {
        _limitControllers[colorKey]?.text = (_limitStats[colorKey] ?? 10).toString();
        // If count increased and reached the limit in auto mode
        if (_currentStats[colorKey] > _limitStats[colorKey]) {
          // Show notification
          final colorName = _getColorNameFromKey(colorKey);
          _showLimitNotification(colorName);
        }
      }
    }
  }


// ======================= Action Functions =========================

  // Reset color count in Firebase
  Future<void> _resetColorCount(String colorKey) async {
    await _firebaseService.resetCurrentColor(colorKey);
    _showSnackBar("Đã đặt lại giá trị màu ${_getColorNameFromKey(colorKey)}!");
  }
  // Interaction handling functions
  Future<void> _toggleAutoMode() async {
    setState(() {
      _isAutoMode = !_isAutoMode;
    });
    await _firebaseService.updateAutoMode(_isAutoMode);
  }

  Future<void> _updateColorLimit(ColorLimit color, int limit) async {
    if (limit > 0) {
      // Convert from enum to string to save to Firebase
      String colorKey = _firebaseService.colorLimitToString(color);
      
      await _firebaseService.updateColorLimit(color, limit);
      _showSnackBar("Giới hạn màu ${_colorInfo[color]?.name} đã được cập nhật thành $limit!");
      setState(() {
        _stats["limits"][colorKey] = limit;
      });
    } else {
      _showSnackBar("Giới hạn phải lớn hơn 0!");
    }
  }

  Future<void> _runServo(String servo) async {
    if (!_isAutoMode) {
      await _firebaseService.updateMotor(true);
      await _firebaseService.updateServo(servo, true);
      await Future.delayed(const Duration(seconds: 2));
      await _firebaseService.updateServo(servo, false);
      await _firebaseService.updateMotor(false);
    }
  }

  Future<void> _detectColor(ColorLimit colorLimit) async {
    String colorKey = _firebaseService.colorLimitToString(colorLimit);
    if (!_isValidColor(_colorDetected)) {
      _showSnackBar("Không thể phát hiện màu hợp lệ!");
      return;
    }

    if (!_colorIsAvailable(colorKey)) {
      _showSnackBar("Đã đạt giới hạn tối đa cho màu ${_colorInfo[colorLimit]?.name}! Hãy đặt lại giá trị trước khi tiếp tục.");
      return;
    }

    await _runServo(_colorInfo[colorLimit]!.servo);
    //Todo: Remove add color from application
    //await _addColor(colorKey);
  }

  Future<void> _resetStats() async {
    await _firebaseService.resetStats();
  }

  Future<void> _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => LoginScreen()),
    );
  }

// ======================= Extension Functions =========================
  // Validation and check functions
  bool _isValidColor(String color) {
    if(_colorDetected == "0x00000000") return false;
    try {
      int.parse(color);
      return true;
    } catch (e) {
      return false;
    }
  }

  bool _colorIsAvailable(String color) {
    int currentCount = _currentStats[color] ?? Config.defaultValue;
    int limit = _limitStats[color] ?? Config.defaultLimit;
    return currentCount < limit;
  }

  // Helper to get color name from string key
  String _getColorNameFromKey(String colorKey) {
    switch (colorKey) {
      case "red": return _colorInfo[ColorLimit.red]?.name ?? "Đỏ";
      case "blue": return _colorInfo[ColorLimit.blue]?.name ?? "Xanh dương";
      case "yellow": return _colorInfo[ColorLimit.yellow]?.name ?? "Vàng";
      default: return colorKey;
    }
  }

  // Helper to map string key to ColorLimit
  ColorLimit _getColorLimitFromKey(String colorKey) {
    switch (colorKey) {
      case "red": return ColorLimit.red;
      case "blue": return ColorLimit.blue;
      case "yellow": return ColorLimit.yellow;
      default: return ColorLimit.red; // Default to red as fallback
    }
  }

  // Display SnackBar
  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  void _onSaveColorLimit() {
    _updateColorLimit(ColorLimit.red, int.tryParse(_limitControllers["red"]!.text) ?? Config.defaultLimit);
    _updateColorLimit(ColorLimit.blue, int.tryParse(_limitControllers["blue"]!.text) ?? Config.defaultLimit);
    _updateColorLimit(ColorLimit.yellow, int.tryParse(_limitControllers["yellow"]!.text) ?? Config.defaultLimit);

    // TODO: emit event, call listener, notify parent, etc.
    print("Đã lưu giới hạn màu thành công!");
  }

  void _showLimitDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            "Cập nhật giới hạn màu sắc",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildLimitInput(ColorLimit.red, _limitControllers["red"]!, Colors.red, "Đỏ"),
              const SizedBox(height: 12),
              _buildLimitInput(ColorLimit.blue, _limitControllers["blue"]!, Colors.blue, "Xanh dương"),
              const SizedBox(height: 12),
              _buildLimitInput(ColorLimit.yellow, _limitControllers["yellow"]!, Colors.yellow, "Vàng"),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("Hủy"),
              style: TextButton.styleFrom(
                foregroundColor: Colors.grey[700],
              ),
            ),
            ElevatedButton(
              onPressed: () {
                _onSaveColorLimit();
                Navigator.of(context).pop();
              },
              child: const Text("Lưu"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
          actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        );
      },
    );
  }

  // Wiget to build limit input field 
  Widget _buildLimitInput(ColorLimit limit, TextEditingController controller, Color color, String label) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontSize: 14),
          ),
        ),
        SizedBox(
          width: 60,
          height: 36,
          child: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(vertical: 8),
              isDense: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Widget to build limit info in main widget
  Widget _buildLimitInfo(String colorKey) {
    final colorLimit = _getColorLimitFromKey(colorKey);
    final colorData = _colorInfo[colorLimit]!;
    final current = _currentStats[colorKey] ?? Config.defaultValue;
    final limit = _limitStats[colorKey] ?? Config.defaultLimit;
    final bool isAtLimit = current >= limit;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: colorData.color,
                  borderRadius: BorderRadius.circular(7),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                colorData.name,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                "$current/$limit",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isAtLimit ? FontWeight.bold : FontWeight.w500,
                  color: isAtLimit ? Colors.red : Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: limit > 0 ? current / limit : 0,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(
                isAtLimit ? Colors.red : colorData.color,
              ),
              minHeight: 6,
            ),
          ),
          if (isAtLimit && !_isAutoMode) ...[
            const SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: () => _resetColorCount(colorKey),
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text("Đặt lại"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade100,
                foregroundColor: Colors.red.shade700,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                minimumSize: const Size(100, 30),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 0,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // Widget to build mode indicator
  Widget _buildModeIndicator() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _isAutoMode 
            ? [Colors.green.shade400, Colors.green.shade600]
            : [Colors.orange.shade400, Colors.orange.shade600],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: _isAutoMode 
              ? Colors.green.withOpacity(0.3)
              : Colors.orange.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _isAutoMode ? Icons.auto_mode : Icons.pan_tool,
                color: Colors.white,
                size: 28,
              ),
              const SizedBox(width: 12),
              Text(
                "Chế độ: ${_isAutoMode ? 'Tự động' : 'Thủ công'}",
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (!_isAutoMode)
            _buildColorPreview(),
        ],
      ),
    );
  }

  // Widget to build color preview
  Widget _buildColorPreview() {
    try {
      if (_colorDetected.isEmpty) {
        return const _ColorDetectionStatus(
          isValid: false, 
          message: "Không phát hiện màu sắc"
        );
      }
      return _ColorDetectionStatus(
        isValid: _colorDetected != '0x00000000',
        color: Color(int.parse(_colorDetected)),
      );

    } catch (e) {
      return const _ColorDetectionStatus(
        isValid: false, 
        message: "Không phát hiện màu sắc hợp lệ"
      );
    }
  }

  Widget _buildColorButton(ColorLimit colorLimit) {
    final colorData = _colorInfo[colorLimit]!;
    final colorKey = _firebaseService.colorLimitToString(colorLimit);
    final bool isDarkColor = colorLimit == ColorLimit.red || colorLimit == ColorLimit.blue;
    final bool isAtLimit = (_currentStats[colorKey] ?? 0) >= (_limitStats[colorKey] ?? Config.defaultLimit);
    
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: isAtLimit 
                ? Colors.grey.withOpacity(0.4) 
                : colorData.color.withOpacity(0.4),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
        borderRadius: BorderRadius.circular(12),
      ),
      child: ElevatedButton(
        onPressed: isAtLimit ? null : () => _detectColor(colorLimit),
        style: ElevatedButton.styleFrom(
          backgroundColor: isAtLimit ? Colors.grey.shade400 : colorData.color,
          foregroundColor: isDarkColor ? Colors.white : Colors.black,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
          disabledBackgroundColor: Colors.grey.shade300,
          disabledForegroundColor: Colors.grey.shade700,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(isAtLimit ? Icons.block : Icons.colorize, size: 22),
            const SizedBox(width: 10),
            Text(
              isAtLimit 
                  ? "Giới hạn ${colorData.name}"
                  : "Phát hiện ${colorData.name}",
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  //Wiget to build limits panel in main widget
  Widget _buildLimitsSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.bar_chart, color: Colors.blue.shade700),
                  const SizedBox(width: 8),
                  const Text(
                    "Giới hạn màu sắc",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: _showLimitDialog,
                icon: const Icon(Icons.settings, size: 18),
                label: const Text("Cài đặt"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey.shade200,
                  foregroundColor: Colors.black87,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 3,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: ["red", "blue", "yellow"].map((colorKey) => _buildLimitInfo(colorKey)).toList(),
          ),
        ],
      ),
    );
  }


  // Widget to build action buttons in main widget
  Widget _buildActionButtons() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ElevatedButton.icon(
            onPressed: _toggleAutoMode,
            icon: Icon(_isAutoMode ? Icons.toggle_off : Icons.toggle_on),
            label: Text(
              _isAutoMode ? "Tắt chế độ tự động" : "Bật chế độ tự động",
              style: const TextStyle(fontSize: 16),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: _isAutoMode ? Colors.red : Colors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 2,
            ),
          ),
          const SizedBox(height: 16),
          
          if (!_isAutoMode) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade100),
              ),
              child: Text(
                "Chọn màu để thủ công phân loại:",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.blue.shade700,
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            ...colorButtonsSection,
            
            const SizedBox(height: 16),
          ],
          
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _resetStats,
                  icon: const Icon(Icons.refresh),
                  label: const Text("Đặt lại tất cả", style: TextStyle(fontSize: 15)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _logout(context),
                  icon: const Icon(Icons.logout),
                  label: const Text("Đăng xuất", style: TextStyle(fontSize: 15)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[800],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  // Create list of color buttons
  List<Widget> get colorButtonsSection {
    final List<Widget> buttons = [];
    for (final colorLimit in colorKeyMap.entries) {
      buttons.add(_buildColorButton(colorLimit.key));
      buttons.add(const SizedBox(height: 12));
    }
    
    // Remove last spacer
    if (buttons.isNotEmpty) {
      buttons.removeLast();
    }
    
    return buttons;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          "Hệ thống phân loại màu",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildModeIndicator(),
                const SizedBox(height: 20),
                
               // Display chart
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.pie_chart, color: Colors.purple.shade700, size: 22),
                        const SizedBox(width: 8),
                        const Text(
                          "Thống kê phân loại màu",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Thay thế PieChartCircle bằng biểu đồ mới
                    EnhancedStatsChart(
                      stats: _stats,
                      currentStats: _currentStats,
                      limitStats: _limitStats,
                      colorInfo: _colorInfo,
                    ),
                  ],
                ),
              ),
                const SizedBox(height: 20),
                
                _buildLimitsSection(),
                const SizedBox(height: 20),
                
                _buildActionButtons(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}


//======================== Class =========================
// Widget to display color detection status
class _ColorDetectionStatus extends StatelessWidget {
  final bool isValid;
  final Color? color;
  final String? message;

  const _ColorDetectionStatus({
    required this.isValid,
    this.color,
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isValid ? Colors.green.withOpacity(0.5) : Colors.red.withOpacity(0.5),
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isValid ? Icons.check_circle : Icons.error,
            color: isValid ? Colors.green : Colors.red,
            size: 22,
          ),
          const SizedBox(width: 12),
          if (isValid && color != null) ...[
            const Text(
              "Màu hiện tại: ",
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.black87,
                fontSize: 16,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],  
              ),
            ),
          ] else if (message != null) ...[
            Text(
              message!,
              style: const TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.w500,
              ),
            ),
          ] else ...[
            const Text(
              "Lỗi không xác định",
              style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// Lớp lưu trữ thông tin màu
class ColorInfo {
  final String name;
  final Color color;
  final String servo;
  final String colorCode;

  ColorInfo({
    required this.name,
    required this.color,
    required this.servo,
    required this.colorCode,
  });
}
//========================================================