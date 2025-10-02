// lib/screens/root_shell.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../screens/home_screen.dart';
import '../screens/dashboard_screen.dart';
import '../screens/profile_screen.dart';

class RootShell extends StatefulWidget {
  const RootShell({super.key});
  @override
  State<RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<RootShell> {
  int _index = 0;

  final _pages = [
    HomeScreen(),
    const DashboardScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isUltraCompact = size.width < 340 || size.height < 640;

    return Scaffold(
      body: IndexedStack(index: _index, children: _pages),
      bottomNavigationBar: CompactBottomBar(
        index: _index,
        onChanged: (i) => setState(() => _index = i),
        compact: MediaQuery.of(context).size.width < 340 ||
            MediaQuery.of(context).size.height < 640,
      ),
    );
  }
}

/// Compact, responsive bottom bar that works on all Flutter versions.
/// You fully control height, icon size, label visibility.
class CompactBottomBar extends StatelessWidget {
  final int index;
  final ValueChanged<int> onChanged;
  final bool compact;

  const CompactBottomBar({
    super.key,
    required this.index,
    required this.onChanged,
    required this.compact,
  });

  @override
  Widget build(BuildContext context) {
    // Kích thước responsive
    final double barHeight     = compact ? 42.h : 50.h;
    final double iconSizeUnsel = compact ? 18.w : 22.w;
    final double iconSizeSel   = compact ? 20.w : 24.w;
    final bool showLabels      = !compact;
    final double fontSize      = compact ? 9.sp : 11.sp;

    // Bottom inset (home-indicator / tai thỏ)
    final double bottomInset   = MediaQuery.of(context).padding.bottom;
    // Chỉ lấy 40% inset để không “dư đáy”, tối đa 10dp
    final double bottomPad = (bottomInset * 0.3).clamp(0, 8).toDouble();

    final items = <_BarItem>[
      _BarItem(Icons.home_outlined, Icons.home, 'Home'),
      _BarItem(Icons.dashboard_outlined, Icons.dashboard, 'DashBoard'),
      _BarItem(Icons.person_outline, Icons.person, 'Profile'),
    ];

    return Material( // dùng Material để shadow đều hơn
      color: Colors.transparent,
      child: SafeArea(
        // KHÔNG tự động cộng full inset của SafeArea
        top: false,
        bottom: false,
        child: Container(
          // Tổng height = barHeight + phần pad nhỏ theo inset
          height: barHeight + bottomPad,
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 8,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          padding: EdgeInsets.only(
            left: 12.w,
            right: 12.w,
            bottom: bottomPad, // kê một ít theo inset, không để quá dày
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(items.length, (i) {
              final selected = i == index;
              final item = items[i];

              return Expanded(
                child: InkWell(
                  borderRadius: BorderRadius.circular(12.r),
                  onTap: () => onChanged(i),
                  child: SizedBox(
                    height: barHeight, // icon/label được căn **đúng giữa** block này
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          selected ? item.activeIcon : item.icon,
                          size: selected ? iconSizeSel : iconSizeUnsel,
                          color: selected ? Colors.green.shade700 : Colors.grey.shade700,
                        ),
                        if (showLabels) ...[
                          SizedBox(height: 2.h),
                          Text(
                            item.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: fontSize,
                              fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                              color: selected ? Colors.green.shade700 : Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _BarItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  _BarItem(this.icon, this.activeIcon, this.label);
}

