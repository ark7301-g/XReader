import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/utils/screen_util_helper.dart';

class CustomBottomNav extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;
  final List<BottomNavItem> items;
  final Color? backgroundColor;
  final Color? selectedItemColor;
  final Color? unselectedItemColor;
  final double? elevation;
  final bool showLabels;
  
  const CustomBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
    this.backgroundColor,
    this.selectedItemColor,
    this.unselectedItemColor,
    this.elevation,
    this.showLabels = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomNavTheme = theme.bottomNavigationBarTheme;
    
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor ?? bottomNavTheme.backgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: elevation ?? 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Container(
          height: ScreenUtilHelper.getBottomNavHeight(showLabels: showLabels),
          padding: EdgeInsets.symmetric(
            horizontal: ScreenUtilHelper.isSmallScreen() ? 8.w : 12.w,
            vertical: ScreenUtilHelper.getResponsiveSpacing(6),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: items.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              final isSelected = index == currentIndex;
              
              return Expanded(
                child: GestureDetector(
                  onTap: () => onTap(index),
                  behavior: HitTestBehavior.opaque,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeInOut,
                    padding: EdgeInsets.symmetric(
                      vertical: 4.h,
                      horizontal: 8.w,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected 
                          ? (selectedItemColor ?? theme.primaryColor).withOpacity(0.1)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(16.r),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // 图标
                        AnimatedScale(
                          scale: isSelected ? 1.1 : 1.0,
                          duration: const Duration(milliseconds: 200),
                          child: Icon(
                            isSelected ? item.activeIcon : item.icon,
                            size: ScreenUtilHelper.getResponsiveIconSize(22),
                            color: isSelected
                                ? selectedItemColor ?? theme.primaryColor
                                : unselectedItemColor ?? bottomNavTheme.unselectedItemColor,
                          ),
                        ),
                        
                        // 标签
                        if (showLabels) ...[
                          SizedBox(height: ScreenUtilHelper.getResponsiveSpacing(2)),
                          AnimatedDefaultTextStyle(
                            duration: const Duration(milliseconds: 200),
                            style: GoogleFonts.notoSans(
                              fontSize: ScreenUtilHelper.getResponsiveFontSize(
                                isSelected ? 10 : 9
                              ),
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                              color: isSelected
                                  ? selectedItemColor ?? theme.primaryColor
                                  : unselectedItemColor ?? bottomNavTheme.unselectedItemColor,
                            ),
                            child: Text(
                              item.label,
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

/// 底部导航�?
class BottomNavItem {
  final IconData icon;
  final IconData? activeIcon;
  final String label;
  final Widget? badge;
  
  const BottomNavItem({
    required this.icon,
    this.activeIcon,
    required this.label,
    this.badge,
  });
}

/// 默认的底部导航项配置
class DefaultBottomNavItems {
  static List<BottomNavItem> get items => [
    const BottomNavItem(
      icon: Icons.library_books_outlined,
      activeIcon: Icons.library_books,
      label: '书架',
    ),
    const BottomNavItem(
      icon: Icons.explore_outlined,
      activeIcon: Icons.explore,
      label: '发现',
    ),
    const BottomNavItem(
      icon: Icons.bookmark_outline,
      activeIcon: Icons.bookmark,
      label: '书签',
    ),
    const BottomNavItem(
      icon: Icons.settings_outlined,
      activeIcon: Icons.settings,
      label: '设置',
    ),
  ];
}

/// 带徽章的底部导航�?
class BadgedBottomNav extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;
  final Map<int, int>? badges; // index -> badge count
  final Color? badgeColor;
  final Color? badgeTextColor;
  
  const BadgedBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.badges,
    this.badgeColor,
    this.badgeTextColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return CustomBottomNav(
      currentIndex: currentIndex,
      onTap: onTap,
      items: DefaultBottomNavItems.items.asMap().entries.map((entry) {
        final index = entry.key;
        final item = entry.value;
        final badgeCount = badges?[index];
        
        return BottomNavItem(
          icon: item.icon,
          activeIcon: item.activeIcon,
          label: item.label,
          badge: badgeCount != null && badgeCount > 0
              ? Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 6.w,
                    vertical: 2.h,
                  ),
                  decoration: BoxDecoration(
                    color: badgeColor ?? theme.colorScheme.error,
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  constraints: BoxConstraints(
                    minWidth: 18.w,
                    minHeight: 18.h,
                  ),
                  child: Text(
                    badgeCount > 99 ? '99+' : badgeCount.toString(),
                    style: GoogleFonts.notoSans(
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w600,
                      color: badgeTextColor ?? Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                )
              : null,
        );
      }).toList(),
    );
  }
}

/// 可隐藏的底部导航�?
class HideableBottomNav extends StatefulWidget {
  final int currentIndex;
  final Function(int) onTap;
  final bool visible;
  final Duration animationDuration;
  final Curve animationCurve;
  
  const HideableBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.visible = true,
    this.animationDuration = const Duration(milliseconds: 300),
    this.animationCurve = Curves.easeInOut,
  });

  @override
  State<HideableBottomNav> createState() => _HideableBottomNavState();
}

class _HideableBottomNavState extends State<HideableBottomNav>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 1.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: widget.animationCurve,
    ));
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: widget.animationCurve,
    ));

    if (widget.visible) {
      _animationController.forward();
    }
  }

  @override
  void didUpdateWidget(HideableBottomNav oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.visible != oldWidget.visible) {
      if (widget.visible) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: CustomBottomNav(
          currentIndex: widget.currentIndex,
          onTap: widget.onTap,
          items: DefaultBottomNavItems.items,
        ),
      ),
    );
  }
}

/// 浮动样式的底部导航栏
class FloatingBottomNav extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;
  final EdgeInsets margin;
  final double borderRadius;
  
  const FloatingBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.margin = const EdgeInsets.all(16),
    this.borderRadius = 24,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(borderRadius.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius.r),
        child: CustomBottomNav(
          currentIndex: currentIndex,
          onTap: onTap,
          items: DefaultBottomNavItems.items,
          elevation: 0,
        ),
      ),
    );
  }
}
