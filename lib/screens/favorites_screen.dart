import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme/app_colors.dart';
import '../providers/spots_provider.dart';
import '../widgets/spot_card.dart';
import 'spot_details_screen.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // App Bar مع Tabs
          Container(
            color: AppColors.surface,
            child: SafeArea(
              bottom: false,
              child: Column(
                children: [
                  // العنوان
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        Icon(Icons.bookmark, color: AppColors.primary, size: 28),
                        const SizedBox(width: 8),
                        Text(
                          'المحفوظات والمفضلة',
                          style: GoogleFonts.cairo(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // التبويبات
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TabBar(
                      controller: _tabController,
                      indicator: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      labelColor: Colors.white,
                      unselectedLabelColor: AppColors.textSecondary,
                      labelStyle: GoogleFonts.cairo(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                      unselectedLabelStyle: GoogleFonts.cairo(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                      indicatorSize: TabBarIndicatorSize.tab,
                      dividerColor: Colors.transparent,
                      tabs: [
                        Tab(
                          icon: Icon(Icons.favorite),
                          text: 'المفضلة',
                        ),
                        Tab(
                          icon: Icon(Icons.bookmark),
                          text: 'المحفوظات',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
          
          // المحتوى
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildFavoritesTab(),
                _buildSavedTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFavoritesTab() {
    return Consumer<SpotsProvider>(
      builder: (context, provider, _) {
        final favoriteSpots = provider.spots
            .where((spot) => provider.isFavorite(spot.id))
            .toList();
        
        if (favoriteSpots.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.favorite_border,
                  size: 100,
                  color: AppColors.textTertiary.withOpacity(0.3),
                ),
                const SizedBox(height: 16),
                Text(
                  'لا توجد أماكن مفضلة',
                  style: GoogleFonts.cairo(
                    fontSize: 18,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'اضغط على ❤️ في أي مكان لإضافته للمفضلة',
                  style: GoogleFonts.cairo(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }
        
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: favoriteSpots.length,
          itemBuilder: (context, index) {
            final spot = favoriteSpots[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: SpotCard(
                spot: spot,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => SpotDetailsScreen(spot: spot),
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSavedTab() {
    return Consumer<SpotsProvider>(
      builder: (context, provider, _) {
        final savedSpots = provider.spots
            .where((spot) => provider.isSaved(spot.id))
            .toList();
        
        if (savedSpots.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.bookmark_border,
                  size: 100,
                  color: AppColors.textTertiary.withOpacity(0.3),
                ),
                const SizedBox(height: 16),
                Text(
                  'لا توجد أماكن محفوظة',
                  style: GoogleFonts.cairo(
                    fontSize: 18,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'اضغط على 🔖 في أي مكان لحفظه',
                  style: GoogleFonts.cairo(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }
        
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: savedSpots.length,
          itemBuilder: (context, index) {
            final spot = savedSpots[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: SpotCard(
                spot: spot,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => SpotDetailsScreen(spot: spot),
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }
}
