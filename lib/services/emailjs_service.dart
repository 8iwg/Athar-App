import 'dart:math';
import 'package:emailjs/emailjs.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// خدمة EmailJS لإرسال إيميلات التحقق المخصصة
class EmailJsService {
  // معلومات EmailJS من dashboard.emailjs.com
  static const String serviceId = 'service_0amf8bb';
  static const String templateId = 'idi88fq';
  static const String publicKey = 'lQCfSxIR0DcnBoEKn';
  
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// توليد رمز تحقق مكون من 6 أرقام
  String _generateVerificationCode() {
    final random = Random();
    return (100000 + random.nextInt(900000)).toString();
  }

  /// إرسال رمز التحقق عبر EmailJS
  Future<String> sendVerificationEmail({
    required String toEmail,
    required String userName,
  }) async {
    try {
      final verificationCode = _generateVerificationCode();
      
      // حفظ رمز التحقق في Firestore مع تاريخ انتهاء (10 دقائق)
      await _firestore.collection('verification_codes').doc(toEmail).set({
        'code': verificationCode,
        'createdAt': FieldValue.serverTimestamp(),
        'expiresAt': DateTime.now().add(const Duration(minutes: 10)).toIso8601String(),
        'used': false,
      });

      // إرسال الإيميل عبر EmailJS
      final templateParams = {
        'to_email': toEmail,
        'to_name': userName,
        'verification_code': verificationCode,
        'app_name': 'أثر',
      };

      await send(
        serviceId,
        templateId,
        templateParams,
        const Options(
          publicKey: publicKey,
        ),
      );

      return verificationCode;
    } catch (e) {
      throw Exception('فشل إرسال رمز التحقق: $e');
    }
  }

  /// التحقق من رمز التحقق
  Future<bool> verifyCode({
    required String email,
    required String code,
  }) async {
    try {
      final doc = await _firestore
          .collection('verification_codes')
          .doc(email)
          .get();

      if (!doc.exists) {
        return false;
      }

      final data = doc.data()!;
      final savedCode = data['code'] as String;
      final expiresAt = DateTime.parse(data['expiresAt'] as String);
      final used = data['used'] as bool;

      // التحقق من عدم استخدام الرمز مسبقاً
      if (used) {
        return false;
      }

      // التحقق من عدم انتهاء صلاحية الرمز
      if (DateTime.now().isAfter(expiresAt)) {
        return false;
      }

      // التحقق من تطابق الرمز
      if (savedCode != code) {
        return false;
      }

      // وضع علامة على الرمز كمستخدم
      await _firestore.collection('verification_codes').doc(email).update({
        'used': true,
      });

      return true;
    } catch (e) {
      return false;
    }
  }

  /// حذف رمز التحقق بعد النجاح
  Future<void> deleteVerificationCode(String email) async {
    try {
      await _firestore.collection('verification_codes').doc(email).delete();
    } catch (e) {
      // تجاهل الأخطاء في الحذف
    }
  }

  /// إرسال إيميل إعادة تعيين كلمة المرور
  Future<void> sendPasswordResetEmail({
    required String toEmail,
    required String userName,
    required String resetLink,
  }) async {
    try {
      final templateParams = {
        'to_email': toEmail,
        'to_name': userName,
        'reset_link': resetLink,
        'app_name': 'أثر',
      };

      await send(
        serviceId,
        'YOUR_PASSWORD_RESET_TEMPLATE_ID', // قالب منفصل لإعادة تعيين كلمة المرور
        templateParams,
        const Options(
          publicKey: publicKey,
        ),
      );
    } catch (e) {
      throw Exception('فشل إرسال رابط إعادة التعيين: $e');
    }
  }
}
