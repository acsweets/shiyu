import 'dart:async';

import 'package:flutter/material.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../../../platform/desktop/floating_window_controller.dart';
import '../application/retirement_controller.dart';
import 'retirement_card.dart';

class RetirementPage extends StatefulWidget {
  const RetirementPage({required this.controller, this.window, super.key});

  /// 当前应用的唯一设置与快照状态。
  final RetirementController controller;

  /// 移动端没有桌面窗口行为。
  final FloatingWindowController? window;
  @override
  State<RetirementPage> createState() => _RetirementPageState();
}

class _RetirementPageState extends State<RetirementPage>
    with WidgetsBindingObserver {
  /// 尚未保存的时区输入，保留错误值供用户修正。
  late final TextEditingController _zone;

  /// 浮窗是否展开配置区，移动端始终展开。
  bool _expanded = false;

  @override
  void initState() {
    super.initState();
    _zone = TextEditingController(text: widget.controller.timeZone);
    WidgetsBinding.instance.addObserver(this);
    widget.controller.setVisible(true);
  }

  @override
  void dispose() {
    widget.controller.setVisible(false);
    WidgetsBinding.instance.removeObserver(this);
    _zone.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) widget.controller.setVisible(true);
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden ||
        state == AppLifecycleState.detached) {
      widget.controller.setVisible(false);
    }
  }

  Future<void> _toggleExpanded() async {
    final bool next = !_expanded;
    await widget.window?.setExpanded(next);
    if (mounted) setState(() => _expanded = next);
  }

  void _drag(DragStartDetails details) {
    unawaited(widget.window?.drag() ?? Future<void>.value());
  }

  Future<void> _chooseDate() async {
    final DateTime? date = await showDatePicker(
      context: context,
      initialDate:
          DateTime.tryParse(widget.controller.retirementDate ?? '') ??
          DateTime.now(),
      firstDate: DateTime(1),
      lastDate: DateTime(9999, 12, 31),
    );
    if (date != null) {
      await widget.controller.save(
        date.toIso8601String().split('T').first,
        _zone.text,
      );
    }
  }

  Future<void> _saveZone() async {
    await widget.controller.save(widget.controller.retirementDate, _zone.text);
  }

  Future<void> _clear() async {
    await widget.controller.save(null, _zone.text);
  }

  Future<void> _addWidget() async {
    bool requested = false;
    try {
      requested = await widget.controller.widgets.pin();
    } catch (_) {
      requested = false;
    }
    if (mounted && !requested) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).widgetInstructions),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) =>
      AnimatedBuilder(animation: widget.controller, builder: _buildContent);

  Widget _buildContent(BuildContext context, Widget? child) {
    final AppLocalizations strings = AppLocalizations.of(context);
    final bool expanded = widget.window == null || _expanded;
    return Scaffold(
      backgroundColor: widget.window == null ? null : Colors.transparent,
      body: SafeArea(
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFAFBFDFC),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFD8E5DE)),
          ),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: <Widget>[
              GestureDetector(
                behavior: HitTestBehavior.translucent,
                onPanStart: widget.window == null ? null : _drag,
                child: Row(
                  children: <Widget>[
                    const Icon(Icons.hourglass_bottom_rounded, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        strings.appName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    if (widget.window != null) ...<Widget>[
                      IconButton(
                        tooltip: strings.configure,
                        onPressed: _toggleExpanded,
                        icon: const Icon(Icons.tune_rounded),
                      ),
                      IconButton(
                        tooltip: strings.hideWindow,
                        onPressed: widget.window!.hide,
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ],
                ),
              ),
              RetirementCard(controller: widget.controller),
              if (widget.controller.problem != null)
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Text(
                    strings.settingsError,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              if (expanded) ...<Widget>[
                const SizedBox(height: 16),
                FilledButton.icon(
                  key: const ValueKey<String>('chooseDate'),
                  onPressed:
                      widget.controller.saving ||
                          widget.controller.editingBlocked
                      ? null
                      : _chooseDate,
                  icon: const Icon(Icons.calendar_month),
                  label: Text(strings.chooseRetirement),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _zone,
                  decoration: InputDecoration(
                    labelText: strings.timeZoneLabel,
                    hintText: 'Asia/Shanghai',
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: OutlinedButton(
                        onPressed:
                            widget.controller.saving ||
                                widget.controller.editingBlocked
                            ? null
                            : _saveZone,
                        child: Text(strings.saveSettings),
                      ),
                    ),
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed:
                          widget.controller.saving ||
                              widget.controller.editingBlocked
                          ? null
                          : _clear,
                      child: Text(strings.clearTarget),
                    ),
                  ],
                ),
                if (widget.window == null)
                  OutlinedButton.icon(
                    onPressed: _addWidget,
                    icon: const Icon(Icons.widgets_outlined),
                    label: Text(strings.addWidget),
                  ),
                const SizedBox(height: 16),
                Text(
                  strings.calendarFallback,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 8),
                Text(
                  strings.currentSlice,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
