import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../l10n/generated/app_localizations.dart';

/// 字段只显示已选的 IANA 时区，输入仅用于筛选下拉选项。
class SettingsTimeZone extends StatefulWidget {
  const SettingsTimeZone({
    required this.value,
    required this.changed,
    this.error,
    super.key,
  });

  /// 当前已选的时区，保留旧配置中的原始名称。
  final String value;

  /// 选择真实条目后更新草稿，空值表示只读。
  final ValueChanged<String>? changed;

  /// 核心返回的校验提示。
  final String? error;

  @override
  State<SettingsTimeZone> createState() => _SettingsTimeZoneState();
}

class _SettingsTimeZoneState extends State<SettingsTimeZone> {
  /// 菜单关闭后焦点回到下拉按钮。
  final FocusNode _buttonFocus = FocusNode();

  /// 选择或再次点击字段时关闭菜单。
  final MenuController _menu = MenuController();

  @override
  void dispose() {
    _buttonFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: LayoutBuilder(builder: _field),
  );

  Widget _field(BuildContext context, BoxConstraints constraints) {
    final AppLocalizations strings = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        MenuAnchor(
          controller: _menu,
          childFocusNode: _buttonFocus,
          alignmentOffset: const Offset(0, 4),
          menuChildren: <Widget>[
            SizedBox(
              width: math.min(420, constraints.maxWidth),
              child: _TimeZoneOptions(value: widget.value, choose: _choose),
            ),
          ],
          child: OutlinedButton(
            key: const ValueKey<String>('time-zone-picker'),
            focusNode: _buttonFocus,
            onPressed: widget.changed == null ? null : _toggle,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(strings.timeZoneLabel),
                      Text(widget.value, overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.expand_more),
              ],
            ),
          ),
        ),
        if (widget.error case final String error)
          Text(
            error,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
      ],
    );
  }

  void _toggle() {
    if (_menu.isOpen) {
      _menu.close();
    } else {
      _menu.open();
    }
  }

  void _choose(String value) {
    _menu.close();
    if (value != widget.value) widget.changed?.call(value);
  }
}

class _TimeZoneOptions extends StatefulWidget {
  const _TimeZoneOptions({required this.value, required this.choose});

  /// 当前值始终可见，包括旧配置中使用的别名。
  final String value;

  /// 应用一个已列出的选项。
  final ValueChanged<String> choose;

  @override
  State<_TimeZoneOptions> createState() => _TimeZoneOptionsState();
}

class _TimeZoneOptionsState extends State<_TimeZoneOptions> {
  /// 常用时区优先列出，其余选项按资产中的顺序排列。
  static const List<String> _common = <String>[
    'Asia/Shanghai',
    'Asia/Hong_Kong',
    'Asia/Taipei',
    'Asia/Tokyo',
    'Asia/Seoul',
    'Asia/Singapore',
    'UTC',
    'Europe/London',
    'Europe/Paris',
    'America/New_York',
    'America/Los_Angeles',
  ];

  /// 列表随菜单打开加载，成功后由资产缓存复用。
  Future<List<String>>? _zones;

  /// 搜索词从不写入设置。
  String _query = '';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _zones ??= _loadZones(DefaultAssetBundle.of(context));
  }

  Future<List<String>> _loadZones(AssetBundle bundle) async =>
      const LineSplitter().convert(
        await bundle.loadString('assets/time_zones.txt'),
      );

  @override
  Widget build(BuildContext context) =>
      FutureBuilder<List<String>>(future: _zones, builder: _buildOptions);

  Widget _buildOptions(
    BuildContext context,
    AsyncSnapshot<List<String>> snapshot,
  ) {
    final AppLocalizations strings = AppLocalizations.of(context);
    final List<String> options = <String>{
      widget.value,
      ..._common,
      ...?snapshot.data,
    }.where(_matches).toList();
    final double height = math.min(
      320,
      MediaQuery.sizeOf(context).height * 0.42,
    );
    return SizedBox(
      height: height,
      child: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.all(8),
            child: TextField(
              key: const ValueKey<String>('time-zone-search'),
              onChanged: _filter,
              autocorrect: false,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: strings.timeZoneSearch,
              ),
            ),
          ),
          Expanded(
            child: options.isEmpty
                ? _emptyOptions(snapshot, strings)
                : ListView.builder(
                    primary: false,
                    padding: EdgeInsets.zero,
                    itemCount: options.length,
                    itemBuilder: (BuildContext context, int index) =>
                        _option(options[index]),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _emptyOptions(
    AsyncSnapshot<List<String>> snapshot,
    AppLocalizations strings,
  ) => Center(
    child: snapshot.connectionState == ConnectionState.waiting
        ? const CircularProgressIndicator()
        : Text(
            snapshot.hasError
                ? strings.metricUnavailable
                : strings.timeZoneNoMatches,
          ),
  );

  void _filter(String value) => setState(() {
    _query = value.trim().toLowerCase().replaceAll(' ', '_');
  });

  bool _matches(String value) => value.toLowerCase().contains(_query);

  Widget _option(String value) => MenuItemButton(
    closeOnActivate: false,
    onPressed: () => widget.choose(value),
    leadingIcon: value == widget.value
        ? const Icon(Icons.check, size: 18)
        : const SizedBox(width: 18),
    child: Text(value, overflow: TextOverflow.ellipsis),
  );
}
