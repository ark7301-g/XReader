import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

/// 加载指示�?
class LoadingIndicator extends StatelessWidget {
  final double? size;
  final Color? color;
  final String? message;
  final bool showMessage;
  
  const LoadingIndicator({
    super.key,
    this.size,
    this.color,
    this.message,
    this.showMessage = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: size ?? 40.w,
            height: size ?? 40.w,
            child: CircularProgressIndicator(
              strokeWidth: 3.w,
              color: color ?? theme.primaryColor,
            ),
          ),
          if (showMessage && message != null) ...[
            SizedBox(height: 16.h),
            Text(
              message!,
              style: GoogleFonts.notoSans(
                fontSize: 14.sp,
                color: theme.textTheme.bodySmall?.color,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// 空状态组�?
class EmptyState extends StatelessWidget {
  final IconData? icon;
  final String title;
  final String? subtitle;
  final Widget? action;
  final double? iconSize;
  final Color? iconColor;
  
  const EmptyState({
    super.key,
    this.icon,
    required this.title,
    this.subtitle,
    this.action,
    this.iconSize,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: iconSize ?? 64.sp,
                color: iconColor ?? theme.textTheme.bodySmall?.color?.withOpacity(0.5),
              ),
              SizedBox(height: 24.h),
            ],
            Text(
              title,
              style: GoogleFonts.notoSans(
                fontSize: 18.sp,
                fontWeight: FontWeight.w500,
                color: theme.textTheme.bodyMedium?.color,
              ),
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              SizedBox(height: 8.h),
              Text(
                subtitle!,
                style: GoogleFonts.notoSans(
                  fontSize: 14.sp,
                  color: theme.textTheme.bodySmall?.color,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (action != null) ...[
              SizedBox(height: 24.h),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}

/// 错误状态组�?
class ErrorState extends StatelessWidget {
  final String title;
  final String? subtitle;
  final VoidCallback? onRetry;
  final String? retryText;
  final IconData? icon;
  
  const ErrorState({
    super.key,
    required this.title,
    this.subtitle,
    this.onRetry,
    this.retryText,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon ?? Icons.error_outline,
              size: 64.sp,
              color: theme.colorScheme.error.withOpacity(0.7),
            ),
            SizedBox(height: 24.h),
            Text(
              title,
              style: GoogleFonts.notoSans(
                fontSize: 18.sp,
                fontWeight: FontWeight.w500,
                color: theme.textTheme.bodyMedium?.color,
              ),
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              SizedBox(height: 8.h),
              Text(
                subtitle!,
                style: GoogleFonts.notoSans(
                  fontSize: 14.sp,
                  color: theme.textTheme.bodySmall?.color,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (onRetry != null) ...[
              SizedBox(height: 24.h),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: Icon(Icons.refresh, size: 18.sp),
                label: Text(retryText ?? '重试'),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(
                    horizontal: 24.w,
                    vertical: 12.h,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// 自定义按�?
class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final ButtonType type;
  final ButtonSize size;
  final IconData? icon;
  final bool isLoading;
  final bool fullWidth;
  final Color? backgroundColor;
  final Color? textColor;
  final double? borderRadius;
  
  const CustomButton({
    super.key,
    required this.text,
    this.onPressed,
    this.type = ButtonType.primary,
    this.size = ButtonSize.medium,
    this.icon,
    this.isLoading = false,
    this.fullWidth = false,
    this.backgroundColor,
    this.textColor,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    final buttonStyle = _getButtonStyle(theme);
    final textStyle = _getTextStyle(theme);
    final padding = _getPadding();
    
    Widget button = isLoading
        ? _buildLoadingButton(buttonStyle, padding, textStyle)
        : _buildNormalButton(buttonStyle, textStyle, padding);
    
    if (fullWidth) {
      button = SizedBox(
        width: double.infinity,
        child: button,
      );
    }
    
    return button;
  }
  
  ButtonStyle _getButtonStyle(ThemeData theme) {
    Color bgColor;
    Color fgColor;
    BorderSide? border;
    
    switch (type) {
      case ButtonType.primary:
        bgColor = backgroundColor ?? theme.primaryColor;
        fgColor = textColor ?? Colors.white;
        break;
      case ButtonType.secondary:
        bgColor = backgroundColor ?? theme.cardColor;
        fgColor = textColor ?? theme.textTheme.bodyMedium?.color ?? Colors.black;
        border = BorderSide(color: theme.dividerColor);
        break;
      case ButtonType.text:
        bgColor = Colors.transparent;
        fgColor = textColor ?? theme.primaryColor;
        break;
      case ButtonType.outline:
        bgColor = Colors.transparent;
        fgColor = textColor ?? theme.primaryColor;
        border = BorderSide(color: theme.primaryColor);
        break;
    }
    
    return ElevatedButton.styleFrom(
      backgroundColor: bgColor,
      foregroundColor: fgColor,
      elevation: type == ButtonType.text ? 0 : 2,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(borderRadius ?? 8.r),
        side: border ?? BorderSide.none,
      ),
    );
  }
  
  TextStyle _getTextStyle(ThemeData theme) {
    double fontSize;
    FontWeight fontWeight;
    
    switch (size) {
      case ButtonSize.small:
        fontSize = 12.sp;
        fontWeight = FontWeight.w500;
        break;
      case ButtonSize.medium:
        fontSize = 14.sp;
        fontWeight = FontWeight.w500;
        break;
      case ButtonSize.large:
        fontSize = 16.sp;
        fontWeight = FontWeight.w600;
        break;
    }
    
    return GoogleFonts.notoSans(
      fontSize: fontSize,
      fontWeight: fontWeight,
    );
  }
  
  EdgeInsets _getPadding() {
    switch (size) {
      case ButtonSize.small:
        return EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h);
      case ButtonSize.medium:
        return EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h);
      case ButtonSize.large:
        return EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h);
    }
  }
  
  Widget _buildNormalButton(ButtonStyle style, TextStyle textStyle, EdgeInsets padding) {
    return ElevatedButton(
      onPressed: onPressed,
      style: style.copyWith(
        padding: WidgetStateProperty.all(padding),
        textStyle: WidgetStateProperty.all(textStyle),
      ),
      child: icon != null
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: textStyle.fontSize),
                SizedBox(width: 8.w),
                Text(text),
              ],
            )
          : Text(text),
    );
  }
  
  Widget _buildLoadingButton(ButtonStyle style, EdgeInsets padding, TextStyle textStyle) {
    return ElevatedButton(
      onPressed: null,
      style: style.copyWith(
        padding: WidgetStateProperty.all(padding),
        backgroundColor: WidgetStateProperty.all(
          style.backgroundColor?.resolve({}) ?? Colors.grey,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 16.w,
            height: 16.w,
            child: CircularProgressIndicator(
              strokeWidth: 2.w,
              color: Colors.white,
            ),
          ),
          SizedBox(width: 8.w),
          Text(
            '加载中...',
            style: GoogleFonts.notoSans(
              fontSize: textStyle.fontSize,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

enum ButtonType { primary, secondary, text, outline }
enum ButtonSize { small, medium, large }

/// 自定义卡�?
class CustomCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final double? borderRadius;
  final Color? backgroundColor;
  final List<BoxShadow>? boxShadow;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  
  const CustomCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.borderRadius,
    this.backgroundColor,
    this.boxShadow,
    this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    Widget card = Container(
      margin: margin,
      padding: padding ?? EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: backgroundColor ?? theme.cardColor,
        borderRadius: BorderRadius.circular(borderRadius ?? 12.r),
        boxShadow: boxShadow ?? [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
    
    if (onTap != null || onLongPress != null) {
      card = GestureDetector(
        onTap: onTap,
        onLongPress: onLongPress,
        child: card,
      );
    }
    
    return card;
  }
}

/// 分割�?
class CustomDivider extends StatelessWidget {
  final double? height;
  final double? thickness;
  final Color? color;
  final double? indent;
  final double? endIndent;
  
  const CustomDivider({
    super.key,
    this.height,
    this.thickness,
    this.color,
    this.indent,
    this.endIndent,
  });

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: height ?? 1.h,
      thickness: thickness ?? 0.5.h,
      color: color ?? Theme.of(context).dividerColor.withOpacity(0.3),
      indent: indent,
      endIndent: endIndent,
    );
  }
}

/// 自定义文本字�?
class CustomTextField extends StatelessWidget {
  final String? hintText;
  final String? labelText;
  final IconData? prefixIcon;
  final IconData? suffixIcon;
  final VoidCallback? onSuffixIconTap;
  final TextEditingController? controller;
  final Function(String)? onChanged;
  final Function(String)? onSubmitted;
  final TextInputType? keyboardType;
  final bool obscureText;
  final int? maxLines;
  final int? maxLength;
  final bool enabled;
  final String? errorText;
  final FocusNode? focusNode;
  
  const CustomTextField({
    super.key,
    this.hintText,
    this.labelText,
    this.prefixIcon,
    this.suffixIcon,
    this.onSuffixIconTap,
    this.controller,
    this.onChanged,
    this.onSubmitted,
    this.keyboardType,
    this.obscureText = false,
    this.maxLines,
    this.maxLength,
    this.enabled = true,
    this.errorText,
    this.focusNode,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return TextField(
      controller: controller,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      keyboardType: keyboardType,
      obscureText: obscureText,
      maxLines: maxLines ?? 1,
      maxLength: maxLength,
      enabled: enabled,
      focusNode: focusNode,
      style: GoogleFonts.notoSans(
        fontSize: 16.sp,
        color: theme.textTheme.bodyMedium?.color,
      ),
      decoration: InputDecoration(
        hintText: hintText,
        labelText: labelText,
        errorText: errorText,
        prefixIcon: prefixIcon != null
            ? Icon(prefixIcon, size: 20.sp)
            : null,
        suffixIcon: suffixIcon != null
            ? GestureDetector(
                onTap: onSuffixIconTap,
                child: Icon(suffixIcon, size: 20.sp),
              )
            : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.r),
          borderSide: BorderSide(
            color: theme.dividerColor.withOpacity(0.5),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.r),
          borderSide: BorderSide(
            color: theme.dividerColor.withOpacity(0.3),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.r),
          borderSide: BorderSide(
            color: theme.primaryColor,
            width: 2.w,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.r),
          borderSide: BorderSide(
            color: theme.colorScheme.error,
            width: 2.w,
          ),
        ),
        contentPadding: EdgeInsets.symmetric(
          horizontal: 16.w,
          vertical: 12.h,
        ),
        hintStyle: GoogleFonts.notoSans(
          fontSize: 16.sp,
          color: theme.textTheme.bodySmall?.color,
        ),
        labelStyle: GoogleFonts.notoSans(
          fontSize: 16.sp,
          color: theme.textTheme.bodySmall?.color,
        ),
      ),
    );
  }
}
