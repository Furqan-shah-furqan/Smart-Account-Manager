import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'app_theme.dart';

enum AppToastType { success, error, warning, info }

class DataCard extends StatelessWidget {
  final String title;
  final Widget child;

  const DataCard({super.key, required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final cardPadding = screenWidth < 520 ? 14.0 : 18.0;
    final titleSize = screenWidth < 520 ? 16.0 : 18.0;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(cardPadding),
      decoration: cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: titleSize,
              fontWeight: FontWeight.w900,
              color: AppTheme.dark,
            ),
          ),
          SizedBox(height: screenWidth < 520 ? 10 : 14),
          child,
        ],
      ),
    );
  }
}

class StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const StatCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final cardWidth = screenWidth < 620
        ? screenWidth - 36
        : screenWidth < 1100
            ? 220.0
            : 250.0;
    final cardPadding = screenWidth < 620 ? 14.0 : 18.0;

    return SizedBox(
      width: cardWidth,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Container(
            padding: EdgeInsets.all(cardPadding),
            decoration: cardDecoration(),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 27,
                  backgroundColor: color.withOpacity(0.12),
                  child: Icon(icon, color: color),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Color(0xff6b7280), fontSize: 13),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        value,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: screenWidth < 620 ? 18 : 20,
                          fontWeight: FontWeight.w900,
                          color: AppTheme.dark,
                        ),
                      ),
                    ],
                  ),
                ),
                if (onTap != null) ...[
                  const SizedBox(width: 8),
                  const Icon(Icons.chevron_right_rounded, color: Color(0xff9ca3af)),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class StatusBar extends StatelessWidget {
  final String title;
  final String value;
  final double percent;
  final Color color;
  final IconData icon;

  const StatusBar({
    super.key,
    required this.title,
    required this.value,
    required this.percent,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final safePercent = percent.clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 17,
              backgroundColor: color.withOpacity(0.12),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.w800))),
            Text(value, style: TextStyle(color: color, fontWeight: FontWeight.w900)),
          ],
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: LinearProgressIndicator(
            value: safePercent,
            minHeight: 9,
            backgroundColor: color.withOpacity(0.12),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}

BoxDecoration cardDecoration() {
  return BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(24),
    border: Border.all(color: const Color(0xffe5e7eb)),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.04),
        blurRadius: 20,
        offset: const Offset(0, 8),
      ),
    ],
  );
}

Widget primaryButton(String text, IconData icon, VoidCallback onPressed) {
  return Builder(
    builder: (context) {
      final screenWidth = MediaQuery.of(context).size.width;
      final horizontalPadding = screenWidth < 520 ? 12.0 : 16.0;
      final verticalPadding = screenWidth < 520 ? 12.0 : 14.0;

      return ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 18),
        label: Text(text, overflow: TextOverflow.ellipsis),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primary,
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: verticalPadding),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      );
    },
  );
}

Widget horizontalTable(Widget child) {
  return LayoutBuilder(
    builder: (context, constraints) {
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: ConstrainedBox(
          constraints: BoxConstraints(minWidth: constraints.maxWidth),
          child: child,
        ),
      );
    },
  );
}

Widget emptyBox(String text) {
  return Container(
    width: double.infinity,
    padding: const EdgeInsets.all(22),
    alignment: Alignment.center,
    child: Text(text, style: const TextStyle(color: Color(0xff6b7280))),
  );
}

Widget responsiveTwo(Widget left, Widget right) {
  return LayoutBuilder(
    builder: (context, constraints) {
      if (constraints.maxWidth < 850) {
        return Column(children: [left, const SizedBox(height: 18), right]);
      }

      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: left),
          const SizedBox(width: 18),
          Expanded(child: right),
        ],
      );
    },
  );
}

Widget textInput({
  required String label,
  required TextEditingController controller,
  bool number = false,
  ValueChanged<String>? onChanged,
  bool obscure = false,
}) {
  return Builder(
    builder: (context) {
      final screenWidth = MediaQuery.of(context).size.width;

      return Padding(
        padding: EdgeInsets.only(top: screenWidth < 520 ? 10 : 12),
        child: TextField(
          controller: controller,
          obscureText: obscure,
          keyboardType: number ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
          onChanged: onChanged,
          decoration: InputDecoration(labelText: label),
        ),
      );
    },
  );
}

double toDouble(String value) {
  final cleaned = value.trim().replaceAll(',', '').replaceAll('%', '');
  return double.tryParse(cleaned) ?? 0;
}

int toInt(String value) {
  final cleaned = value.trim().replaceAll(',', '').replaceAll('%', '');
  return int.tryParse(cleaned) ?? double.tryParse(cleaned)?.round() ?? 0;
}

AppToastType detectToastType(String message) {
  final text = message.toLowerCase();

  if (text.contains('saved') ||
      text.contains('success') ||
      text.contains('created') ||
      text.contains('updated')) {
    return AppToastType.success;
  }

  if (text.contains('required') ||
      text.contains('not enough') ||
      text.contains('invalid') ||
      text.contains('error') ||
      text.contains('exception') ||
      text.contains('failed') ||
      text.contains('greater than') ||
      text.contains('not logged')) {
    return AppToastType.error;
  }

  if (text.contains('add') ||
      text.contains('first') ||
      text.contains('warning') ||
      text.contains('please')) {
    return AppToastType.warning;
  }

  return AppToastType.info;
}

Color toastTextColor(AppToastType type) {
  switch (type) {
    case AppToastType.success:
      return const Color(0xff15803d);
    case AppToastType.error:
      return const Color(0xffb91c1c);
    case AppToastType.warning:
      return const Color(0xffb45309);
    case AppToastType.info:
      return const Color(0xff1d4ed8);
  }
}

Color toastBgColor(AppToastType type) {
  switch (type) {
    case AppToastType.success:
      return const Color(0xffdcfce7);
    case AppToastType.error:
      return const Color(0xffffe4e6);
    case AppToastType.warning:
      return const Color(0xfffff7ed);
    case AppToastType.info:
      return const Color(0xffdbeafe);
  }
}

IconData toastIcon(AppToastType type) {
  switch (type) {
    case AppToastType.success:
      return Icons.check_circle_rounded;
    case AppToastType.error:
      return Icons.error_rounded;
    case AppToastType.warning:
      return Icons.warning_rounded;
    case AppToastType.info:
      return Icons.info_rounded;
  }
}

/// Top notification used by the whole app.
/// Old calls like showSnack(context, 'Saved successfully.') still work.
void showSnack(
  BuildContext context,
  String message, {
  AppToastType? type,
}) {
  final overlay = Overlay.maybeOf(context);
  if (overlay == null) return;

  final toastType = type ?? detectToastType(message);
  final screenWidth = MediaQuery.of(context).size.width;
  final toastWidth = math.min(520.0, screenWidth * 0.90);
  final topPadding = MediaQuery.of(context).padding.top + 14;

  late OverlayEntry entry;

  entry = OverlayEntry(
    builder: (context) {
      return _TopToast(
        message: message.replaceAll('Exception: ', ''),
        type: toastType,
        width: toastWidth,
        topPadding: topPadding,
        onClose: () {
          if (entry.mounted) entry.remove();
        },
      );
    },
  );

  overlay.insert(entry);

  Timer(const Duration(seconds: 3), () {
    if (entry.mounted) entry.remove();
  });
}

class _TopToast extends StatefulWidget {
  final String message;
  final AppToastType type;
  final double width;
  final double topPadding;
  final VoidCallback onClose;

  const _TopToast({
    required this.message,
    required this.type,
    required this.width,
    required this.topPadding,
    required this.onClose,
  });

  @override
  State<_TopToast> createState() => _TopToastState();
}

class _TopToastState extends State<_TopToast>
    with SingleTickerProviderStateMixin {
  late final AnimationController controller;
  late final Animation<Offset> slideAnimation;
  late final Animation<double> fadeAnimation;

  @override
  void initState() {
    super.initState();

    controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
    );

    slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1.2),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: controller, curve: Curves.easeOutCubic),
    );

    fadeAnimation = CurvedAnimation(parent: controller, curve: Curves.easeOut);

    controller.forward();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = toastTextColor(widget.type);
    final bg = toastBgColor(widget.type);

    return Positioned(
      top: widget.topPadding,
      left: 0,
      right: 0,
      child: Material(
        color: Colors.transparent,
        child: Center(
          child: SlideTransition(
            position: slideAnimation,
            child: FadeTransition(
              opacity: fadeAnimation,
              child: Container(
                width: widget.width,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: color.withOpacity(0.25)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Icon(toastIcon(widget.type), color: color, size: 22),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        widget.message,
                        style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.w800,
                          height: 1.3,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: widget.onClose,
                      child: Icon(Icons.close_rounded, color: color, size: 18),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
