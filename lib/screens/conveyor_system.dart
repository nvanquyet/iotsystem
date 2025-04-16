import 'package:convenyor_system/screens/login_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:convenyor_system/services/firebase_service.dart';
import 'package:convenyor_system/Widgets/PieChartCircle.dart';

class ConveyorSystem extends StatefulWidget {
  const ConveyorSystem({Key? key}) : super(key: key);

  @override
  _ConveyorSystemState createState() => _ConveyorSystemState();
}

class _ConveyorSystemState extends State<ConveyorSystem> {
  final FirebaseService _firebaseService = FirebaseService();
  
  // Cấu trúc dữ liệu
  bool _isAutoMode = false;
  String _colorDetected = "0xFF000000";
  Map<String, dynamic> _stats = {
    "red": 0, 
    "blue": 0, 
    "yellow": 0, 
    "green": 0, 
    "total": 0,
    "limits": {"red": 10, "blue": 10, "yellow": 10, "green": 10}
  };
  
  // Controllers cho input giới hạn
  final TextEditingController _redLimitController = TextEditingController(text: "10");
  final TextEditingController _blueLimitController = TextEditingController(text: "10");
  final TextEditingController _yellowLimitController = TextEditingController(text: "10");
  final TextEditingController _greenLimitController = TextEditingController(text: "10");

  // Định nghĩa thông tin màu sắc để dễ sử dụng
  final Map<String, ColorInfo> _colorInfo = {
    "red": ColorInfo(
      name: "Đỏ",
      color: Colors.red,
      servo: "servo1",
      colorCode: "0xFFFF0000",
    ),
    "blue": ColorInfo(
      name: "Xanh dương",
      color: Colors.blue,
      servo: "servo3",
      colorCode: "0xFF0000FF",
    ),
    "yellow": ColorInfo(
      name: "Vàng",
      color: Colors.yellow,
      servo: "servo2",
      colorCode: "0xFFFFFF00",
    ),
    "green": ColorInfo(
      name: "Xanh lá",
      color: Colors.green,
      servo: "servo4",
      colorCode: "0xFF00FF00",
    ),
  };

  @override
  void initState() {
    super.initState();
    _setupListeners();
  }

  @override
  void dispose() {
    _disposeControllers();
    super.dispose();
  }

  // Thiết lập các listeners
  void _setupListeners() {
    _listenToAutoMode();
    _listenToStats();
    _listenToColorDetected();
  }

  // Giải phóng controllers
  void _disposeControllers() {
    _redLimitController.dispose();
    _blueLimitController.dispose();
    _yellowLimitController.dispose();
    _greenLimitController.dispose();
  }

  // Các hàm listener
  void _listenToStats() {
    _firebaseService.listenToStats().listen((newStats) {
      setState(() {
        _stats = newStats;
        _updateLimitControllers();
      });
    });
  }

  void _updateLimitControllers() {
    _redLimitController.text = (_stats["limits"]?["red"] ?? 10).toString();
    _blueLimitController.text = (_stats["limits"]?["blue"] ?? 10).toString();
    _yellowLimitController.text = (_stats["limits"]?["yellow"] ?? 10).toString();
    _greenLimitController.text = (_stats["limits"]?["green"] ?? 10).toString();
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

  // Các hàm xác thực và kiểm tra
  bool _isValidColor(String color) {
    try {
      int.parse(color);
      return true;
    } catch (e) {
      return false;
    }
  }

  bool _checkColorLimit(String color) {
    int currentCount = _stats[color] ?? 0;
    int limit = _stats["limits"]?[color] ?? 10;
    return currentCount < limit;
  }

  // Các hàm xử lý tương tác
  Future<void> _toggleAutoMode() async {
    setState(() {
      _isAutoMode = !_isAutoMode;
    });
    await _firebaseService.updateAutoMode(_isAutoMode);
  }

  Future<void> _updateColorLimit(String color, int limit) async {
    if (limit > 0) {
      //await _firebaseService.updateColorLimit(color, limit);
      _showSnackBar("Giới hạn màu ${_colorInfo[color]?.name} đã được cập nhật thành $limit!");
      setState(() {
        _stats["limits"][color] = limit;
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
      await Future.delayed(const Duration(seconds: 1));
      await _firebaseService.updateMotor(false);
    }
  }

  Future<void> _addColor(String color) async {
    if (_checkColorLimit(color)) {
      await _firebaseService.updateStats(color);
    } else {
      _showSnackBar("Đã đạt giới hạn tối đa cho màu ${_colorInfo[color]?.name}!");
    }
  }

  Future<void> _detectColor(String colorKey) async {
    if (!_isValidColor(_colorDetected)) {
      _showSnackBar("Không thể phát hiện màu hợp lệ!");
      return;
    }

    if (!_checkColorLimit(colorKey)) {
      _showSnackBar("Đã đạt giới hạn tối đa cho màu ${_colorInfo[colorKey]?.name}!");
      return;
    }

    await _runServo(_colorInfo[colorKey]!.servo);
    await _addColor(colorKey);
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

  // Hiển thị SnackBar
  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  // Hiển thị dialog cập nhật giới hạn
  void _showLimitDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Cập nhật giới hạn màu sắc"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildLimitInput("Đỏ", _redLimitController, Colors.red),
                const SizedBox(height: 12),
                _buildLimitInput("Xanh dương", _blueLimitController, Colors.blue),
                const SizedBox(height: 12),
                _buildLimitInput("Vàng", _yellowLimitController, Colors.yellow),
                const SizedBox(height: 12),
                _buildLimitInput("Xanh lá", _greenLimitController, Colors.green),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("Hủy"),
            ),
            ElevatedButton(
              onPressed: () {
                _updateColorLimit("red", int.tryParse(_redLimitController.text) ?? 10);
                _updateColorLimit("blue", int.tryParse(_blueLimitController.text) ?? 10);
                _updateColorLimit("yellow", int.tryParse(_yellowLimitController.text) ?? 10);
                _updateColorLimit("green", int.tryParse(_greenLimitController.text) ?? 10);
                Navigator.of(context).pop();
              },
              child: const Text("Lưu"),
            ),
          ],
        );
      },
    );
  }

  // Chuyển đổi thống kê thành danh sách ColorStats
  List<ColorStats> _getColorStats() {
    final total = (_stats["total"] ?? 0) > 0 ? _stats["total"] : 1;
    
    Map<String, double> percentages = {};
    double totalPercentage = 0;
    
    // Tính toán phần trăm cho mỗi màu
    for (final colorKey in _colorInfo.keys) {
      final percentage = (_stats[colorKey] ?? 0) * 100.0 / total;
      percentages[colorKey] = percentage;
      totalPercentage += percentage;
    }
    
    // Nếu không có dữ liệu
    if (totalPercentage == 0) {
      final defaultValue = 100.0 / _colorInfo.length;
      return _colorInfo.entries.map((entry) => 
        ColorStats(entry.value.colorCode, _stats[entry.key] ?? 0, defaultValue)
      ).toList();
    }
    
    // Điều chỉnh tỷ lệ để tổng đúng 100%
    if (totalPercentage != 100.0) {
      final factor = 100.0 / totalPercentage;
      for (final colorKey in percentages.keys) {
        percentages[colorKey] = percentages[colorKey]! * factor;
      }
    }
    
    // Chuyển đổi thành danh sách ColorStats
    return _colorInfo.entries.map((entry) {
      final colorKey = entry.key;
      final colorData = entry.value;
      final adjustedPercentage = double.parse(percentages[colorKey]!.toStringAsFixed(2));
      return ColorStats(colorData.colorCode, _stats[colorKey] ?? 0, adjustedPercentage);
    }).toList();
  }

  // UI builders
  Widget _buildLimitInput(String label, TextEditingController controller, Color color) {
    return Row(
      children: [
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          "$label:",
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              hintText: "Giới hạn",
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLimitInfo(String colorKey) {
    final colorData = _colorInfo[colorKey]!;
    final current = _stats[colorKey] ?? 0;
    final limit = _stats["limits"]?[colorKey] ?? 10;
    final bool isAtLimit = current >= limit;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: colorData.color,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 4),
              Text(
                colorData.name,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
              ),
            ],
          ),
          const SizedBox(height: 4),
          // Progress indicator
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: limit > 0 ? current / limit : 0,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(
                isAtLimit ? Colors.red : colorData.color,
              ),
              minHeight: 4,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "$current/$limit",
            style: TextStyle(
              fontSize: 11,
              fontWeight: isAtLimit ? FontWeight.bold : FontWeight.normal,
              color: isAtLimit ? Colors.red : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.white,
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
              Icon(
                _isAutoMode ? Icons.auto_mode : Icons.pan_tool,
                color: _isAutoMode ? Colors.green : Colors.orange,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                "Chế độ: ${_isAutoMode ? 'Tự động' : 'Thủ công'}",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: _isAutoMode ? Colors.green : Colors.orange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (!_isAutoMode)
            _buildColorPreview(),
        ],
      ),
    );
  }

  Widget _buildColorPreview() {
    try {
      if (_colorDetected.isEmpty) {
        return const _ColorDetectionStatus(
          isValid: false, 
          message: "Không phát hiện màu sắc"
        );
      }
      
      final color = Color(int.parse(_colorDetected));
      return _ColorDetectionStatus(
        isValid: true,
        color: color,
      );
    } catch (e) {
      return const _ColorDetectionStatus(
        isValid: false, 
        message: "Không phát hiện màu sắc hợp lệ"
      );
    }
  }

  Widget _buildColorButton(String colorKey) {
    final colorData = _colorInfo[colorKey]!;
    return ElevatedButton(
      onPressed: () => _detectColor(colorKey),
      style: ElevatedButton.styleFrom(
        backgroundColor: colorData.color,
        foregroundColor: 
          colorKey == "yellow" ? Colors.black : Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        elevation: 3,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.colorize, size: 20),
          const SizedBox(width: 8),
          Text(
            "Phát hiện ${colorData.name}",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildLimitsSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
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
              const Text(
                "Giới hạn màu sắc",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.settings_outlined, size: 20),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: _showLimitDialog,
                tooltip: "Cài đặt giới hạn",
              ),
            ],
          ),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: _colorInfo.keys.map((colorKey) => _buildLimitInfo(colorKey)).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
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
            label: Text(_isAutoMode ? "Tắt chế độ tự động" : "Bật chế độ tự động"),
            style: ElevatedButton.styleFrom(
              backgroundColor: _isAutoMode ? Colors.red : Colors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          if (!_isAutoMode) ...[
            Text(
              "Chọn màu để phát hiện:",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 12),
            
            ...colorButtonsSection,
            
            const SizedBox(height: 16),
          ],
          
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _resetStats,
                  icon: const Icon(Icons.refresh),
                  label: const Text("Đặt lại thống kê"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _logout(context),
                  icon: const Icon(Icons.logout),
                  label: const Text("Đăng xuất"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[800],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  // Tạo danh sách các nút màu sắc
  List<Widget> get colorButtonsSection {
    final List<Widget> buttons = [];
    
    for (final colorKey in _colorInfo.keys) {
      buttons.add(_buildColorButton(colorKey));
      buttons.add(const SizedBox(height: 12));
    }
    
    // Xóa spacer cuối cùng
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
                
                // Hiển thị biểu đồ
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
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
                      const Text(
                        "Thống kê phân loại màu",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      PieChartCircle(
                        colorStats: _getColorStats(),
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

// Widget hiển thị trạng thái phát hiện màu
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
        color: isValid ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isValid ? Colors.green.withOpacity(0.3) : Colors.red.withOpacity(0.3),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isValid ? Icons.check_circle_outline : Icons.error_outline,
            color: isValid ? Colors.green : Colors.red,
            size: 20,
          ),
          const SizedBox(width: 12),
          if (isValid && color != null) ...[
            const Text(
              "Màu hiện tại: ",
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(width: 4),
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.withOpacity(0.5)),
              ),
            ),
          ] else ...[
            Text(
              message ?? "Lỗi không xác định",
              style: const TextStyle(
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