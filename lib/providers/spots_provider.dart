import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/camping_spot.dart';
import '../services/cloudinary_service.dart';

class SpotsProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  List<CampingSpot> _spots = [];
  bool _isLoading = false;
  String? _error;

  List<CampingSpot> get spots => _spots;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// جلب جميع أماكن الكشتات من Firestore
  Future<void> fetchSpots() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final QuerySnapshot snapshot = await _firestore
          .collection('spots')
          .orderBy('createdAt', descending: true)
          .limit(50) // نحمل 50 بوست أول شيء
          .get();

      _spots = snapshot.docs
          .map((doc) => CampingSpot.fromJson({
                ...doc.data() as Map<String, dynamic>,
                'id': doc.id,
              }))
          .toList();

      debugPrint('✅ تم تحميل ${_spots.length} مكان من Firestore');
      _error = null;
    } catch (e) {
      _error = 'حدث خطأ في جلب البيانات: $e';
      debugPrint(_error);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// إضافة مكان كشتة جديد وحفظه في Firestore
  Future<bool> addSpot(CampingSpot spot) async {
    try {
      // إضافة إلى Firestore
      final docRef = await _firestore.collection('spots').add(spot.toJson());
      
      // تحديث الـ ID بعد الإضافة
      final newSpot = spot.copyWith(id: docRef.id);
      await docRef.update({'id': docRef.id});
      
      // إضافة محلياً
      _spots.insert(0, newSpot);
      
      debugPrint('✅ تم إضافة المكان: ${spot.name} - ID: ${docRef.id}');
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'فشل إضافة المكان: $e';
      debugPrint('❌ $_error');
      notifyListeners();
      return false;
    }
  }

  /// الإعجاب بمكان وحفظ في Firestore
  Future<void> toggleLike(String spotId, String userId) async {
    try {
      final spotIndex = _spots.indexWhere((s) => s.id == spotId);
      if (spotIndex == -1) return;

      final spot = _spots[spotIndex];
      final likedBy = List<String>.from(spot.likedBy);
      int likes = spot.likes;

      // تحديث اللايكات
      if (likedBy.contains(userId)) {
        likedBy.remove(userId);
        likes--;
      } else {
        likedBy.add(userId);
        likes++;
      }

      // تحديث في Firestore
      await _firestore.collection('spots').doc(spotId).update({
        'likes': likes,
        'likedBy': likedBy,
      });

      // تحديث محلياً
      final updatedSpot = spot.copyWith(likes: likes, likedBy: likedBy);
      _spots[spotIndex] = updatedSpot;

      notifyListeners();
      debugPrint('✅ تم تحديث اللايك للمكان: ${spot.name}');
    } catch (e) {
      _error = 'فشل تحديث الإعجاب: $e';
      debugPrint(_error);
    }
  }

  /// الحصول على المستخدمين اللي حطوا لايك
  Future<List<String>> getLikedUsers(String spotId) async {
    try {
      final doc = await _firestore.collection('spots').doc(spotId).get();
      if (doc.exists) {
        return List<String>.from(doc.data()?['likedBy'] ?? []);
      }
      return [];
    } catch (e) {
      debugPrint('❌ فشل جلب المستخدمين: $e');
      return [];
    }
  }

  /// الحصول على مجموع اللايكات لمستخدم معين
  Future<int> getUserTotalLikes(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('spots')
          .where('userId', isEqualTo: userId)
          .get();

      int totalLikes = 0;
      for (var doc in snapshot.docs) {
        totalLikes += (doc.data()['likes'] as int?) ?? 0;
      }

      debugPrint('✅ إجمالي اللايكات للمستخدم $userId: $totalLikes');
      return totalLikes;
    } catch (e) {
      debugPrint('❌ فشل حساب اللايكات: $e');
      return 0;
    }
  }

  /// حذف مكان وحفظ التغييرات
  Future<bool> deleteSpot(String spotId) async {
    try {
      // البحث عن البوست للحصول على روابط الصور
      final spot = _spots.firstWhere((s) => s.id == spotId);
      
      debugPrint('🗑️ بدء حذف البوست: ${spot.name}');
      debugPrint('📸 عدد الصور المراد حذفها: ${spot.imageUrls.length}');
      
      // حذف الصور من Cloudinary أولاً
      await CloudinaryService.deleteMultipleImages(spot.imageUrls);
      
      // ثم حذف البوست من Firestore
      await _firestore.collection('spots').doc(spotId).delete();
      
      // إزالة من القائمة المحلية
      _spots.removeWhere((s) => s.id == spotId);
      notifyListeners();
      
      debugPrint('✅ تم حذف المكان والصور بنجاح');
      return true;
    } catch (e) {
      _error = 'فشل حذف المكان: $e';
      debugPrint('❌ $_error');
      return false;
    }
  }

  // ==================== المفضلات ====================
  
  final List<String> _favorites = [];
  
  List<String> get favorites => _favorites;
  
  /// إضافة/إزالة من المفضلة
  Future<void> toggleFavorite(String spotId) async {
    if (_favorites.contains(spotId)) {
      _favorites.remove(spotId);
    } else {
      _favorites.add(spotId);
    }
    notifyListeners();
  }
  
  /// التحقق من وجود المكان في المفضلة
  bool isFavorite(String spotId) {
    return _favorites.contains(spotId);
  }
  
  /// الحصول على المفضلات
  List<CampingSpot> getFavoriteSpots() {
    return _spots.where((spot) => _favorites.contains(spot.id)).toList();
  }

  // ==================== المحفوظات (Saved) ====================
  
  final List<String> _saved = [];
  
  List<String> get saved => _saved;
  
  /// إضافة/إزالة من المحفوظات
  Future<void> toggleSaved(String spotId) async {
    if (_saved.contains(spotId)) {
      _saved.remove(spotId);
    } else {
      _saved.add(spotId);
    }
    notifyListeners();
  }
  
  /// التحقق من وجود المكان في المحفوظات
  bool isSaved(String spotId) {
    return _saved.contains(spotId);
  }
  
  /// الحصول على المحفوظات
  List<CampingSpot> getSavedSpots() {
    return _spots.where((spot) => _saved.contains(spot.id)).toList();
  }
}
