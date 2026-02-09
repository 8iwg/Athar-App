import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' hide Path;
import 'package:url_launcher/url_launcher.dart';
import 'package:geolocator/geolocator.dart';
import '../core/theme/app_colors.dart';
import '../models/camping_spot.dart';
import '../providers/spots_provider.dart';
import '../providers/auth_provider.dart';
import '../data/saudi_cities.dart';
import '../services/ad_service.dart';
import 'spot_details_screen.dart';

class CustomMapScreen extends StatefulWidget {
  const CustomMapScreen({Key? key}) : super(key: key);

  @override
  State<CustomMapScreen> createState() => _CustomMapScreenState();
}

class _CustomMapScreenState extends State<CustomMapScreen> with TickerProviderStateMixin {
  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();
  String? _selectedCategory;
  String? _selectedRegion;
  String? _selectedCity;
  bool _isSatelliteView = true;
  bool _showSearch = false;
  List<CampingSpot> _searchResults = [];
  CampingSpot? _selectedSpot;
  
  // متغيرات المسار
  LatLng? _currentLocation;
  List<LatLng> _routePoints = [];
  bool _isLoadingRoute = false;
  String? _routeDistance;
  String? _routeDuration;
  List<String> _routeInstructions = [];
  
  // متغيرات الأنيميشن
  late AnimationController _pulseController;
  late AnimationController _markerController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _markerAnimation;
  
  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    
    _markerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    
    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    
    _markerAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _markerController, curve: Curves.elasticOut),
    );
    
    _markerController.forward();
  }
  
  @override
  void dispose() {
    _searchController.dispose();
    _pulseController.dispose();
    _markerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final spots = Provider.of<SpotsProvider>(context).spots;
    var filteredSpots = spots;
    
    // تصفية حسب الفئة
    if (_selectedCategory != null) {
      filteredSpots = filteredSpots.where((s) => s.category == _selectedCategory).toList();
    }
    
    // تصفية حسب المنطقة
    if (_selectedRegion != null) {
      filteredSpots = filteredSpots.where((s) => s.region == _selectedRegion).toList();
    }
    
    // تصفية حسب المدينة
    if (_selectedCity != null) {
      filteredSpots = filteredSpots.where((s) => s.city == _selectedCity).toList();
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // الخريطة الحقيقية من OpenStreetMap
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: const LatLng(24.7136, 46.6753), // الرياض
              initialZoom: 6.0,
              minZoom: 5.0,
              maxZoom: 18.0,
            ),
            children: [
              // طبقة الخريطة - قمر صناعي أو عادية
              TileLayer(
                urlTemplate: _isSatelliteView
                    ? 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}'
                    : 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.atharmaps.app',
                maxZoom: 19,
              ),
              
              // طبقة الأسماء والطرق (فوق القمر الصناعي)
              if (_isSatelliteView)
                TileLayer(
                  urlTemplate: 'https://tiles.stadiamaps.com/tiles/stamen_terrain_labels/{z}/{x}/{y}{r}.png',
                  userAgentPackageName: 'com.atharmaps.app',
                  maxZoom: 19,
                ),
              
              // رسم المسار
              if (_routePoints.isNotEmpty)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: _routePoints,
                      strokeWidth: 5.0,
                      color: AppColors.primary,
                      borderStrokeWidth: 2.0,
                      borderColor: Colors.white,
                    ),
                  ],
                ),
              
              // علامة الموقع الحالي مع تأثير نابض
              if (_currentLocation != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _currentLocation!,
                      width: 80,
                      height: 80,
                      child: AnimatedBuilder(
                        animation: _pulseAnimation,
                        builder: (context, child) {
                          return Stack(
                            alignment: Alignment.center,
                            children: [
                              // الدائرة الخارجية النابضة
                              Transform.scale(
                                scale: _pulseAnimation.value,
                                child: Container(
                                  width: 60,
                                  height: 60,
                                  decoration: BoxDecoration(
                                    color: Colors.blue.withOpacity(0.2),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.blue.withOpacity(0.4),
                                      width: 2,
                                    ),
                                  ),
                                ),
                              ),
                              // النقطة المركزية
                              Container(
                                width: 20,
                                height: 20,
                                decoration: BoxDecoration(
                                  color: Colors.blue,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 3),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.blue.withOpacity(0.5),
                                      blurRadius: 10,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ],
                ),
              
              // علامات الأماكن مع أنيميشن
              MarkerLayer(
                markers: filteredSpots.map((spot) {
                  final isSelected = _selectedSpot?.id == spot.id;
                  return Marker(
                    point: LatLng(spot.latitude, spot.longitude),
                    width: isSelected ? 70 : 50,
                    height: isSelected ? 70 : 50,
                    child: GestureDetector(
                      onTap: () {
                        // فتح صفحة التفاصيل الكاملة مباشرة
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => SpotDetailsScreen(spot: spot),
                          ),
                        );
                      },
                      child: TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0.0, end: 1.0),
                        duration: Duration(milliseconds: 300 + (filteredSpots.indexOf(spot) * 50)),
                        curve: Curves.elasticOut,
                        builder: (context, value, child) {
                          return Transform.scale(
                            scale: value,
                            child: Column(
                              children: [
                                Container(
                                  width: isSelected ? 56 : 42,
                                  height: isSelected ? 56 : 42,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.primary.withOpacity(0.6),
                                        blurRadius: isSelected ? 20 : 10,
                                        spreadRadius: isSelected ? 4 : 2,
                                      ),
                                    ],
                                    border: Border.all(
                                      color: Colors.white,
                                      width: isSelected ? 3.5 : 2.5,
                                    ),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(6),
                                    child: spot.imageUrls.isNotEmpty
                                        ? Image.network(
                                            spot.imageUrls.first,
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, __, ___) => Container(
                                              color: _getCategoryColor(spot.category),
                                              child: Icon(
                                                _getCategoryIcon(spot.category),
                                                color: Colors.white,
                                                size: isSelected ? 24 : 18,
                                              ),
                                            ),
                                          )
                                        : Container(
                                            color: _getCategoryColor(spot.category),
                                            child: Icon(
                                              _getCategoryIcon(spot.category),
                                              color: Colors.white,
                                              size: isSelected ? 24 : 18,
                                            ),
                                          ),
                                  ),
                                ),
                                Container(
                                  width: 2,
                                  height: 6,
                                  color: AppColors.primary,
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),

          // Header مع البحث
          SafeArea(
            child: Column(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  decoration: BoxDecoration(
                    color: AppColors.surface.withOpacity(0.95),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.shadow,
                        blurRadius: 20,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [AppColors.primary, AppColors.earth],
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.satellite_alt_rounded,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'خريطة السعودية',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                Text(
                                  '${filteredSpots.length} مكان • القمر الصناعي',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.search_rounded,
                              color: _showSearch ? AppColors.primary : AppColors.textSecondary,
                            ),
                            onPressed: () {
                              setState(() => _showSearch = !_showSearch);
                            },
                          ),
                          IconButton(
                            icon: Icon(
                              _isSatelliteView ? Icons.map_rounded : Icons.satellite_rounded,
                              color: AppColors.primary,
                            ),
                            onPressed: () {
                              setState(() => _isSatelliteView = !_isSatelliteView);
                            },
                          ),
                        ],
                      ),
                      if (_showSearch) ...[
                        const SizedBox(height: 12),
                        TextField(
                          controller: _searchController,
                          onChanged: (value) => _searchSpots(value, spots),
                          decoration: InputDecoration(
                            hintText: 'ابحث عن مكان...',
                            prefixIcon: const Icon(Icons.search, color: AppColors.primary),
                            suffixIcon: _searchController.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear),
                                    onPressed: () {
                                      _searchController.clear();
                                      setState(() => _searchResults.clear());
                                    },
                                  )
                                : null,
                            filled: true,
                            fillColor: AppColors.background.withOpacity(0.5),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                        ),
                      ],
                      if (_searchResults.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Container(
                          constraints: const BoxConstraints(maxHeight: 200),
                          decoration: BoxDecoration(
                            color: AppColors.background.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ListView.builder(
                            shrinkWrap: true,
                            itemCount: _searchResults.length,
                            itemBuilder: (context, index) {
                              final spot = _searchResults[index];
                              return ListTile(
                                leading: Icon(
                                  _getCategoryIcon(spot.category),
                                  color: _getCategoryColor(spot.category),
                                ),
                                title: Text(spot.name),
                                subtitle: Text(spot.category),
                                onTap: () {
                                  _mapController.move(
                                    LatLng(spot.latitude, spot.longitude),
                                    15.0,
                                  );
                                  setState(() {
                                    _selectedSpot = spot;
                                    _showSearch = false;
                                    _searchResults.clear();
                                    _searchController.clear();
                                  });
                                  _showSpotDetails(spot);
                                },
                              );
                            },
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                
                // زر التصفية الشامل
                _buildFilterButton(),
              ],
            ),
          ),

          // أزرار التحكم المحسّنة
          Positioned(
            bottom: 140,
            right: 16,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // البوصلة
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Icon(
                        Icons.navigation_rounded,
                        color: AppColors.primary,
                        size: 30,
                      ),
                      Positioned(
                        top: 8,
                        child: Text(
                          'N',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: AppColors.error,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                // زر الموقع
                FloatingActionButton(
                  heroTag: 'location',
                  onPressed: _getCurrentLocation,
                  backgroundColor: AppColors.primary,
                  child: const Icon(Icons.my_location_rounded, color: Colors.white),
                ),
                const SizedBox(height: 12),
                // زر التكبير
                FloatingActionButton.small(
                  heroTag: 'zoom_in',
                  onPressed: () {
                    final currentZoom = _mapController.camera.zoom;
                    _mapController.move(
                      _mapController.camera.center,
                      currentZoom + 1,
                    );
                  },
                  backgroundColor: Colors.white,
                  child: Icon(Icons.add, color: AppColors.primary),
                ),
                const SizedBox(height: 8),
                // زر التصغير
                FloatingActionButton.small(
                  heroTag: 'zoom_out',
                  onPressed: () {
                    final currentZoom = _mapController.camera.zoom;
                    _mapController.move(
                      _mapController.camera.center,
                      currentZoom - 1,
                    );
                  },
                  backgroundColor: Colors.white,
                  child: Icon(Icons.remove, color: AppColors.primary),
                ),
              ],
            ),
          ),

          // معلومات المسار
          if (_routePoints.isNotEmpty)
            Positioned(
              top: 300,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.shadow,
                      blurRadius: 15,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'المسار',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: AppColors.error),
                          onPressed: () {
                            setState(() {
                              _routePoints.clear();
                              _routeDistance = null;
                              _routeDuration = null;
                              _routeInstructions.clear();
                            });
                          },
                        ),
                      ],
                    ),
                    if (_routeDistance != null) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.straighten, size: 18, color: AppColors.primary),
                          const SizedBox(width: 8),
                          Text('المسافة: $_routeDistance'),
                        ],
                      ),
                    ],
                    if (_routeDuration != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.schedule, size: 18, color: AppColors.primary),
                          const SizedBox(width: 8),
                          Text('المدة: $_routeDuration'),
                        ],
                      ),
                    ],
                    if (_routeInstructions.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      const Text(
                        'التعليمات:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        constraints: const BoxConstraints(maxHeight: 150),
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: _routeInstructions.length > 5 ? 5 : _routeInstructions.length,
                          itemBuilder: (context, index) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${index + 1}.',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _routeInstructions[index],
                                      style: const TextStyle(fontSize: 13),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

          // مؤشر التحميل
          if (_isLoadingRoute)
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.3),
                child: const Center(
                  child: CircularProgressIndicator(
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),


        ],
      ),
    );
  }

  Widget _buildFilterButton() {
    final hasFilters = _selectedCategory != null || _selectedRegion != null || _selectedCity != null;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: _showFilterSheet,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: hasFilters 
                ? AppColors.primary.withOpacity(0.1) 
                : AppColors.surface.withOpacity(0.95),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: hasFilters ? AppColors.primary : AppColors.surface,
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.shadow,
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: hasFilters
                      ? LinearGradient(
                          colors: [AppColors.primary, AppColors.earth],
                        )
                      : LinearGradient(
                          colors: [AppColors.textSecondary, AppColors.textTertiary],
                        ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.filter_list_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'تصفية الأماكن',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (hasFilters) ...[
                      const SizedBox(height: 4),
                      Text(
                        _getFilterSummary(),
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ] else
                      Text(
                        'اختر الفئة، المنطقة، أو المدينة',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                color: AppColors.textSecondary,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  String _getFilterSummary() {
    List<String> filters = [];
    if (_selectedCategory != null) filters.add(_selectedCategory!);
    if (_selectedRegion != null) filters.add(_selectedRegion!);
    if (_selectedCity != null) filters.add(_selectedCity!);
    return filters.join(' • ');
  }
  
  void _showFilterSheet() {
    final spots = Provider.of<SpotsProvider>(context, listen: false).spots;
    final categories = spots.map((s) => s.category).toSet().toList()..sort();
    final regions = SaudiCities.regionsWithCities.keys.toList()..sort();
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder: (context, scrollController) => Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              children: [
                // Handle bar
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  width: 50,
                  height: 5,
                  decoration: BoxDecoration(
                    color: AppColors.divider,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                
                // Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'تصفية الأماكن',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      if (_selectedCategory != null || _selectedRegion != null || _selectedCity != null)
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _selectedCategory = null;
                              _selectedRegion = null;
                              _selectedCity = null;
                            });
                            setModalState(() {});
                          },
                          child: Text(
                            'مسح الكل',
                            style: TextStyle(
                              color: AppColors.error,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                
                Divider(color: AppColors.divider, height: 1),
                
                // Content
                Expanded(
                  child: ListView(
                    controller: scrollController,
                    padding: const EdgeInsets.all(20),
                    children: [
                      // الفئات
                      _buildFilterSection(
                        title: 'الفئة',
                        icon: Icons.category_rounded,
                        items: ['الكل', ...categories],
                        selectedItem: _selectedCategory,
                        onSelect: (value) {
                          setState(() {
                            _selectedCategory = value == 'الكل' ? null : value;
                          });
                          setModalState(() {});
                        },
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // المناطق
                      _buildFilterSection(
                        title: 'المنطقة',
                        icon: Icons.location_city_rounded,
                        items: ['الكل', ...regions],
                        selectedItem: _selectedRegion,
                        onSelect: (value) {
                          setState(() {
                            _selectedRegion = value == 'الكل' ? null : value;
                            _selectedCity = null; // إعادة تعيين المدينة
                          });
                          setModalState(() {});
                        },
                      ),
                      
                      // المدن (تظهر فقط عند اختيار منطقة)
                      if (_selectedRegion != null) ...[
                        const SizedBox(height: 24),
                        _buildFilterSection(
                          title: 'المدينة',
                          icon: Icons.location_on_rounded,
                          items: ['الكل', ...SaudiCities.regionsWithCities[_selectedRegion!]!],
                          selectedItem: _selectedCity,
                          onSelect: (value) {
                            setState(() {
                              _selectedCity = value == 'الكل' ? null : value;
                            });
                            setModalState(() {});
                          },
                        ),
                      ],
                      
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
                
                // Footer buttons
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, -5),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'تطبيق التصفية',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildFilterSection({
    required String title,
    required IconData icon,
    required List<String> items,
    required String? selectedItem,
    required Function(String) onSelect,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: AppColors.textSecondary),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: items.map((item) {
            final isSelected = (item == 'الكل' && selectedItem == null) || 
                               (selectedItem == item);
            return GestureDetector(
              onTap: () => onSelect(item),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  gradient: isSelected
                      ? LinearGradient(
                          colors: [AppColors.primary, AppColors.earth],
                        )
                      : null,
                  color: isSelected ? null : AppColors.background,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected 
                        ? Colors.transparent 
                        : AppColors.divider,
                    width: 1,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          )
                        ]
                      : null,
                ),
                child: Text(
                  item,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    color: isSelected ? Colors.white : AppColors.textPrimary,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  void _searchSpots(String query, List<CampingSpot> spots) {
    if (query.isEmpty) {
      setState(() => _searchResults.clear());
      return;
    }
    
    final results = spots.where((spot) {
      return spot.name.contains(query) ||
             spot.description.contains(query) ||
             spot.category.contains(query);
    }).take(5).toList();
    
    setState(() => _searchResults = results);
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'كشتة': return Colors.orange;
      case 'مخيم': return Colors.green;
      case 'استراحة': return Colors.amber;
      case 'منتزه': return Colors.cyan;
      case 'جبال': return Colors.purple;
      case 'وديان': return Colors.blue;
      case 'شواطئ': return Colors.lightBlue;
      default: return AppColors.primary;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'كشتة': return Icons.local_fire_department_rounded;
      case 'مخيم': return Icons.nights_stay_rounded;
      case 'استراحة': return Icons.home_rounded;
      case 'منتزه': return Icons.park_rounded;
      case 'جبال': return Icons.terrain_rounded;
      case 'وديان': return Icons.water_rounded;
      case 'شواطئ': return Icons.beach_access_rounded;
      default: return Icons.place_rounded;
    }
  }



  // الحصول على الموقع الحالي
  Future<void> _getCurrentLocation() async {
    try {
      // التحقق من الصلاحيات
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('يجب السماح بالوصول للموقع'),
                backgroundColor: AppColors.error,
              ),
            );
          }
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('صلاحية الموقع محظورة. يرجى تفعيلها من الإعدادات'),
              backgroundColor: AppColors.error,
            ),
          );
        }
        return;
      }

      // الحصول على الموقع
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _currentLocation = LatLng(position.latitude, position.longitude);
      });

      // التحرك للموقع الحالي
      _mapController.move(_currentLocation!, 15.0);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم تحديد موقعك الحالي'),
            backgroundColor: AppColors.success,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في الحصول على الموقع: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  // رسم المسار (خط مباشر للويب)
  Future<void> _drawRoute(CampingSpot spot) async {
    if (_currentLocation == null) {
      await _getCurrentLocation();
      if (_currentLocation == null) return;
    }

    setState(() {
      _isLoadingRoute = true;
    });

    try {
      // حساب المسافة المباشرة
      final distance = Geolocator.distanceBetween(
        _currentLocation!.latitude,
        _currentLocation!.longitude,
        spot.latitude,
        spot.longitude,
      );

      // رسم خط مباشر بين النقطتين
      final points = [
        _currentLocation!,
        LatLng(spot.latitude, spot.longitude),
      ];

      // حساب الوقت المقدر (بسرعة 60 كم/ساعة)
      final distanceKm = distance / 1000;
      final durationMinutes = (distanceKm / 60) * 60;

      // إنشاء تعليمات بسيطة
      final instructions = [
        'ابدأ من موقعك الحالي',
        'اتجه نحو ${spot.name}',
        'المسافة المباشرة: ${distanceKm.toStringAsFixed(1)} كم',
        'الوقت المقدر: ${durationMinutes.toStringAsFixed(0)} دقيقة',
        'ملاحظة: هذا مسار تقريبي مباشر',
      ];

      setState(() {
        _routePoints = points;
        _routeDistance = '${distanceKm.toStringAsFixed(1)} كم';
        _routeDuration = '${durationMinutes.toStringAsFixed(0)} دقيقة';
        _routeInstructions = instructions;
        _isLoadingRoute = false;
      });

      // التحرك لعرض المسار كاملاً
      _fitRouteBounds();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم رسم المسار التقريبي'),
            backgroundColor: AppColors.success,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoadingRoute = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('حدث خطأ في رسم المسار'),
            backgroundColor: AppColors.error,
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  // ضبط حدود الخريطة لعرض المسار كاملاً
  void _fitRouteBounds() {
    if (_routePoints.isEmpty) return;

    double minLat = _routePoints[0].latitude;
    double maxLat = _routePoints[0].latitude;
    double minLng = _routePoints[0].longitude;
    double maxLng = _routePoints[0].longitude;

    for (var point in _routePoints) {
      if (point.latitude < minLat) minLat = point.latitude;
      if (point.latitude > maxLat) maxLat = point.latitude;
      if (point.longitude < minLng) minLng = point.longitude;
      if (point.longitude > maxLng) maxLng = point.longitude;
    }

    final centerLat = (minLat + maxLat) / 2;
    final centerLng = (minLng + maxLng) / 2;

    _mapController.move(LatLng(centerLat, centerLng), 12.0);
  }

  void _showSpotDetails(CampingSpot spot) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        minChildSize: 0.3,
        maxChildSize: 0.8,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.all(20),
          child: ListView(
            controller: scrollController,
            children: [
              Center(
                child: Container(
                  width: 50,
                  height: 5,
                  decoration: BoxDecoration(
                    color: AppColors.divider,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                spot.name,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.star, color: AppColors.warning, size: 20),
                  const SizedBox(width: 4),
                  Text('${spot.rating}'),
                  const SizedBox(width: 16),
                  Icon(Icons.favorite, color: AppColors.error, size: 20),
                  const SizedBox(width: 4),
                  Text('${spot.likes}'),
                ],
              ),
              const SizedBox(height: 16),
              Text(spot.description),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _showNavigationOptions(spot),
                      icon: const Icon(Icons.navigation_rounded),
                      label: const Text('دلني'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => SpotDetailsScreen(spot: spot),
                          ),
                        );
                      },
                      icon: const Icon(Icons.visibility_rounded),
                      label: const Text('التفاصيل'),
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
  
  void _showNavigationOptions(CampingSpot spot) async {
    Navigator.pop(context); // إغلاق نافذة التفاصيل
    
    // عرض الإعلان أولاً
    await AdService().showInterstitialAdIfReady(
      onAdClosed: () {
        // بعد إغلاق الإعلان، عرض قائمة الخيارات
        _showNavigationOptionsDialog(spot);
      },
      frequency: 3, // كل 3 مرات
    );
  }
  
  void _showNavigationOptionsDialog(CampingSpot spot) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              width: 50,
              height: 5,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            
            Text(
              'اختر تطبيق التنقل',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Google Maps
            _buildNavigationOption(
              icon: Icons.map_rounded,
              title: 'Google Maps',
              subtitle: 'مسار مفصل مع تعليمات صوتية',
              color: const Color(0xFF4285F4),
              onTap: () {
                Navigator.pop(context);
                _openGoogleMaps(spot);
              },
            ),
            
            const SizedBox(height: 12),
            
            // Waze
            _buildNavigationOption(
              icon: Icons.navigation_rounded,
              title: 'Waze',
              subtitle: 'تنبيهات فورية عن الزحام والمرور',
              color: const Color(0xFF33CCFF),
              onTap: () {
                Navigator.pop(context);
                _openWaze(spot);
              },
            ),
            
            const SizedBox(height: 12),
            
            // Apple Maps
            _buildNavigationOption(
              icon: Icons.explore_rounded,
              title: 'Apple Maps',
              subtitle: 'خرائط آبل لأجهزة iOS',
              color: const Color(0xFF007AFF),
              onTap: () {
                Navigator.pop(context);
                _openAppleMaps(spot);
              },
            ),
            
            const SizedBox(height: 12),
            
            // مسار تقريبي داخل التطبيق
            _buildNavigationOption(
              icon: Icons.route_rounded,
              title: 'مسار تقريبي',
              subtitle: 'عرض المسافة المباشرة علي الخريطة',
              color: AppColors.primary,
              onTap: () {
                Navigator.pop(context);
                _drawRoute(spot);
              },
            ),
            
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
  
  Widget _buildNavigationOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, color: color, size: 16),
          ],
        ),
      ),
    );
  }
  
  Future<void> _openGoogleMaps(CampingSpot spot) async {
    final lat = spot.latitude;
    final lng = spot.longitude;
    final name = Uri.encodeComponent(spot.name);
    
    // Google Maps URL مع اللغة العربية
    final url = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng&destination_place_id=$name&travelmode=driving&hl=ar'
    );
    
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        // محاولة فتح الرابط مباشرة
        await launchUrl(url, mode: LaunchMode.platformDefault);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('لم يتمكن من فتح Google Maps: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
  
  Future<void> _openWaze(CampingSpot spot) async {
    final lat = spot.latitude;
    final lng = spot.longitude;
    
    // Waze URL مع اللغة العربية
    final url = Uri.parse(
      'https://waze.com/ul?ll=$lat,$lng&navigate=yes&lang=ar'
    );
    
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        await launchUrl(url, mode: LaunchMode.platformDefault);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('لم يتمكن من فتح Waze: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
  
  Future<void> _openAppleMaps(CampingSpot spot) async {
    final lat = spot.latitude;
    final lng = spot.longitude;
    
    // Apple Maps URL
    final url = Uri.parse(
      'https://maps.apple.com/?daddr=$lat,$lng&dirflg=d&t=m'
    );
    
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        await launchUrl(url, mode: LaunchMode.platformDefault);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('لم يتمكن من فتح Apple Maps: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  // فتح تطبيق الخرائط مع التنقل والتعليمات الصوتية بالعربي
  Future<void> _openNavigation(CampingSpot spot) async {
    final lat = spot.latitude;
    final lng = spot.longitude;
    final name = Uri.encodeComponent(spot.name);

    // إغلاق النافذة السفلية
    Navigator.pop(context);

    // محاولة فتح تطبيقات الخرائط بالترتيب
    // Google Maps مع اللغة العربية
    final googleMapsUrl = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng&destination_place_id=$name&travelmode=driving&hl=ar'
    );
    
    // Apple Maps
    final appleMapsUrl = Uri.parse(
      'https://maps.apple.com/?daddr=$lat,$lng&dirflg=d&t=m'
    );
    
    // Waze مع اللغة العربية
    final wazeUrl = Uri.parse(
      'https://waze.com/ul?ll=$lat,$lng&navigate=yes&lang=ar'
    );

    try {
      // محاولة فتح Google Maps أولاً
      if (await canLaunchUrl(googleMapsUrl)) {
        await launchUrl(
          googleMapsUrl,
          mode: LaunchMode.externalApplication,
        );
      } 
      // إذا لم يتوفر، محاولة فتح Apple Maps
      else if (await canLaunchUrl(appleMapsUrl)) {
        await launchUrl(
          appleMapsUrl,
          mode: LaunchMode.externalApplication,
        );
      }
      // إذا لم يتوفر، محاولة فتح Waze
      else if (await canLaunchUrl(wazeUrl)) {
        await launchUrl(
          wazeUrl,
          mode: LaunchMode.externalApplication,
        );
      }
      // إذا لم يتوفر أي تطبيق، عرض رسالة
      else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('لم يتم العثور على تطبيق خرائط'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('حدث خطأ في فتح الخرائط: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
}

// رسم شكل تقريبي للسعودية
class SaudiMapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFB8956A).withOpacity(0.3)
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = const Color(0xFFB8956A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    // رسم شكل تقريبي للسعودية
    final path = Path();
    
    // بداية من الشمال الغربي
    path.moveTo(size.width * 0.15, size.height * 0.2);
    path.lineTo(size.width * 0.25, size.height * 0.15);
    path.lineTo(size.width * 0.45, size.height * 0.12);
    path.lineTo(size.width * 0.65, size.height * 0.18);
    path.lineTo(size.width * 0.75, size.height * 0.25);
    path.lineTo(size.width * 0.82, size.height * 0.35);
    path.lineTo(size.width * 0.85, size.height * 0.5);
    path.lineTo(size.width * 0.8, size.height * 0.65);
    path.lineTo(size.width * 0.7, size.height * 0.75);
    path.lineTo(size.width * 0.5, size.height * 0.78);
    path.lineTo(size.width * 0.3, size.height * 0.75);
    path.lineTo(size.width * 0.2, size.height * 0.65);
    path.lineTo(size.width * 0.15, size.height * 0.5);
    path.lineTo(size.width * 0.12, size.height * 0.35);
    path.close();

    canvas.drawPath(path, paint);
    canvas.drawPath(path, borderPaint);

    // رسم خطوط تمثل المناطق
    final regionPaint = Paint()
      ..color = const Color(0xFFB8956A).withOpacity(0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    // خطوط أفقية ورأسية لتمثيل المناطق
    for (int i = 1; i < 4; i++) {
      canvas.drawLine(
        Offset(size.width * 0.2, size.height * 0.2 + (size.height * 0.15 * i)),
        Offset(size.width * 0.8, size.height * 0.2 + (size.height * 0.15 * i)),
        regionPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
