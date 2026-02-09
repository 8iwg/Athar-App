import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart' as flutter_svg;
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme/app_colors.dart';

class SplashScreen extends StatefulWidget {
  final VoidCallback onComplete;

  const SplashScreen({super.key, required this.onComplete});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToHome();
  }

  Future<void> _navigateToHome() async {
    // وقت كافٍ للاستمتاع بالأنيميشن
    await Future.delayed(const Duration(milliseconds: 3500));
    if (mounted) {
      widget.onComplete();
    }
  }

  @override
  Widget build(BuildContext context) {
    // نستخدم ألوان التطبيق فقط كما طلبت
    // نفترض أن AppColors.primary أو gradient موجودة
    
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          // التزام تام بتدرج التطبيق
          gradient: AppColors.earthGradient,
        ),
        child: Stack(
          children: [
            // 1. خلفية زخرفية خفيفة جداً (اختياري لزيادة الفخامة بنفس ألوان التطبيق)
            Positioned(
              top: -50,
              right: -50,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.05),
                ),
              ),
            ),

            // 2. المحتوى الرئيسي (اللوقو والنص)
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // اللوقو: يظهر بوقار
                  flutter_svg.SvgPicture.asset(
                    'assets/images/logo.svg',
                    width: 180,
                    height: 180,
                    fit: BoxFit.contain,
                  )
                  .animate()
                  .scale(duration: 1000.ms, curve: Curves.easeOutBack)
                  .fadeIn(duration: 800.ms)
                  .shimmer(delay: 1500.ms, duration: 1000.ms, color: Colors.white.withOpacity(0.3)),
                  
                  const SizedBox(height: 30),
                  
                  // اسم التطبيق
                  Text(
                    'أثر',
                    style: GoogleFonts.cairo(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                      color: Colors.white,
                      shadows: [
                        Shadow(
                          color: Colors.black.withOpacity(0.2),
                          offset: const Offset(0, 2),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                  )
                  .animate()
                  .fadeIn(delay: 800.ms, duration: 600.ms)
                  .slideY(begin: 0.3, end: 0, duration: 600.ms),
                  
                  const SizedBox(height: 8),
                  
                  // الوصف
                  Text(
                    'دليل الأماكن في السعودية',
                    style: GoogleFonts.cairo(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 1,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  )
                  .animate()
                  .fadeIn(delay: 1200.ms, duration: 600.ms)
                  .slideY(begin: 0.3, end: 0, duration: 600.ms),
                ],
              ),
            ),

            // 3. بار التحميل الأنيق
            Positioned(
              bottom: 80,
              left: 0,
              right: 0,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 60),
                child: Column(
                  children: [
                    // البار نفسه
                    Container(
                      height: 4,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Stack(
                          children: [
                            // البار المتحرك
                            Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.white.withOpacity(0.8),
                                    Colors.white,
                                    Colors.white.withOpacity(0.8),
                                  ],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.white.withOpacity(0.5),
                                    blurRadius: 8,
                                    spreadRadius: 1,
                                  ),
                                ],
                              ),
                            )
                            .animate()
                            .scaleX(
                              begin: 0,
                              end: 1,
                              duration: 3000.ms,
                              curve: Curves.easeInOut,
                              alignment: Alignment.centerLeft,
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    // نقاط تحميل متحركة
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(3, (index) {
                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 5),
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.white.withOpacity(0.5),
                                blurRadius: 8,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                        )
                        .animate(onPlay: (controller) => controller.repeat())
                        .scale(
                          delay: Duration(milliseconds: index * 200),
                          duration: 600.ms,
                          begin: const Offset(1, 1),
                          end: const Offset(0.5, 0.5),
                        )
                        .then()
                        .scale(
                          duration: 600.ms,
                          begin: const Offset(0.5, 0.5),
                          end: const Offset(1, 1),
                        );
                      }),
                    ),
                  ],
                ),
              )
              .animate()
              .fadeIn(delay: 1500.ms, duration: 800.ms),
            ),


          ],
        ),
      ),
    );
  }
}