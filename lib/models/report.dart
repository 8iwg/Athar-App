import 'package:cloud_firestore/cloud_firestore.dart';

class Report {
  final String id;
  final String spotId;
  final String spotName;
  final String reporterId;
  final String reporterName;
  final String reason;
  final DateTime createdAt;
  final String? additionalInfo;

  Report({
    required this.id,
    required this.spotId,
    required this.spotName,
    required this.reporterId,
    required this.reporterName,
    required this.reason,
    required this.createdAt,
    this.additionalInfo,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'spotId': spotId,
      'spotName': spotName,
      'reporterId': reporterId,
      'reporterName': reporterName,
      'reason': reason,
      'createdAt': createdAt.toIso8601String(),
      'additionalInfo': additionalInfo,
    };
  }

  factory Report.fromJson(Map<String, dynamic> json) {
    DateTime parseCreatedAt() {
      final createdAt = json['createdAt'];
      if (createdAt == null) return DateTime.now();
      
      // إذا كان Timestamp من Firestore
      if (createdAt is Timestamp) {
        return createdAt.toDate();
      }
      
      // إذا كان String
      if (createdAt is String) {
        return DateTime.parse(createdAt);
      }
      
      return DateTime.now();
    }
    
    return Report(
      id: json['id'] ?? '',
      spotId: json['spotId'] ?? '',
      spotName: json['spotName'] ?? '',
      reporterId: json['reporterId'] ?? '',
      reporterName: json['reporterName'] ?? '',
      reason: json['reason'] ?? '',
      createdAt: parseCreatedAt(),
      additionalInfo: json['additionalInfo'],
    );
  }
}
