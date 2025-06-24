import 'dart:io';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:intl/intl.dart';
import 'models.dart';

class HistoryDetailPage extends StatelessWidget {
  final HistoryItem item;

  const HistoryDetailPage({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final statusColor = item.status == DiagnosticStatus.healthy ? Colors.green : Colors.red;
    final recommendation = item.status == DiagnosticStatus.healthy
        ? "diagnostic_recommendation_healthy".tr()
        : "diagnostic_recommendation_disease".tr();

    return Scaffold(
      appBar: AppBar(
        title: Text("history_detail_title".tr()),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 1,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (item.imagePath != null && File(item.imagePath!).existsSync())
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(File(item.imagePath!), fit: BoxFit.cover),
              )
            else
              Container(
                height: 180,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.image_not_supported, size: 64, color: Colors.grey),
              ),
            const SizedBox(height: 16),
            Text(item.plantName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text("${"diagnostic_confidence_label".tr()} : ${(item.confidence * 100).toStringAsFixed(1)}%"),
            const SizedBox(height: 4),
            Text("${"diagnostic_date_label".tr()} : ${DateFormat.yMMMMd().add_Hm().format(item.date)}"),
            const SizedBox(height: 4),
            Text(
              "${"diagnostic_status_label".tr()} : ${item.status == DiagnosticStatus.healthy ? "diagnostic_status_healthy".tr() : "diagnostic_status_disease".tr()}",
              style: TextStyle(color: statusColor, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 20),
            Text("diagnostic_recommendation_title".tr(), style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text(recommendation, style: const TextStyle(fontSize: 15)),
          ],
        ),
      ),
    );
  }
}
