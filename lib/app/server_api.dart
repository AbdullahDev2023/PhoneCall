import 'dart:convert';

import 'package:http/http.dart' as http;

import '../platform/generated/platform_api.g.dart';

class PhoneCallServerApiDefaults {
  static const String baseUrl =
      'https://phonecall.visioncoachinginstitute.online';
}

class ServerDeviceProfile {
  const ServerDeviceProfile({
    required this.deviceId,
    required this.deviceName,
    required this.createdAt,
    required this.updatedAt,
    required this.lastSeenAt,
  });

  factory ServerDeviceProfile.fromJson(Map<String, dynamic> json) {
    return ServerDeviceProfile(
      deviceId: json['deviceId'] as String? ?? '',
      deviceName: json['deviceName'] as String? ?? '',
      createdAt: json['createdAt'] as String? ?? '',
      updatedAt: json['updatedAt'] as String? ?? '',
      lastSeenAt: json['lastSeenAt'] as String? ?? '',
    );
  }

  final String deviceId;
  final String deviceName;
  final String createdAt;
  final String updatedAt;
  final String lastSeenAt;
}

class ServerSyncResult {
  const ServerSyncResult({required this.device, required this.storedLogs});

  factory ServerSyncResult.fromJson(Map<String, dynamic> json) {
    return ServerSyncResult(
      device: ServerDeviceProfile.fromJson(
        json['device'] as Map<String, dynamic>? ?? <String, dynamic>{},
      ),
      storedLogs: json['storedLogs'] as int? ?? 0,
    );
  }

  final ServerDeviceProfile device;
  final int storedLogs;
}

class PhoneCallServerApi {
  PhoneCallServerApi({required this.baseUrl, http.Client? client})
    : _client = client ?? http.Client();

  final String baseUrl;
  final http.Client _client;

  Uri _uri(String path) {
    final normalizedBase = baseUrl.endsWith('/') ? baseUrl : '$baseUrl/';
    return Uri.parse(
      normalizedBase,
    ).resolve(path.startsWith('/') ? path.substring(1) : path);
  }

  Map<String, String> get _jsonHeaders => <String, String>{
    'Content-Type': 'application/json; charset=utf-8',
    'Accept': 'application/json',
  };

  Future<ServerDeviceProfile?> fetchDeviceProfile(String deviceId) async {
    final response = await _client.get(_uri('/api/devices/$deviceId'));
    if (response.statusCode == 404) {
      return null;
    }
    _throwIfUnexpected(response);
    return ServerDeviceProfile.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<ServerDeviceProfile> upsertDeviceProfile({
    required String deviceId,
    required String deviceName,
  }) async {
    final response = await _client.put(
      _uri('/api/devices/$deviceId'),
      headers: _jsonHeaders,
      body: jsonEncode(<String, dynamic>{'deviceName': deviceName}),
    );
    _throwIfUnexpected(response);
    return ServerDeviceProfile.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<ServerSyncResult> syncCallLogs({
    required String deviceId,
    required List<RecentCall> logs,
  }) async {
    final response = await _client.post(
      _uri('/api/devices/$deviceId/call-logs'),
      headers: _jsonHeaders,
      body: jsonEncode(<String, dynamic>{
        'logs': logs.map(_serializeRecentCall).toList(growable: false),
      }),
    );
    _throwIfUnexpected(response);
    return ServerSyncResult.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  void _throwIfUnexpected(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return;
    }
    throw http.ClientException(
      'Server request failed with status ${response.statusCode}: ${response.body}',
      response.request?.url,
    );
  }
}

Map<String, dynamic> _serializeRecentCall(RecentCall call) {
  return <String, dynamic>{
    'id': call.id ?? '',
    'number': call.number,
    'displayName': call.displayName,
    'photoUri': call.photoUri,
    'contactId': call.contactId,
    'timestampMillis': call.timestampMillis,
    'durationSeconds': call.durationSeconds,
    'type': call.type?.name,
    'accountId': call.accountId,
    'occurrences': call.occurrences,
  };
}
