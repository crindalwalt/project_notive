import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class CollapsibleSidebar extends StatefulWidget {
  final Widget child;
  final String title;
  final bool initiallyExpanded;
  final double expandedWidth;
  final double collapsedWidth;
  final VoidCallback? onToggle;

  const CollapsibleSidebar({
    super.key,
    required this.child,
    required this.title,
    this.initiallyExpanded = true,
    this.expandedWidth = 280,
    this.collapsedWidth = 60,
    this.onToggle,
  });

  @override
  State<CollapsibleSidebar> createState() => _CollapsibleSidebarState();
}

class _CollapsibleSidebarState extends State<CollapsibleSidebar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _widthAnimation;
  late bool _isExpanded;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initiallyExpanded;
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _widthAnimation = Tween<double>(
      begin: widget.collapsedWidth,
      end: widget.expandedWidth,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    if (_isExpanded) {
      _controller.value = 1.0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
    widget.onToggle?.call();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: _widthAnimation,
      builder: (context, child) {
        return Container(
          width: _widthAnimation.value,
          decoration: BoxDecoration(
            color: isDark
                ? AppTheme.darkSidebarBackground
                : AppTheme.lightSidebarBackground,
            border: Border(
              right: BorderSide(
                color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
                width: 1,
              ),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with toggle button
              Container(
                height: 56,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: _toggle,
                      icon: Icon(
                        _isExpanded ? Icons.menu_open : Icons.menu,
                        size: 20,
                        color: isDark
                            ? AppTheme.darkSecondaryText
                            : AppTheme.lightSecondaryText,
                      ),
                      splashRadius: 20,
                    ),
                    if (_isExpanded) ...[
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          widget.title,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              // Divider
              Divider(
                height: 1,
                thickness: 1,
                color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
              ),
              // Content
              Expanded(
                child: _isExpanded
                    ? widget.child
                    : Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Column(
                          children: [
                            IconButton(
                              onPressed: () {},
                              icon: const Icon(Icons.folder_outlined, size: 20),
                              splashRadius: 20,
                            ),
                            const SizedBox(height: 8),
                            IconButton(
                              onPressed: () {},
                              icon: const Icon(
                                Icons.note_add_outlined,
                                size: 20,
                              ),
                              splashRadius: 20,
                            ),
                          ],
                        ),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}
