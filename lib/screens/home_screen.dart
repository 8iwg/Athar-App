import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // لتغيير لون أيقونات الستاتس بار
import 'package:provider/provider.dart';
import '../core/theme/app_colors.dart';
import '../providers/spots_provider.dart';
import '../models/camping_spot.dart';
import '../widgets/spot_card.dart';
import '../widgets/elegant_drawer.dart';
import 'add_spot_screen.dart';
import 'spot_details_screen.dart';
import '../data/saudi_cities.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  int _currentIndex = 1;
  late AnimationController _fabAnimationController;
  final ScrollController _scrollController = ScrollController();

  final List<String> _tags = ['الكل', 'جبال', 'كشتة', 'وديان', 'شواطئ', 'غابات', 'مرتفعات'];
  int _selectedTagIndex = 0;
  String? _selectedFilterRegion;
  String? _selectedFilterCity;
  String? _selectedCategory; // التصنيف المختار من الـ drawer
  bool _showFavoritesOnly = false; // عرض المفضلة فقط (سيتم نقلها لقسم منفصل)

  @override
  void initState() {
    super.initState();
    _fabAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500), // إبطاء الحركة لتكون أنعم
      lowerBound: 0.9,
      upperBound: 1.0,
    )..repeat(reverse: true);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeApp();
    });
  }

  @override
  void dispose() {
    _fabAnimationController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _initializeApp() async {
    await context.read<SpotsProvider>().fetchSpots();
  }

  @override
  Widget build(BuildContext context) {
    // جعل الستاتس بار يتناسب مع الثيم الفخم
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);

    return Scaffold(
      extendBody: true,
      drawer: ElegantDrawer(
        onCategorySelected: (category) {
          print('🔍 تم اختيار القسم: $category');
          print('📊 قبل setState - القسم الحالي: $_selectedCategory، التاق: $_selectedTagIndex');
          setState(() {
            _selectedCategory = category;
            _showFavoritesOnly = false;
            
            // تحديث التاق ليطابق القسم المختار
            if (category == null) {
              _selectedTagIndex = 0; // الكل
            } else {
              final index = _tags.indexOf(category);
              print('🎯 البحث عن "$category" في التاقات، الموقع: $index');
              if (index != -1) {
                _selectedTagIndex = index;
              }
            }
          });
          print('📊 بعد setState - القسم الجديد: $_selectedCategory، التاق: $_selectedTagIndex');
        },
        onFavoritesToggle: (showFavorites) {
          print('❤️ تبديل المفضلة: $showFavorites');
          setState(() {
            _showFavoritesOnly = showFavorites;
            _selectedCategory = null;
          });
        },
      ),
      body: Container(
        // خلفية بريميوم: تدرج لوني خفيف جداً يعطي عمق
        decoration: BoxDecoration(
          color: AppColors.background,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.background,
              AppColors.surfaceVariant.withOpacity(0.3),
              AppColors.primary.withOpacity(0.05), // لمسة خفيفة من اللون الأساسي
            ],
          ),
        ),
        child: Stack(
          children: [
            _currentIndex == 0 ? _buildMapView() : _buildFeedView(),
            
            // زر الفلتر
            if (_currentIndex == 1)
              Positioned(
                top: 50,
                left: 16,
                child: _buildFilterButton(),
              ),
            
            // تدرج سفلي لدمج القائمة مع البار السفلي
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              height: 120,
              child: IgnorePointer(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        AppColors.background.withOpacity(0.9),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildLuxuriousBottomNav(),
    );
  }

  // --- قسم عرض القائمة الفاخر ---
  Widget _buildFeedView() {
    return RefreshIndicator(
      onRefresh: () async {
        await context.read<SpotsProvider>().fetchSpots();
      },
      color: AppColors.primary,
      backgroundColor: AppColors.surface,
      strokeWidth: 3.0,
      child: CustomScrollView(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
        slivers: [
          _buildLuxuriousAppBar(),
          _buildGlassyTagsSection(),
          const SliverPadding(padding: EdgeInsets.only(top: 10)),
          _buildSpotsList(),
          const SliverPadding(padding: EdgeInsets.only(bottom: 120)),
        ],
      ),
    );
  }

  Widget _buildLuxuriousAppBar() {
    return SliverAppBar(
      expandedHeight: 130.0,
      floating: false,
      pinned: true,
      backgroundColor: AppColors.background,
      surfaceTintColor: Colors.transparent,
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.1),
      flexibleSpace: FlexibleSpaceBar(
        centerTitle: false,
        titlePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        title: LayoutBuilder(
          builder: (context, constraints) {
            // منطق بسيط لإخفاء العنوان الكبير عند السكرول
            final isCollapsed = constraints.maxHeight < 100;
            return AnimatedOpacity(
              duration: const Duration(milliseconds: 300),
              opacity: 1.0,
              child: Row(
                children: [
                   if (isCollapsed) ...[
                      Icon(Icons.terrain_rounded, color: AppColors.primary, size: 20),
                      const SizedBox(width: 8),
                   ],
                  Text(
                    isCollapsed ? 'أثر' : 'اكتشف\nأجمل الكشتات',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: isCollapsed ? 20 : 22, // حجم أكبر في الوضع المفتوح
                      fontWeight: FontWeight.w900,
                      height: 1.2,
                      fontFamily: 'Cairo', // تأكد أن الخط موجود
                    ),
                    textAlign: TextAlign.right,
                  ),
                ],
              ),
            );
          },
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
              colors: [
                AppColors.surface,
                AppColors.surfaceVariant.withOpacity(0.5),
              ],
            ),
          ),
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              _buildAppBarIconBtn(Icons.search_rounded),
              const SizedBox(width: 10),
              _buildAppBarIconBtn(Icons.notifications_none_rounded),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAppBarIconBtn(IconData icon) {
    return Container(
      width: 45,
      height: 45,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.8),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Icon(icon, color: AppColors.textPrimary, size: 22),
    );
  }

  Widget _buildGlassyTagsSection() {
    return SliverPersistentHeader(
      pinned: true,
      floating: false,
      delegate: _TagsHeaderDelegate(
        tags: _tags,
        selectedIndex: _selectedTagIndex,
        onTagSelected: (index) => setState(() => _selectedTagIndex = index),
      ),
    );
  }

  Widget _buildSpotsList() {
    return Consumer<SpotsProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const SliverFillRemaining(child: Center(child: CircularProgressIndicator()));
        }

        if (provider.spots.isEmpty) {
          return SliverFillRemaining(child: _buildEmptyState());
        }

        // فلترة البوستات حسب المنطقة والمدينة والتصنيف والمفضلة
        var filteredSpots = provider.spots;
        
        // فلتر حسب الـ tag المختار (من الشريط العلوي)
        if (_selectedTagIndex > 0) { // 0 = الكل
          final selectedTag = _tags[_selectedTagIndex];
          filteredSpots = filteredSpots.where((spot) => spot.category == selectedTag).toList();
        }
        
        // فلتر المنطقة
        if (_selectedFilterRegion != null) {
          filteredSpots = filteredSpots.where((spot) => spot.region == _selectedFilterRegion).toList();
        }
        
        // فلتر المدينة
        if (_selectedFilterCity != null) {
          filteredSpots = filteredSpots.where((spot) => spot.city == _selectedFilterCity).toList();
        }
        
        // فلتر التصنيف من الـ drawer
        if (_selectedCategory != null) {
          filteredSpots = filteredSpots.where((spot) => spot.category == _selectedCategory).toList();
        }
        
        // فلتر المفضلة
        if (_showFavoritesOnly) {
          filteredSpots = filteredSpots.where((spot) => provider.isFavorite(spot.id)).toList();
        }

        if (filteredSpots.isEmpty) {
          return SliverFillRemaining(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _showFavoritesOnly ? Icons.favorite_border : Icons.search_off, 
                    size: 80, 
                    color: AppColors.outline.withOpacity(0.3)
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _showFavoritesOnly ? 'لا توجد أماكن مفضلة' : 'لا توجد نتائج للفلتر المحدد', 
                    style: TextStyle(fontSize: 16, color: AppColors.textSecondary)
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _selectedFilterRegion = null;
                        _selectedFilterCity = null;
                        _selectedCategory = null;
                        _showFavoritesOnly = false;
                      });
                    },
                    child: const Text('إزالة الفلتر'),
                  ),
                ],
              ),
            ),
          );
        }

        return SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final spot = filteredSpots[index];
                // إضافة أنيميشن بسيط عند الظهور (اختياري)
                return Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  // نفترض أن SpotCard تم تحديثه ليكون بدون حواف حادة وظل ناعم
                  child: SpotCard(
                    spot: spot,
                    onTap: () => _showSpotDetails(spot),
                  ),
                );
              },
              childCount: filteredSpots.length,
            ),
          ),
        );
      },
    );
  }

  // --- شريط التنقل السفلي الفخم ---
  Widget _buildLuxuriousBottomNav() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 30), // جعله عائماً
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          // الخلفية الزجاجية العائمة
          ClipRRect(
            borderRadius: BorderRadius.circular(35), // زوايا أكثر استدارة
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
              child: Container(
                height: 75,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.85),
                  borderRadius: BorderRadius.circular(35),
                  border: Border.all(color: Colors.white.withOpacity(0.6), width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 25,
                      offset: const Offset(0, 10),
                      spreadRadius: -5,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildNavItem(icon: Icons.map_outlined, activeIcon: Icons.map_rounded, label: 'الخريطة', index: 0),
                    const SizedBox(width: 40), // مسافة للزر العائم
                    _buildNavItem(icon: Icons.grid_view, activeIcon: Icons.grid_view_rounded, label: 'الرئيسية', index: 1),
                  ],
                ),
              ),
            ),
          ),
          
          // الزر العائم المركزي (الجوهرة)
          Positioned(
            top: -25, // يرفع الزر قليلاً للخروج من البار
            child: GestureDetector(
              onTap: _navigateToAddSpot,
              child: ScaleTransition(
                scale: _fabAnimationController,
                child: Container(
                  width: 65,
                  height: 65,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    // تدرج لوني فخم
                    gradient: LinearGradient(
                      colors: [AppColors.primary, AppColors.primary.withOpacity(0.8)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.5),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                      BoxShadow(
                        color: Colors.white.withOpacity(0.5),
                        blurRadius: 0,
                        spreadRadius: 2, // حدود داخلية بيضاء
                        offset: Offset.zero,
                      )
                    ],
                  ),
                  child: const Icon(Icons.add_rounded, color: Colors.white, size: 34),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({required IconData icon, required IconData activeIcon, required String label, required int index}) {
    final isActive = _currentIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primary.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isActive ? activeIcon : icon,
              color: isActive ? AppColors.primary : AppColors.textTertiary,
              size: 26,
            ),
            if (isActive) ...[
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                  fontFamily: 'Cairo',
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }

  // --- الخريطة والدوال المساعدة كما هي مع تحسين بسيط ---
  Widget _buildMapView() {
     // ... (نفس الكود السابق مع تغيير لون الخلفية)
    return Center(child: Text("الخريطة قريباً", style: TextStyle(color: AppColors.textPrimary)));
  }
  
  // دالة التفاصيل كما هي
  void _showSpotDetails(CampingSpot spot) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => SpotDetailsScreen(spot: spot)),
    );
  }

  Future<void> _navigateToAddSpot() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddSpotScreen()),
    );
    if (result == true && mounted) {
      await context.read<SpotsProvider>().fetchSpots();
    }
  }

  Widget _buildFilterButton() {
    final hasFilter = _selectedFilterRegion != null || _selectedFilterCity != null;
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _showFilterDialog,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: hasFilter ? AppColors.primary : Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.filter_list_rounded,
                color: hasFilter ? Colors.white : AppColors.textPrimary,
                size: 20,
              ),
              if (hasFilter) ..[
                const SizedBox(width: 4),
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '1',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showFilterDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.filter_list_rounded, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Text(
                    'فلترة حسب الموقع',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              
              // اختيار المنطقة
              DropdownButtonFormField<String>(
                value: _selectedFilterRegion,
                decoration: InputDecoration(
                  labelText: 'المنطقة',
                  filled: true,
                  fillColor: AppColors.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                items: [
                  const DropdownMenuItem(value: null, child: Text('الكل')),
                  ...SaudiCities.getRegions().map((region) {
                    return DropdownMenuItem(
                      value: region,
                      child: Text(region),
                    );
                  }),
                ],
                onChanged: (value) {
                  setModalState(() {
                    _selectedFilterRegion = value;
                    _selectedFilterCity = null;
                  });
                },
              ),
              
              const SizedBox(height: 16),
              
              // اختيار المدينة
              DropdownButtonFormField<String>(
                value: _selectedFilterCity,
                decoration: InputDecoration(
                  labelText: 'المدينة',
                  filled: true,
                  fillColor: AppColors.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                items: [
                  const DropdownMenuItem(value: null, child: Text('الكل')),
                  if (_selectedFilterRegion != null)
                    ...SaudiCities.getCitiesByRegion(_selectedFilterRegion!).map((city) {
                      return DropdownMenuItem(
                        value: city,
                        child: Text(city),
                      );
                    }),
                ],
                onChanged: _selectedFilterRegion == null
                    ? null
                    : (value) {
                        setModalState(() {
                          _selectedFilterCity = value;
                        });
                      },
              ),
              
              const SizedBox(height: 24),
              
              // أزرار التحكم
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        setModalState(() {
                          _selectedFilterRegion = null;
                          _selectedFilterCity = null;
                        });
                        setState(() {});
                      },
                      child: const Text('إعادة تعيين'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {});
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text('تطبيق'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterButton() {
    final hasFilter = _selectedFilterRegion != null || _selectedFilterCity != null;
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _showFilterDialog,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: hasFilter ? AppColors.primary : Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.filter_list_rounded,
                color: hasFilter ? Colors.white : AppColors.textPrimary,
                size: 20,
              ),
              if (hasFilter) ...[
                const SizedBox(width: 4),
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '1',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showFilterDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.filter_list_rounded, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Text(
                    'فلترة حسب الموقع',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              
              // اختيار المنطقة
              DropdownButtonFormField<String>(
                value: _selectedFilterRegion,
                decoration: InputDecoration(
                  labelText: 'المنطقة',
                  filled: true,
                  fillColor: AppColors.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                items: [
                  const DropdownMenuItem(value: null, child: Text('الكل')),
                  ...SaudiCities.getRegions().map((region) {
                    return DropdownMenuItem(
                      value: region,
                      child: Text(region),
                    );
                  }),
                ],
                onChanged: (value) {
                  setModalState(() {
                    _selectedFilterRegion = value;
                    _selectedFilterCity = null;
                  });
                },
              ),
              
              const SizedBox(height: 16),
              
              // اختيار المدينة
              DropdownButtonFormField<String>(
                value: _selectedFilterCity,
                decoration: InputDecoration(
                  labelText: 'المدينة',
                  filled: true,
                  fillColor: AppColors.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                items: [
                  const DropdownMenuItem(value: null, child: Text('الكل')),
                  if (_selectedFilterRegion != null)
                    ...SaudiCities.getCitiesByRegion(_selectedFilterRegion!).map((city) {
                      return DropdownMenuItem(
                        value: city,
                        child: Text(city),
                      );
                    }),
                ],
                onChanged: _selectedFilterRegion == null
                    ? null
                    : (value) {
                        setModalState(() {
                          _selectedFilterCity = value;
                        });
                      },
              ),
              
              const SizedBox(height: 24),
              
              // أزرار التحكم
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        setModalState(() {
                          _selectedFilterRegion = null;
                          _selectedFilterCity = null;
                        });
                        setState(() {});
                      },
                      child: const Text('إعادة تعيين'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {});
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text('تطبيق'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
     return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.terrain_outlined, size: 80, color: AppColors.outline.withOpacity(0.3)),
          const SizedBox(height: 16),
          Text('لا توجد كشتات حالياً', style: TextStyle(fontSize: 16, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

// Delegate للتاقات الثابتة
class _TagsHeaderDelegate extends SliverPersistentHeaderDelegate {
  final List<String> tags;
  final int selectedIndex;
  final Function(int) onTagSelected;

  _TagsHeaderDelegate({
    required this.tags,
    required this.selectedIndex,
    required this.onTagSelected,
  });

  @override
  double get minExtent => 70;

  @override
  double get maxExtent => 70;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Material(
      elevation: 4,
      color: AppColors.background,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: tags.length,
          itemBuilder: (context, index) {
            final isSelected = selectedIndex == index;
            return GestureDetector(
              onTap: () => onTagSelected(index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeOutCubic,
                margin: const EdgeInsets.only(left: 12),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                decoration: BoxDecoration(
                  gradient: isSelected
                      ? LinearGradient(
                          colors: [AppColors.primary, AppColors.earth],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : LinearGradient(
                          colors: [Colors.white, Colors.white.withOpacity(0.5)],
                        ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.4),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          )
                        ]
                      : [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.03),
                            blurRadius: 5,
                            offset: const Offset(0, 2),
                          )
                        ],
                ),
                child: Center(
                  child: Text(
                    tags[index],
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
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

  @override
  bool shouldRebuild(_TagsHeaderDelegate oldDelegate) {
    return selectedIndex != oldDelegate.selectedIndex;
  }
}