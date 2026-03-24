import 'package:flutter/material.dart';

class CrmDashboardStyles {
  const CrmDashboardStyles._();

  static const Color menuGrey = Color(0xFFE7E7E7);
  static const Color borderSoft = Color(0xFFC9C9C9);
  static const Color dividerSoft = Color(0xFFD6D6D6);
  static const Color textDark = Color(0xFF151515);
}

class CrmPanel extends StatelessWidget {
  const CrmPanel({
    super.key,
    required this.title,
    this.placeholder = 'Placeholder',
    this.child,
    this.actions,
  });

  final String title;
  final String placeholder;
  final Widget? child;
  final List<Widget>? actions;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: CrmDashboardStyles.menuGrey,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: CrmDashboardStyles.borderSoft, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: CrmDashboardStyles.textDark,
                      fontSize: 15.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (actions != null)
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: actions!,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const Divider(height: 1, color: CrmDashboardStyles.dividerSoft),
          Expanded(
            child: child ??
                Center(
                  child: Text(
                    placeholder,
                    style: const TextStyle(color: Colors.black54),
                  ),
                ),
          ),
        ],
      ),
    );
  }
}
