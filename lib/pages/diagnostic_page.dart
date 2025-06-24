import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;
import 'package:plant_guard/pages/database_helper.dart';
import 'package:easy_localization/easy_localization.dart';
import 'models.dart';

class DiagnosticPage extends StatefulWidget {
  final File imageFile;

  const DiagnosticPage({Key? key, required this.imageFile}) : super(key: key);

  @override
  _DiagnosticPageState createState() => _DiagnosticPageState();
}

class _DiagnosticPageState extends State<DiagnosticPage> with TickerProviderStateMixin {
  late Interpreter _interpreter;
  List<String> _labels = [];
  String _predictedClass = '';
  double _confidence = 0.0;
  String _statusMessage = "diagnostic_loading".tr();
  bool _isLoading = true;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    loadModelAndRunInference();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> loadModelAndRunInference() async {
    try {
      final rawLabels = await rootBundle.loadString('assets/models/labels.txt');
      _labels = rawLabels.split('\n').where((e) => e.trim().isNotEmpty).toList();

      _interpreter = await Interpreter.fromAsset('assets/models/tomato_disease_model.tflite');

      final input = await preprocessImage(widget.imageFile);
      final output = List.filled(_labels.length, 0.0).reshape([1, _labels.length]);

      try {
        _interpreter.run(input.reshape([1, 150, 150, 3]), output);
      } catch (e) {
        debugPrint("❌ Erreur pendant TFLite run: $e");
        setState(() {
          _statusMessage = "diagnostic_status_error".tr();
          _isLoading = false;
        });
        return;
      }

      final scores = output[0];
      final maxIndex = scores.indexWhere((v) => v == scores.reduce((double a, double b) => a > b ? a : b));
      final confidence = scores[maxIndex];

      setState(() {
        _predictedClass = _labels[maxIndex].trim();
        _confidence = confidence;
        _statusMessage = _getStatusMessage(_predictedClass);
        _isLoading = false;
      });

      await saveToSQLite(_predictedClass, confidence);
      _animationController.forward();
    } catch (e) {
      setState(() {
        _statusMessage = "diagnostic_status_error".tr();
        _isLoading = false;
      });
    }
  }

  Future<void> saveToSQLite(String diagnosis, double confidence) async {
    final historyItem = HistoryItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      plantName: diagnosis,
      date: DateTime.now(),
      confidence: confidence,
      status: HistoryItem.getStatusFromDiagnosis(diagnosis),
      imagePath: widget.imageFile.path,
    );

    await DatabaseHelper.instance.insertHistory(historyItem);
    debugPrint("✅ Diagnostic enregistré dans SQLite");
  }

  String _getStatusMessage(String predictedClass) {
    if (predictedClass.toLowerCase().contains('healthy') || predictedClass.toLowerCase().contains('sain')) {
      return "diagnostic_status_healthy".tr();
    } else {
      return "diagnostic_status_disease".tr();
    }
  }

  String _getRecommendations() {
    if (_statusMessage == "diagnostic_status_healthy".tr()) {
      return "diagnostic_recommendation_healthy".tr();
    } else if (_statusMessage == "diagnostic_status_disease".tr()) {
      return "diagnostic_recommendation_disease".tr();
    } else {
      return "diagnostic_recommendation_loading".tr();
    }
  }

  Color _getStatusColor() {
    if (_statusMessage == "diagnostic_status_healthy".tr()) {
      return Colors.green;
    } else if (_statusMessage == "diagnostic_status_disease".tr()) {
      return Colors.red;
    } else if (_statusMessage == "diagnostic_status_error".tr()) {
      return Colors.orange;
    }
    return Colors.blue;
  }

  IconData _getStatusIcon() {
    if (_statusMessage == "diagnostic_status_healthy".tr()) {
      return Icons.check_circle;
    } else if (_statusMessage == "diagnostic_status_disease".tr()) {
      return Icons.warning;
    } else if (_statusMessage == "diagnostic_status_error".tr()) {
      return Icons.error;
    }
    return Icons.hourglass_empty;
  }

  Future<Float32List> preprocessImage(File imageFile) async {
    final bytes = await imageFile.readAsBytes();
    final image = img.decodeImage(bytes)!;
    final resized = img.copyResize(image, width: 150, height: 150);
    final pixels = resized.getBytes(order: img.ChannelOrder.rgb);
    final input = Float32List(pixels.length);
    for (int i = 0; i < pixels.length; i++) {
      input[i] = pixels[i] / 255.0;
    }
    return input;
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
        Flexible(
          child: Text(value, textAlign: TextAlign.end, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }

  Widget _buildImageSection() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 5))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Image.file(widget.imageFile, height: 280, width: double.infinity, fit: BoxFit.cover),
      ),
    );
  }

  Widget _buildStatusCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _getStatusColor().withOpacity(0.1),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: _getStatusColor().withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: _getStatusColor(), shape: BoxShape.circle),
                child: Icon(_getStatusIcon(), color: Colors.white, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("diagnostic_result_title".tr(), style: TextStyle(fontSize: 14, color: Colors.grey[600], fontWeight: FontWeight.w500)),
                    const SizedBox(height: 4),
                    Text(_statusMessage, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _getStatusColor())),
                    const SizedBox(height: 8),
                    _buildDetailRow("diagnostic_class_label".tr(), _predictedClass),
                    const SizedBox(height: 4),
                    _buildDetailRow("diagnostic_confidence_label".tr(), "${(_confidence * 100).toStringAsFixed(1)}%"),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendationsCard() {
    if (_predictedClass.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [Colors.blue[50]!, Colors.blue[100]!], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb_outline, color: Colors.blue[700], size: 24),
              const SizedBox(width: 8),
              Text("diagnostic_recommendation_title".tr(), style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue[700])),
            ],
          ),
          const SizedBox(height: 12),
          Text(_getRecommendations(), style: TextStyle(fontSize: 14, color: Colors.blue[800], height: 1.4)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text("diagnostic_title".tr(), style: const TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
      ),
      body: _isLoading
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.green[600]!), strokeWidth: 3),
            const SizedBox(height: 20),
            Text("diagnostic_loading".tr(), style: TextStyle(fontSize: 16, color: Colors.grey[600])),
          ],
        ),
      )
          : FadeTransition(
        opacity: _fadeAnimation,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildImageSection(),
              const SizedBox(height: 24),
              _buildStatusCard(),
              const SizedBox(height: 20),
              _buildRecommendationsCard(),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back),
                label: Text("diagnostic_back_button".tr()),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[600],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
