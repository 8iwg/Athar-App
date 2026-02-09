import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart' as flutter_svg;
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme/app_colors.dart';
import '../providers/spots_provider.dart';
import '../providers/auth_provider.dart';
import '../models/camping_spot.dart';
import '../widgets/spot_feed_card.dart';
import '../widgets/elegant_drawer.dart';
import 'camera_screen.dart';
import 'profile_screen.dart';
import 'settings_screen.dart';
import 'spot_details_screen.dart';
import 'custom_map_screen.dart';
import 'favorites_screen.dart';

enum SortType { latest, topLikes, topViews }

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  SortType _sortType = SortType.latest;
  String? _selectedTag;
  String? _selectedCategory; // للتصفية حسب القسم من الـ Drawer
  bool _showFavoritesOnly = false;
  
  // 1. إضافة كنترولر للأنيميشن (حركة التنفس للزر)
  late AnimationController _fabAnimationController;

  final List<String> _tags = [
    'الكل', 'جبال', 'كشتة', 'وديان', 'شواطئ', 'غابات', 'مرتفعات',
  ];

  @override
  void initState() {
    super.initState();
    // إعداد حركة الزر النابض
    _fabAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
      lowerBound: 0.92,
      upperBound: 1.0,
    )..repeat(reverse: true);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeApp();
    });
  }

  @override
  void dispose() {
    _fabAnimationController.dispose();
    super.dispose();
  }

  Future<void> _initializeApp() async {
    final spotsProvider = context.read<SpotsProvider>();
    await spotsProvider.fetchSpots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true, // ضروري عشان الخلفية والبار العائم
      endDrawer: ElegantDrawer(
        onCategorySelected: (category) {
          print('🔍 main_screen: تم اختيار القسم: $category');
          setState(() {
            _selectedCategory = category;
            _showFavoritesOnly = false;
            
            // تحديث التاق ليطابق القسم
            if (category == null) {
              _selectedTag = null;
            } else {
              _selectedTag = category;
            }
          });
        },
        onFavoritesToggle: (showFavorites) {
          print('❤️ main_screen: تبديل المفضلة: $showFavorites');
          setState(() {
            _showFavoritesOnly = showFavorites;
            _selectedCategory = null;
            _currentIndex = 2; // الانتقال لصفحة المفضلة
          });
        },
        onSettingsTap: () {
          setState(() {
            _currentIndex = 3; // الانتقال لصفحة الإعدادات
          });
        },
      ),
      body: Container(
        // 2. الخلفية البريميوم (Ambient Background)
        decoration: BoxDecoration(
          color: AppColors.background,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.background,
              AppColors.surfaceVariant.withOpacity(0.4),
              AppColors.primary.withOpacity(0.08),
            ],
          ),
        ),
        child: Stack(
          children: [
            _getPage(),
            
            // تدرج سفلي لدمج المحتوى مع الناف بار العائم
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              height: 140,
              child: IgnorePointer(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        AppColors.background.withOpacity(0.95),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildLuxuryBottomNav(),
    );
  }

  Widget _getPage() {
    // استخدمنا هذا عشان نحافظ على حالة الصفحات
    return IndexedStack(
      index: _currentIndex,
      children: [
        _buildHomePage(),
        const CustomMapScreen(),
        const FavoritesScreen(),
        SettingsScreen(onBackToHome: () => setState(() => _currentIndex = 0)),
      ],
    );
  }

  Widget _buildHomePage() {
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        _buildLuxuryAppBar(),
        _buildFeedList(),
        const SliverPadding(padding: EdgeInsets.only(bottom: 130)), // مساحة إضافية للبار العائم
      ],
    );
  }

  Widget _buildLuxuryAppBar() {
    return SliverAppBar(
      floating: false,
      pinned: true,
      snap: false,
      expandedHeight: 200, // ارتفاع كافٍ للتاقات والأزرار
      backgroundColor: AppColors.background,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      leading: Center(
        child: Consumer<AuthProvider>(
          builder: (context, authProvider, _) {
            final avatarUrl = authProvider.currentUser?.avatarUrl;
            
            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ProfileScreen(onBackToHome: () {})),
                );
              },
              child: Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: avatarUrl == null ? Colors.white.withOpacity(0.5) : null,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 12,
                    )
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(26),
                  child: avatarUrl != null
                      ? (avatarUrl.startsWith('data:image')
                          ? Image.memory(
                              Uri.parse(avatarUrl).data!.contentAsBytes(),
                              fit: BoxFit.cover,
                              width: 52,
                              height: 52,
                              errorBuilder: (_, __, ___) => Icon(
                                Icons.person,
                                color: AppColors.textPrimary,
                                size: 28,
                              ),
                            )
                          : Image.network(
                              avatarUrl,
                              fit: BoxFit.cover,
                              width: 52,
                              height: 52,
                              errorBuilder: (_, __, ___) => Icon(
                                Icons.person,
                                color: AppColors.textPrimary,
                                size: 28,
                              ),
                            ))
                      : Icon(
                          authProvider.isAuthenticated ? Icons.person : Icons.person_outline,
                          color: AppColors.textPrimary,
                          size: 28,
                        ),
                ),
              ),
            );
          },
        ),
      ),
      title: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.5),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: Colors.white.withOpacity(0.4)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'استكشف',
                  style: GoogleFonts.almarai(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsetsDirectional.only(end: 16.0),
          child: Builder(
            builder: (context) => Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                  )
                ]
              ),
              child: IconButton(
                icon: Icon(Icons.menu_rounded, color: AppColors.textPrimary, size: 24),
                onPressed: () => Scaffold.of(context).openEndDrawer(),
              ),
            ),
          ),
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(140),
        child: Column(
          children: [
            // التاقات
            SizedBox(
              height: 70,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                itemCount: _tags.length,
                reverse: true,
                itemBuilder: (context, index) {
                  final tag = _tags[index];
                  final isSelected = _selectedTag == (tag == 'الكل' ? null : tag);
                  return _buildModernTag(tag, isSelected);
                },
              ),
            ),
            // أزرار الترتيب
            _buildSortButtonsRow(),
          ],
        ),
      ),
    );
  }

  Widget _buildModernTag(String tag, bool isSelected) {
    return GestureDetector(
      onTap: () {
        if (_selectedTag != (tag == 'الكل' ? null : tag)) {
          setState(() => _selectedTag = tag == 'الكل' ? null : tag);
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
        margin: const EdgeInsets.only(left: 12),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          gradient: isSelected 
              ? LinearGradient(
                  colors: [AppColors.primary, AppColors.earth],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : LinearGradient(
                  colors: [Colors.white.withOpacity(0.9), Colors.white.withOpacity(0.6)],
                ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.4),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  )
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 5,
                    offset: const Offset(0, 3),
                  )
                ],
          border: isSelected 
              ? Border.all(color: Colors.white.withOpacity(0.2)) 
              : Border.all(color: Colors.white.withOpacity(0.5)),
        ),
        child: Center(
          child: Text(
            tag,
            style: TextStyle(
              fontFamily: 'Rubik',
              fontSize: 14,
              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
              color: isSelected ? Colors.white : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGradientTagsSection() {
    return SliverToBoxAdapter(
      child: Container(
        height: 75, // زيادة الارتفاع قليلاً للظلال
        margin: const EdgeInsets.symmetric(vertical: 10),
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5), // بادينق للظلال
          itemCount: _tags.length,
          reverse: true,
          itemBuilder: (context, index) {
            final tag = _tags[index];
            final isSelected = _selectedTag == tag || (_selectedTag == null && tag == 'الكل');
            
            return GestureDetector(
              onTap: () {
                if (_selectedTag != (tag == 'الكل' ? null : tag)) {
                  setState(() => _selectedTag = tag == 'الكل' ? null : tag);
                }
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 350),
                curve: Curves.easeOutCubic,
                margin: const EdgeInsets.only(left: 12),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  gradient: isSelected 
                      ? LinearGradient(
                          colors: [AppColors.primary, AppColors.earth],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : LinearGradient(
                          colors: [Colors.white.withOpacity(0.9), Colors.white.withOpacity(0.6)],
                        ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.4),
                            blurRadius: 15,
                            offset: const Offset(0, 8),
                          )
                        ]
                      : [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.03),
                            blurRadius: 5,
                            offset: const Offset(0, 3),
                          )
                        ],
                  border: isSelected 
                      ? Border.all(color: Colors.white.withOpacity(0.2)) 
                      : Border.all(color: Colors.white.withOpacity(0.5)),
                ),
                child: Center(
                  child: Text(
                    tag,
                    style: TextStyle(
                      fontFamily: 'Rubik',
                      fontSize: 14,
                      fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                      color: isSelected ? Colors.white : AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildFloatingSortButtons() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        child: _buildSortButtonsRow(),
      ),
    );
  }

  Widget _buildSortButtonsRow() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(25),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.6),
            borderRadius: BorderRadius.circular(25),
            border: Border.all(color: Colors.white.withOpacity(0.5)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          padding: const EdgeInsets.all(5),
          child: Row(
            children: [
              _buildModernSortItem('الأحدث', SortType.latest),
              _buildModernSortItem('الأكثر تفاعلاً', SortType.topLikes),
              _buildModernSortItem('الأعلى مشاهدة', SortType.topViews),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModernSortItem(String label, SortType type) {
    final isSelected = _sortType == type;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _sortType = type),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.surface : Colors.transparent, // الأبيض للخيار المحدد
            borderRadius: BorderRadius.circular(20),
            boxShadow: isSelected ? [
               BoxShadow(
                 color: Colors.black.withOpacity(0.05),
                 blurRadius: 10,
                 offset: const Offset(0, 2)
               )
            ] : [],
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Rubik',
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w900 : FontWeight.w500,
              color: isSelected ? AppColors.primary : AppColors.textTertiary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeedList() {
    return Consumer<SpotsProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const SliverFillRemaining(
            hasScrollBody: false,
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          );
        }

        if (provider.spots.isEmpty) {
          return SliverFillRemaining(
            hasScrollBody: false,
            child: _buildEmptyState(),
          );
        }

        var spots = List<CampingSpot>.from(provider.spots);
        
        // فلترة بالتصنيف (Tag) من القائمة العلوية
        if (_selectedTag != null) {
          spots = spots.where((spot) => spot.category == _selectedTag).toList();
        }
        
        switch (_sortType) {
          case SortType.latest:
            spots.sort((a, b) => b.createdAt.compareTo(a.createdAt));
            break;
          case SortType.topLikes:
            spots.sort((a, b) => b.likes.compareTo(a.likes));
            break;
          case SortType.topViews:
            break;
        }

        // عرض حالة فارغة إذا لم يكن هناك نتائج بعد الفلترة
        if (spots.isEmpty) {
          return SliverFillRemaining(
            hasScrollBody: false,
            child: _buildEmptyState(),
          );
        }

        return SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final spot = spots[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 24), // زيادة المسافة للفخامة
                  child: SpotFeedCard(
                    spot: spot,
                    onTap: () => _navigateToDetails(spot),
                  ),
                );
              },
              childCount: spots.length,
            ),
          ),
        );
      },
    );
  }

  // --- شريط التنقل السفلي الفخم والعائم (The Star of the Show) ---
  Widget _buildLuxuryBottomNav() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 30), // هوامش لجعله عائماً
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          // 3. البار الزجاجي العائم
          ClipRRect(
            borderRadius: BorderRadius.circular(40),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.85),
                  borderRadius: BorderRadius.circular(40),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.8),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 30,
                      offset: const Offset(0, 15),
                      spreadRadius: -5,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildNavItem(icon: Icons.home_outlined, activeIcon: Icons.home_rounded, index: 0),
                    _buildNavItem(icon: Icons.map_outlined, activeIcon: Icons.map_rounded, index: 1),
                    const SizedBox(width: 60), // مساحة للجوهرة
                    _buildNavItem(icon: Icons.history_rounded, activeIcon: Icons.history_rounded, index: 2),
                    _buildNavItem(icon: Icons.settings_outlined, activeIcon: Icons.settings_rounded, index: 3),
                  ],
                ),
              ),
            ),
          ),
          
          // 4. زر الكاميرا (الجوهرة)
          Positioned(
            top: -25,
            child: _buildGlowingFab(),
          ),
        ],
      ),
    );
  }

  Widget _buildGlowingFab() {
    return GestureDetector(
      onTap: _openCamera,
      child: ScaleTransition(
        scale: _fabAnimationController, // تطبيق حركة التنفس
        child: Container(
          width: 75,
          height: 75,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            // تدرج لوني فخم
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.primary,
                AppColors.earth,
              ],
            ),
            boxShadow: [
              // توهج خارجي قوي
              BoxShadow(
                color: AppColors.primary.withOpacity(0.5),
                blurRadius: 20,
                offset: const Offset(0, 10),
                spreadRadius: 2,
              ),
              // إضاءة داخلية (Rim Light)
              BoxShadow(
                color: Colors.white.withOpacity(0.4),
                blurRadius: 0,
                offset: const Offset(0, 0),
                spreadRadius: 3, // حدود داخلية مضيئة
              ),
            ],
          ),
          child: Center(
            child: Icon(
              Icons.add_a_photo_rounded,
              color: Colors.white,
              size: 32,
              shadows: [
                Shadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 5,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required IconData activeIcon,
    required int index,
  }) {
    final isActive = _currentIndex == index;
    
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primary.withOpacity(0.1) : Colors.transparent,
          shape: BoxShape.circle,
        ),
        child: Icon(
          isActive ? activeIcon : icon,
          color: isActive ? AppColors.primary : AppColors.textTertiary,
          size: 26,
        ),
      ),
    );
  }

  // --- دوال مساعدة ---
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.5),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white),
            ),
            child: Icon(
              Icons.landscape_rounded,
              size: 70,
              color: AppColors.textTertiary.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'لا توجد أماكن بعد',
            style: GoogleFonts.cairo(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  void _openCamera() async {
    // التحقق من تسجيل الدخول
    final authProvider = context.read<AuthProvider>();
    if (!authProvider.isAuthenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('يجب تسجيل الدخول أولاً لإضافة مكان جديد'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          backgroundColor: AppColors.error,
          action: SnackBarAction(
            label: 'تسجيل',
            textColor: Colors.white,
            onPressed: () {
              // الانتقال لصفحة تسجيل الدخول
              Navigator.pushNamed(context, '/login');
            },
          ),
        ),
      );
      return;
    }
    
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CameraScreen()),
    );
    if (result == true && mounted) {
      await context.read<SpotsProvider>().fetchSpots();
      setState(() => _currentIndex = 0);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('تم نشر مكانك الجديد بنجاح ✨'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  void _navigateToDetails(CampingSpot spot) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => SpotDetailsScreen(spot: spot)),
    );
  }

  void _navigateToLocation(CampingSpot spot) {
    debugPrint('Navigate to: ${spot.latitude}, ${spot.longitude}');
  }

  Widget _buildDefaultIcon(bool isAuthenticated) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withOpacity(0.5),
      ),
      child: Center(
        child: Icon(
          isAuthenticated ? Icons.person : Icons.person_outline,
          color: AppColors.textPrimary,
          size: 24,
        ),
      ),
    );
  }
}