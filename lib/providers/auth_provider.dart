import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:convert';
import '../models/user_model.dart';
import '../services/emailjs_service.dart';

class AuthProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final EmailJsService _emailJsService = EmailJsService();
  
  UserModel? _currentUser;
  bool _isLoading = false;
  bool _isGuestMode = false;

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _currentUser != null;
  bool get isGuestMode => _isGuestMode;
  String? get user => _currentUser?.id;
  FirebaseFirestore get firestore => _firestore;

  AuthProvider() {
    _initAuth();
  }

  /// تهيئة المصادقة والتحقق من المستخدم الحالي
  Future<void> _initAuth() async {
    try {
      _auth.authStateChanges().listen((User? firebaseUser) async {
        try {
          if (firebaseUser != null) {
            // التحقق من الحظر أولاً
            final isBanned = await _checkIfBanned(firebaseUser.uid);
            if (isBanned) {
              // تسجيل الخروج فوراً
              await signOut();
              return;
            }
            await _loadUserData(firebaseUser.uid);
          } else {
            _currentUser = null;
            notifyListeners();
          }
        } catch (e) {
          _currentUser = null;
          notifyListeners();
        }
      });
    } catch (e) {
    }
  }

  /// التحقق من حظر المستخدم
  Future<bool> _checkIfBanned(String uid) async {
    try {
      final doc = await _firestore.collection('banned_users').doc(uid).get();
      return doc.exists;
    } catch (e) {
      return false;
    }
  }

  /// الاستمرار كزائر
  void continueAsGuest() {
    _isGuestMode = true;
    notifyListeners();
  }

  /// تحميل بيانات المستخدم من Firestore
  Future<void> _loadUserData(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        _currentUser = UserModel.fromJson({...doc.data()!, 'id': uid});
        _isGuestMode = false;
        notifyListeners();
      }
    } catch (e) {
    }
  }

  /// إعادة تحميل بيانات المستخدم الحالي
  Future<void> refreshUser() async {
    if (_currentUser != null) {
      await _loadUserData(_currentUser!.id);
    }
  }



  /// تسجيل دخول بحساب Apple
  Future<bool> signInWithApple() async {
    _isLoading = true;
    notifyListeners();

    try {
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      final oAuthCredential = OAuthProvider('apple.com').credential(
        idToken: appleCredential.identityToken,
        accessToken: appleCredential.authorizationCode,
      );

      final userCredential = await _auth.signInWithCredential(oAuthCredential);
      final user = userCredential.user;

      if (user != null) {
        // التحقق من وجود المستخدم في Firestore
        final userDoc = await _firestore.collection('users').doc(user.uid).get();
        
        if (!userDoc.exists) {
          // إنشاء حساب جديد - بيانات أولية
          final nickname = appleCredential.givenName ?? appleCredential.familyName ?? 'مستخدم Apple';
          final username = 'user_${user.uid.substring(0, 8)}';
          
          final newUser = UserModel(
            id: user.uid,
            email: user.email ?? 'apple@athar.app',
            username: username,
            nickname: nickname,
            region: '', // سيتم إكماله في صفحة إكمال البيانات
            city: '', // سيتم إكماله في صفحة إكمال البيانات
            createdAt: DateTime.now(),
            authProvider: AuthProviderType.apple,
            isEmailVerified: true,
          );

          await _firestore.collection('users').doc(user.uid).set(newUser.toJson());
          _currentUser = newUser;
        } else {
          await _loadUserData(user.uid);
        }
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  /// تسجيل دخول بحساب Google
  Future<bool> signInWithGoogle() async {
    _isLoading = true;
    notifyListeners();

    try {
      // تنظيف أي جلسة سابقة أولاً
      await _googleSignIn.signOut();
      
      // تسجيل الدخول بـ Google
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      if (googleUser == null) {
        _isLoading = false;
        notifyListeners();
        return false;
      }

      
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      
      if (googleAuth.accessToken == null || googleAuth.idToken == null) {
        _isLoading = false;
        notifyListeners();
        return false;
      }
      
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      final user = userCredential.user;

      if (user != null) {
        
        // التحقق من وجود المستخدم في Firestore
        final userDoc = await _firestore.collection('users').doc(user.uid).get();
        
        if (!userDoc.exists) {
          // إنشاء حساب جديد - بيانات أولية
          final username = 'user_${user.uid.substring(0, 8)}';
          
          final newUser = UserModel(
            id: user.uid,
            email: user.email ?? 'google@athar.app',
            username: username,
            nickname: user.displayName ?? 'مستخدم Google',
            avatarUrl: user.photoURL,
            region: '', // سيتم إكماله في صفحة إكمال البيانات
            city: '', // سيتم إكماله في صفحة إكمال البيانات
            createdAt: DateTime.now(),
            authProvider: AuthProviderType.google,
            isEmailVerified: true,
          );

          await _firestore.collection('users').doc(user.uid).set(newUser.toJson());
          _currentUser = newUser;
        } else {
          await _loadUserData(user.uid);
        }
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  /// تسجيل دخول بالبريد الإلكتروني
  Future<bool> signInWithEmail({
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = userCredential.user;
      if (user != null) {
        await _loadUserData(user.uid);
        _isLoading = false;
        notifyListeners();
        return true;
      }

      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  /// إنشاء حساب بالبريد الإلكتروني مع إرسال رمز التحقق
  Future<Map<String, dynamic>> signUpWithEmail({
    required String email,
    required String password,
    required String username,
    required String nickname,
    required String region,
    required String city,
    XFile? avatarFile,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      // إنشاء حساب في Firebase Auth
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = userCredential.user;
      if (user != null) {
        // رفع صورة الأفاتار إلى Firebase Storage
        String? avatarUrl;
        if (avatarFile != null) {
          avatarUrl = await _uploadAvatar(user.uid, avatarFile);
        }

        // إنشاء بيانات المستخدم
        final newUser = UserModel(
          id: user.uid,
          email: email,
          username: username,
          nickname: nickname,
          region: region,
          city: city,
          avatarUrl: avatarUrl,
          createdAt: DateTime.now(),
          authProvider: AuthProviderType.email,
          isEmailVerified: false,
        );

        // حفظ بيانات المستخدم في Firestore
        await _firestore.collection('users').doc(user.uid).set(newUser.toJson());

        // إرسال رمز التحقق عبر EmailJS
        await _emailJsService.sendVerificationEmail(
          toEmail: email,
          userName: nickname,
        );
        
        _currentUser = newUser;
        _isLoading = false;
        notifyListeners();
        
        return {
          'success': true,
          'needsVerification': true,
          'message': 'تم إرسال رمز التحقق إلى بريدك الإلكتروني',
        };
      }

      _isLoading = false;
      notifyListeners();
      return {
        'success': false,
        'needsVerification': false,
        'message': 'فشل إنشاء الحساب',
      };
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }
  
  /// إعادة إرسال رمز التحقق
  Future<bool> resendVerificationEmail() async {
    try {
      if (_currentUser != null) {
        await _emailJsService.sendVerificationEmail(
          toEmail: _currentUser!.email,
          userName: _currentUser!.nickname,
        );
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }
  
  /// التحقق من رمز التحقق الذي أدخله المستخدم
  Future<bool> verifyEmailCode(String code) async {
    try {
      if (_currentUser == null) return false;
      
      final isValid = await _emailJsService.verifyCode(
        email: _currentUser!.email,
        code: code,
      );
      
      if (isValid) {
        // تحديث حالة التحقق في Firestore
        await _firestore.collection('users').doc(_currentUser!.id).update({
          'isEmailVerified': true,
        });
        
        _currentUser = _currentUser!.copyWith(isEmailVerified: true);
        notifyListeners();
        
        // حذف رمز التحقق بعد النجاح
        await _emailJsService.deleteVerificationCode(_currentUser!.email);
        
        return true;
      }
      
      return false;
    } catch (e) {
      return false;
    }
  }
  
  /// التحقق من حالة البريد الإلكتروني (للتوافق مع الكود القديم)
  Future<bool> checkEmailVerification() async {
    // هذه الدالة لم تعد مستخدمة مع EmailJS
    // نبقيها فقط للتوافق مع الشاشات القديمة
    return _currentUser?.isEmailVerified ?? false;
  }

  /// تحويل الصورة إلى Base64 للحفظ في Firestore مباشرة
  Future<String?> _uploadAvatar(String userId, XFile avatarFile) async {
    try {
      final bytes = await avatarFile.readAsBytes();
      
      // تحويل إلى Base64
      final base64Image = base64Encode(bytes);
      
      return 'data:image/jpeg;base64,$base64Image';
    } catch (e) {
      return null;
    }
  }

  /// التحقق من توفر اسم المستخدم
  Future<bool> isUsernameAvailable(String username) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      // البحث عن اسم المستخدم في قاعدة البيانات
      final querySnapshot = await _firestore
          .collection('users')
          .where('username', isEqualTo: username)
          .get();

      // إذا لم يوجد، أو كان للمستخدم الحالي، فهو متاح
      if (querySnapshot.docs.isEmpty) return true;
      if (querySnapshot.docs.first.id == user.uid) return true;
      
      return false;
    } catch (e) {
      return false;
    }
  }

  /// تحديث معلومات المستخدم
  Future<void> updateUserProfile({
    required String username,
    required String nickname,
    required String region,
    required String city,
    XFile? avatarFile,
    bool removeAvatar = false,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null || _currentUser == null) {
        return;
      }

      
      // التحقق من توفر اسم المستخدم إذا تم تغييره
      if (username != _currentUser!.username) {
        final isAvailable = await isUsernameAvailable(username);
        if (!isAvailable) {
          throw Exception('اسم المستخدم محجوز بالفعل');
        }
      }

      // رفع صورة جديدة إذا تم اختيارها
      String? avatarUrl = _currentUser!.avatarUrl;
      if (removeAvatar) {
        avatarUrl = null;
      } else if (avatarFile != null) {
        avatarUrl = await _uploadAvatar(user.uid, avatarFile);
      }

      // تحديث البيانات في Firestore
      final updateData = <String, dynamic>{
        'username': username,
        'nickname': nickname,
        'region': region,
        'city': city,
      };
      
      if (removeAvatar) {
        // حذف الحقل
        await _firestore.collection('users').doc(user.uid).update({
          ...updateData,
        });
        await _firestore.collection('users').doc(user.uid).update({
          'avatarUrl': FieldValue.delete(),
        });
      } else {
        if (avatarUrl != null) {
          updateData['avatarUrl'] = avatarUrl;
        }
        await _firestore.collection('users').doc(user.uid).update(updateData);
      }

      // تحديث الحالة المحلية
      _currentUser = _currentUser!.copyWith(
        username: username,
        nickname: nickname,
        region: region,
        city: city,
        avatarUrl: removeAvatar ? null : avatarUrl,
      );
      
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  /// تسجيل خروج
  Future<void> signOut() async {
    await _auth.signOut();
    await _googleSignIn.signOut();
    _currentUser = null;
    notifyListeners();
  }

  /// حذف الحساب نهائياً
  Future<void> deleteAccount() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        await user.delete();
        await _googleSignIn.signOut();
        _currentUser = null;
        notifyListeners();
      }
    } catch (e) {
      rethrow;
    }
  }

  /// التحقق مما إذا كان المستخدم الحالي قد تحقق من بريده
  bool get isEmailVerified {
    return _auth.currentUser?.emailVerified ?? false;
  }

  /// الحصول على اسم المستخدم
  String get userName {
    return _currentUser?.nickname ?? 'مستخدم';
  }

  /// الحصول على معرف المستخدم
  String get userId {
    return _currentUser?.id ?? 'demo_user';
  }
}
