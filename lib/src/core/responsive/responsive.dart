part of '../../../main.dart';

enum AppViewportSize { mobile, tablet, desktop }

abstract final class AppBreakpoints {
  static const double mobile = 600;
  static const double desktop = 1024;

  static AppViewportSize classify(double width) {
    if (width < mobile) return AppViewportSize.mobile;
    if (width < desktop) return AppViewportSize.tablet;
    return AppViewportSize.desktop;
  }

  static bool isMobile(double width) => width < mobile;
  static bool isTablet(double width) => width >= mobile && width < desktop;
  static bool isDesktop(double width) => width >= desktop;
}

abstract final class AppResponsiveInsets {
  static EdgeInsets pagePadding(double width) {
    if (AppBreakpoints.isMobile(width)) {
      return const EdgeInsets.all(AppSpacing.xl);
    }

    if (AppBreakpoints.isTablet(width)) {
      return const EdgeInsets.all(AppSpacing.xxl);
    }

    return const EdgeInsets.symmetric(
      horizontal: AppSpacing.xxxl,
      vertical: AppSpacing.xxl,
    );
  }
}

abstract final class AppResponsiveSizing {
  static double contentMaxWidth(double width) {
    if (AppBreakpoints.isMobile(width)) return width;
    if (AppBreakpoints.isTablet(width)) return AppMaxWidth.standard;
    return AppMaxWidth.wide;
  }
}

extension LabResponsiveContext on BuildContext {
  double get viewportWidth => MediaQuery.sizeOf(this).width;

  AppViewportSize get viewportSizeClass {
    return AppBreakpoints.classify(viewportWidth);
  }

  bool get isMobileLayout => viewportSizeClass == AppViewportSize.mobile;
  bool get isTabletLayout => viewportSizeClass == AppViewportSize.tablet;
  bool get isDesktopLayout => viewportSizeClass == AppViewportSize.desktop;

  EdgeInsets get responsivePagePadding {
    return AppResponsiveInsets.pagePadding(viewportWidth);
  }
}

class ResponsiveContainer extends StatelessWidget {
  final Widget child;
  final double? maxWidth;
  final EdgeInsetsGeometry? padding;
  final AlignmentGeometry alignment;

  const ResponsiveContainer({
    super.key,
    required this.child,
    this.maxWidth,
    this.padding,
    this.alignment = Alignment.topCenter,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double availableWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width;
        final double resolvedMaxWidth =
            maxWidth ?? AppResponsiveSizing.contentMaxWidth(availableWidth);

        return Align(
          alignment: alignment,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: resolvedMaxWidth),
            child: Padding(
              padding:
                  padding ?? AppResponsiveInsets.pagePadding(availableWidth),
              child: child,
            ),
          ),
        );
      },
    );
  }
}

class ResponsiveGrid extends StatelessWidget {
  final List<Widget> children;
  final double minTileWidth;
  final double spacing;
  final double runSpacing;
  final int? maxColumns;

  const ResponsiveGrid({
    super.key,
    required this.children,
    this.minTileWidth = 220,
    this.spacing = AppSpacing.lg,
    this.runSpacing = AppSpacing.lg,
    this.maxColumns,
  });

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        final double availableWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width;
        final int naturalColumns =
            ((availableWidth + spacing) / (minTileWidth + spacing))
                .floor()
                .clamp(1, children.length)
                .toInt();
        final int columns = maxColumns == null
            ? naturalColumns
            : naturalColumns.clamp(1, maxColumns!).toInt();
        final double tileWidth =
            (availableWidth - (spacing * (columns - 1))) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: runSpacing,
          children: [
            for (final Widget child in children)
              SizedBox(width: tileWidth, child: child),
          ],
        );
      },
    );
  }
}
