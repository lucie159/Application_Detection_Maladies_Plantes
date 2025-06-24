enum DiagnosticStatus { healthy, disease }

class HistoryItem {
  final String id;
  final String plantName;
  final DateTime date;
  final double confidence;
  final DiagnosticStatus status;
  final String? imagePath;

  HistoryItem({
    required this.id,
    required this.plantName,
    required this.date,
    required this.confidence,
    required this.status,
    this.imagePath,
  });

  factory HistoryItem.fromMap(Map<String, dynamic> map) {
    return HistoryItem(
      id: map['id'],
      plantName: map['plantName'],
      date: DateTime.parse(map['date']),
      confidence: map['confidence'] is int
          ? (map['confidence'] as int).toDouble()
          : double.tryParse(map['confidence'].toString()) ?? 0.0,
      status: map['status'] == 'healthy'
          ? DiagnosticStatus.healthy
          : DiagnosticStatus.disease,
      imagePath: map['imagePath'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'plantName': plantName,
      'date': date.toIso8601String(),
      'confidence': confidence,
      'status': status == DiagnosticStatus.healthy ? 'healthy' : 'disease',
      'imagePath': imagePath,
    };
  }

  static DiagnosticStatus getStatusFromDiagnosis(String diagnosis) {
    if (diagnosis.toLowerCase().contains('healthy') ||
        diagnosis.toLowerCase().contains('sain')) {
      return DiagnosticStatus.healthy;
    } else {
      return DiagnosticStatus.disease;
    }
  }

  String getStatusText() {
    switch (status) {
      case DiagnosticStatus.healthy:
        return 'Sain';
      case DiagnosticStatus.disease:
        return 'Malade';
    }
  }
}
