import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:plant_guard/pages/database_helper.dart';
import 'models.dart';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  List<HistoryItem> _historyItems = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    loadHistoryFromDatabase();
  }

  Future<void> loadHistoryFromDatabase() async {
    setState(() => _isLoading = true);
    try {
      final items = await DatabaseHelper.instance.getAllHistory();
      setState(() {
        _historyItems = items;
        _isLoading = false;
      });
      _animationController.forward();
    } catch (e) {
      debugPrint("Erreur de chargement historique : $e");
      setState(() => _isLoading = false);
    }
  }

  Future<void> clearHistory() async {
    await DatabaseHelper.instance.clearHistory();
    setState(() => _historyItems = []);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text("history_title".tr(), style: const TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        actions: [
          if (_historyItems.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_forever),
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: Text("history_clear_confirm_title".tr()),
                    content: Text("history_clear_confirm_body".tr()),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(context, false), child: Text("cancel".tr())),
                      ElevatedButton(onPressed: () => Navigator.pop(context, true), child: Text("confirm".tr())),
                    ],
                  ),
                );
                if (confirm == true) await clearHistory();
              },
            )
        ],
        systemOverlayStyle: SystemUiOverlayStyle.dark,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.green[600]!)))
          : _historyItems.isEmpty
          ? Center(child: Text("history_empty".tr(), style: TextStyle(fontSize: 16, color: Colors.grey[600])))
          : FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _historyItems.length,
            itemBuilder: (context, index) {
              final item = _historyItems[index];
              return _buildHistoryCard(item);
            },
          ),
        ),
      ),
    );
  }

  Widget _buildHistoryCard(HistoryItem item) {
    final color = item.status == DiagnosticStatus.healthy ? Colors.green : Colors.red;
    return GestureDetector(
      onTap: () => _showHistoryDetailDialog(item),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 2))],
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.all(16),
          leading: item.imagePath != null && File(item.imagePath!).existsSync()
              ? ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.file(File(item.imagePath!), width: 60, height: 60, fit: BoxFit.cover),
          )
              : const Icon(Icons.image_not_supported, size: 48, color: Colors.grey),
          title: Text(item.plantName, style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Text(DateFormat.yMMMMd().add_Hm().format(item.date), style: const TextStyle(fontSize: 12)),
              const SizedBox(height: 4),
              Text("${"diagnostic_confidence_label".tr()} : ${(item.confidence * 100).toStringAsFixed(1)}%",
                  style: const TextStyle(fontSize: 12)),
            ],
          ),
          trailing: Icon(
            item.status == DiagnosticStatus.healthy ? Icons.check_circle : Icons.warning,
            color: color,
            size: 28,
          ),
        ),
      ),
    );
  }

  void _showHistoryDetailDialog(HistoryItem item) {
    final statusColor = item.status == DiagnosticStatus.healthy ? Colors.green : Colors.red;
    final recommendation = item.status == DiagnosticStatus.healthy
        ? "diagnostic_recommendation_healthy".tr()
        : "diagnostic_recommendation_disease".tr();

    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (item.imagePath != null && File(item.imagePath!).existsSync())
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(File(item.imagePath!), fit: BoxFit.cover),
                ),
              const SizedBox(height: 16),
              Text(item.plantName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text("${"diagnostic_confidence_label".tr()} : ${(item.confidence * 100).toStringAsFixed(1)}%"),
              const SizedBox(height: 4),
              Text("${"diagnostic_date_label".tr()} : ${DateFormat.yMMMMd().add_Hm().format(item.date)}"),
              const SizedBox(height: 4),
              Text("${"diagnostic_status_label".tr()} : ${item.status == DiagnosticStatus.healthy ? "diagnostic_status_healthy".tr() : "diagnostic_status_disease".tr()}",
                  style: TextStyle(color: statusColor, fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              Text("${"diagnostic_recommendation_title".tr()}:", style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(recommendation),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: Text("close".tr()),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
