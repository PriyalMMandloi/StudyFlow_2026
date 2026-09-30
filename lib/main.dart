import 'dart:async';
import 'dart:developer' as developer;
import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'study_note.dart';
import 'study_note_store.dart';
import 'study_plan.dart';

const _userDataLoadTimeout = Duration(seconds: 20);
const _profilePhotosBucket = 'profile-photos';
const _profilePhotoUrlLifetimeSeconds = 604800;

Future<String> _createProfilePhotoSignedUrl(String path) => Supabase
    .instance
    .client
    .storage
    .from(_profilePhotosBucket)
    .createSignedUrl(path, _profilePhotoUrlLifetimeSeconds);

String? validateEmail(String? value) {
  final email = value?.trim() ?? '';
  if (email.isEmpty) {
    return 'Please enter your email address.';
  }

  final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
  if (!emailRegex.hasMatch(email)) {
    return 'Please enter a valid email address.';
  }

  return null;
}

String? validateUsername(String? value) {
  final username = value?.trim() ?? '';
  if (username.isEmpty) {
    return 'Please enter a username.';
  }
  if (username.length < 3) {
    return 'Username must be at least 3 characters.';
  }
  if (!RegExp(r"^[a-zA-Z0-9_ .'-]+$").hasMatch(username)) {
    return 'Use letters, numbers, spaces, underscores, or simple punctuation.';
  }
  return null;
}

String? validatePassword(String? value) {
  final password = value ?? '';
  if (password.isEmpty) {
    return 'Please enter your password.';
  }
  if (password.length < 8) {
    return 'Use at least 8 characters.';
  }
  if (!RegExp(r'^(?=.*[A-Za-z])(?=.*\d)').hasMatch(password)) {
    return 'Use letters and numbers in your password.';
  }
  return null;
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load();

  await Supabase.initialize(
    url: dotenv.get('SUPABASE_URL', fallback: ''),
    publishableKey: dotenv.get('SUPABASE_ANON_KEY', fallback: ''),
  );

  runApp(const StudyFlowApp());
}

class MyApp extends StudyFlowApp {
  const MyApp({super.key});
}

class StudyFlowApp extends StatelessWidget {
  const StudyFlowApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: StudyFlowThemeController.instance,
      builder: (context, themeMode, _) => MaterialApp(
        title: 'StudyFlow',
        debugShowCheckedModeBanner: false,
        theme: StudyFlowTheme.lightTheme,
        darkTheme: StudyFlowTheme.lightTheme,
        themeMode: themeMode,
        home: const AuthGate(),
      ),
    );
  }
}

class StudyFlowThemeController extends ValueNotifier<ThemeMode> {
  StudyFlowThemeController._() : super(ThemeMode.light);
  static final instance = StudyFlowThemeController._();
}

class StudyFlowTheme {
  static const Color backgroundLight = Color(0xFFF6F4FF);
  static const Color backgroundWarm = Color(0xFFF9F7FF);
  static const Color glassFill = Color(0xCCFFFFFF);
  static const Color glassBorder = Color(0x33FFFFFF);
  static const Color sage = Color(0xFF6D5DF6);
  static const Color sageStrong = Color(0xFF4F46E5);
  static const Color sageSoft = Color(0xFFEAE5FF);
  static const Color mint = Color(0xFFD9D2FF);
  static const Color charcoal = Color(0xFF1F2337);
  static const Color muted = Color(0xFF5D668C);
  static const Color cream = Color(0xFFFDFBFF);
  static const Color amber = Color(0xFFF6C76E);
  static const Color danger = Color(0xFFEA6B7C);

  static ThemeData get lightTheme {
    final base = ThemeData(
      useMaterial3: true,
      fontFamily: 'Roboto',
      scaffoldBackgroundColor: backgroundLight,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: sage,
        brightness: Brightness.light,
        primary: sage,
        secondary: sageStrong,
        surface: Colors.white,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: charcoal,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
      ),
      cardTheme: const CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        color: Colors.white,
        surfaceTintColor: Colors.transparent,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.55),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        hintStyle: TextStyle(color: muted.withValues(alpha: 0.7), fontSize: 14),
        labelStyle: const TextStyle(color: muted, fontSize: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(18)),
          borderSide: BorderSide(color: Color(0x1F647067)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(18)),
          borderSide: BorderSide(color: Color(0x1F647067)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(18)),
          borderSide: BorderSide(color: sage, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(18)),
          borderSide: BorderSide(color: danger, width: 1.2),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: sage,
          foregroundColor: Colors.white,
          minimumSize: const Size(0, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.transparent,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        indicatorColor: const Color(0xFFD8E9DE),
        labelTextStyle: WidgetStatePropertyAll(
          const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
        ),
      ),
    );

    return base.copyWith(
      textTheme: base.textTheme.copyWith(
        headlineLarge: const TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.w800,
          color: charcoal,
          letterSpacing: -0.9,
        ),
        headlineMedium: const TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w800,
          color: charcoal,
          letterSpacing: -0.7,
        ),
        titleLarge: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: charcoal,
        ),
        titleMedium: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: charcoal,
        ),
        bodyLarge: const TextStyle(fontSize: 16, color: charcoal),
        bodyMedium: const TextStyle(fontSize: 14, color: charcoal),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: Colors.white.withValues(alpha: 0.75),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        titleTextStyle: const TextStyle(
          color: charcoal,
          fontSize: 22,
          fontWeight: FontWeight.w700,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: const Color(0xCC1F2B25),
        contentTextStyle: const TextStyle(color: Colors.white),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }
}

class StudyFlowBackground extends StatelessWidget {
  final Widget child;
  const StudyFlowBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            StudyFlowTheme.backgroundWarm,
            StudyFlowTheme.backgroundLight,
            Color(0xFFEFF5F0),
          ],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -60,
            right: -40,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                color: const Color(0xFFDBEEDC).withValues(alpha: 0.75),
                borderRadius: BorderRadius.circular(110),
              ),
            ),
          ),
          Positioned(
            bottom: 80,
            left: -40,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                color: const Color(0xFFE8E2D6).withValues(alpha: 0.65),
                borderRadius: BorderRadius.circular(90),
              ),
            ),
          ),
          child,
        ],
      ),
    );
  }
}

class GlassAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final bool showBack;
  const GlassAppBar({
    super.key,
    required this.title,
    this.actions,
    this.showBack = true,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
      automaticallyImplyLeading: showBack,
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      actions: actions,
    );
  }
}

class GlassContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double radius;
  final bool blur;
  final Color? color;
  final List<BoxShadow>? boxShadow;
  final Border? border;
  const GlassContainer({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.radius = 28,
    this.blur = true,
    this.color,
    this.boxShadow,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? Colors.white.withValues(alpha: 0.38);
    final decoration = BoxDecoration(
      color: effectiveColor,
      borderRadius: BorderRadius.circular(radius),
      border: border ?? Border.all(color: const Color(0x26FFFFFF), width: 1),
      boxShadow:
          boxShadow ??
          [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
    );

    final content = Container(
      margin: margin,
      padding: padding,
      decoration: decoration,
      child: child,
    );

    if (!blur) return content;

    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: content,
      ),
    );
  }
}

class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double radius;
  final Color? color;
  final VoidCallback? onTap;
  final Border? border;
  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.radius = 24,
    this.color,
    this.onTap,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    final card = GlassContainer(
      padding: padding ?? const EdgeInsets.all(18),
      margin: margin,
      radius: radius,
      color: color ?? Colors.white.withValues(alpha: 0.42),
      border: border ?? Border.all(color: const Color(0x3DFFFFFF), width: 1),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.03),
          blurRadius: 16,
          offset: const Offset(0, 6),
        ),
      ],
      child: child,
    );

    if (onTap == null) return card;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(radius),
        onTap: onTap,
        child: card,
      ),
    );
  }
}

class GlassButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool filled;
  final bool fullWidth;
  final double height;
  const GlassButton({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.filled = true,
    this.fullWidth = true,
    this.height = 52,
  });

  @override
  Widget build(BuildContext context) {
    final button = FilledButton.icon(
      onPressed: onPressed,
      icon: icon == null ? const SizedBox.shrink() : Icon(icon),
      label: Text(label),
      style: FilledButton.styleFrom(
        backgroundColor: filled
            ? StudyFlowTheme.sage
            : Colors.white.withValues(alpha: 0.45),
        foregroundColor: filled ? Colors.white : StudyFlowTheme.charcoal,
        minimumSize: Size.fromHeight(height),
        side: filled
            ? null
            : const BorderSide(color: Color(0x2A5C8D72), width: 1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
    );

    if (!fullWidth) {
      return button;
    }

    return SizedBox(width: double.infinity, child: button);
  }
}

class GlassTextField extends StatelessWidget {
  final TextEditingController controller;
  final String labelText;
  final String? hintText;
  final bool obscureText;
  final TextInputType? keyboardType;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final TextInputAction? textInputAction;
  final void Function(String)? onSubmitted;
  final int? maxLength;
  const GlassTextField({
    super.key,
    required this.controller,
    required this.labelText,
    this.hintText,
    this.obscureText = false,
    this.keyboardType,
    this.prefixIcon,
    this.suffixIcon,
    this.textInputAction,
    this.onSubmitted,
    this.maxLength,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      onSubmitted: onSubmitted,
      maxLength: maxLength,
      decoration: InputDecoration(
        labelText: labelText,
        hintText: hintText,
        prefixIcon: prefixIcon,
        suffixIcon: suffixIcon,
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final TextAlign? textAlign;
  const SectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.textAlign,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.4,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Text(
            subtitle!,
            style: TextStyle(
              color: StudyFlowTheme.muted,
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
            ),
            textAlign: textAlign,
          ),
        ],
      ],
    );
  }
}

class StudyFlowNavBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  const StudyFlowNavBar({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
      child: GlassContainer(
        radius: 30,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        color: Colors.white.withValues(alpha: 0.32),
        child: NavigationBar(
          height: 72,
          selectedIndex: selectedIndex,
          onDestinationSelected: onDestinationSelected,
          backgroundColor: Colors.transparent,
          indicatorColor: const Color(0xFFE7E2FF),
          indicatorShape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          shadowColor: Colors.transparent,
          elevation: 0,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined, size: 22),
              selectedIcon: Icon(Icons.home_rounded, size: 22),
              label: 'Home',
            ),
            NavigationDestination(
              icon: Icon(Icons.menu_book_outlined, size: 22),
              selectedIcon: Icon(Icons.menu_book_rounded, size: 22),
              label: 'Chapters',
            ),
            NavigationDestination(
              icon: Icon(Icons.checklist_outlined, size: 22),
              selectedIcon: Icon(Icons.checklist_rounded, size: 22),
              label: 'Tasks',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline, size: 22),
              selectedIcon: Icon(Icons.person_rounded, size: 22),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}

class ProgressPill extends StatelessWidget {
  final String text;
  final Color? color;
  const ProgressPill({super.key, required this.text, this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: (color ?? StudyFlowTheme.sageSoft).withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color == null ? StudyFlowTheme.sageStrong : Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.05,
        ),
      ),
    );
  }
}

class ProgressRing extends StatelessWidget {
  final double value;
  final double size;
  final double strokeWidth;
  final Color? color;
  final String? label;
  const ProgressRing({
    super.key,
    required this.value,
    this.size = 110,
    this.strokeWidth = 10,
    this.color,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    final ringColor = color ?? StudyFlowTheme.sageStrong;
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              value: value.clamp(0.0, 1.0),
              strokeWidth: strokeWidth,
              backgroundColor: const Color(0xFFE7EEE9),
              valueColor: AlwaysStoppedAnimation<Color>(ringColor),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${(value * 100).round()}%',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: StudyFlowTheme.charcoal,
                ),
              ),
              if (label != null) ...[
                const SizedBox(height: 3),
                Text(
                  label!,
                  style: TextStyle(
                    color: StudyFlowTheme.muted,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class StatTile extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color? accent;
  const StatTile({
    super.key,
    required this.icon,
    required this.value,
    required this.label,
    this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: (accent ?? StudyFlowTheme.sageSoft).withValues(
                alpha: 0.75,
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              icon,
              color: accent == null ? StudyFlowTheme.sageStrong : Colors.white,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                    letterSpacing: -0.4,
                  ),
                ),
                Text(
                  label,
                  style: TextStyle(
                    color: StudyFlowTheme.muted,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class StudyFlowData extends ChangeNotifier {
  StudyFlowData._();
  static final StudyFlowData instance = StudyFlowData._();

  int goalMinutes = 120;
  int completedMinutes = 0;
  int completedTasks = 0;
  final List<int> weeklyMinutes = List<int>.filled(7, 0);
  final Map<DateTime, int> _activityCounts = {};
  String profileDisplayName = 'StudyFlow User';
  String? profileAvatarUrl;
  String? profileAvatarPath;
  String? _loadedUserId;
  String? _loadingUserId;
  Future<void>? _loadFuture;
  Future<void> _pendingWrite = Future<void>.value();
  int _loadGeneration = 0;

  Future<void> loadForUser(User user, {bool force = false}) {
    if (!force && _loadedUserId == user.id) return Future<void>.value();
    if (!force && _loadingUserId == user.id && _loadFuture != null) {
      return _loadFuture!;
    }

    final generation = ++_loadGeneration;
    _loadingUserId = user.id;
    _loadedUserId = null;
    _loadFuture = _loadUserData(user, generation).timeout(
      _userDataLoadTimeout,
      onTimeout: () {
        if (generation == _loadGeneration) {
          _loadGeneration++;
          _loadedUserId = null;
          _loadingUserId = null;
          _loadFuture = null;
          StudyPlanStore.instance.clearForSignedOut();
        }
        throw TimeoutException('Loading StudyFlow data timed out.');
      },
    );
    _resetData();
    notifyListeners();
    return _loadFuture!;
  }

  Future<void> _loadUserData(User user, int generation) async {
    final client = Supabase.instance.client;
    try {
      final profile = await client
          .from('profiles')
          .select('username, display_name, avatar_url')
          .eq('id', user.id)
          .maybeSingle();

      if (!_isCurrentLoad(user.id, generation)) return;

      final metadata = user.userMetadata ?? <String, dynamic>{};
      final metadataName = (metadata['display_name'] ?? metadata['name'])
          ?.toString()
          .trim();
      final fallbackName = metadataName?.isNotEmpty == true
          ? metadataName!
          : 'StudyFlow User';

      if (profile == null) {
        profileDisplayName = fallbackName;
        await client.from('profiles').upsert({
          'id': user.id,
          'username': profileDisplayName,
          'display_name': profileDisplayName,
        }, onConflict: 'id');
        if (!_isCurrentLoad(user.id, generation)) return;
      } else {
        final storedUsername = (profile['username'] as String?)?.trim();
        final storedDisplayName = (profile['display_name'] as String?)?.trim();
        profileDisplayName =
            (storedUsername?.isNotEmpty == true
                        ? storedUsername
                        : storedDisplayName)
                    ?.isNotEmpty ==
                true
            ? (storedUsername?.isNotEmpty == true
                  ? storedUsername!
                  : storedDisplayName!)
            : fallbackName;
        profileAvatarPath = profile['avatar_url'] as String?;
        final avatarPath = profileAvatarPath;
        if (avatarPath != null) {
          try {
            profileAvatarUrl = avatarPath.startsWith('https://')
                ? avatarPath
                : await _createProfilePhotoSignedUrl(avatarPath);
          } catch (error, stackTrace) {
            developer.log(
              'Could not load the profile photo URL.',
              name: 'StudyFlowProfile',
              error: error,
              stackTrace: stackTrace,
            );
          }
        }
      }

      final saved = await client
          .from('studyflow_user_data')
          .select('state')
          .eq('user_id', user.id)
          .maybeSingle();

      if (!_isCurrentLoad(user.id, generation)) return;

      _loadedUserId = user.id;
      if (saved == null) {
        await _persist();
      } else {
        _restoreState(saved['state']);
      }

      if (!_isCurrentLoad(user.id, generation)) return;
      await StudyPlanStore.instance.loadForUser(user.id);

      if (!_isCurrentLoad(user.id, generation)) return;
      notifyListeners();
    } catch (_) {
      if (generation == _loadGeneration) {
        _loadedUserId = null;
        _loadingUserId = null;
        _loadFuture = null;
      }
      rethrow;
    }
  }

  bool _isCurrentLoad(String userId, int generation) =>
      generation == _loadGeneration &&
      Supabase.instance.client.auth.currentUser?.id == userId;

  void clearForSignedOut() {
    _loadGeneration++;
    _loadedUserId = null;
    _loadingUserId = null;
    _loadFuture = null;
    _resetData();
    StudyNoteStore.instance.clearForSignedOut();
    StudyPlanStore.instance.clearForSignedOut();
    notifyListeners();
  }

  void _resetData() {
    goalMinutes = 120;
    completedMinutes = 0;
    completedTasks = 0;
    weeklyMinutes.fillRange(0, weeklyMinutes.length, 0);
    _activityCounts.clear();
    profileDisplayName = 'StudyFlow User';
    profileAvatarUrl = null;
    profileAvatarPath = null;
  }

  void _restoreState(Object? value) {
    if (value is! Map) return;
    final state = Map<String, dynamic>.from(value);

    goalMinutes = (state['goalMinutes'] as num?)?.toInt() ?? goalMinutes;
    completedMinutes =
        (state['completedMinutes'] as num?)?.toInt() ?? completedMinutes;
    completedTasks =
        (state['completedTasks'] as num?)?.toInt() ?? completedTasks;

    final savedWeekly = state['weeklyMinutes'];
    if (savedWeekly is List) {
      for (var index = 0; index < weeklyMinutes.length; index++) {
        weeklyMinutes[index] = index < savedWeekly.length
            ? (savedWeekly[index] as num?)?.toInt() ?? 0
            : 0;
      }
    }

    final savedActivity = state['activityCounts'];
    if (savedActivity is Map) {
      _activityCounts.clear();
      for (final entry in savedActivity.entries) {
        final date = DateTime.tryParse(entry.key.toString());
        final count = (entry.value as num?)?.toInt() ?? 0;
        if (date != null && count > 0) {
          _activityCounts[_dateOnly(date)] = count;
        }
      }
    }
  }

  Map<String, dynamic> _stateJson() => {
    'schemaVersion': 1,
    'goalMinutes': goalMinutes,
    'completedMinutes': completedMinutes,
    'completedTasks': completedTasks,
    'weeklyMinutes': [...weeklyMinutes],
    'activityCounts': {
      for (final entry in _activityCounts.entries)
        _dateOnly(entry.key).toIso8601String().substring(0, 10): entry.value,
    },
  };

  void setProfileAvatar({required String? path, required String? url}) {
    profileAvatarPath = path;
    profileAvatarUrl = url;
    notifyListeners();
  }

  Future<void> updateProfileName(String username) async {
    final trimmed = username.trim();
    final cleaned = validateUsername(trimmed);
    if (cleaned != null) {
      throw ArgumentError(cleaned);
    }

    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) {
      throw StateError('No active user is available to update the profile.');
    }

    final payload = {
      'id': userId,
      'username': trimmed,
      'display_name': trimmed,
    };

    await Supabase.instance.client
        .from('profiles')
        .upsert(payload, onConflict: 'id');

    profileDisplayName = trimmed;
    notifyListeners();
  }

  Future<void> _persist() {
    final userId = _loadedUserId;
    if (userId == null) return Future<void>.value();
    final state = _stateJson();

    final write = _pendingWrite.then((_) async {
      final client = Supabase.instance.client;
      if (client.auth.currentUser?.id != userId) return;
      await client.from('studyflow_user_data').upsert({
        'user_id': userId,
        'state': state,
      }, onConflict: 'user_id');
    });
    _pendingWrite = write.catchError((Object error, StackTrace stackTrace) {
      developer.log(
        'Could not persist StudyFlow data to Supabase.',
        name: 'StudyFlowData',
        error: error,
        stackTrace: stackTrace,
      );
    });
    return write;
  }

  Future<void> saveChanges() async {
    notifyListeners();
    await _persist();
  }

  DateTime _dateOnly(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  void _updateActivity(DateTime date, int change) {
    final day = _dateOnly(date);
    final count = (_activityCounts[day] ?? 0) + change;
    if (count > 0) {
      _activityCounts[day] = count;
    } else {
      _activityCounts.remove(day);
    }
  }

  bool hasActivityOn(DateTime date) =>
      (_activityCounts[_dateOnly(date)] ?? 0) > 0;

  int get currentStreak {
    final today = _dateOnly(DateTime.now());
    if (!hasActivityOn(today)) return 0;

    var streak = 0;
    var day = today;
    while (hasActivityOn(day)) {
      streak++;
      day = day.subtract(const Duration(days: 1));
    }
    return streak;
  }

  int get longestStreak {
    if (_activityCounts.isEmpty) return 0;

    final dates = _activityCounts.keys.toList()..sort();
    var longest = 1;
    var streak = 1;
    for (var i = 1; i < dates.length; i++) {
      if (dates[i].difference(dates[i - 1]).inDays == 1) {
        streak++;
        if (streak > longest) longest = streak;
      } else {
        streak = 1;
      }
    }
    return longest;
  }

  Future<void> setGoal(int minutes) async {
    final previous = _stateJson();
    goalMinutes = minutes;
    notifyListeners();
    try {
      await _persist();
    } catch (_) {
      _restoreState(previous);
      notifyListeners();
      rethrow;
    }
  }

  Future<void> recordTask({
    required bool completed,
    required int minutes,
  }) async {
    final previous = _stateJson();
    final dayIndex = DateTime.now().weekday - 1;
    if (completed) {
      completedTasks++;
      completedMinutes += minutes;
      weeklyMinutes[dayIndex] += minutes;
      _updateActivity(DateTime.now(), 1);
    } else {
      if (completedTasks > 0) completedTasks--;
      completedMinutes = (completedMinutes - minutes).clamp(0, 100000).toInt();
      weeklyMinutes[dayIndex] = (weeklyMinutes[dayIndex] - minutes)
          .clamp(0, 100000)
          .toInt();
      _updateActivity(DateTime.now(), -1);
    }
    notifyListeners();
    try {
      await _persist();
    } catch (_) {
      _restoreState(previous);
      notifyListeners();
      rethrow;
    }
  }

  Future<void> recordFocusSession(int minutes) async {
    final previous = _stateJson();
    completedMinutes += minutes;
    weeklyMinutes[DateTime.now().weekday - 1] += minutes;
    _updateActivity(DateTime.now(), 1);
    notifyListeners();
    try {
      await _persist();
    } catch (_) {
      _restoreState(previous);
      notifyListeners();
      rethrow;
    }
  }

  double get goalProgress => goalMinutes <= 0
      ? 0.0
      : (completedMinutes / goalMinutes).clamp(0.0, 1.0).toDouble();
}

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  StreamSubscription<AuthState>? _authSubscription;

  @override
  void initState() {
    super.initState();
    final auth = Supabase.instance.client.auth;
    _authSubscription = auth.onAuthStateChange.listen((state) {
      final user = state.session?.user;
      final previousUserId = StudyFlowData.instance._loadedUserId;
      if (user == null) {
        StudyFlowData.instance.clearForSignedOut();
        return;
      }

      if (previousUserId != null && previousUserId != user.id) {
        StudyFlowData.instance.clearForSignedOut();
      }
    });
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        final user =
            snapshot.data?.session?.user ??
            Supabase.instance.client.auth.currentUser;
        if (user == null) return const LoginScreen();

        return FutureBuilder<void>(
          future: StudyFlowData.instance.loadForUser(user),
          builder: (context, dataSnapshot) {
            if (dataSnapshot.connectionState != ConnectionState.done) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }
            if (dataSnapshot.hasError) {
              return Scaffold(
                body: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          dataSnapshot.error is TimeoutException
                              ? 'StudyFlow is taking too long to load. Check your connection and retry.'
                              : 'Could not load your StudyFlow data.',
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        FilledButton(
                          onPressed: () {
                            setState(() {});
                            StudyFlowData.instance.loadForUser(
                              user,
                              force: true,
                            );
                          },
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }
            return MainNavigation(key: _mainNavigationKey);
          },
        );
      },
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _loading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    final emailError = validateEmail(email);
    if (emailError != null) {
      _showMessage(emailError);
      return;
    }

    final passwordError = validatePassword(password);
    if (passwordError != null) {
      _showMessage(passwordError);
      return;
    }

    setState(() => _loading = true);

    try {
      final response = await Supabase.instance.client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.session == null) {
        throw StateError('Supabase did not return a session.');
      }

      if (!mounted) return;
      Navigator.of(context).popUntil((route) => route.isFirst);
    } on AuthException catch (e) {
      _showMessage(_supabaseAuthMessage(e));
    } catch (e, stackTrace) {
      developer.log(
        'Unexpected error during account creation.',
        name: 'StudyFlowAuth',
        error: e,
        stackTrace: stackTrace,
      );

      _showMessage('Account creation error: $e');
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  String _supabaseAuthMessage(AuthException e) {
    final message = e.message.toLowerCase();
    if (message.contains('invalid login credentials') ||
        message.contains('invalid credentials') ||
        message.contains('invalid grant') ||
        message.contains('email or password')) {
      return 'Incorrect email or password. Please try again.';
    }
    if (message.contains('rate limit') || message.contains('too many')) {
      return 'Too many attempts. Please wait a moment and try again.';
    }
    if (message.contains('network') || message.contains('timeout')) {
      return 'Network issue. Please check your connection and retry.';
    }
    return e.message.isNotEmpty ? e.message : 'Could not sign in.';
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return StudyFlowBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 430),
                child: GlassContainer(
                  radius: 32,
                  padding: const EdgeInsets.fromLTRB(22, 26, 22, 22),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 78,
                          height: 78,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFB9D8C0), Color(0xFF85B998)],
                            ),
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(
                                  0xFF7FA991,
                                ).withValues(alpha: 0.25),
                                blurRadius: 18,
                                offset: const Offset(0, 12),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.menu_book_rounded,
                            size: 38,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),
                      const Text(
                        'Welcome back',
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.8,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Sign in with your email and password.',
                        style: TextStyle(
                          color: StudyFlowTheme.muted,
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 28),
                      GlassTextField(
                        controller: _emailController,
                        labelText: 'Email',
                        hintText: 'you@example.com',
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        prefixIcon: const Icon(
                          Icons.email_outlined,
                          color: StudyFlowTheme.sageStrong,
                        ),
                      ),
                      const SizedBox(height: 18),
                      GlassTextField(
                        controller: _passwordController,
                        labelText: 'Password',
                        hintText: 'Enter your password',
                        obscureText: _obscurePassword,
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _signIn(),
                        prefixIcon: const Icon(
                          Icons.lock_outline,
                          color: StudyFlowTheme.sageStrong,
                        ),
                        suffixIcon: IconButton(
                          onPressed: () => setState(
                            () => _obscurePassword = !_obscurePassword,
                          ),
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                          color: StudyFlowTheme.muted,
                        ),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: FilledButton(
                          onPressed: _loading ? null : _signIn,
                          style: FilledButton.styleFrom(
                            backgroundColor: StudyFlowTheme.sage,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                          ),
                          child: _loading
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text(
                                  'Sign In',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: TextButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const CreateAccountScreen(),
                                  ),
                                );
                              },
                              child: const Text('Create Account'),
                            ),
                          ),
                          Expanded(
                            child: TextButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ForgotPasswordScreen(
                                      initialEmail: _emailController.text
                                          .trim(),
                                    ),
                                  ),
                                );
                              },
                              child: const Text('Forgot Password'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class CreateAccountScreen extends StatefulWidget {
  const CreateAccountScreen({super.key});

  @override
  State<CreateAccountScreen> createState() => _CreateAccountScreenState();
}

class _CreateAccountScreenState extends State<CreateAccountScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  bool _loading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _createAccount() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    final emailError = validateEmail(email);
    if (emailError != null) {
      _showMessage(emailError);
      return;
    }

    final passwordError = validatePassword(password);
    if (passwordError != null) {
      _showMessage(passwordError);
      return;
    }

    if (password != confirmPassword) {
      _showMessage('Passwords do not match.');
      return;
    }

    setState(() => _loading = true);

    try {
      final username = _usernameController.text.trim();
      final usernameError = validateUsername(username);
      if (usernameError != null) {
        _showMessage(usernameError);
        return;
      }

      final response = await Supabase.instance.client.auth.signUp(
        email: email,
        password: password,
      );

      final user = response.session?.user;
      if (user != null) {
        await Supabase.instance.client.from('profiles').upsert({
          'id': user.id,
          'username': username,
          'display_name': username,
        }, onConflict: 'id');
        if (!mounted) return;
        Navigator.of(context).popUntil((route) => route.isFirst);
        return;
      }

      if (!mounted) return;
      _showMessage(
        'Account created successfully. You can now sign in with your email and password.',
      );
      Navigator.of(context).pop();
    } on AuthException catch (e) {
      final message = e.message.toLowerCase();
      if (message.contains('user already registered') ||
          message.contains('already exists') ||
          message.contains('duplicate') ||
          message.contains('user with this email already exists')) {
        _showMessage(
          'An account with this email already exists. Please sign in instead.',
        );
      } else if (message.contains('password')) {
        _showMessage('Please choose a stronger password.');
      } else if (message.contains('network')) {
        _showMessage('Network issue. Please check your connection and retry.');
      } else {
        _showMessage(
          e.message.isNotEmpty ? e.message : 'Could not create your account.',
        );
      }
    } catch (e, stackTrace) {
      developer.log(
        'Unexpected error during account creation.',
        name: 'StudyFlowAuth',
        error: e,
        stackTrace: stackTrace,
      );
      _showMessage('Could not create your account. Please try again.');
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return StudyFlowBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: const GlassAppBar(title: 'Create account', showBack: true),
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 430),
                child: GlassContainer(
                  radius: 32,
                  padding: const EdgeInsets.fromLTRB(22, 18, 22, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Create your account',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.7,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Use your email and a secure password to get started.',
                        style: TextStyle(
                          color: StudyFlowTheme.muted,
                          fontSize: 14.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 28),
                      GlassTextField(
                        controller: _emailController,
                        labelText: 'Email',
                        hintText: 'you@example.com',
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        prefixIcon: const Icon(
                          Icons.email_outlined,
                          color: StudyFlowTheme.sageStrong,
                        ),
                      ),
                      const SizedBox(height: 18),
                      GlassTextField(
                        controller: _usernameController,
                        labelText: 'Username',
                        hintText: 'studyflow_user',
                        textInputAction: TextInputAction.next,
                        prefixIcon: const Icon(
                          Icons.person_outline,
                          color: StudyFlowTheme.sageStrong,
                        ),
                      ),
                      const SizedBox(height: 18),
                      GlassTextField(
                        controller: _passwordController,
                        labelText: 'Password',
                        hintText: 'Create a password',
                        obscureText: _obscurePassword,
                        textInputAction: TextInputAction.next,
                        prefixIcon: const Icon(
                          Icons.lock_outline,
                          color: StudyFlowTheme.sageStrong,
                        ),
                        suffixIcon: IconButton(
                          onPressed: () => setState(
                            () => _obscurePassword = !_obscurePassword,
                          ),
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                          color: StudyFlowTheme.muted,
                        ),
                      ),
                      const SizedBox(height: 18),
                      GlassTextField(
                        controller: _confirmPasswordController,
                        labelText: 'Confirm password',
                        hintText: 'Re-enter your password',
                        obscureText: _obscureConfirmPassword,
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _createAccount(),
                        prefixIcon: const Icon(
                          Icons.lock_reset_rounded,
                          color: StudyFlowTheme.sageStrong,
                        ),
                        suffixIcon: IconButton(
                          onPressed: () => setState(
                            () => _obscureConfirmPassword =
                                !_obscureConfirmPassword,
                          ),
                          icon: Icon(
                            _obscureConfirmPassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                          color: StudyFlowTheme.muted,
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: FilledButton(
                          onPressed: _loading ? null : _createAccount,
                          style: FilledButton.styleFrom(
                            backgroundColor: StudyFlowTheme.sage,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                          ),
                          child: _loading
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text(
                                  'Create account',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key, this.initialEmail});

  final String? initialEmail;

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  late final TextEditingController _emailController = TextEditingController(
    text: widget.initialEmail ?? '',
  );
  bool _loading = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendResetLink() async {
    final email = _emailController.text.trim();
    final validationError = validateEmail(email);
    if (validationError != null) {
      _showMessage(validationError);
      return;
    }

    setState(() => _loading = true);

    try {
      await Supabase.instance.client.auth.resetPasswordForEmail(email);
      if (!mounted) return;
      _showMessage(
        'If an account exists for $email, a password reset email has been sent.',
      );
      Navigator.of(context).pop();
    } on AuthException catch (e) {
      _showMessage(_supabaseResetMessage(e));
    } catch (e, stackTrace) {
      developer.log(
        'Unexpected error during password reset request.',
        name: 'StudyFlowAuth',
        error: e,
        stackTrace: stackTrace,
      );
      _showMessage(
        'Could not send the password reset email. Please try again.',
      );
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  String _supabaseResetMessage(AuthException e) {
    final message = e.message.toLowerCase();
    if (message.contains('network')) {
      return 'Network issue. Please check your connection and retry.';
    }
    if (message.contains('invalid')) {
      return 'Please enter a valid email address.';
    }
    return e.message.isNotEmpty ? e.message : 'Could not send the reset email.';
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return StudyFlowBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: const GlassAppBar(title: 'Reset password', showBack: true),
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 430),
                child: GlassContainer(
                  radius: 32,
                  padding: const EdgeInsets.fromLTRB(22, 18, 22, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Reset your password',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.7,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'We will send a password reset email to your account if it exists.',
                        style: TextStyle(
                          color: StudyFlowTheme.muted,
                          fontSize: 14.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 28),
                      GlassTextField(
                        controller: _emailController,
                        labelText: 'Email',
                        hintText: 'you@example.com',
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _sendResetLink(),
                        prefixIcon: const Icon(
                          Icons.email_outlined,
                          color: StudyFlowTheme.sageStrong,
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: FilledButton(
                          onPressed: _loading ? null : _sendResetLink,
                          style: FilledButton.styleFrom(
                            backgroundColor: StudyFlowTheme.sage,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                          ),
                          child: _loading
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text(
                                  'Send reset email',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

final _mainNavigationKey = GlobalKey<_MainNavigationState>();

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;

  void goHome() {
    if (_currentIndex == 0) return;
    setState(() => _currentIndex = 0);
  }

  final List<Widget> _screens = const [
    DashboardScreen(),
    PlannerScreen(),
    FocusScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return StudyFlowBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: IndexedStack(index: _currentIndex, children: _screens),
        bottomNavigationBar: SafeArea(
          top: false,
          child: StudyFlowNavBar(
            selectedIndex: _currentIndex,
            onDestinationSelected: (index) {
              setState(() => _currentIndex = index);
            },
          ),
        ),
      ),
    );
  }
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  DateTime _selectedDate = DateTime.now();
  final Random _quoteRandom = Random();
  late int _homeQuoteIndex = _quoteRandom.nextInt(_motivationQuotes.length);

  void _showAnotherHomeQuote() {
    setState(() {
      final nextIndex = _quoteRandom.nextInt(_motivationQuotes.length - 1);
      _homeQuoteIndex = nextIndex >= _homeQuoteIndex
          ? nextIndex + 1
          : nextIndex;
    });
  }

  String _randomGreeting() {
    final greetings = [
      'Hi',
      'Hello',
      'Hola',
      'Ciao',
      'Bonjour',
      'Namaste',
      'Konnichiwa',
      'Hej',
      'Salut',
      'Welcome',
    ];
    return (greetings..shuffle()).first;
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) return 'Good morning';
    if (hour >= 12 && hour < 17) return 'Good afternoon';
    if (hour >= 17 && hour < 21) return 'Good evening';
    return 'Good night';
  }

  String _dateLabel() {
    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return '${weekdays[_selectedDate.weekday - 1]}, ${_selectedDate.day}';
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      helpText: 'Choose a study date',
    );

    if (picked != null && mounted) {
      setState(() => _selectedDate = picked);
    }
  }

  void _openProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ProfileScreen()),
    );
  }

  void _openFocus(String title, String subject, int minutes) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FocusScreen(
          taskTitle: title,
          subject: subject,
          durationMinutes: minutes,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: StudyPlanStore.instance,
      builder: (context, _) {
        final chapters = StudyPlanStore.instance.chapters;
        final storeError = StudyPlanStore.instance.error;
        final isLoading = StudyPlanStore.instance.isLoading;
        final completedChapters = chapters
            .where((chapter) => chapter.isCompleted)
            .length;
        final progress = chapters.isEmpty
            ? 0.0
            : completedChapters / chapters.length;
        final rawName = StudyFlowData.instance.profileDisplayName.trim();
        final firstName = rawName.isNotEmpty
            ? rawName.split(' ').first
            : 'there';
        final focusChapter =
            chapters.where((chapter) => !chapter.isCompleted).firstOrNull ??
            (chapters.isEmpty ? null : chapters.first);
        final todayTasks = chapters
            .expand((chapter) => chapter.tasks)
            .where((task) => !task.isCompleted)
            .take(3)
            .toList();
        final chapterShortcuts = chapters.take(3).toList();

        return LayoutBuilder(
          builder: (context, constraints) {
            final contentWidth = constraints.maxWidth > 560
                ? 560.0
                : constraints.maxWidth;

            return SafeArea(
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: contentWidth),
                  child: CustomScrollView(
                    physics: const BouncingScrollPhysics(),
                    slivers: [
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                        sliver: SliverToBoxAdapter(
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${_greeting()} 👋',
                                      style: TextStyle(
                                        color: StudyFlowTheme.muted,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      '${_randomGreeting()}, $firstName',
                                      style: const TextStyle(
                                        fontSize: 29,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: -0.8,
                                        color: StudyFlowTheme.charcoal,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                onPressed: _openProfile,
                                tooltip: 'Profile',
                                icon: Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE6E0FF),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white.withValues(
                                        alpha: 0.85,
                                      ),
                                      width: 3,
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.person_outline_rounded,
                                    color: StudyFlowTheme.sageStrong,
                                    size: 24,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 8,
                        ),
                        sliver: SliverToBoxAdapter(
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 260),
                            curve: Curves.easeOutCubic,
                            child: GestureDetector(
                              onTap: _pickDate,
                              child: GlassContainer(
                                radius: 20,
                                padding: const EdgeInsets.all(8),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Container(
                                        height: 46,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFEDE8FF),
                                          borderRadius: BorderRadius.circular(
                                            15,
                                          ),
                                        ),
                                        alignment: Alignment.center,
                                        child: Text(
                                          _dateLabel(),
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w800,
                                            color: StudyFlowTheme.sageStrong,
                                          ),
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: Center(
                                        child: Text(
                                          'Today',
                                          style: TextStyle(
                                            color: StudyFlowTheme.muted,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const Icon(
                                      Icons.keyboard_arrow_down_rounded,
                                      size: 21,
                                      color: StudyFlowTheme.muted,
                                    ),
                                    const SizedBox(width: 8),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
                        sliver: SliverToBoxAdapter(
                          child: GlassCard(
                            radius: 30,
                            padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
                            child: Row(
                              children: [
                                ProgressRing(
                                  value: progress,
                                  size: 110,
                                  strokeWidth: 10,
                                  color: StudyFlowTheme.sageStrong,
                                ),
                                const SizedBox(width: 18),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      ProgressPill(
                                        text: chapters.isEmpty
                                            ? 'START HERE'
                                            : 'STUDY PLAN',
                                        color: Colors.white,
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        chapters.isEmpty
                                            ? "Let's create your study plan."
                                            : 'Your study progress',
                                        style: const TextStyle(
                                          color: StudyFlowTheme.charcoal,
                                          fontSize: 22,
                                          height: 1.05,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        chapters.isEmpty
                                            ? 'Add your first chapter to begin tracking progress.'
                                            : '$completedChapters of ${chapters.length} chapters completed',
                                        style: TextStyle(
                                          color: StudyFlowTheme.muted,
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.w600,
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
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 10),
                        sliver: SliverToBoxAdapter(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Quick actions',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.4,
                                ),
                              ),
                              Text(
                                'Stay consistent',
                                style: TextStyle(
                                  color: StudyFlowTheme.muted,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        sliver: SliverToBoxAdapter(
                          child: Row(
                            children: [
                              Expanded(
                                child: GlassCard(
                                  radius: 22,
                                  onTap: () => _openFocus(
                                    focusChapter?.title ?? 'Independent study',
                                    focusChapter?.subject ?? 'Personal study',
                                    focusChapter?.estimatedMinutes ?? 25,
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(15),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          width: 42,
                                          height: 42,
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFEDE8FF),
                                            borderRadius: BorderRadius.circular(
                                              14,
                                            ),
                                          ),
                                          child: const Icon(
                                            Icons.timer_rounded,
                                            color: StudyFlowTheme.sageStrong,
                                          ),
                                        ),
                                        const SizedBox(height: 13),
                                        const Text(
                                          'Focus',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          'Start a session',
                                          style: TextStyle(
                                            fontSize: 11.5,
                                            color: StudyFlowTheme.muted,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: GlassCard(
                                  radius: 22,
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const StudyStreakScreen(),
                                    ),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(15),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          width: 42,
                                          height: 42,
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFFFF1D7),
                                            borderRadius: BorderRadius.circular(
                                              14,
                                            ),
                                          ),
                                          child: const Icon(
                                            Icons.local_fire_department_rounded,
                                            color: Color(0xFFF0A13A),
                                          ),
                                        ),
                                        const SizedBox(height: 13),
                                        Text(
                                          '${StudyFlowData.instance.currentStreak} days',
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          'Study streak',
                                          style: TextStyle(
                                            fontSize: 11.5,
                                            color: StudyFlowTheme.muted,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (isLoading)
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(20, 22, 20, 12),
                          sliver: SliverToBoxAdapter(
                            child: GlassCard(
                              radius: 22,
                              child: const Padding(
                                padding: EdgeInsets.all(20),
                                child: Center(
                                  child: SizedBox(
                                    width: 28,
                                    height: 28,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 3,
                                      color: StudyFlowTheme.sageStrong,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        )
                      else if (storeError != null)
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(20, 22, 20, 12),
                          sliver: SliverToBoxAdapter(
                            child: GlassCard(
                              radius: 24,
                              child: Padding(
                                padding: const EdgeInsets.all(20),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Icon(
                                      Icons.error_outline_rounded,
                                      color: StudyFlowTheme.danger,
                                      size: 30,
                                    ),
                                    const SizedBox(height: 12),
                                    const Text(
                                      'Could not load your study plan.',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Check your connection and try again.',
                                      style: TextStyle(
                                        color: StudyFlowTheme.muted,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        )
                      else if (chapters.isEmpty)
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(20, 22, 20, 10),
                          sliver: SliverToBoxAdapter(
                            child: GlassCard(
                              radius: 24,
                              child: Padding(
                                padding: const EdgeInsets.all(20),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Icon(
                                      Icons.auto_stories_outlined,
                                      color: StudyFlowTheme.sageStrong,
                                      size: 30,
                                    ),
                                    const SizedBox(height: 12),
                                    const Text(
                                      "Let's create your study plan.",
                                      style: TextStyle(
                                        fontSize: 19,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      'Add a chapter to start tracking your study progress.',
                                      style: TextStyle(
                                        color: StudyFlowTheme.muted,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    FilledButton.icon(
                                      onPressed: () =>
                                          _openChapterEditor(context),
                                      icon: const Icon(Icons.add_rounded),
                                      label: const Text(
                                        'Create Your First Chapter',
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        )
                      else ...[
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(20, 22, 20, 10),
                          sliver: SliverToBoxAdapter(
                            child: Row(
                              children: [
                                const Expanded(
                                  child: Text(
                                    'Today\'s tasks',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: -0.4,
                                    ),
                                  ),
                                ),
                                Text(
                                  '${todayTasks.length} pending',
                                  style: const TextStyle(
                                    color: StudyFlowTheme.sageStrong,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        SliverPadding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          sliver: SliverToBoxAdapter(
                            child: GlassCard(
                              radius: 24,
                              child: todayTasks.isEmpty
                                  ? const Padding(
                                      padding: EdgeInsets.all(16),
                                      child: Text(
                                        'No tasks left for today — nice work.',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                          color: StudyFlowTheme.charcoal,
                                        ),
                                      ),
                                    )
                                  : Column(
                                      children: [
                                        for (final task in todayTasks)
                                          Padding(
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 6,
                                            ),
                                            child: InkWell(
                                              borderRadius:
                                                  BorderRadius.circular(18),
                                              onTap: () => _toggleChapterTask(
                                                context,
                                                task,
                                              ),
                                              child: Container(
                                                padding: const EdgeInsets.all(
                                                  12,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: const Color(
                                                    0xFFF5F2FF,
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(18),
                                                ),
                                                child: Row(
                                                  children: [
                                                    Container(
                                                      width: 34,
                                                      height: 34,
                                                      decoration: BoxDecoration(
                                                        color: Colors.white,
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              12,
                                                            ),
                                                      ),
                                                      child: const Icon(
                                                        Icons
                                                            .check_circle_outline_rounded,
                                                        color: StudyFlowTheme
                                                            .sageStrong,
                                                      ),
                                                    ),
                                                    const SizedBox(width: 12),
                                                    Expanded(
                                                      child: Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: [
                                                          Text(
                                                            task.title,
                                                            style:
                                                                const TextStyle(
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w800,
                                                                  fontSize: 14,
                                                                ),
                                                          ),
                                                          const SizedBox(
                                                            height: 3,
                                                          ),
                                                          Text(
                                                            task.estimatedMinutes ==
                                                                    null
                                                                ? 'Flexible session'
                                                                : '${task.estimatedMinutes} minutes',
                                                            style: TextStyle(
                                                              color:
                                                                  StudyFlowTheme
                                                                      .muted,
                                                              fontSize: 12,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w600,
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
                                      ],
                                    ),
                            ),
                          ),
                        ),
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(20, 22, 20, 10),
                          sliver: SliverToBoxAdapter(
                            child: Row(
                              children: [
                                const Expanded(
                                  child: Text(
                                    'Chapter shortcuts',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: -0.4,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  tooltip: 'Create chapter',
                                  onPressed: () => _openChapterEditor(context),
                                  icon: const Icon(
                                    Icons.add_circle_outline_rounded,
                                    color: StudyFlowTheme.sageStrong,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        SliverPadding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          sliver: SliverToBoxAdapter(
                            child: Wrap(
                              spacing: 12,
                              runSpacing: 12,
                              children: [
                                for (final chapter in chapterShortcuts)
                                  SizedBox(
                                    width: 154,
                                    child: GlassCard(
                                      radius: 22,
                                      onTap: () => _openFocus(
                                        chapter.title,
                                        chapter.subject,
                                        chapter.estimatedMinutes,
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.all(14),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Container(
                                              width: 36,
                                              height: 36,
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFEDE8FF),
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              child: const Icon(
                                                Icons.auto_stories_rounded,
                                                color:
                                                    StudyFlowTheme.sageStrong,
                                                size: 20,
                                              ),
                                            ),
                                            const SizedBox(height: 12),
                                            Text(
                                              chapter.title,
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w800,
                                                fontSize: 14,
                                              ),
                                            ),
                                            const SizedBox(height: 5),
                                            Text(
                                              chapter.subject,
                                              style: TextStyle(
                                                color: StudyFlowTheme.muted,
                                                fontWeight: FontWeight.w600,
                                                fontSize: 11.5,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ],
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(20, 18, 20, 36),
                        sliver: SliverToBoxAdapter(
                            child: GlassCard(
                              key: const ValueKey('home-motivation-card'),
                            radius: 22,
                              onTap: _showAnotherHomeQuote,
                              child: Row(
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEDE8FF),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: const Icon(
                                    Icons.lightbulb_rounded,
                                    color: StudyFlowTheme.sageStrong,
                                  ),
                                ),
                                const SizedBox(width: 13),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _motivationQuotes[_homeQuoteIndex],
                                        key: const ValueKey(
                                          'home-motivation-quote',
                                        ),
                                        style: TextStyle(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 14,
                                          color: StudyFlowTheme.charcoal,
                                        ),
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                        'Tap for another quote',
                                        style: TextStyle(
                                          color: StudyFlowTheme.muted,
                                          fontSize: 12,
                                          height: 1.35,
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
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

Future<void> _openChapterEditor(
  BuildContext context, {
  StudyChapter? chapter,
}) async {
  final draft = await _showStudyChapterDialog(context, chapter: chapter);
  if (draft == null || !context.mounted) return;

  try {
    if (chapter == null) {
      await StudyPlanStore.instance.createChapter(draft);
    } else {
      await StudyPlanStore.instance.updateChapter(chapter.id, draft);
    }
  } catch (error, stackTrace) {
    if (context.mounted) _showStudyPlanError(context, error, stackTrace);
  }
}

Future<StudyChapterDraft?> _showStudyChapterDialog(
  BuildContext context, {
  StudyChapter? chapter,
}) async {
  final titleController = TextEditingController(text: chapter?.title ?? '');
  final subjectController = TextEditingController(text: chapter?.subject ?? '');
  final descriptionController = TextEditingController(
    text: chapter?.description ?? '',
  );
  final durationController = TextEditingController(
    text: (chapter?.estimatedMinutes ?? 30).toString(),
  );

  try {
    return await showDialog<StudyChapterDraft>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(chapter == null ? 'Create chapter' : 'Edit chapter'),
        content: SizedBox(
          width: min(MediaQuery.sizeOf(dialogContext).width * 0.85, 560.0),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(labelText: 'Chapter title'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: subjectController,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Subject or category',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descriptionController,
                  minLines: 3,
                  maxLines: null,
                  keyboardType: TextInputType.multiline,
                  textAlignVertical: TextAlignVertical.top,
                  decoration: const InputDecoration(
                    labelText: 'Description (optional)',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: durationController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Estimated minutes',
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final title = titleController.text.trim();
              final subject = subjectController.text.trim();
              final minutes = int.tryParse(durationController.text.trim());
              if (title.isEmpty ||
                  subject.isEmpty ||
                  minutes == null ||
                  minutes <= 0) {
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Enter a title, subject, and positive duration.',
                    ),
                  ),
                );
                return;
              }
              Navigator.pop(
                dialogContext,
                StudyChapterDraft(
                  title: title,
                  subject: subject,
                  description: descriptionController.text,
                  estimatedMinutes: minutes,
                ),
              );
            },
            child: Text(chapter == null ? 'Create chapter' : 'Save changes'),
          ),
        ],
      ),
    );
  } finally {
    titleController.dispose();
    subjectController.dispose();
    descriptionController.dispose();
    durationController.dispose();
  }
}

Future<StudyChapterTaskDraft?> _showStudyTaskDialog(
  BuildContext context, {
  StudyChapterTask? task,
}) async {
  final titleController = TextEditingController(text: task?.title ?? '');
  final durationController = TextEditingController(
    text: task?.estimatedMinutes?.toString() ?? '',
  );

  try {
    return await showDialog<StudyChapterTaskDraft>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(task == null ? 'Add topic or task' : 'Edit topic or task'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(labelText: 'Title'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: durationController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Estimated minutes (optional)',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final title = titleController.text.trim();
              final rawMinutes = durationController.text.trim();
              final minutes = rawMinutes.isEmpty
                  ? null
                  : int.tryParse(rawMinutes);
              if (title.isEmpty ||
                  (rawMinutes.isNotEmpty &&
                      (minutes == null || minutes <= 0))) {
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  const SnackBar(
                    content: Text('Enter a title and valid optional duration.'),
                  ),
                );
                return;
              }
              Navigator.pop(
                dialogContext,
                StudyChapterTaskDraft(title: title, estimatedMinutes: minutes),
              );
            },
            child: Text(task == null ? 'Add' : 'Save'),
          ),
        ],
      ),
    );
  } finally {
    titleController.dispose();
    durationController.dispose();
  }
}

Future<void> _toggleChapterCompletion(
  BuildContext context,
  StudyChapter chapter,
) async {
  final completed = !chapter.isCompleted;
  try {
    await StudyPlanStore.instance.setChapterCompleted(
      chapter.id,
      completed: completed,
    );
    try {
      await StudyFlowData.instance.recordTask(
        completed: completed,
        minutes: chapter.estimatedMinutes,
      );
    } catch (_) {
      await StudyPlanStore.instance.setChapterCompleted(
        chapter.id,
        completed: chapter.isCompleted,
      );
      rethrow;
    }
  } catch (error, stackTrace) {
    if (context.mounted) _showStudyPlanError(context, error, stackTrace);
  }
}

Future<void> _toggleChapterTask(
  BuildContext context,
  StudyChapterTask task,
) async {
  final completed = !task.isCompleted;
  try {
    await StudyPlanStore.instance.setTaskCompleted(
      task.id,
      completed: completed,
    );
    try {
      await StudyFlowData.instance.recordTask(
        completed: completed,
        minutes: task.estimatedMinutes ?? 0,
      );
    } catch (_) {
      await StudyPlanStore.instance.setTaskCompleted(
        task.id,
        completed: task.isCompleted,
      );
      rethrow;
    }
  } catch (error, stackTrace) {
    if (context.mounted) _showStudyPlanError(context, error, stackTrace);
  }
}

void _showStudyPlanError(
  BuildContext context,
  Object error,
  StackTrace stackTrace,
) {
  developer.log(
    'Study plan operation failed.',
    name: 'StudyPlan',
    error: error,
    stackTrace: stackTrace,
  );
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text('Could not save your study plan. Please try again.'),
    ),
  );
}

Future<bool> _confirmStudyPlanDeletion(
  BuildContext context, {
  required String title,
  required String message,
}) async =>
    await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    ) ??
    false;

class StudyChapterCard extends StatelessWidget {
  const StudyChapterCard({
    super.key,
    required this.chapter,
    required this.onToggleCompleted,
    required this.onToggleTask,
    required this.onFocus,
    this.onEdit,
    this.onDelete,
    this.onAddTask,
    this.onEditTask,
    this.onDeleteTask,
  });

  final StudyChapter chapter;
  final VoidCallback onToggleCompleted;
  final ValueChanged<StudyChapterTask> onToggleTask;
  final VoidCallback onFocus;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onAddTask;
  final ValueChanged<StudyChapterTask>? onEditTask;
  final ValueChanged<StudyChapterTask>? onDeleteTask;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      radius: 22,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Checkbox(
                value: chapter.isCompleted,
                onChanged: (_) => onToggleCompleted(),
                activeColor: StudyFlowTheme.sage,
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      chapter.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        decoration: chapter.isCompleted
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      chapter.subject,
                      style: const TextStyle(
                        color: StudyFlowTheme.sageStrong,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Start focus session',
                onPressed: onFocus,
                icon: const Icon(Icons.play_circle_outline_rounded),
              ),
              if (onEdit != null || onDelete != null)
                PopupMenuButton<String>(
                  tooltip: 'Chapter actions',
                  onSelected: (value) {
                    if (value == 'edit') onEdit?.call();
                    if (value == 'delete') onDelete?.call();
                  },
                  itemBuilder: (context) => [
                    if (onEdit != null)
                      const PopupMenuItem(value: 'edit', child: Text('Edit')),
                    if (onDelete != null)
                      const PopupMenuItem(
                        value: 'delete',
                        child: Text('Delete'),
                      ),
                  ],
                ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(left: 12, right: 12, bottom: 8),
            child: Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                ProgressPill(text: '${chapter.estimatedMinutes} MIN'),
                if (chapter.isCompleted) const ProgressPill(text: 'COMPLETED'),
              ],
            ),
          ),
          if (chapter.description?.isNotEmpty == true)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
              child: Text(
                chapter.description!,
                style: TextStyle(color: StudyFlowTheme.muted, height: 1.4),
              ),
            ),
          for (final task in chapter.tasks)
            Padding(
              padding: const EdgeInsets.only(left: 6),
              child: Row(
                children: [
                  Checkbox(
                    value: task.isCompleted,
                    onChanged: (_) => onToggleTask(task),
                    activeColor: StudyFlowTheme.sage,
                    visualDensity: VisualDensity.compact,
                  ),
                  Expanded(
                    child: Text(
                      task.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        decoration: task.isCompleted
                            ? TextDecoration.lineThrough
                            : null,
                        color: task.isCompleted
                            ? StudyFlowTheme.muted
                            : StudyFlowTheme.charcoal,
                      ),
                    ),
                  ),
                  if (task.estimatedMinutes != null)
                    Text(
                      '${task.estimatedMinutes}m',
                      style: TextStyle(
                        color: StudyFlowTheme.muted,
                        fontSize: 12,
                      ),
                    ),
                  if (onEditTask != null || onDeleteTask != null)
                    PopupMenuButton<String>(
                      tooltip: 'Topic actions',
                      onSelected: (value) {
                        if (value == 'edit') onEditTask?.call(task);
                        if (value == 'delete') onDeleteTask?.call(task);
                      },
                      itemBuilder: (context) => [
                        if (onEditTask != null)
                          const PopupMenuItem(
                            value: 'edit',
                            child: Text('Edit'),
                          ),
                        if (onDeleteTask != null)
                          const PopupMenuItem(
                            value: 'delete',
                            child: Text('Delete'),
                          ),
                      ],
                    ),
                ],
              ),
            ),
          if (onAddTask != null)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: onAddTask,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add topic or task'),
              ),
            ),
        ],
      ),
    );
  }
}

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isUpdatingPhoto = false;

  Future<void> _pickProfilePhoto() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null || _isUpdatingPhoto) return;

    setState(() => _isUpdatingPhoto = true);
    try {
      final image = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 85,
      );
      if (image == null) return;

      final extension = image.name.split('.').last.toLowerCase();
      final mimeType =
          image.mimeType ??
          switch (extension) {
            'png' => 'image/png',
            'webp' => 'image/webp',
            'jpg' || 'jpeg' => 'image/jpeg',
            _ => '',
          };
      if (!const {'image/jpeg', 'image/png', 'image/webp'}.contains(mimeType)) {
        throw const FormatException('Choose a JPEG, PNG, or WebP image.');
      }

      final path = '${user.id}/avatar';
      final storage = Supabase.instance.client.storage.from(
        _profilePhotosBucket,
      );
      await storage.uploadBinary(
        path,
        await image.readAsBytes(),
        fileOptions: FileOptions(upsert: true, contentType: mimeType),
      );
      await Supabase.instance.client
          .from('profiles')
          .update({'avatar_url': path})
          .eq('id', user.id);
      final signedUrl = await _createProfilePhotoSignedUrl(path);
      StudyFlowData.instance.setProfileAvatar(path: path, url: signedUrl);
    } catch (error, stackTrace) {
      developer.log(
        'Could not upload the profile photo.',
        name: 'StudyFlowProfile',
        error: error,
        stackTrace: stackTrace,
      );
      if (mounted) {
        final message = error is FormatException
            ? error.message
            : 'Could not upload your photo. Check your connection and try again.';
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
      }
    } finally {
      if (mounted) setState(() => _isUpdatingPhoto = false);
    }
  }

  Future<void> _removeProfilePhoto() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null || _isUpdatingPhoto) return;
    final path = StudyFlowData.instance.profileAvatarPath;

    setState(() => _isUpdatingPhoto = true);
    try {
      await Supabase.instance.client
          .from('profiles')
          .update({'avatar_url': null})
          .eq('id', user.id);
      StudyFlowData.instance.setProfileAvatar(path: null, url: null);

      if (path != null) {
        try {
          await Supabase.instance.client.storage
              .from(_profilePhotosBucket)
              .remove([path]);
        } catch (error, stackTrace) {
          developer.log(
            'Could not remove the previous profile photo object.',
            name: 'StudyFlowProfile',
            error: error,
            stackTrace: stackTrace,
          );
        }
      }
    } catch (error, stackTrace) {
      developer.log(
        'Could not remove the profile photo.',
        name: 'StudyFlowProfile',
        error: error,
        stackTrace: stackTrace,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not remove your photo. Please try again.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isUpdatingPhoto = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    final name = StudyFlowData.instance.profileDisplayName;
    final photoUrl = StudyFlowData.instance.profileAvatarUrl;
    final hasPhoto = StudyFlowData.instance.profileAvatarPath != null;

    final String email = user?.email ?? 'No email available';

    return Scaffold(
      backgroundColor: StudyFlowTheme.backgroundLight,
      appBar: const GlassAppBar(title: 'Profile'),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 30),
          child: Column(
            children: [
              const SizedBox(height: 10),
              GestureDetector(
                onTap: _isUpdatingPhoto ? null : _pickProfilePhoto,
                child: Stack(
                  children: [
                    Container(
                      width: 92,
                      height: 92,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [Color(0xFFDCEFE0), Color(0xFFBBD5C1)],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.06),
                            blurRadius: 18,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: photoUrl == null
                            ? const Icon(
                                Icons.person_outline,
                                size: 48,
                                color: StudyFlowTheme.sageStrong,
                              )
                            : Image.network(
                                photoUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (_, _, _) => const Icon(
                                  Icons.person_outline,
                                  size: 48,
                                  color: StudyFlowTheme.sageStrong,
                                ),
                              ),
                      ),
                    ),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: CircleAvatar(
                        radius: 16,
                        backgroundColor: Colors.white,
                        child: _isUpdatingPhoto
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(
                                Icons.camera_alt_outlined,
                                size: 17,
                                color: StudyFlowTheme.sageStrong,
                              ),
                      ),
                    ),
                  ],
                ),
              ),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 4,
                children: [
                  TextButton.icon(
                    onPressed: _isUpdatingPhoto ? null : _pickProfilePhoto,
                    icon: const Icon(Icons.edit_outlined, size: 17),
                    label: Text(hasPhoto ? 'Change photo' : 'Edit photo'),
                  ),
                  if (hasPhoto)
                    TextButton.icon(
                      onPressed: _isUpdatingPhoto ? null : _removeProfilePhoto,
                      icon: const Icon(Icons.delete_outline, size: 17),
                      label: const Text('Remove'),
                    ),
                ],
              ),
              const SizedBox(height: 18),
              Text(
                name,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                email,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: StudyFlowTheme.muted,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 28),

              GlassCard(
                radius: 20,
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  leading: Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEAF5EE),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.person_outline,
                      color: StudyFlowTheme.sageStrong,
                    ),
                  ),
                  title: const Text(
                    'Username',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      name,
                      style: TextStyle(
                        color: StudyFlowTheme.muted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  trailing: const Icon(
                    Icons.edit_outlined,
                    color: StudyFlowTheme.muted,
                  ),
                  onTap: () async {
                    final controller = TextEditingController(text: name);
                    final result = await showDialog<String>(
                      context: context,
                      builder: (dialogContext) => AlertDialog(
                        title: const Text('Edit username'),
                        content: TextField(
                          controller: controller,
                          autofocus: true,
                          decoration: const InputDecoration(
                            labelText: 'Username',
                          ),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(dialogContext).pop(),
                            child: const Text('Cancel'),
                          ),
                          FilledButton(
                            onPressed: () => Navigator.of(
                              dialogContext,
                            ).pop(controller.text),
                            child: const Text('Save'),
                          ),
                        ],
                      ),
                    );

                    if (result == null || !context.mounted) return;

                    final value = result.trim();
                    final error = validateUsername(value);
                    if (error != null) {
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text(error)));
                      return;
                    }

                    try {
                      await StudyFlowData.instance.updateProfileName(value);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Username updated.')),
                        );
                      }
                    } catch (error) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              error is ArgumentError
                                  ? error.message.toString()
                                  : 'Could not update your username. Please try again.',
                            ),
                          ),
                        );
                      }
                    }
                  },
                ),
              ),

              const SizedBox(height: 12),

              GlassCard(
                radius: 20,
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  leading: Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEAF5EE),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.email_outlined,
                      color: StudyFlowTheme.sageStrong,
                    ),
                  ),
                  title: const Text(
                    'Email',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      email,
                      style: TextStyle(
                        color: StudyFlowTheme.muted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              GlassCard(
                radius: 20,
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  leading: Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEAF5EE),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.lock_reset_rounded,
                      color: StudyFlowTheme.sageStrong,
                    ),
                  ),
                  title: const Text(
                    'Reset password',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                  subtitle: const Padding(
                    padding: EdgeInsets.only(top: 4),
                    child: Text(
                      'Send a recovery email for this account',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  trailing: const Icon(
                    Icons.chevron_right,
                    color: StudyFlowTheme.muted,
                  ),
                  onTap: () {
                    if (context.mounted) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ForgotPasswordScreen(
                            initialEmail: user?.email ?? '',
                          ),
                        ),
                      );
                    }
                  },
                ),
              ),

              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                height: 54,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    await Supabase.instance.client.auth.signOut();

                    if (context.mounted) {
                      Navigator.pop(context);
                    }
                  },
                  icon: const Icon(Icons.logout, color: Colors.redAccent),
                  label: const Text(
                    'Sign Out',
                    style: TextStyle(
                      color: Colors.redAccent,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.redAccent),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PlannerScreen extends StatefulWidget {
  const PlannerScreen({super.key});

  @override
  State<PlannerScreen> createState() => _PlannerScreenState();
}

class _PlannerScreenState extends State<PlannerScreen> {
  Future<void> _deleteChapter(StudyChapter chapter) async {
    final confirmed = await _confirmStudyPlanDeletion(
      context,
      title: 'Delete chapter?',
      message: '"${chapter.title}" and its topics will be permanently removed.',
    );
    if (!confirmed || !mounted) return;

    try {
      await StudyPlanStore.instance.deleteChapter(chapter.id);
    } catch (error, stackTrace) {
      if (mounted) _showStudyPlanError(context, error, stackTrace);
    }
  }

  Future<void> _addTask(StudyChapter chapter) async {
    final draft = await _showStudyTaskDialog(context);
    if (draft == null) return;
    try {
      await StudyPlanStore.instance.createTask(chapter.id, draft);
    } catch (error, stackTrace) {
      if (mounted) _showStudyPlanError(context, error, stackTrace);
    }
  }

  Future<void> _editTask(StudyChapterTask task) async {
    final draft = await _showStudyTaskDialog(context, task: task);
    if (draft == null) return;
    try {
      await StudyPlanStore.instance.updateTask(task.id, draft);
    } catch (error, stackTrace) {
      if (mounted) _showStudyPlanError(context, error, stackTrace);
    }
  }

  Future<void> _deleteTask(StudyChapterTask task) async {
    final confirmed = await _confirmStudyPlanDeletion(
      context,
      title: 'Delete topic or task?',
      message: '"${task.title}" will be permanently removed.',
    );
    if (!confirmed) return;
    try {
      await StudyPlanStore.instance.deleteTask(task.id);
    } catch (error, stackTrace) {
      if (mounted) _showStudyPlanError(context, error, stackTrace);
    }
  }

  Future<void> _reorderChapters(int oldIndex, int newIndex) async {
    final orderedIds = StudyPlanStore.instance.chapters
        .map((chapter) => chapter.id)
        .toList();
    final moved = orderedIds.removeAt(oldIndex);
    orderedIds.insert(newIndex, moved);
    try {
      await StudyPlanStore.instance.reorderChapters(orderedIds);
    } catch (error, stackTrace) {
      if (mounted) _showStudyPlanError(context, error, stackTrace);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Study Planner',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.7,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Plan your study sessions and stay on track.',
              style: TextStyle(
                color: StudyFlowTheme.muted,
                fontSize: 14.5,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 24),
            GlassContainer(
              radius: 22,
              padding: const EdgeInsets.all(10),
              child: Row(
                children: [
                  ...List.generate(4, (index) {
                    final date = DateTime.now().add(Duration(days: index));
                    final label = index == 0
                        ? 'Today'
                        : const [
                            'Mon',
                            'Tue',
                            'Wed',
                            'Thu',
                            'Fri',
                            'Sat',
                            'Sun',
                          ][date.weekday - 1];
                    return [
                      if (index > 0) const SizedBox(width: 10),
                      Expanded(
                        child: _PlannerDate(
                          day: '${date.day}',
                          label: label,
                          selected: index == 0,
                        ),
                      ),
                    ];
                  }).expand((children) => children),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Your chapters',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.2,
                  ),
                ),
                FilledButton.icon(
                  onPressed: () => _openChapterEditor(context),
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Create chapter'),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Expanded(
              child: AnimatedBuilder(
                animation: StudyPlanStore.instance,
                builder: (context, _) {
                  final store = StudyPlanStore.instance;
                  if (store.isLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (store.error != null) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('Could not load your chapters.'),
                          const SizedBox(height: 10),
                          OutlinedButton.icon(
                            onPressed: () => store.loadForUser(
                              Supabase.instance.client.auth.currentUser!.id,
                              force: true,
                            ),
                            icon: const Icon(Icons.refresh),
                            label: const Text('Retry'),
                          ),
                        ],
                      ),
                    );
                  }
                  if (store.chapters.isEmpty) {
                    return StudyPlanEmptyState(
                      onCreate: () => _openChapterEditor(context),
                    );
                  }

                  return ReorderableListView.builder(
                    itemCount: store.chapters.length,
                    onReorder: _reorderChapters,
                    itemBuilder: (context, index) {
                      final chapter = store.chapters[index];
                      return Padding(
                        key: ValueKey(chapter.id),
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ReorderableDragStartListener(
                              index: index,
                              child: const SizedBox(
                                height: 52,
                                child: Icon(
                                  Icons.drag_handle_rounded,
                                  color: StudyFlowTheme.muted,
                                ),
                              ),
                            ),
                            Expanded(
                              child: StudyChapterCard(
                                chapter: chapter,
                                onToggleCompleted: () =>
                                    _toggleChapterCompletion(context, chapter),
                                onToggleTask: (task) =>
                                    _toggleChapterTask(context, task),
                                onFocus: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => FocusScreen(
                                      taskTitle: chapter.title,
                                      subject: chapter.subject,
                                      durationMinutes: chapter.estimatedMinutes,
                                    ),
                                  ),
                                ),
                                onEdit: () => _openChapterEditor(
                                  context,
                                  chapter: chapter,
                                ),
                                onDelete: () => _deleteChapter(chapter),
                                onAddTask: () => _addTask(chapter),
                                onEditTask: _editTask,
                                onDeleteTask: _deleteTask,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class StudyPlanEmptyState extends StatelessWidget {
  const StudyPlanEmptyState({super.key, required this.onCreate});

  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: GlassCard(
          radius: 24,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.auto_stories_outlined,
                color: StudyFlowTheme.sageStrong,
                size: 38,
              ),
              const SizedBox(height: 12),
              const Text(
                "Let's create your study plan.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              Text(
                'Create a chapter to organize topics and track your progress.',
                textAlign: TextAlign.center,
                style: TextStyle(color: StudyFlowTheme.muted, height: 1.4),
              ),
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: onCreate,
                icon: const Icon(Icons.add_rounded),
                label: const Text('Create Your First Chapter'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlannerDate extends StatelessWidget {
  final String day;
  final String label;
  final bool selected;

  const _PlannerDate({
    required this.day,
    required this.label,
    required this.selected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 13),
      decoration: BoxDecoration(
        gradient: selected
            ? const LinearGradient(
                colors: [Color(0xFF5F9C75), Color(0xFF407D5E)],
              )
            : null,
        color: selected ? null : Colors.white.withValues(alpha: 0.28),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: selected ? const Color(0xFF5E9A74) : const Color(0x1F5E7B5A),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: selected ? Colors.white70 : StudyFlowTheme.muted,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            day,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: selected ? Colors.white : StudyFlowTheme.charcoal,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// FOCUS
// ─────────────────────────────────────────────

class FocusScreen extends StatefulWidget {
  final String taskTitle;
  final String subject;
  final int durationMinutes;

  const FocusScreen({
    super.key,
    this.taskTitle = 'Personal study',
    this.subject = 'Study session',
    this.durationMinutes = 45,
  });

  @override
  State<FocusScreen> createState() => _FocusScreenState();
}

class _FocusScreenState extends State<FocusScreen> {
  Timer? _timer;

  late int _remainingSeconds;

  bool _isRunning = false;

  @override
  void initState() {
    super.initState();

    _remainingSeconds = widget.durationMinutes * 60;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    if (_remainingSeconds <= 0) {
      _resetTimer();
    }

    _timer?.cancel();

    setState(() {
      _isRunning = true;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds <= 1) {
        timer.cancel();

        if (mounted) {
          setState(() {
            _remainingSeconds = 0;
            _isRunning = false;
          });

          unawaited(_recordFocusCompletion());
        }

        return;
      }

      if (mounted) {
        setState(() {
          _remainingSeconds--;
        });
      }
    });
  }

  void _pauseTimer() {
    _timer?.cancel();

    setState(() {
      _isRunning = false;
    });
  }

  void _resetTimer() {
    _timer?.cancel();

    setState(() {
      _remainingSeconds = widget.durationMinutes * 60;
      _isRunning = false;
    });
  }

  void _showCompletedMessage() {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Focus session completed! 🎉')),
    );
  }

  Future<void> _recordFocusCompletion() async {
    try {
      await StudyFlowData.instance.recordFocusSession(widget.durationMinutes);
      _showCompletedMessage();
    } catch (error, stackTrace) {
      developer.log(
        'Could not save the completed focus session.',
        name: 'StudyFlowData',
        error: error,
        stackTrace: stackTrace,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Focus finished, but progress could not be saved.'),
          ),
        );
      }
    }
  }

  String _formatTime() {
    final minutes = _remainingSeconds ~/ 60;

    final seconds = _remainingSeconds % 60;

    return '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final totalSeconds = widget.durationMinutes * 60;
    final progress = totalSeconds == 0 ? 0.0 : _remainingSeconds / totalSeconds;

    return Scaffold(
      backgroundColor: StudyFlowTheme.backgroundLight,
      appBar: const GlassAppBar(title: 'Focus Session'),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
          child: GlassContainer(
            radius: 32,
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Text(
                  widget.taskTitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 23,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  widget.subject,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: StudyFlowTheme.muted,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: 260,
                  height: 260,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 250,
                        height: 250,
                        child: CircularProgressIndicator(
                          value: progress,
                          strokeWidth: 10,
                          backgroundColor: const Color(0xFFE7F0E8),
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            StudyFlowTheme.sage,
                          ),
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _formatTime(),
                            style: const TextStyle(
                              fontSize: 46,
                              fontWeight: FontWeight.w800,
                              color: StudyFlowTheme.charcoal,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            _isRunning ? 'Stay focused' : 'Focus session',
                            style: TextStyle(
                              color: StudyFlowTheme.muted,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: _isRunning ? _pauseTimer : _startTimer,
                        icon: Icon(_isRunning ? Icons.pause : Icons.play_arrow),
                        label: Text(_isRunning ? 'Pause' : 'Start Session'),
                        style: FilledButton.styleFrom(
                          backgroundColor: StudyFlowTheme.sage,
                          minimumSize: const Size(0, 52),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      height: 52,
                      width: 52,
                      child: OutlinedButton(
                        onPressed: _resetTimer,
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          side: const BorderSide(color: Color(0x2E5D8E71)),
                        ),
                        child: const Icon(
                          Icons.restart_alt,
                          color: StudyFlowTheme.sageStrong,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextButton.icon(
                  onPressed: () {
                    _mainNavigationKey.currentState?.goHome();
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  },
                  icon: const Icon(Icons.arrow_back_rounded, size: 18),
                  label: const Text('Back to home'),
                  style: TextButton.styleFrom(
                    foregroundColor: StudyFlowTheme.sageStrong,
                    minimumSize: const Size(0, 42),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// NOTES
// ─────────────────────────────────────────────

class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key});

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId != null) {
      unawaited(StudyNoteStore.instance.loadForUser(userId));
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _editNote({StudyNote? note}) async {
    final titleController = TextEditingController(text: note?.title ?? '');
    final subjectController = TextEditingController(text: note?.subject ?? '');
    final contentController = TextEditingController(text: note?.content ?? '');

    try {
      final draft = await showDialog<StudyNoteDraft>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(note == null ? 'Create note' : 'Edit note'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(labelText: 'Title'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: subjectController,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Subject or category (optional)',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: contentController,
                  minLines: 4,
                  maxLines: 8,
                  decoration: const InputDecoration(labelText: 'Content'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final title = titleController.text.trim();
                final content = contentController.text.trim();
                if (title.isEmpty || content.isEmpty) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    const SnackBar(content: Text('Enter a title and content.')),
                  );
                  return;
                }
                Navigator.pop(
                  dialogContext,
                  StudyNoteDraft(
                    title: title,
                    subject: subjectController.text,
                    content: content,
                  ),
                );
              },
              child: const Text('Save'),
            ),
          ],
        ),
      );

      if (draft == null) return;
      if (note == null) {
        await StudyNoteStore.instance.create(draft);
      } else {
        await StudyNoteStore.instance.update(note.id, draft);
      }
    } catch (error, stackTrace) {
      if (mounted) _showNotesError(context, error, stackTrace);
    } finally {
      titleController.dispose();
      subjectController.dispose();
      contentController.dispose();
    }
  }

  Future<void> _deleteNote(StudyNote note) async {
    final confirmed =
        await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Delete note?'),
            content: Text('"${note.title}" will be permanently removed.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text('Delete'),
              ),
            ],
          ),
        ) ??
        false;
    if (!confirmed) return;

    try {
      await StudyNoteStore.instance.delete(note.id);
    } catch (error, stackTrace) {
      if (mounted) _showNotesError(context, error, stackTrace);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'My Notes',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
                  ),
                ),
                IconButton(
                  tooltip: 'Create note',
                  onPressed: () => _editNote(),
                  icon: const Icon(Icons.add_rounded),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Keep your learning organized.',
              style: TextStyle(
                color: StudyFlowTheme.muted,
                fontSize: 14.5,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _searchController,
              onChanged: (value) => setState(() => _searchQuery = value.trim()),
              decoration: InputDecoration(
                hintText: 'Search notes',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _searchQuery.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Clear search',
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                        icon: const Icon(Icons.close_rounded),
                      ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: AnimatedBuilder(
                animation: StudyNoteStore.instance,
                builder: (context, _) {
                  final store = StudyNoteStore.instance;
                  if (store.isLoading ||
                      !store.isLoaded && store.error == null) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (store.error != null) {
                    final userId =
                        Supabase.instance.client.auth.currentUser?.id;
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('Could not load your notes.'),
                          const SizedBox(height: 10),
                          OutlinedButton.icon(
                            onPressed: userId == null
                                ? null
                                : () => unawaited(
                                    store.loadForUser(userId, force: true),
                                  ),
                            icon: const Icon(Icons.refresh),
                            label: const Text('Retry'),
                          ),
                        ],
                      ),
                    );
                  }

                  final notes = filterStudyNotes(store.notes, _searchQuery);

                  if (notes.isEmpty && _searchQuery.isEmpty) {
                    return StudyNotesEmptyState(onCreate: () => _editNote());
                  }
                  if (notes.isEmpty) {
                    return const Center(
                      child: Text('No notes match your search.'),
                    );
                  }

                  return ListView.builder(
                    itemCount: notes.length,
                    itemBuilder: (context, index) {
                      final note = notes[index];
                      return _NoteCard(
                        note: note,
                        onTap: () => _editNote(note: note),
                        onDelete: () => _deleteNote(note),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

void _showNotesError(
  BuildContext context,
  Object error,
  StackTrace stackTrace,
) {
  developer.log(
    'Note operation failed.',
    name: 'StudyFlowNotes',
    error: error,
    stackTrace: stackTrace,
  );
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('Could not save the note. Please try again.')),
  );
}

class StudyNotesEmptyState extends StatelessWidget {
  const StudyNotesEmptyState({super.key, required this.onCreate});

  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.sticky_note_2_outlined,
              size: 44,
              color: StudyFlowTheme.sageStrong,
            ),
            const SizedBox(height: 14),
            const Text(
              'No notes yet',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text(
              'Create your first note to keep your learning organized.',
              textAlign: TextAlign.center,
              style: TextStyle(color: StudyFlowTheme.muted, height: 1.4),
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: onCreate,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Create Note'),
            ),
          ],
        ),
      ),
    );
  }
}

class _NoteCard extends StatelessWidget {
  final StudyNote note;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _NoteCard({
    required this.note,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      margin: const EdgeInsets.only(bottom: 12),
      radius: 22,
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: const Color(0xFFEAF5EE),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.description_outlined,
              color: StudyFlowTheme.sageStrong,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  note.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                if (note.subject?.isNotEmpty == true) ...[
                  Text(
                    note.subject!,
                    style: const TextStyle(
                      color: StudyFlowTheme.sageStrong,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 5),
                ],
                Text(
                  note.content,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: StudyFlowTheme.muted,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            tooltip: 'Note actions',
            onSelected: (action) {
              if (action == 'edit') onTap();
              if (action == 'delete') onDelete();
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'edit', child: Text('Edit')),
              PopupMenuItem(value: 'delete', child: Text('Delete')),
            ],
          ),
        ],
      ),
    );
  }
}

class NoteDetailScreen extends StatefulWidget {
  final String title;
  final String subject;
  final String content;
  final void Function(String title, String subject, String content) onSave;

  const NoteDetailScreen({
    super.key,
    required this.title,
    required this.subject,
    required this.content,
    required this.onSave,
  });

  @override
  State<NoteDetailScreen> createState() => _NoteDetailScreenState();
}

class _NoteDetailScreenState extends State<NoteDetailScreen> {
  late String _title = widget.title;
  late String _subject = widget.subject;
  late String _content = widget.content;

  Future<void> _showEditDialog() async {
    final titleController = TextEditingController(text: _title);
    final subjectController = TextEditingController(text: _subject);
    final contentController = TextEditingController(text: _content);

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'Edit Note',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: InputDecoration(
                    labelText: 'Title',
                    prefixIcon: const Icon(Icons.title_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: subjectController,
                  decoration: InputDecoration(
                    labelText: 'Subject',
                    prefixIcon: const Icon(Icons.book_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: contentController,
                  minLines: 4,
                  maxLines: 8,
                  decoration: InputDecoration(
                    labelText: 'Note',
                    prefixIcon: const Icon(Icons.notes_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final title = titleController.text.trim();
                final subject = subjectController.text.trim();
                final content = contentController.text.trim();

                if (title.isEmpty || subject.isEmpty || content.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please fill in all fields.')),
                  );
                  return;
                }

                setState(() {
                  _title = title;
                  _subject = subject;
                  _content = content;
                });
                widget.onSave(title, subject, content);
                Navigator.pop(dialogContext);
              },
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF6FA67A),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text('Save Changes'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: StudyFlowTheme.backgroundLight,
      appBar: AppBar(
        title: const Text(
          'Note',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            tooltip: 'Edit note',
            icon: const Icon(Icons.edit_outlined),
            onPressed: _showEditDialog,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        child: GlassContainer(
          radius: 30,
          padding: const EdgeInsets.all(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _title,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _subject,
                style: const TextStyle(
                  color: StudyFlowTheme.sageStrong,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                _content,
                style: const TextStyle(
                  fontSize: 16,
                  height: 1.6,
                  color: StudyFlowTheme.charcoal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// ─────────────────────────────────────────────
// MORE
// ─────────────────────────────────────────────

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  Future<void> _showThemeDialog(BuildContext context) async {
    final selected = await showDialog<ThemeMode>(
      context: context,
      builder: (dialogContext) => SimpleDialog(
        title: const Text('Appearance'),
        children: [
          ListTile(
            leading: Icon(
              StudyFlowThemeController.instance.value == ThemeMode.light
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
            ),
            title: const Text('Light'),
            subtitle: const Text('Always use the light StudyFlow theme'),
            onTap: () => Navigator.pop(dialogContext, ThemeMode.light),
          ),
          ListTile(
            leading: Icon(
              StudyFlowThemeController.instance.value == ThemeMode.system
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
            ),
            title: const Text('Device setting'),
            subtitle: const Text('Follow your device preference safely'),
            onTap: () => Navigator.pop(dialogContext, ThemeMode.system),
          ),
        ],
      ),
    );

    if (selected != null) {
      StudyFlowThemeController.instance.value = selected;
    }
  }

  void _open(BuildContext context, String title) {
    final pages = <String, Widget>{
      'Goals': const GoalsScreen(),
      'Analytics': const AnalyticsScreen(),
      'Study Streak': const StudyStreakScreen(),
      'Motivation': const MotivationScreen(),
    };

    final page = pages[title];
    if (page == null) return;

    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 28, 20, 30),
        children: [
          const Text(
            'More',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.7,
            ),
          ),
          const SizedBox(height: 22),
          _MoreTile(
            icon: Icons.flag_outlined,
            title: 'Goals',
            subtitle: 'Set and track your daily study goal',
            onTap: () => _open(context, 'Goals'),
          ),
          _MoreTile(
            icon: Icons.bar_chart_outlined,
            title: 'Analytics',
            subtitle: 'View your weekly study progress',
            onTap: () => _open(context, 'Analytics'),
          ),
          _MoreTile(
            icon: Icons.local_fire_department_outlined,
            title: 'Study Streak',
            subtitle: 'Keep your study consistency going',
            onTap: () => _open(context, 'Study Streak'),
          ),
          _MoreTile(
            icon: Icons.lightbulb_outline,
            title: 'Motivation',
            subtitle: 'Daily quotes and study tips',
            onTap: () => _open(context, 'Motivation'),
          ),
          _MoreTile(
            icon: Icons.brightness_6_outlined,
            title: 'Appearance',
            subtitle: 'Light or follow your device setting',
            onTap: () => _showThemeDialog(context),
          ),
          const SizedBox(height: 4),
          GlassCard(
            radius: 22,
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 7,
              ),
              leading: Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFE9E8),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.logout, color: Colors.redAccent),
              ),
              title: const Text(
                'Sign Out',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              subtitle: const Padding(
                padding: EdgeInsets.only(top: 3),
                child: Text('Sign out of your StudyFlow account'),
              ),
              trailing: const Icon(
                Icons.chevron_right,
                color: StudyFlowTheme.muted,
              ),
              onTap: () async {
                await Supabase.instance.client.auth.signOut();
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _MoreTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _MoreTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      radius: 22,
      margin: const EdgeInsets.only(bottom: 12),
      onTap: onTap,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
        leading: Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: const Color(0xFFEAF5EE),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: StudyFlowTheme.sageStrong),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 3),
          child: Text(
            subtitle,
            style: TextStyle(
              color: StudyFlowTheme.muted,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        trailing: const Icon(Icons.chevron_right, color: StudyFlowTheme.muted),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// GOALS
// ─────────────────────────────────────────────

class GoalsScreen extends StatelessWidget {
  const GoalsScreen({super.key});

  String _formatMinutes(int minutes) {
    if (minutes < 60) return '$minutes min';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return m == 0 ? '${h}h' : '${h}h ${m}m';
  }

  Future<void> _changeGoal(BuildContext context) async {
    final controller = TextEditingController(
      text: StudyFlowData.instance.goalMinutes.toString(),
    );

    final value = await showDialog<int>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Set daily goal'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Study minutes',
            hintText: 'Example: 120',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final value = int.tryParse(controller.text.trim());
              if (value != null && value > 0) {
                Navigator.pop(dialogContext, value);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    controller.dispose();

    if (value != null) {
      try {
        await StudyFlowData.instance.setGoal(value);
      } catch (error, stackTrace) {
        if (context.mounted) {
          _showStudyPlanError(context, error, stackTrace);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: StudyFlowTheme.backgroundLight,
      appBar: const GlassAppBar(title: 'Goals'),
      body: AnimatedBuilder(
        animation: StudyFlowData.instance,
        builder: (context, _) {
          final data = StudyFlowData.instance;
          final progress = data.goalProgress;

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 30),
            children: [
              GlassContainer(
                radius: 28,
                padding: const EdgeInsets.all(22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.flag_rounded,
                      size: 34,
                      color: StudyFlowTheme.sageStrong,
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'Today’s study goal',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${_formatMinutes(data.completedMinutes)} of ${_formatMinutes(data.goalMinutes)} completed',
                      style: TextStyle(
                        color: StudyFlowTheme.muted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 12,
                        backgroundColor: Colors.white.withValues(alpha: 0.55),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          StudyFlowTheme.sage,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '${(progress * 100).round()}% complete',
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              GlassCard(
                radius: 22,
                child: ListTile(
                  leading: const Icon(
                    Icons.timer_outlined,
                    color: StudyFlowTheme.sageStrong,
                  ),
                  title: const Text(
                    'Daily target',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                  subtitle: Text(
                    _formatMinutes(data.goalMinutes),
                    style: TextStyle(
                      color: StudyFlowTheme.muted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  trailing: const Icon(
                    Icons.edit_outlined,
                    color: StudyFlowTheme.muted,
                  ),
                  onTap: () => _changeGoal(context),
                ),
              ),
              const SizedBox(height: 12),
              GlassCard(
                radius: 22,
                child: ListTile(
                  leading: const Icon(
                    Icons.task_alt,
                    color: StudyFlowTheme.sageStrong,
                  ),
                  title: const Text(
                    'Tasks completed',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                  subtitle: Text(
                    '${data.completedTasks} tasks completed',
                    style: TextStyle(
                      color: StudyFlowTheme.muted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'How goals work',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              Text(
                'Complete a planned task or finish a Focus session. Your study progress updates automatically.',
                style: TextStyle(
                  color: StudyFlowTheme.muted,
                  height: 1.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────
// ANALYTICS
// ─────────────────────────────────────────────

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  String _format(int minutes) {
    if (minutes < 60) return '$minutes min';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return m == 0 ? '${h}h' : '${h}h ${m}m';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: StudyFlowTheme.backgroundLight,
      appBar: const GlassAppBar(title: 'Analytics'),
      body: AnimatedBuilder(
        animation: StudyFlowData.instance,
        builder: (context, _) {
          final data = StudyFlowData.instance;
          final total = data.weeklyMinutes.fold<int>(0, (a, b) => a + b);

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 30),
            children: [
              Row(
                children: [
                  Expanded(
                    child: StatTile(
                      icon: Icons.timer_outlined,
                      value: _format(data.completedMinutes),
                      label: 'Today',
                      accent: StudyFlowTheme.sageStrong,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: StatTile(
                      icon: Icons.task_alt,
                      value: '${data.completedTasks}',
                      label: 'Tasks done',
                      accent: const Color(0xFF4F8D60),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              StatTile(
                icon: Icons.calendar_month_outlined,
                value: _format(total),
                label: 'Last 7 days',
                accent: const Color(0xFFA3C9B0),
              ),
              const SizedBox(height: 20),
              GlassContainer(
                radius: 28,
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Weekly progress',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Study time over the last 7 days',
                      style: TextStyle(
                        color: StudyFlowTheme.muted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      height: 220,
                      width: double.infinity,
                      child: _WeeklyLineChart(values: data.weeklyMinutes),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              GlassContainer(
                radius: 22,
                padding: const EdgeInsets.all(18),
                child: Row(
                  children: [
                    const Icon(
                      Icons.insights_outlined,
                      color: StudyFlowTheme.sageStrong,
                      size: 30,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        data.completedMinutes >= data.goalMinutes
                            ? 'Great work! You reached your daily goal. 🎉'
                            : 'Keep going — you are building your study habit.',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _WeeklyLineChart extends StatelessWidget {
  final List<int> values;

  const _WeeklyLineChart({required this.values});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _WeeklyChartPainter(values),
      child: const SizedBox.expand(),
    );
  }
}

class _WeeklyChartPainter extends CustomPainter {
  final List<int> values;

  _WeeklyChartPainter(this.values);

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;

    final chartLeft = 28.0;
    final chartRight = size.width - 8;
    final chartTop = 10.0;
    final chartBottom = size.height - 28;
    final chartWidth = chartRight - chartLeft;
    final chartHeight = chartBottom - chartTop;

    final gridPaint = Paint()
      ..color = const Color(0xFFE2E7E2)
      ..strokeWidth = 1;

    final linePaint = Paint()
      ..color = const Color(0xFF6FA67A)
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final dotPaint = Paint()
      ..color = const Color(0xFF5B9067)
      ..style = PaintingStyle.fill;

    final maxValue = (values.reduce((a, b) => a > b ? a : b)).clamp(10, 999999);

    for (int i = 0; i < 4; i++) {
      final y = chartTop + chartHeight * i / 3;
      canvas.drawLine(Offset(chartLeft, y), Offset(chartRight, y), gridPaint);
    }

    final path = Path();

    for (int i = 0; i < values.length; i++) {
      final x =
          chartLeft + (chartWidth * i / (values.length - 1).clamp(1, 100));
      final y = chartBottom - (values[i] / maxValue) * chartHeight;

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, linePaint);

    for (int i = 0; i < values.length; i++) {
      final x =
          chartLeft + (chartWidth * i / (values.length - 1).clamp(1, 100));
      final y = chartBottom - (values[i] / maxValue) * chartHeight;

      canvas.drawCircle(Offset(x, y), 5, dotPaint);
    }

    const labels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    final textStyle = const TextStyle(color: Color(0xFF6F756F), fontSize: 11);

    for (int i = 0; i < labels.length; i++) {
      final x =
          chartLeft + (chartWidth * i / (labels.length - 1).clamp(1, 100));
      final tp = TextPainter(
        text: TextSpan(text: labels[i], style: textStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(x - tp.width / 2, chartBottom + 8));
    }
  }

  @override
  bool shouldRepaint(covariant _WeeklyChartPainter oldDelegate) {
    return true;
  }
}

// ─────────────────────────────────────────────
// STUDY STREAK
// ─────────────────────────────────────────────

class StudyStreakScreen extends StatelessWidget {
  const StudyStreakScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: StudyFlowTheme.backgroundLight,
      appBar: const GlassAppBar(title: 'Study Streak'),
      body: AnimatedBuilder(
        animation: StudyFlowData.instance,
        builder: (context, _) {
          final data = StudyFlowData.instance;

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 30),
            children: [
              GlassContainer(
                radius: 28,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 28,
                ),
                child: Column(
                  children: [
                    const Text('🔥', style: TextStyle(fontSize: 64)),
                    const SizedBox(height: 8),
                    Text(
                      '${data.currentStreak} Day Streak',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.6,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Keep studying every day to maintain your streak.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: StudyFlowTheme.muted,
                        height: 1.4,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _StreakStat(
                      value: '${data.currentStreak}',
                      label: 'Current streak',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StreakStat(
                      value: '${data.longestStreak}',
                      label: 'Longest streak',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Text(
                'This week',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 12),
              GlassContainer(
                radius: 24,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 18,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: List.generate(7, (index) {
                    final today = DateTime.now();
                    final monday = today.subtract(
                      Duration(days: today.weekday - 1),
                    );
                    final date = monday.add(Duration(days: index));
                    const labels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
                    return _StreakDay(
                      day: labels[index],
                      active: data.hasActivityOn(date),
                    );
                  }),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Complete at least one task or Focus session each day to keep building your streak.',
                style: TextStyle(
                  color: StudyFlowTheme.muted,
                  height: 1.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _StreakStat extends StatelessWidget {
  final String value;
  final String label;

  const _StreakStat({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      radius: 22,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            Text(
              value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: StudyFlowTheme.muted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StreakDay extends StatelessWidget {
  final String day;
  final bool active;

  const _StreakDay({required this.day, required this.active});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          active ? '🔥' : '○',
          style: TextStyle(
            fontSize: active ? 24 : 22,
            color: active ? null : Colors.grey.shade400,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          day,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade700,
          ),
        ),
      ],
    );
  }
}

const _motivationQuotes = [
  'Small steps still move you forward.',
  'Begin before you feel ready.',
  'Your effort today builds tomorrow’s confidence.',
  'One focused minute can begin a better hour.',
  'Progress grows from showing up.',
  'Every page turned is progress made.',
  'Keep going; your future self is cheering you on.',
  'A little practice makes a lasting difference.',
  'You can do hard things one step at a time.',
  'Focus on the next step, not the whole staircase.',
  'Your pace is still progress.',
  'Curiosity is a powerful place to start.',
  'Mistakes are proof that you are learning.',
  'Make today count in small ways.',
  'Consistency turns effort into momentum.',
  'You are closer than you were yesterday.',
  'Start with what you know; build from there.',
  'Every study session is an investment in you.',
  'Patience and practice make progress.',
  'Keep learning; your possibilities keep growing.',
  'A fresh start can begin right now.',
  'Your determination is stronger than distraction.',
  'One clear goal can change your whole day.',
  'Give your best to this moment.',
  'You do not need perfect conditions to begin.',
  'Small wins create strong habits.',
  'Trust the work you put in.',
  'Take a breath, then take the next step.',
  'Learning today opens doors tomorrow.',
  'You have the ability to figure this out.',
  'Let your progress be louder than your doubts.',
  'Every question brings you closer to understanding.',
  'Be proud of the effort no one sees.',
  'A steady rhythm carries you far.',
  'Your goals are worth your attention.',
  'Keep your focus; the results will follow.',
  'You are building more than knowledge.',
  'The best time to begin is this moment.',
  'Turn one page, solve one problem, keep moving.',
  'Your hard work is adding up.',
  'Choose progress over perfection today.',
  'You can restart as many times as you need.',
  'Every focused effort makes you stronger.',
  'Stay patient with the process.',
  'Your commitment is shaping your future.',
  'Keep reaching; growth takes practice.',
  'You are capable of more than you think.',
  'Make room for progress, not pressure.',
  'One task at a time is enough.',
  'Your next breakthrough starts with practice.',
  'Show up for the future you want.',
  'Keep learning; every day adds something.',
  'Your effort matters, especially on tough days.',
  'Build confidence by keeping small promises to yourself.',
  'A focused start is already a win.',
  'You grow each time you try again.',
];

// ─────────────────────────────────────────────
// MOTIVATION
// ─────────────────────────────────────────────

class MotivationScreen extends StatefulWidget {
  const MotivationScreen({super.key});

  @override
  State<MotivationScreen> createState() => _MotivationScreenState();
}

class _MotivationScreenState extends State<MotivationScreen> {
  int _index = 0;
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _index = _random.nextInt(_motivationQuotes.length);
  }

  void _nextQuote() {
    setState(() {
      final nextIndex = _random.nextInt(_motivationQuotes.length - 1);
      _index = nextIndex >= _index ? nextIndex + 1 : nextIndex;
    });
  }

  @override
  Widget build(BuildContext context) {
    final quote = _motivationQuotes[_index];

    return Scaffold(
      backgroundColor: StudyFlowTheme.backgroundLight,
      appBar: const GlassAppBar(title: 'Motivation'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 30),
        children: [
          GlassContainer(
            radius: 32,
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const Icon(
                  Icons.format_quote_rounded,
                  size: 42,
                  color: StudyFlowTheme.sageStrong,
                ),
                const SizedBox(height: 18),
                Text(
                  '“$quote”',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 23,
                    fontWeight: FontWeight.w800,
                    height: 1.35,
                    letterSpacing: -0.2,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _nextQuote,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('New Quote'),
            style: FilledButton.styleFrom(
              backgroundColor: StudyFlowTheme.sage,
              padding: const EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// SHARED WIDGETS
// ─────────────────────────────────────────────
