import 'dart:io';
import 'dart:math';

import 'package:call_log/call_log.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../model/customer_call_model.dart';
import 'customer_call_viewmodel.dart';

/// Android Call Log adapter for the Sanpra Employee Customer Call feature.
///
/// Responsibilities:
/// - Request/check Android Call Log permission through the `call_log` package.
/// - Read the device's existing Android call history.
/// - Convert Android call-log entries into DeviceCallLogEntry objects.
/// - Provide a stable app-generated installation ID.
/// - Do NOT match customers.
/// - Do NOT call ERPNext.
/// - Do NOT upload anything.
///
/// Customer matching and ERPNext synchronization remain in
/// CustomerCallViewModel.syncDeviceCalls().
class AndroidCallLogAdapter {
  AndroidCallLogAdapter._();

  static const String _installationIdKey =
      'customer_call_installation_id';

  static const String _syncedCallIdsKey =
      'customer_call_synced_android_call_log_ids';

  /// Reads the Android call history and converts it to the application's
  /// DeviceCallLogEntry model.
  ///
  /// `call_log` automatically checks/requests the required Android permission
  /// when CallLog.get() is called.
  static Future<List<DeviceCallLogEntry>> loadCalls() async {
    if (!Platform.isAndroid) {
      throw UnsupportedError(
        'Customer call tracking is supported on Android only.',
      );
    }

    final deviceId = await _getInstallationId();

    final prefs = await SharedPreferences.getInstance();
    final syncedCallIds =
        prefs.getStringList(_syncedCallIdsKey)?.toSet() ?? <String>{};

    final Iterable<CallLogEntry> entries = await CallLog.get();

    final calls = <DeviceCallLogEntry>[];

    for (final entry in entries) {
      final phoneNumber = (entry.number ?? '').trim();

      // Some Android call-log rows may not contain a phone number.
      // Such rows cannot be matched against ERPNext customer numbers.
      if (phoneNumber.isEmpty) {
        continue;
      }

      final callType = _mapCallType(entry.callType);

      // Ignore Android call types that are not part of our CustomerCallType
      // model, such as voicemail/blocked/unknown/wifi-specific types.
      if (callType == null) {
        continue;
      }

      final timestamp = entry.timestamp;
      final callDateTime = timestamp == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(timestamp);

      // A call without a timestamp cannot be safely synchronized as a
      // customer call record.
      if (callDateTime == null) {
        continue;
      }

      final durationSeconds = entry.duration ?? 0;

      final androidCallLogId = _getCallLogId(entry, callDateTime);

      // Do not return calls that were already confirmed as synchronized.
      if (syncedCallIds.contains(androidCallLogId)) {
        continue;
      }

      calls.add(
        DeviceCallLogEntry(
          phoneNumber: phoneNumber,
          callType: callType,
          callDateTime: callDateTime,
          durationSeconds: durationSeconds < 0 ? 0 : durationSeconds,
          androidCallLogId: androidCallLogId,
          deviceId: deviceId,
          source: CustomerCallSource.androidCallLog,
        ),
      );
    }

    return calls;
  }

  /// Marks Android call-log IDs as successfully synchronized.
  ///
  /// This is called only after the ERPNext sync has completed successfully
  /// for the corresponding records. Failed records are intentionally not
  /// stored, so a later Sync can retry them.
  static Future<void> markCallsAsSynced(
      Iterable<String> androidCallLogIds,
      ) async {
    final idsToStore = androidCallLogIds
        .map((id) => id.trim())
        .where((id) => id.isNotEmpty)
        .toSet();

    if (idsToStore.isEmpty) return;

    final prefs = await SharedPreferences.getInstance();

    final existing =
        prefs.getStringList(_syncedCallIdsKey)?.toSet() ?? <String>{};

    existing.addAll(idsToStore);

    await prefs.setStringList(
      _syncedCallIdsKey,
      existing.toList(),
    );
  }

  /// Returns the same installation ID every time for this app installation.
  ///
  /// This is intentionally app-generated and stored in SharedPreferences.
  /// It does NOT use IMEI, serial number, MAC address, or another restricted
  /// hardware identifier.
  static Future<String> _getInstallationId() async {
    final prefs = await SharedPreferences.getInstance();

    final existing = prefs.getString(_installationIdKey)?.trim();

    if (existing != null && existing.isNotEmpty) {
      return existing;
    }

    final now = DateTime.now().microsecondsSinceEpoch;
    final random = Random.secure().nextInt(0x7fffffff);

    final generatedId = 'sanpra-${now.toRadixString(36)}-'
        '${random.toRadixString(36)}';

    await prefs.setString(_installationIdKey, generatedId);

    return generatedId;
  }

  /// Converts the Android call_log package enum to the application's
  /// CustomerCallType enum.
  static CustomerCallType? _mapCallType(CallType? type) {
    switch (type) {
      case CallType.incoming:
        return CustomerCallType.incoming;

      case CallType.outgoing:
        return CustomerCallType.outgoing;

      case CallType.missed:
        return CustomerCallType.missed;

      case CallType.rejected:
        return CustomerCallType.rejected;

      default:
        return null;
    }
  }

  /// Android call-log IDs are used for idempotency/duplicate prevention.
  ///
  /// A small fallback is provided for unusual devices where the plugin does
  /// not return an ID.
  static String _getCallLogId(
      CallLogEntry entry,
      DateTime callDateTime,
      ) {
    final id = entry.id;

    if (id != null && id.toString().trim().isNotEmpty) {
      return id.toString();
    }

    return 'fallback-${callDateTime.microsecondsSinceEpoch}-'
        '${(entry.number ?? '').trim()}';
  }
}
