import 'package:flutter/material.dart';
import '../constants/app_theme.dart';

class AnimatedAuthButton extends StatefulWidget {
  final String text;
  final bool isLoading;
  final VoidCallback? onTap;
  final Color? color;

  const AnimatedAuthButton({
    super.key,
    required this.text,
    required this.isLoading,
    this.onTap,
    this.color,
  });

  @override
  State<AnimatedAuthButton> createState() => _AnimatedAuthButtonState();
}

class _AnimatedAuthButtonState extends State<AnimatedAuthButton> {
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;
        return Center(
          child: GestureDetector(
            onTap: widget.isLoading ? null : widget.onTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 350),
              curve: Curves.easeOutCubic,
              width: widget.isLoading ? 56 : maxWidth,
              height: 56,
              decoration: BoxDecoration(
                color: widget.color ?? AppTheme.primary,
                borderRadius: BorderRadius.circular(widget.isLoading ? 28 : 16),
                boxShadow: [
                  BoxShadow(
                    color: (widget.color ?? AppTheme.primary).withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Center(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: widget.isLoading
                      ? const SizedBox(
                          key: ValueKey('loading'),
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : Text(
                          widget.text,
                          key: const ValueKey('text'),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
