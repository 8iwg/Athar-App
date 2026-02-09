import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/theme/app_colors.dart';
import '../models/camping_spot.dart';
import '../providers/spots_provider.dart';
import '../providers/auth_provider.dart';
import '../services/ad_service.dart';
import 'spot_details_screen.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({Key? key}) : super(key: key);

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final Completer<GoogleMapController> _controller = Completer();
  Set<Marker> _markers = {};
  Position? _currentPosition;
  bool _isLoading = true;
  MapType _currentMapType = MapType.hybrid; // القمر الصناعي مع الأسماء
  
  // موقع الرياض الافتراضي
  static const CameraPosition _initialPosition = CameraPosition(
    target: LatLng(24.7136, 46.6753),
    zoom: 11,
  );

  // ستايل الخريطة المخصص بألوان التطبيق
  static const String _mapStyle = '''
  [
    {
      "elementType": "geometry",
      "stylers": [{"color": "#f5f1ed"}]
    },
    {
      "elementType": "labels.icon",
      "stylers": [{"visibility": "off"}]
    },
    {
      "elementType": "labels.text.fill",
      "stylers": [{"color": "#8B7355"}]
    },
    {
      "elementType": "labels.text.stroke",
      "stylers": [{"color": "#f5f1ed"}]
    },
    {
      "featureType": "administrative.land_parcel",
      "elementType": "labels.text.fill",
      "stylers": [{"color": "#B8956A"}]
    },
    {
      "featureType": "poi",
      "elementType": "geometry",
      "stylers": [{"color": "#E8DCC8"}]
    },
    {
      "featureType": "poi",
      "elementType": "labels.text.fill",
      "stylers": [{"color": "#A68B5B"}]
    },
    {
      "featureType": "poi.park",
      "elementType": "geometry",
      "stylers": [{"color": "#C8B8A0"}]
    },
    {
      "featureType": "poi.park",
      "elementType": "labels.text.fill",
      "stylers": [{"color": "#8B7355"}]
    },
    {
      "featureType": "road",
      "elementType": "geometry",
      "stylers": [{"color": "#FFFFFF"}]
    },
    {
      "featureType": "road.arterial",
      "elementType": "geometry",
      "stylers": [{"color": "#F5EDE0"}]
    },
    {
      "featureType": "road.highway",
      "elementType": "geometry",
      "stylers": [{"color": "#B8956A"}]
    },
    {
      "featureType": "road.highway",
      "elementType": "geometry.stroke",
      "stylers": [{"color": "#A68B5B"}]
    },
    {
      "featureType": "road.highway.controlled_access",
      "elementType": "geometry",
      "stylers": [{"color": "#C9A86A"}]
    },
    {
      "featureType": "road.highway.controlled_access",
      "elementType": "geometry.stroke",
      "stylers": [{"color": "#B8956A"}]
    },
    {
      "featureType": "transit",
      "elementType": "geometry",
      "stylers": [{"color": "#E8DCC8"}]
    },
    {
      "featureType": "transit.station",
      "elementType": "labels.text.fill",
      "stylers": [{"color": "#A68B5B"}]
    },
    {
      "featureType": "water",
      "elementType": "geometry",
      "stylers": [{"color": "#A7C7E7"}]
    },
    {
      "featureType": "water",
      "elementType": "labels.text.fill",
      "stylers": [{"color": "#6B8BA3"}]
    }
  ]
  ''';

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    _loadSpots();
  }

  Future<void> _getCurrentLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() => _isLoading = false);
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      
      setState(() {
        _currentPosition = position;
      });

      final controller = await _controller.future;
      controller.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(position.latitude, position.longitude),
            zoom: 14,
          ),
        ),
      );
    } catch (e) {
      print('خطأ في الحصول على الموقع: $e');
    }
  }

  Future<void> _loadSpots() async {
    final spots = Provider.of<SpotsProvider>(context, listen: false).spots;
    
    Set<Marker> markers = {};
    
    for (var spot in spots) {
      markers.add(
        Marker(
          markerId: MarkerId(spot.id),
          position: LatLng(spot.latitude, spot.longitude),
          infoWindow: InfoWindow(
            title: spot.name,
            snippet: '${spot.category} • ${spot.likes} ❤️ • ${spot.rating} ⭐',
            onTap: () => _showSpotDetails(spot),
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            _getCategoryHue(spot.category),
          ),
          onTap: () => _showSpotDetails(spot),
        ),
      );
    }

    // إضافة marker للموقع الحالي
    if (_currentPosition != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('current_location'),
          position: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
          infoWindow: const InfoWindow(
            title: '📍 موقعك الحالي',
            snippet: 'أنت هنا',
          ),
        ),
      );
    }

    setState(() {
      _markers = markers;
      _isLoading = false;
    });
  }

  double _getCategoryHue(String category) {
    switch (category) {
      case 'كشتة':
        return BitmapDescriptor.hueOrange; // برتقالي
      case 'مخيم':
        return BitmapDescriptor.hueGreen; // أخضر
      case 'استراحة':
        return BitmapDescriptor.hueYellow; // أصفر
      case 'منتزه':
        return BitmapDescriptor.hueCyan; // سماوي
      case 'جبال':
        return BitmapDescriptor.hueViolet; // بنفسجي
      case 'وديان':
        return BitmapDescriptor.hueBlue; // أزرق
      case 'شواطئ':
        return BitmapDescriptor.hueAzure; // أزرق فاتح
      default:
        return BitmapDescriptor.hueRed; // أحمر افتراضي
    }
  }

  void _showSpotDetails(CampingSpot spot) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 20,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.all(20),
            children: [
              // Handle للسحب
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
              
              // صورة المكان
              if (spot.imageUrls.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: AspectRatio(
                    aspectRatio: 16 / 10,
                    child: spot.imageUrls.first.startsWith('http')
                        ? Image.network(
                            spot.imageUrls.first,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stack) => _buildImagePlaceholder(),
                          )
                        : _buildImagePlaceholder(),
                  ),
                )
              else
                _buildImagePlaceholder(),
              const SizedBox(height: 20),
              
              // الاسم والفئة
              Row(
                children: [
                  Expanded(
                    child: Text(
                      spot.name,
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(25),
                      border: Border.all(
                        color: AppColors.primary.withOpacity(0.3),
                        width: 1.5,
                      ),
                    ),
                    child: Text(
                      spot.category,
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // التقييم والإعجابات
              Row(
                children: [
                  _buildStatChip(
                    icon: Icons.star_rounded,
                    value: '${spot.rating}',
                    color: AppColors.warning,
                  ),
                  const SizedBox(width: 12),
                  _buildStatChip(
                    icon: Icons.favorite_rounded,
                    value: '${spot.likes}',
                    color: AppColors.error,
                  ),
                  const SizedBox(width: 12),
                  _buildStatChip(
                    icon: Icons.location_on_rounded,
                    value: spot.category,
                    color: AppColors.primary,
                  ),
                ],
              ),
              const SizedBox(height: 20),
              
              // الوصف
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  spot.description,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 15,
                    height: 1.6,
                  ),
                ),
              ),
              
              // الإيجابيات والسلبيات والتنبيهات
              if (spot.pros.isNotEmpty || spot.cons.isNotEmpty || spot.warnings.isNotEmpty) ...[
                const SizedBox(height: 20),
                if (spot.pros.isNotEmpty) _buildFeaturesList('الإيجابيات', spot.pros, AppColors.success, Icons.check_circle_rounded),
                if (spot.cons.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _buildFeaturesList('السلبيات', spot.cons, AppColors.error, Icons.cancel_rounded),
                ],
                if (spot.warnings.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _buildFeaturesList('تنبيهات', spot.warnings, AppColors.warning, Icons.warning_amber_rounded),
                ],
              ],
              
              const SizedBox(height: 24),
              
              // أزرار
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: () => _navigateToSpot(spot),
                      icon: const Icon(Icons.navigation_rounded, size: 20),
                      label: const Text('دلني عليه'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => SpotDetailsScreen(spot: spot),
                          ),
                        );
                      },
                      icon: const Icon(Icons.visibility_rounded, size: 20),
                      label: const Text('التفاصيل'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: BorderSide(color: AppColors.primary, width: 2),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildImagePlaceholder() {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Center(
        child: Icon(
          Icons.landscape_rounded,
          size: 80,
          color: AppColors.primary,
        ),
      ),
    );
  }
  
  Widget _buildStatChip({
    required IconData icon,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 6),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildFeaturesList(String title, List<String> items, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: color,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 8, right: 28),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 6),
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        item,
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  void _navigateToSpot(CampingSpot spot) async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    
    if (!auth.isAuthenticated || auth.currentUser?.id == 'guest') {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يجب تسجيل الدخول للاستفادة من ميزة التنقل'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    Navigator.pop(context); // إغلاق النافذة السفلية
    
    // عرض الإعلان أولاً
    await AdService().showInterstitialAdIfReady(
      onAdClosed: () {
        // بعد إغلاق الإعلان، عرض قائمة الخيارات
        _showNavigationOptions(spot);
      },
      frequency: 3,
    );
  }
  
  void _showNavigationOptions(CampingSpot spot) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
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
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            
            Text(
              'اختر تطبيق التنقل',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
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
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
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
    final url = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng&destination_place_id=$name&travelmode=driving&hl=ar'
    );
    
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }
  
  Future<void> _openWaze(CampingSpot spot) async {
    final lat = spot.latitude;
    final lng = spot.longitude;
    final url = Uri.parse(
      'https://waze.com/ul?ll=$lat,$lng&navigate=yes&lang=ar'
    );
    
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }
  
  Future<void> _openAppleMaps(CampingSpot spot) async {
    final lat = spot.latitude;
    final lng = spot.longitude;
    final url = Uri.parse(
      'https://maps.apple.com/?daddr=$lat,$lng&dirflg=d&t=m'
    );
    
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }
  
  void _toggleMapType() {
    setState(() {
      switch (_currentMapType) {
        case MapType.hybrid:
          _currentMapType = MapType.normal;
          break;
        case MapType.normal:
          _currentMapType = MapType.satellite;
          break;
        case MapType.satellite:
          _currentMapType = MapType.hybrid;
          break;
        default:
          _currentMapType = MapType.hybrid;
      }
    });
    
    // عرض رسالة نوع الخريطة
    String mapTypeName;
    switch (_currentMapType) {
      case MapType.hybrid:
        mapTypeName = 'قمر صناعي + خريطة';
        break;
      case MapType.satellite:
        mapTypeName = 'قمر صناعي فقط';
        break;
      case MapType.normal:
        mapTypeName = 'خريطة عادية';
        break;
      default:
        mapTypeName = 'قمر صناعي + خريطة';
    }
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mapTypeName),
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.primary,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // الخريطة
          GoogleMap(
            mapType: _currentMapType,
            initialCameraPosition: _initialPosition,
            markers: _markers,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
            onMapCreated: (GoogleMapController controller) {
              _controller.complete(controller);
              if (_currentMapType == MapType.normal) {
                controller.setMapStyle(_mapStyle);
              }
            },
          ),
          
            // Header مخصص
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // شريط البحث والأزرار
                    Row(
                      children: [
                        // شريط البحث
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(16),
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
                                Icon(Icons.search, color: AppColors.textSecondary),
                                const SizedBox(width: 12),
                                Text(
                                  'ابحث عن مكان...',
                                  style: TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        
                        // زر نوع الخريطة
                        _buildActionButton(
                          icon: Icons.layers_rounded,
                          onTap: _toggleMapType,
                        ),
                      ],
                    ),
                  
                  const Spacer(),
                  
                  // أزرار التحكم السفلية
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Column(
                        children: [
                          // زر الموقع الحالي
                          _buildActionButton(
                            icon: Icons.my_location,
                            onTap: _getCurrentLocation,
                          ),
                          const SizedBox(height: 12),
                          
                          // زر تحديث المواقع
                          _buildActionButton(
                            icon: Icons.refresh,
                            onTap: _loadSpots,
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          // Loading indicator
          if (_isLoading)
            Container(
              color: Colors.black26,
              child: const Center(
                child: CircularProgressIndicator(
                  color: AppColors.primary,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadow,
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(icon, color: AppColors.primary),
      ),
    );
  }

  void _showFilters() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'تصفية حسب الفئة',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildFilterChip('الكل'),
                _buildFilterChip('كشتة'),
                _buildFilterChip('مخيم'),
                _buildFilterChip('استراحة'),
                _buildFilterChip('منتزه'),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    return ChoiceChip(
      label: Text(label),
      selected: false,
      onSelected: (selected) {
        // تطبيق الفلتر
        Navigator.pop(context);
      },
      selectedColor: AppColors.primary,
      labelStyle: const TextStyle(color: AppColors.textPrimary),
    );
  }
  
  void _showSpotsListDialog(BuildContext context) {
    final spots = Provider.of<SpotsProvider>(context, listen: false).spots;
    
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 600, maxHeight: 600),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text(
                    'جميع الأماكن',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: spots.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.location_off,
                              size: 64,
                              color: AppColors.textSecondary,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'لا توجد أماكن متاحة حالياً',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: spots.length,
                        itemBuilder: (context, index) {
                          final spot = spots[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              contentPadding: const EdgeInsets.all(12),
                              leading: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  width: 60,
                                  height: 60,
                                  color: AppColors.primary.withOpacity(0.1),
                                  child: spot.imageUrls.isNotEmpty && spot.imageUrls.first.startsWith('http')
                                      ? Image.network(
                                          spot.imageUrls.first,
                                          fit: BoxFit.cover,
                                        )
                                      : Icon(
                                          Icons.landscape,
                                          color: AppColors.primary,
                                          size: 30,
                                        ),
                                ),
                              ),
                              title: Text(
                                spot.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 4),
                                  Text(
                                    spot.category,
                                    style: TextStyle(
                                      color: AppColors.primary,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Icon(Icons.star, size: 14, color: AppColors.warning),
                                      const SizedBox(width: 4),
                                      Text('${spot.rating}'),
                                      const SizedBox(width: 12),
                                      Icon(Icons.favorite, size: 14, color: AppColors.error),
                                      const SizedBox(width: 4),
                                      Text('${spot.likes}'),
                                    ],
                                  ),
                                ],
                              ),
                              trailing: Icon(
                                Icons.arrow_forward_ios,
                                size: 16,
                                color: AppColors.textSecondary,
                              ),
                              onTap: () {
                                Navigator.pop(context);
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => SpotDetailsScreen(spot: spot),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      ),
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
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.explore_off_rounded,
              size: 80,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'لا توجد أماكن حالياً',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'كن أول من يضيف مكاناً مميزاً',
            style: TextStyle(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildSpotCard(CampingSpot spot) {
    return InkWell(
      onTap: () => _showSpotDetails(spot),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadow,
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                    child: Container(
                      width: double.infinity,
                      color: AppColors.primary.withOpacity(0.1),
                      child: spot.imageUrls.isNotEmpty && spot.imageUrls.first.startsWith('http')
                          ? Image.network(
                              spot.imageUrls.first,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => _buildCardPlaceholder(),
                            )
                          : _buildCardPlaceholder(),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: _getCategoryColor(spot.category),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      child: Text(
                        spot.category,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    spot.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.star_rounded, size: 16, color: AppColors.warning),
                      const SizedBox(width: 4),
                      Text(
                        '${spot.rating}',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(width: 12),
                      Icon(Icons.favorite_rounded, size: 16, color: AppColors.error),
                      const SizedBox(width: 4),
                      Text(
                        '${spot.likes}',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildCardPlaceholder() {
    return Center(
      child: Icon(Icons.landscape_rounded, size: 50, color: AppColors.primary),
    );
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
  
  Widget _buildWebMapAlternative() {
    final spots = Provider.of<SpotsProvider>(context).spots;
    
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primary, AppColors.earth],
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
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
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.map_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'اكتشف الأماكن المميزة',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          '${spots.length} مكان متاح في السعودية',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.filter_list_rounded, color: Colors.white),
                    onPressed: _showFilters,
                  ),
                ],
              ),
            ),
            
            // قائمة الأماكن
            Expanded(
              child: spots.isEmpty
                  ? _buildEmptyState()
                  : GridView.builder(
                      padding: const EdgeInsets.all(16),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: MediaQuery.of(context).size.width > 900 ? 3 : 2,
                        childAspectRatio: 0.8,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                      ),
                      itemCount: spots.length,
                      itemBuilder: (context, index) => _buildSpotCard(spots[index]),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
