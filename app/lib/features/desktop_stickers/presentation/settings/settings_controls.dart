import 'package:flutter/material.dart';

import '../../../../app/theme/settings_paper.dart';

export '../../../../app/theme/settings_paper.dart';

/// 带当前值、选中标记和系统键盘行为的贴边菜单。
class PaperMenu extends StatefulWidget {
  const PaperMenu({
    required this.label,
    required this.items,
    this.tooltip,
    super.key,
  });

  /// 收起时的当前值或操作。
  final String label;

  /// 已按当前场景组织的选项。
  final List<Widget> items;

  /// 有多个同名动作时补充目标说明。
  final String? tooltip;

  @override
  State<PaperMenu> createState() => _PaperMenuState();
}

class _PaperMenuState extends State<PaperMenu> {
  /// 关闭菜单后用于返回触发按钮。
  final FocusNode _buttonFocus = FocusNode();

  @override
  void dispose() {
    _buttonFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MenuAnchor(
    childFocusNode: _buttonFocus,
    alignmentOffset: const Offset(0, 5),
    style: MenuStyle(
      backgroundColor: const WidgetStatePropertyAll<Color>(
        SettingsPaper.surface,
      ),
      surfaceTintColor: const WidgetStatePropertyAll<Color>(Colors.transparent),
      elevation: const WidgetStatePropertyAll<double>(5),
      padding: const WidgetStatePropertyAll<EdgeInsetsGeometry>(
        EdgeInsets.all(4),
      ),
      shape: WidgetStatePropertyAll<OutlinedBorder>(
        RoundedRectangleBorder(
          borderRadius: SettingsPaper.corners,
          side: const BorderSide(color: SettingsPaper.line),
        ),
      ),
    ),
    menuChildren: widget.items,
    builder: _trigger,
  );

  Widget _trigger(BuildContext context, MenuController menu, Widget? child) {
    final Widget button = OutlinedButton(
      focusNode: _buttonFocus,
      onPressed: menu.isOpen ? menu.close : menu.open,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(widget.label),
          const SizedBox(width: 8),
          const Icon(Icons.expand_more, size: 18),
        ],
      ),
    );
    return widget.tooltip == null
        ? button
        : Tooltip(message: widget.tooltip!, child: button);
  }
}

class PaperOption extends StatelessWidget {
  const PaperOption({
    required this.label,
    required this.onSelect,
    this.selected = false,
    this.autofocus = false,
    this.detail,
    super.key,
  });

  /// 选项的主要内容。
  final String label;

  /// 选择时触发的动作。
  final VoidCallback onSelect;

  /// 当前值在菜单中有勾选标记。
  final bool selected;

  /// 菜单刚打开时的首个键盘焦点。
  final bool autofocus;

  /// 目标窗口现有的倒计时。
  final String? detail;

  @override
  Widget build(BuildContext context) => Semantics(
    selected: selected,
    child: MenuItemButton(
      onPressed: onSelect,
      autofocus: autofocus,
      leadingIcon: selected
          ? const Icon(Icons.check, size: 16, color: SettingsPaper.accent)
          : const SizedBox(width: 16),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(label),
            if (detail != null)
              Text(
                detail!,
                style: const TextStyle(
                  color: SettingsPaper.muted,
                  fontSize: 13,
                ),
              ),
          ],
        ),
      ),
    ),
  );
}

/// 在单张纸面中对齐名称、说明和右侧控件。
class PaperSettingRow extends StatelessWidget {
  const PaperSettingRow({
    required this.title,
    required this.control,
    this.detail,
    super.key,
  });

  /// 设置项名称。
  final String title;

  /// 设置项右侧的交互控件。
  final Widget control;

  /// 设置项用途或当前状态。
  final String? detail;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 10),
    child: Row(
      children: <Widget>[
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(title),
              if (detail != null) ...<Widget>[
                const SizedBox(height: 4),
                Text(
                  detail!,
                  style: const TextStyle(color: SettingsPaper.muted),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(width: 12),
        control,
      ],
    ),
  );
}
