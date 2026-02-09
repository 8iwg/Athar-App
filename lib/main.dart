import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';
import 'core/theme/app_theme.dart';
import 'screens/splash_screen.dart';
import 'screens/main_screen.dart';
import 'screens/moderator_screen.dart';
import 'screens/manage_moderators_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/login_email_screen.dart';
import 'screens/auth/signup_screen.dart';
import 'screens/auth/email_verification_screen.dart';
import 'screens/auth/email_verification_code_screen.dart';
import 'screens/auth/complete_profile_screen.dart';
import 'screens/security_settings_screen.dart';
import 'screens/banned_screen.dart';
import 'models/user_model.dart';
import 'providers/spots_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/theme_provider.dart';
import 'services/ad_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await initializeDateFormatting('ar', null);

    // تهيئة Firebase مع التعامل مع التهيئة التلقائية
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      }
    } catch (e) {
      // Firebase مهيأ تلقائياً - لا مشكلة
      if (!e.toString().contains('duplicate-app')) {
        rethrow;
      }
    }
    
    // تهيئة الإعلانات
    await AdService.initialize();
    AdService().loadInterstitialAd();

  } catch (e) {
    // تجاهل أخطاء التهيئة غير الحرجة
  }

  runApp(const AtharApp());
}

class AtharApp extends StatefulWidget {
  const AtharApp({super.key});

  @override
  State<AtharApp> createState() => _AtharAppState();
}

// حارس صفحات المشرفين - طبقة حماية إضافية
class _ModeratorGuard extends StatelessWidget {
  final Widget child;
  const _ModeratorGuard({required this.child});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _verifyModeratorAccess(context),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.data != true) {
          // إعادة التوجيه للصفحة الرئيسية فوراً
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.of(context).pushReplacementNamed('/main');
          });
          return const Scaffold(
            body: Center(
              child: Text('وصول غير مصرح'),
            ),
          );
        }

        return child;
      },
    );
  }

  Future<bool> _verifyModeratorAccess(BuildContext context) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final email = authProvider.currentUser?.email;

    if (email == null) return false;

    // التحقق من المالك
    if (email == 'rshyizer+1@gmail.com') return true;

    // التحقق من قائمة المشرفين في Firestore
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('moderators')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      return snapshot.docs.isNotEmpty;
    } catch (e) {
      return false;
    }
  }
}

// فحص حظر المستخدم
Future<bool> _checkIfUserBanned(String userId) async {
  try {
    final doc = await FirebaseFirestore.instance
        .collection('banned_users')
        .doc(userId)
        .get();
    return doc.exists;
  } catch (e) {
    return false;
  }
}

class _AtharAppState extends State<AtharApp> {
  bool _showSplash = true;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => SpotsProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) => MaterialApp(
          title: 'أثر',
          debugShowCheckedModeBanner: false,
          theme: themeProvider.isDarkMode ? AppTheme.darkTheme : AppTheme.lightTheme,
          onGenerateRoute: (settings) {
            // حماية الصفحات الخاصة بالمشرفين
            if (settings.name == '/moderator' || settings.name == '/manage-moderators') {
              return MaterialPageRoute(
                builder: (context) => _ModeratorGuard(
                  child: settings.name == '/moderator'
                      ? const ModeratorScreen()
                      : const ManageModeratorsScreen(),
                ),
              );
            }
            return null;
          },
          routes: {
            '/main': (context) => const MainScreen(),
            '/login': (context) => const LoginScreen(),
            '/login-email': (context) => const LoginEmailScreen(),
            '/signup': (context) => const SignUpScreen(),
            '/email-verification': (context) => const EmailVerificationScreen(),
            '/email-verification-code': (context) => const EmailVerificationCodeScreen(),
            '/complete-profile': (context) => const CompleteProfileScreen(),
            '/security-settings': (context) => SecuritySettingsScreen(),
            '/banned': (context) => const BannedScreen(),
          },
          home: _showSplash
              ? SplashScreen(
            onComplete: () {
              setState(() => _showSplash = false);
            },
          )
              : Consumer<AuthProvider>(
            builder: (context, authProvider, _) {
              // السماح بوضع الزائر
              if (authProvider.isGuestMode) {
                return const MainScreen();
              }

              if (!authProvider.isAuthenticated) {
                return const LoginScreen();
              }

              final user = authProvider.currentUser;
              if (user == null) return const LoginScreen();

              // فحص الحظر - أولوية قصوى
              return FutureBuilder<bool>(
                future: _checkIfUserBanned(user.id),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Scaffold(
                      body: Center(child: CircularProgressIndicator()),
                    );
                  }

                  if (snapshot.data == true) {
                    return const BannedScreen();
                  }

                  // التحقق من تحقق البريد الإلكتروني
                  if (user.authProvider == AuthProviderType.email &&
                      !authProvider.isEmailVerified) {
                    return const EmailVerificationScreen();
                  }

                  // التحقق من اكتمال البيانات الشخصية
                  if (user.region.isEmpty || user.city.isEmpty) {
                    return const CompleteProfileScreen();
                  }

                  return const MainScreen();
                },
              );
            },
          ),
        ),
      ),
    );
  }
}
