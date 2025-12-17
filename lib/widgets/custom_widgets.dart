import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import '../theme/app_theme.dart';

// Custom Loading Widget
class CustomLoadingWidget extends StatelessWidget {
  final String? message;
  final double size;

  const CustomLoadingWidget({
    super.key,
    this.message,
    this.size = 50,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            gradient: AppTheme.primaryGradient,
            borderRadius: BorderRadius.circular(size / 2),
          ),
          child: const Icon(
            Icons.psychology,
            color: Colors.white,
            size: 30,
          ),
        ).animate(onPlay: (controller) => controller.repeat())
            .rotate(duration: 2000.ms)
            .then()
            .scale(begin: const Offset(1, 1), end: const Offset(1.1, 1.1))
            .then()
            .scale(begin: const Offset(1.1, 1.1), end: const Offset(1, 1)),
        
        if (message != null) ...[
          const SizedBox(height: 16),
          Text(
            message!,
            style: AppTheme.bodyMedium.copyWith(
              color: AppTheme.textGrey,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }
}

// Custom Card Widget
class CustomCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final Color? color;
  final List<BoxShadow>? boxShadow;

  const CustomCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.onTap,
    this.color,
    this.boxShadow,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color ?? AppTheme.cardWhite,
        borderRadius: BorderRadius.circular(16),
        boxShadow: boxShadow ?? AppTheme.cardShadow,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: padding ?? const EdgeInsets.all(20),
            child: child,
          ),
        ),
      ),
    );
  }
}

// Custom Button Widget
class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isSecondary;
  final IconData? icon;
  final double? width;

  const CustomButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.isSecondary = false,
    this.icon,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: 56,
      decoration: BoxDecoration(
        gradient: isSecondary ? null : AppTheme.primaryGradient,
        color: isSecondary ? Colors.grey[100] : null,
        borderRadius: BorderRadius.circular(12),
        boxShadow: isSecondary ? null : AppTheme.buttonShadow,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isLoading ? null : onPressed,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (isLoading)
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        isSecondary ? AppTheme.primaryBlue : Colors.white,
                      ),
                    ),
                  )
                else ...[
                  if (icon != null) ...[
                    Icon(
                      icon,
                      color: isSecondary ? AppTheme.primaryBlue : Colors.white,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    text,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isSecondary ? AppTheme.primaryBlue : Colors.white,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Custom Input Field
class CustomInputField extends StatelessWidget {
  final String label;
  final String? hint;
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final bool obscureText;
  final IconData? prefixIcon;
  final IconData? suffixIcon;
  final VoidCallback? onSuffixTap;
  final TextInputType? keyboardType;
  final int maxLines;
  final bool enabled;

  const CustomInputField({
    super.key,
    required this.label,
    this.hint,
    this.controller,
    this.validator,
    this.obscureText = false,
    this.prefixIcon,
    this.suffixIcon,
    this.onSuffixTap,
    this.keyboardType,
    this.maxLines = 1,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTheme.labelLarge,
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          validator: validator,
          obscureText: obscureText,
          keyboardType: keyboardType,
          maxLines: maxLines,
          enabled: enabled,
          style: AppTheme.bodyLarge,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: prefixIcon != null ? Icon(prefixIcon) : null,
            suffixIcon: suffixIcon != null
                ? IconButton(
                    icon: Icon(suffixIcon),
                    onPressed: onSuffixTap,
                  )
                : null,
          ),
        ),
      ],
    );
  }
}

// Status Chip Widget
class StatusChip extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;

  const StatusChip({
    super.key,
    required this.label,
    required this.color,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: 14,
              color: Colors.white,
            ),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

// Shimmer Loading Card
class ShimmerCard extends StatelessWidget {
  final double height;
  final double? width;

  const ShimmerCard({
    super.key,
    this.height = 100,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        width: width,
        height: height,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }
}

// Empty State Widget
class EmptyStateWidget extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? buttonText;
  final VoidCallback? onButtonPressed;

  const EmptyStateWidget({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.buttonText,
    this.onButtonPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppTheme.primaryBlue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(40),
              ),
              child: Icon(
                icon,
                size: 40,
                color: AppTheme.primaryBlue,
              ),
            ).animate().scale(delay: 200.ms),
            
            const SizedBox(height: 24),
            
            Text(
              title,
              style: AppTheme.headingSmall,
              textAlign: TextAlign.center,
            ).animate().fadeIn(delay: 400.ms),
            
            const SizedBox(height: 8),
            
            Text(
              subtitle,
              style: AppTheme.bodyMedium.copyWith(
                color: AppTheme.textGrey,
              ),
              textAlign: TextAlign.center,
            ).animate().fadeIn(delay: 600.ms),
            
            if (buttonText != null && onButtonPressed != null) ...[
              const SizedBox(height: 24),
              CustomButton(
                text: buttonText!,
                onPressed: onButtonPressed,
                width: 200,
              ).animate().slideY(delay: 800.ms, begin: 0.3),
            ],
          ],
        ),
      ),
    );
  }
}

// Progress Indicator Widget
class CustomProgressIndicator extends StatelessWidget {
  final double progress;
  final String? label;
  final Color? color;

  const CustomProgressIndicator({
    super.key,
    required this.progress,
    this.label,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label!,
                style: AppTheme.bodyMedium,
              ),
              Text(
                '${(progress * 100).toInt()}%',
                style: AppTheme.bodySmall,
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],
        Container(
          height: 8,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(4),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: progress,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    color ?? AppTheme.primaryBlue,
                    (color ?? AppTheme.primaryBlue).withOpacity(0.7),
                  ],
                ),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ),
      ],
    );
  }
}