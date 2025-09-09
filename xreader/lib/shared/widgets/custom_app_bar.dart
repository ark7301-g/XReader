import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final Widget? leading;
  final bool centerTitle;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double? elevation;
  final bool automaticallyImplyLeading;
  final PreferredSizeWidget? bottom;
  final double? titleSpacing;
  final double? leadingWidth;
  final TextStyle? titleTextStyle;
  
  const CustomAppBar({
    super.key,
    required this.title,
    this.actions,
    this.leading,
    this.centerTitle = true,
    this.backgroundColor,
    this.foregroundColor,
    this.elevation,
    this.automaticallyImplyLeading = true,
    this.bottom,
    this.titleSpacing,
    this.leadingWidth,
    this.titleTextStyle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return AppBar(
      title: Text(
        title,
        style: titleTextStyle ?? GoogleFonts.notoSans(
          fontSize: 22.sp,
          fontWeight: FontWeight.w500,
          color: foregroundColor ?? theme.appBarTheme.foregroundColor,
        ),
      ),
      centerTitle: centerTitle,
      backgroundColor: backgroundColor ?? Colors.transparent,
      foregroundColor: foregroundColor ?? theme.appBarTheme.foregroundColor,
      elevation: elevation ?? 0,
      actions: actions,
      leading: leading,
      automaticallyImplyLeading: automaticallyImplyLeading,
      bottom: bottom,
      titleSpacing: titleSpacing,
      leadingWidth: leadingWidth,
      systemOverlayStyle: isDark 
          ? theme.appBarTheme.systemOverlayStyle
          : theme.appBarTheme.systemOverlayStyle,
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(
    kToolbarHeight + (bottom?.preferredSize.height ?? 0)
  );
}

/// 带搜索功能的AppBar
class SearchAppBar extends StatefulWidget implements PreferredSizeWidget {
  final String title;
  final String searchHint;
  final Function(String)? onSearchChanged;
  final VoidCallback? onSearchClear;
  final List<Widget>? actions;
  final Widget? leading;
  final bool automaticallyImplyLeading;
  
  const SearchAppBar({
    super.key,
    required this.title,
    this.searchHint = '搜索...',
    this.onSearchChanged,
    this.onSearchClear,
    this.actions,
    this.leading,
    this.automaticallyImplyLeading = true,
  });

  @override
  State<SearchAppBar> createState() => _SearchAppBarState();
  
  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class _SearchAppBarState extends State<SearchAppBar> 
    with SingleTickerProviderStateMixin {
  bool _isSearching = false;
  late TextEditingController _searchController;
  late FocusNode _searchFocusNode;
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _searchFocusNode = FocusNode();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _startSearch() {
    setState(() {
      _isSearching = true;
    });
    _animationController.forward();
    _searchFocusNode.requestFocus();
  }

  void _stopSearch() {
    setState(() {
      _isSearching = false;
    });
    _animationController.reverse();
    _searchController.clear();
    _searchFocusNode.unfocus();
    widget.onSearchClear?.call();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: widget.leading,
      automaticallyImplyLeading: widget.automaticallyImplyLeading,
      title: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          return _isSearching
              ? FadeTransition(
                  opacity: _animation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(1.0, 0.0),
                      end: Offset.zero,
                    ).animate(_animation),
                    child: Container(
                      height: 40.h,
                      decoration: BoxDecoration(
                        color: theme.cardColor,
                        borderRadius: BorderRadius.circular(20.r),
                        border: Border.all(
                          color: theme.dividerColor.withOpacity(0.3),
                        ),
                      ),
                      child: TextField(
                        controller: _searchController,
                        focusNode: _searchFocusNode,
                        onChanged: widget.onSearchChanged,
                        style: GoogleFonts.notoSans(
                          fontSize: 16.sp,
                          color: theme.textTheme.bodyMedium?.color,
                        ),
                        decoration: InputDecoration(
                          hintText: widget.searchHint,
                          hintStyle: GoogleFonts.notoSans(
                            fontSize: 16.sp,
                            color: theme.textTheme.bodySmall?.color,
                          ),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 16.w,
                            vertical: 8.h,
                          ),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: Icon(
                                    Icons.clear,
                                    size: 20.sp,
                                    color: theme.textTheme.bodySmall?.color,
                                  ),
                                  onPressed: () {
                                    _searchController.clear();
                                    widget.onSearchClear?.call();
                                  },
                                )
                              : null,
                        ),
                      ),
                    ),
                  ),
                )
              : FadeTransition(
                  opacity: Tween<double>(begin: 1.0, end: 0.0).animate(_animation),
                  child: Text(
                    widget.title,
                    style: GoogleFonts.notoSans(
                      fontSize: 22.sp,
                      fontWeight: FontWeight.w500,
                      color: theme.appBarTheme.foregroundColor,
                    ),
                  ),
                );
        },
      ),
      actions: [
        if (!_isSearching) ...[
          IconButton(
            icon: Icon(
              Icons.search,
              size: 24.sp,
            ),
            onPressed: _startSearch,
          ),
          if (widget.actions != null) ...widget.actions!,
        ] else ...[
          IconButton(
            icon: Icon(
              Icons.close,
              size: 24.sp,
            ),
            onPressed: _stopSearch,
          ),
        ],
      ],
    );
  }
}

/// 简单的导航AppBar，带返回按钮
class SimpleAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final VoidCallback? onBackPressed;
  final bool showBackButton;
  
  const SimpleAppBar({
    super.key,
    required this.title,
    this.actions,
    this.onBackPressed,
    this.showBackButton = true,
  });

  @override
  Widget build(BuildContext context) {
    return CustomAppBar(
      title: title,
      actions: actions,
      leading: showBackButton
          ? IconButton(
              icon: Icon(
                Icons.arrow_back_ios_new,
                size: 20.sp,
              ),
              onPressed: onBackPressed ?? () => Navigator.of(context).pop(),
            )
          : null,
      automaticallyImplyLeading: showBackButton,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

/// 透明AppBar，用于阅读器等沉浸式界面
class TransparentAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  final List<Widget>? actions;
  final Widget? leading;
  final bool visible;
  final Duration animationDuration;
  
  const TransparentAppBar({
    super.key,
    this.title,
    this.actions,
    this.leading,
    this.visible = true,
    this.animationDuration = const Duration(milliseconds: 300),
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return AnimatedOpacity(
      opacity: visible ? 1.0 : 0.0,
      duration: animationDuration,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              theme.scaffoldBackgroundColor.withOpacity(0.9),
              theme.scaffoldBackgroundColor.withOpacity(0.7),
              theme.scaffoldBackgroundColor.withOpacity(0.0),
            ],
          ),
        ),
        child: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: leading,
          title: title != null
              ? Text(
                  title!,
                  style: GoogleFonts.notoSans(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w500,
                    color: theme.appBarTheme.foregroundColor,
                  ),
                )
              : null,
          actions: actions,
          centerTitle: true,
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 20);
}
