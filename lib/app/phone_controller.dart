import 'dart:async';
import 'dart:math';

import 'package:flutter/widgets.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/phone_formatters.dart';
import '../platform/generated/platform_api.g.dart';
import '../platform/phone_platform.dart';
import 'server_api.dart';

class PhoneController extends ChangeNotifier with WidgetsBindingObserver {
  PhoneController();

  static const String _preferredAccountPreferenceKey =
      'preferred_call_account_id';
  static const String _deviceIdPreferenceKey = 'device_id';
  static const String _serverBaseUrlPreferenceKey = 'server_base_url';

  final DialerPlatformApi _dialerApi = PhonePlatform.dialer;
  final ContactsPlatformApi _contactsApi = PhonePlatform.contacts;
  final RecentsPlatformApi _recentsApi = PhonePlatform.recents;
  final Random _random = Random.secure();

  SharedPreferences? _preferences;
  StreamSubscription<CallSessionState>? _callStateSubscription;
  PhoneCallServerApi? _serverApi;
  bool _isSyncingCallLogs = false;

  bool isInitializing = true;
  int selectedTabIndex = 1;
  bool showMissedOnly = false;
  String searchQuery = '';
  String keypadInput = '';
  bool isDefaultDialer = false;
  String serverBaseUrl = PhoneCallServerApiDefaults.baseUrl;
  String deviceId = '';
  String serverDeviceName = '';
  String? lastSyncError;
  DateTime? lastCallLogSyncAt;

  PermissionState? permissionState;
  CallSessionState? callState;

  List<ContactSummary> _allContacts = <ContactSummary>[];
  List<RecentCall> _recentCalls = <RecentCall>[];
  List<SimAccount> simAccounts = <SimAccount>[];

  String? preferredAccountId;

  bool get contactsGranted => permissionState?.contactsGranted ?? false;
  bool get writeContactsGranted =>
      permissionState?.writeContactsGranted ?? false;
  bool get callLogGranted => permissionState?.callLogGranted ?? false;
  bool get phoneGranted => permissionState?.phoneGranted ?? false;

  bool get hasCorePermissions =>
      contactsGranted && writeContactsGranted && callLogGranted && phoneGranted;

  bool get needsOnboarding => !hasCorePermissions || !isDefaultDialer;

  bool get hasActiveCall {
    final status = callState?.status;
    return status != null &&
        status != CallStatus.idle &&
        status != CallStatus.disconnected;
  }

  bool get hasServerSync => deviceId.isNotEmpty;

  String get effectiveDeviceName {
    if (serverDeviceName.trim().isNotEmpty) {
      return serverDeviceName.trim();
    }
    return _buildDefaultDeviceName(deviceId);
  }

  String get shortDeviceId {
    if (deviceId.length <= 8) {
      return deviceId;
    }
    return deviceId.substring(0, 8);
  }

  List<ContactSummary> get favoriteContacts {
    return _allContacts
        .where((contact) => contact.isStarred == true)
        .where(_matchesContactSearch)
        .toList();
  }

  List<ContactSummary> get visibleContacts {
    return _allContacts.where(_matchesContactSearch).toList();
  }

  List<RecentCall> get visibleRecentCalls {
    final query = searchQuery.trim().toLowerCase();
    return _recentCalls.where((call) {
      if (showMissedOnly && call.type != CallType.missed) {
        return false;
      }
      if (query.isEmpty) {
        return true;
      }
      final displayName = (call.displayName ?? '').toLowerCase();
      return displayName.contains(query) || (call.number ?? '').contains(query);
    }).toList();
  }

  List<ContactSummary> get keypadSuggestions {
    if (keypadInput.isEmpty) {
      return favoriteContacts.take(6).toList();
    }

    final digits = normalizedDigits(keypadInput);
    final matches =
        _allContacts.where((contact) {
          final primaryNumber = contact.primaryNumber ?? '';
          return normalizedDigits(primaryNumber).contains(digits) ||
              matchesT9(contact.displayName ?? '', digits);
        }).toList();

    matches.sort((left, right) {
      if (left.isStarred != right.isStarred) {
        return left.isStarred == true ? -1 : 1;
      }
      return (left.displayName ?? '').toLowerCase().compareTo(
        (right.displayName ?? '').toLowerCase(),
      );
    });

    return matches.take(8).toList();
  }

  String get formattedKeypadInput => formatPhoneNumber(keypadInput);

  Future<void> initialize() async {
    WidgetsBinding.instance.addObserver(this);
    _preferences = await SharedPreferences.getInstance();
    preferredAccountId = _preferences?.getString(
      _preferredAccountPreferenceKey,
    );
    serverBaseUrl =
        _preferences?.getString(_serverBaseUrlPreferenceKey) ??
        PhoneCallServerApiDefaults.baseUrl;
    deviceId = await _loadOrCreateDeviceId();
    _serverApi = PhoneCallServerApi(baseUrl: serverBaseUrl);

    _callStateSubscription = CallStateBridge.instance.stream.listen(
      _handleCallStateUpdate,
    );

    await refreshAll();
    isInitializing = false;
    notifyListeners();
  }

  Future<void> refreshAll() async {
    await refreshSystemState();
    await refreshServerDeviceProfile();
    await Future.wait<void>(<Future<void>>[
      refreshContacts(),
      refreshRecentCalls(),
    ]);
  }

  Future<void> refreshSystemState() async {
    try {
      permissionState = await _dialerApi.getPermissionState();
      isDefaultDialer = await _dialerApi.isDefaultDialer();
      callState = await _dialerApi.getCurrentCallState();
      simAccounts =
          (await _dialerApi.getCallCapableAccounts())
              .whereType<SimAccount>()
              .toList();
    } on PlatformException catch (error) {
      debugPrint('Failed to refresh system state: ${error.message}');
      simAccounts = <SimAccount>[];
    }
    notifyListeners();
  }

  Future<void> refreshContacts() async {
    if (!contactsGranted) {
      _allContacts = <ContactSummary>[];
      notifyListeners();
      return;
    }
    _allContacts =
        (await _contactsApi.searchContacts(
          '',
        )).whereType<ContactSummary>().toList();
    notifyListeners();
  }

  Future<void> refreshRecentCalls() async {
    if (!callLogGranted) {
      _recentCalls = <RecentCall>[];
      notifyListeners();
      return;
    }
    _recentCalls =
        (await _recentsApi.getRecentCalls(
          showMissedOnly ? CallLogFilter.missed : CallLogFilter.all,
        )).whereType<RecentCall>().toList();
    notifyListeners();
    unawaited(syncRecentCallsToServer());
  }

  Future<void> refreshServerDeviceProfile() async {
    if (_serverApi == null || deviceId.isEmpty) {
      return;
    }

    try {
      final remoteProfile = await _serverApi!.fetchDeviceProfile(deviceId);
      if (remoteProfile == null) {
        final created = await _serverApi!.upsertDeviceProfile(
          deviceId: deviceId,
          deviceName: _buildDefaultDeviceName(deviceId),
        );
        serverDeviceName = created.deviceName;
      } else {
        serverDeviceName = remoteProfile.deviceName;
      }
      lastSyncError = null;
    } catch (error) {
      lastSyncError = 'Device profile sync failed: $error';
    }
    notifyListeners();
  }

  Future<void> syncRecentCallsToServer() async {
    if (_serverApi == null || !_canSyncCallLogs || _isSyncingCallLogs) {
      return;
    }

    _isSyncingCallLogs = true;
    try {
      final result = await _serverApi!.syncCallLogs(
        deviceId: deviceId,
        logs: _recentCalls,
      );
      serverDeviceName = result.device.deviceName;
      lastSyncError = null;
      lastCallLogSyncAt = DateTime.now();
    } catch (error) {
      lastSyncError = 'Call log sync failed: $error';
    } finally {
      _isSyncingCallLogs = false;
      notifyListeners();
    }
  }

  Future<ContactDetail?> loadContactDetail(String id) {
    return _contactsApi.getContact(id);
  }

  Future<List<ContactSummary>> lookupContactsByNumber(String query) async {
    return (await _contactsApi.searchContacts(
      query,
    )).whereType<ContactSummary>().toList();
  }

  Future<RecentCall?> loadCallDetails(String callId) {
    return _recentsApi.getCallDetails(callId);
  }

  Future<ContactDetail> saveContact(EditableContact contact) async {
    final saved = await _contactsApi.saveContact(contact);
    await refreshContacts();
    return saved;
  }

  Future<void> deleteContact(String id) async {
    await _contactsApi.deleteContact(id);
    await refreshContacts();
  }

  Future<void> toggleFavorite(String contactId, bool isStarred) async {
    await _contactsApi.toggleFavorite(contactId, isStarred);
    await refreshContacts();
  }

  Future<void> requestCorePermissions() async {
    await _dialerApi.requestCorePermissions();
    await refreshAll();
  }

  Future<bool> requestDefaultDialerRole() async {
    final launched = await _dialerApi.requestDefaultDialerRole();
    await refreshSystemState();
    return launched;
  }

  Future<void> savePreferredAccount(String? accountId) async {
    preferredAccountId = accountId;
    if (accountId == null || accountId.isEmpty) {
      await _preferences?.remove(_preferredAccountPreferenceKey);
    } else {
      await _preferences?.setString(_preferredAccountPreferenceKey, accountId);
    }
    notifyListeners();
  }

  Future<void> refreshServerBaseUrl(String value) async {
    final normalized = value.trim();
    if (normalized.isEmpty || normalized == serverBaseUrl) {
      return;
    }
    serverBaseUrl = normalized;
    await _preferences?.setString(_serverBaseUrlPreferenceKey, serverBaseUrl);
    _serverApi = PhoneCallServerApi(baseUrl: serverBaseUrl);
    await refreshServerDeviceProfile();
  }

  void setSelectedTab(int index) {
    if (selectedTabIndex == index) {
      return;
    }
    selectedTabIndex = index;
    searchQuery = '';
    notifyListeners();
  }

  void updateSearchQuery(String value) {
    searchQuery = value;
    notifyListeners();
  }

  Future<void> setShowMissedOnly(bool value) async {
    if (showMissedOnly == value) {
      return;
    }
    showMissedOnly = value;
    await refreshRecentCalls();
  }

  void appendDigit(String value) {
    keypadInput += value;
    notifyListeners();
  }

  void removeLastDigit() {
    if (keypadInput.isEmpty) {
      return;
    }
    keypadInput = keypadInput.substring(0, keypadInput.length - 1);
    notifyListeners();
  }

  void clearDigits() {
    if (keypadInput.isEmpty) {
      return;
    }
    keypadInput = '';
    notifyListeners();
  }

  Future<void> placeCall(String rawNumber, {String? accountId}) async {
    final normalizedNumber = normalizedDigits(rawNumber);
    if (normalizedNumber.isEmpty) {
      return;
    }

    await _dialerApi.placeCall(
      normalizedNumber,
      accountId?.isNotEmpty == true ? accountId : preferredAccountId,
    );
    keypadInput = normalizedNumber;
    notifyListeners();
  }

  Future<void> answerCall() => _dialerApi.answerCall();

  Future<void> rejectCall() => _dialerApi.rejectCall();

  Future<void> disconnectCall() => _dialerApi.disconnectCall();

  Future<void> setMuted(bool muted) => _dialerApi.setMuted(muted);

  Future<void> setHold(bool onHold) => _dialerApi.setHold(onHold);

  Future<void> setAudioRoute(AudioRoute route) =>
      _dialerApi.setAudioRoute(route);

  Future<void> playDtmfTone(String digit) => _dialerApi.playDtmfTone(digit);

  Future<void> stopDtmfTone() => _dialerApi.stopDtmfTone();

  Future<void> swapCalls() => _dialerApi.swapCalls();

  Future<void> mergeCalls() => _dialerApi.mergeCalls();

  bool get _canSyncCallLogs => callLogGranted && hasServerSync;

  void _handleCallStateUpdate(CallSessionState state) {
    callState = state;
    notifyListeners();
    if (state.status == CallStatus.disconnected ||
        state.status == CallStatus.idle) {
      unawaited(refreshRecentCalls());
    }
  }

  bool _matchesContactSearch(ContactSummary contact) {
    final query = searchQuery.trim().toLowerCase();
    if (query.isEmpty) {
      return true;
    }
    final primaryNumber = contact.primaryNumber ?? '';
    return (contact.displayName ?? '').toLowerCase().contains(query) ||
        primaryNumber.contains(query);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(refreshServerDeviceProfile());
      unawaited(refreshRecentCalls());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _callStateSubscription?.cancel();
    super.dispose();
  }

  Future<String> _loadOrCreateDeviceId() async {
    final stored = _preferences?.getString(_deviceIdPreferenceKey);
    if (stored != null && stored.trim().isNotEmpty) {
      return stored.trim();
    }

    final generated = _generateDeviceId();
    await _preferences?.setString(_deviceIdPreferenceKey, generated);
    return generated;
  }

  String _generateDeviceId() {
    final timestamp = DateTime.now().microsecondsSinceEpoch.toRadixString(36);
    final randomPart =
        List<int>.generate(
          10,
          (_) => _random.nextInt(16),
        ).map((value) => value.toRadixString(16)).join();
    return 'phonecall-$timestamp-$randomPart';
  }

  String _buildDefaultDeviceName(String value) {
    final cleaned = value.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');
    final suffix = cleaned.length >= 6 ? cleaned.substring(0, 6) : cleaned;
    return suffix.isEmpty
        ? 'PhoneCall device'
        : 'PhoneCall device ${suffix.toUpperCase()}';
  }
}
