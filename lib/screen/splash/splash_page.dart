import 'package:flutter/material.dart';

import '../../services/fcm_service.dart';
import '../../services/login_service.dart';
import '../dashboard/dashboard_page.dart';
import '../login/login_page.dart';

const kBluePrimary = Color(0xFF2563EB);
const kBlueAccent = Color(0xFF38BDF8);
const kBlueDark = Color(0xFF0B1F4D);

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  final AuthService _authService = AuthService();

  late final AnimationController _controller;
  late final Animation<double> _logoScale;
  late final Animation<double> _logoFade;
  late final Animation<Offset> _contentSlide;
  late final Animation<double> _contentFade;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _logoScale = Tween<double>(begin: 0.72, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0, 0.58, curve: Curves.easeOutBack),
      ),
    );
    _logoFade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0, 0.35, curve: Curves.easeOut),
    );
    _contentSlide = Tween<Offset>(
      begin: const Offset(0, 0.22),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.28, 0.82, curve: Curves.easeOutCubic),
      ),
    );
    _contentFade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.28, 0.72, curve: Curves.easeOut),
    );

    _controller.forward();
    _openNextScreen();
  }

  Future<void> _openNextScreen() async {
    // Start authentication immediately.
    final loginFuture = _authService.isLoggedIn();

    // Keep splash visible for at least 2.3 seconds.
    await Future.delayed(const Duration(milliseconds: 4000));

    // Wait for authentication if it hasn't finished yet.
    final loggedIn = await loginFuture;
    if (loggedIn) {
      await FCMService.instance.updateFCMToken();
    }

    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 550),
        pageBuilder: (_, animation, __) =>
        loggedIn ? const DashboardScreen() : const LoginScreen(),
        transitionsBuilder: (_, animation, __, child) {
          final curved = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          );

          return FadeTransition(
            opacity: curved,
            child: ScaleTransition(
              scale: Tween<double>(
                begin: 0.985,
                end: 1,
              ).animate(curved),
              child: child,
            ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [kBlueDark, Color(0xFF123C91), kBluePrimary],
            stops: [0, 0.52, 1],
          ),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            const _BackgroundGlow(),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Column(
                  children: [
                    const Spacer(flex: 4),
                    FadeTransition(
                      opacity: _logoFade,
                      child: ScaleTransition(
                        scale: _logoScale,
                        child: const _AppMark(),
                      ),
                    ),
                    const SizedBox(height: 30),
                    FadeTransition(
                      opacity: _contentFade,
                      child: SlideTransition(
                        position: _contentSlide,
                        child: const Column(
                          children: [
                            Text(
                              'Sanpra Employee',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 29,
                                height: 1.1,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.4,
                              ),
                            ),
                            SizedBox(height: 10),
                            Text(
                              'Smarter teams. Better workdays.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Color(0xFFDCEAFF),
                                fontSize: 15,
                                height: 1.4,
                                fontWeight: FontWeight.w500,
                                letterSpacing: 0.15,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const Spacer(flex: 4),
                    FadeTransition(
                      opacity: _contentFade,
                      child: const _LoadingIndicator(),
                    ),
                    const SizedBox(height: 34),
                    Text(
                      'Powered by Sanpra Software Solutions',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.62),
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.25,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Version 1.0.0',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.42),
                        fontSize: 10.5,
                      ),
                    ),
                    const SizedBox(height: 18),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AppMark extends StatelessWidget {
  const _AppMark();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 124,
      height: 124,
      padding: const EdgeInsets.all(9),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.14),
        borderRadius: BorderRadius.circular(36),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF001D55).withOpacity(0.28),
              blurRadius: 32,
              offset: const Offset(0, 14),
            ),
          ],
        ),
        child: const Stack(
          alignment: Alignment.center,
          children: [
            Icon(Icons.badge_rounded, size: 62, color: kBluePrimary),
            Positioned(
              right: 20,
              bottom: 20,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Color(0xFF16A36A),
                  shape: BoxShape.circle,
                ),
                child: Padding(
                  padding: EdgeInsets.all(4),
                  child: Icon(Icons.check_rounded, size: 13, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoadingIndicator extends StatelessWidget {
  const _LoadingIndicator();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        SizedBox(
          width: 26,
          height: 26,
          child: CircularProgressIndicator(
            color: Colors.white,
            backgroundColor: Color(0x33FFFFFF),
            strokeWidth: 2.4,
            strokeCap: StrokeCap.round,
          ),
        ),
        SizedBox(height: 13),
        Text(
          'Preparing your workspace',
          style: TextStyle(
            color: Color(0xFFCFE1FF),
            fontSize: 12.5,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _BackgroundGlow extends StatelessWidget {
  const _BackgroundGlow();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        children: [
          Positioned(
            top: -100,
            right: -80,
            child: _GlowCircle(
              size: 270,
              color: kBlueAccent.withOpacity(0.18),
            ),
          ),
          Positioned(
            left: -120,
            bottom: 60,
            child: _GlowCircle(
              size: 310,
              color: const Color(0xFF8B5CF6).withOpacity(0.12),
            ),
          ),
        ],
      ),
    );
  }
}

class _GlowCircle extends StatelessWidget {
  const _GlowCircle({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        boxShadow: [
          BoxShadow(color: color, blurRadius: 80, spreadRadius: 18),
        ],
      ),
    );
  }
}
