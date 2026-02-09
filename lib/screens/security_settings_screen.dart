import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:otp/otp.dart';
import '../core/theme/app_colors.dart';
import '../providers/auth_provider.dart';

class SecuritySettingsScreen extends StatefulWidget {
  const SecuritySettingsScreen({super.key});

  @override
  State<SecuritySettingsScreen> createState() => _SecuritySettingsScreenState();
}

class _SecuritySettingsScreenState extends State<SecuritySettingsScreen> {
  bool _is2FAEnabled = false;
  bool _isLoading = true;
  String? _secretKey;

  @override
  void initState() {
    super.initState();
    _loadSecuritySettings();
  }

  Future<void> _loadSecuritySettings() async {
    try {
      final authProvider = context.read<AuthProvider>();
      final user = authProvider.currentUser;
      
      if (user != null) {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.id)
            .get();
        
        if (doc.exists) {
          setState(() {
            _is2FAEnabled = doc.data()?['twoFactorEnabled'] ?? false;
            _secretKey = doc.data()?['totpSecret'];
            _isLoading = false;
          });
        }
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  String _generateSecretKey() {
    final random = Random.secure();
    return List.generate(6, (index) => random.nextInt(10).toString()).join();
  }

  String _generateOtpAuthUrl(String secret, String userEmail) {
    return 'otpauth://totp/أثر:$userEmail?secret=$secret&issuer=أثر';
  }

  Future<void> _enable2FA() async {
    final authProvider = context.read<AuthProvider>();
    final user = authProvider.currentUser;
    
    if (user == null) return;

    // توليد مفتاح سري جديد
    final secret = _generateSecretKey();
    final otpAuthUrl = _generateOtpAuthUrl(secret, user.email);

    if (!mounted) return;

    // عرض QR Code والمفتاح السري
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _Setup2FADialog(
        secret: secret,
        otpAuthUrl: otpAuthUrl,
        userEmail: user.email,
        onVerified: () async {
          // حفظ المفتاح في Firestore
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.id)
              .update({
            'twoFactorEnabled': true,
            'totpSecret': secret,
          });

          setState(() {
            _is2FAEnabled = true;
            _secretKey = secret;
          });

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('✅ تم تفعيل المصادقة الثنائية بنجاح'),
                backgroundColor: AppColors.success,
              ),
            );
          }
        },
      ),
    );
  }

  Future<void> _disable2FA() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'تعطيل المصادقة الثنائية',
          style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
        ),
        content: const Text('هل أنت متأكد من تعطيل المصادقة الثنائية؟ سيقلل هذا من أمان حسابك.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('تعطيل'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final authProvider = context.read<AuthProvider>();
      final user = authProvider.currentUser;

      if (user != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.id)
            .update({
          'twoFactorEnabled': false,
          'totpSecret': FieldValue.delete(),
        });

        setState(() {
          _is2FAEnabled = false;
          _secretKey = null;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('تم تعطيل المصادقة الثنائية'),
              backgroundColor: AppColors.info,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'الأمان والمصادقة الثنائية',
          style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.surface,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 24),

                  // نصائح الأمان
                  Text(
                    'نصائح للحفاظ على أمان حسابك',
                    style: GoogleFonts.cairo(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildSecurityTip(
                    Icons.phonelink_lock,
                    'استخدم تطبيق مصادقة موثوق',
                    'Google Authenticator أو Authy أو Microsoft Authenticator',
                  ),
                  _buildSecurityTip(
                    Icons.backup,
                    'احتفظ بنسخة احتياطية من المفتاح السري',
                    'في مكان آمن للحالات الطارئة',
                  ),
                  _buildSecurityTip(
                    Icons.no_encryption,
                    'لا تشارك المفتاح السري',
                    'مع أي شخص أو على أي منصة',
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildSecurityTip(IconData icon, String title, String subtitle) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(icon, color: AppColors.primary),
        title: Text(
          title,
          style: GoogleFonts.cairo(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(subtitle),
      ),
    );
  }
}

class _Setup2FADialog extends StatefulWidget {
  final String secret;
  final String otpAuthUrl;
  final String userEmail;
  final VoidCallback onVerified;

  const _Setup2FADialog({
    required this.secret,
    required this.otpAuthUrl,
    required this.userEmail,
    required this.onVerified,
  });

  @override
  State<_Setup2FADialog> createState() => _Setup2FADialogState();
}

class _Setup2FADialogState extends State<_Setup2FADialog> {
  final _codeController = TextEditingController();
  bool _isVerifying = false;
  String? _errorMessage;
  int _step = 1;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  String _getCurrentOTP() {
    return OTP.generateTOTPCodeString(
      widget.secret,
      DateTime.now().millisecondsSinceEpoch,
      algorithm: Algorithm.SHA1,
      isGoogle: true,
    );
  }

  Future<void> _verifyCode() async {
    setState(() {
      _isVerifying = true;
      _errorMessage = null;
    });

    try {
      final enteredCode = _codeController.text.trim();
      final validCode = _getCurrentOTP();

      if (enteredCode == validCode) {
        widget.onVerified();
        if (mounted) Navigator.pop(context);
      } else {
        setState(() {
          _errorMessage = 'الرمز غير صحيح. تأكد من إدخاله بشكل صحيح.';
          _isVerifying = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'حدث خطأ أثناء التحقق';
        _isVerifying = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                children: [
                  const Icon(Icons.security, color: AppColors.primary, size: 32),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'إعداد المصادقة الثنائية',
                      style: GoogleFonts.cairo(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // خطوات الإعداد
              if (_step == 1) ...[
                // الخطوة 1: مسح QR Code
                Text(
                  'الخطوة 1: مسح الباركود',
                  style: GoogleFonts.cairo(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  'استخدم تطبيق Google Authenticator أو Authy لمسح الباركود:',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 16),

                // QR Code
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.surfaceVariant),
                    ),
                    child: QrImageView(
                      data: widget.otpAuthUrl,
                      version: QrVersions.auto,
                      size: 200,
                      backgroundColor: Colors.white,
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // المفتاح السري النصي
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'أو أدخل المفتاح يدوياً:',
                        style: GoogleFonts.cairo(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: SelectableText(
                              widget.secret,
                              style: const TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 14,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.copy, size: 20),
                            onPressed: () {
                              Clipboard.setData(ClipboardData(text: widget.secret));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('تم نسخ المفتاح'),
                                  duration: Duration(seconds: 1),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // زر التالي
                ElevatedButton(
                  onPressed: () => setState(() => _step = 2),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('التالي'),
                ),
              ] else ...[
                // الخطوة 2: التحقق من الرمز
                Text(
                  'الخطوة 2: التحقق',
                  style: GoogleFonts.cairo(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  'أدخل الرمز المكون من 6 أرقام من تطبيق المصادقة:',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 16),

                // حقل إدخال الرمز
                TextField(
                  controller: _codeController,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  maxLength: 6,
                  style: const TextStyle(
                    fontSize: 24,
                    letterSpacing: 8,
                    fontWeight: FontWeight.bold,
                  ),
                  decoration: InputDecoration(
                    hintText: '000000',
                    counterText: '',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: AppColors.primary, width: 2),
                    ),
                    errorText: _errorMessage,
                  ),
                  onSubmitted: (_) => _verifyCode(),
                ),

                const SizedBox(height: 24),

                // أزرار التحقق
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => setState(() {
                          _step = 1;
                          _errorMessage = null;
                          _codeController.clear();
                        }),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text('رجوع'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isVerifying ? null : _verifyCode,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.success,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: _isVerifying
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('تحقق'),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
