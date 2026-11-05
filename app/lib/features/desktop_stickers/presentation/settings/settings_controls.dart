import 'package:flutter/material.dart';

/// 设置窗统一使用白色底面、粗体和少量陶土色强调。
abstract final class SettingsPaper {
  static const Color surface = Colors.white;
  static const Color ink = Color(0xFF332B26);
  static const Color muted = Color(0xFF6D5D52);
  static const Color line = Color(0xFFE6E0DB);
  static const Color accent = Color(0xFF854A39);
  static const Color selection = Color(0xFFF8EEEA);
  static const Color hover = Color(0xFFF7F4F2);

  /// 内容标题与正文的字号分别设置，字重共用这一档。
  static const TextStyle _bold = TextStyle(fontWeight: FontWeight.w700);

  /// 标题和正文共享左右对齐线。
  static const double contentInset = 32;

  static final BorderRadius corners = BorderRadius.circular(9);

  static final ThemeData theme = ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: surface,
    colorScheme: const ColorScheme.light(
      primary: accent,
      onPrimary: Colors.white,
      secondary: accent,
      secondaryContainer: selection,
      onSecondaryContainer: ink,
      surface: surface,
      surfaceTint: Colors.transparent,
      surfaceContainerLowest: surface,
      surfaceContainerLow: surface,
      surfaceContainer: surface,
      surfaceContainerHigh: surface,
      surfaceContainerHighest: surface,
      onSurface: ink,
      onSurfaceVariant: muted,
      outline: line,
      outlineVariant: line,
    ),
    textTheme: const TextTheme(
      displayLarge: _bold,
      displayMedium: _bold,
      displaySmall: _bold,
      headlineLarge: _bold,
      headlineMedium: _bold,
      headlineSmall: _bold,
      titleLarge: _bold,
      titleMedium: _bold,
      titleSmall: _bold,
      bodyLarge: _bold,
      bodyMedium: _bold,
      bodySmall: _bold,
      labelLarge: _bold,
      labelMedium: _bold,
      labelSmall: _bold,
    ),
    dividerTheme: const DividerThemeData(color: line, thickness: 1),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: surface,
      contentTextStyle: _bold.copyWith(color: ink, fontSize: 14),
      actionTextColor: accent,
      shape: RoundedRectangleBorder(
        borderRadius: corners,
        side: const BorderSide(color: line),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(0, 38),
        shape: RoundedRectangleBorder(borderRadius: corners),
      ).copyWith(side: WidgetStateProperty.resolveWith(_focusBorder)),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style:
          OutlinedButton.styleFrom(
            minimumSize: const Size(0, 38),
            backgroundColor: surface,
            foregroundColor: ink,
            shape: RoundedRectangleBorder(borderRadius: corners),
          ).copyWith(
            side: WidgetStateProperty.resolveWith(_outline),
            overlayColor: WidgetStateProperty.resolveWith(_overlay),
          ),
    ),
    menuButtonTheme: MenuButtonThemeData(
      style: ButtonStyle(
        minimumSize: const WidgetStatePropertyAll<Size>(Size(0, 38)),
        shape: WidgetStatePropertyAll<OutlinedBorder>(
          RoundedRectangleBorder(borderRadius: corners),
        ),
        overlayColor: WidgetStateProperty.resolveWith(_overlay),
        side: WidgetStateProperty.resolveWith(_focusBorder),
      ),
    ),
    inputDecorationTheme: InputDecorationThemeData(
      filled: true,
      fillColor: surface,
      isDense: true,
      border: OutlineInputBorder(borderRadius: corners),
      enabledBorder: OutlineInputBorder(
        borderRadius: corners,
        borderSide: const BorderSide(color: line),
      ),
    ),
  );

  static Color? _overlay(Set<WidgetState> states) {
    if (states.contains(WidgetState.pressed)) return selection;
    if (states.contains(WidgetState.focused) ||
        states.contains(WidgetState.hovered)) {
      return hover;
    }
    return null;
  }

  static BorderSide _focusBorder(Set<WidgetState> states) =>
      states.contains(WidgetState.focused)
      ? const BorderSide(color: accent, width: 2)
      : BorderSide.none;

  static BorderSide _outline(Set<WidgetState> states) =>
      states.contains(WidgetState.focused)
      ? const BorderSide(color: accent, width: 2)
      : const BorderSide(color: line);
}

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
