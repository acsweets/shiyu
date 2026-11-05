import 'dart:convert';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../application/holiday_status.dart';
import '../data/holiday_pack.dart';
import '../data/holiday_repository.dart';

typedef HolidayCheck = Future<HolidayUpdate> Function();
typedef HolidayImport = Future<HolidayUpdate> Function(String raw);

class HolidayPanel extends StatefulWidget {
  const HolidayPanel({
    required this.status,
    required this.check,
    required this.importPack,
    super.key,
  });

  final HolidayStatus status;
  final HolidayCheck check;
  final HolidayImport importPack;

  @override
  State<HolidayPanel> createState() => _HolidayPanelState();
}

class _HolidayPanelState extends State<HolidayPanel> {
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations strings = AppLocalizations.of(context);
    final HolidayStatus status = widget.status;
    final bool busy = _busy || status.update == HolidayUpdate.checking;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        if (status.version != null)
          Text(
            '${status.region} · ${status.years.join(' / ')} · v${status.version}',
          ),
        if (!status.available) Text(strings.holidayFallback),
        if (busy) Text(strings.holidayChecking),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: <Widget>[
            OutlinedButton(
              onPressed: busy ? null : _check,
              child: Text(strings.holidayCheck),
            ),
            OutlinedButton(
              onPressed: busy ? null : _pick,
              child: Text(strings.holidayImport),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _check() async {
    setState(() => _busy = true);
    try {
      _report(await widget.check());
    } catch (_) {
      _report(HolidayUpdate.failed);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _pick() async {
    setState(() => _busy = true);
    try {
      final XFile? file = await openFile(
        acceptedTypeGroups: const <XTypeGroup>[
          XTypeGroup(
            label: 'JSON',
            extensions: <String>['json'],
            mimeTypes: <String>['application/json'],
            uniformTypeIdentifiers: <String>['public.json'],
          ),
        ],
      );
      if (file == null || !mounted) return;
      if (await file.length() > holidayMaxBytes) {
        _report(HolidayUpdate.rejected);
        return;
      }
      final String raw = utf8.decode(await file.readAsBytes());
      if (mounted) _report(await widget.importPack(raw));
    } on FormatException {
      _report(HolidayUpdate.rejected);
    } catch (_) {
      _report(HolidayUpdate.failed);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _report(HolidayUpdate result) {
    if (!mounted) return;
    final AppLocalizations strings = AppLocalizations.of(context);
    final String? message = switch (result) {
      HolidayUpdate.updated => strings.holidayUpdated,
      HolidayUpdate.latest => strings.holidayLatest,
      HolidayUpdate.rejected => strings.holidayRejected,
      HolidayUpdate.failed => strings.holidayFailed,
      HolidayUpdate.idle || HolidayUpdate.checking => null,
    };
    if (message != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    }
  }
}
