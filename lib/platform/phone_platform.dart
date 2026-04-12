import 'dart:async';

import 'generated/platform_api.g.dart';

class CallStateBridge extends CallStateFlutterApi {
  CallStateBridge._();

  static final CallStateBridge instance = CallStateBridge._();

  final StreamController<CallSessionState> _controller =
      StreamController<CallSessionState>.broadcast();
  bool _isRegistered = false;

  Stream<CallSessionState> get stream => _controller.stream;

  void register() {
    if (_isRegistered) {
      return;
    }
    CallStateFlutterApi.setUp(this);
    _isRegistered = true;
  }

  @override
  void onCallStateChanged(CallSessionState state) {
    _controller.add(state);
  }
}

class PhonePlatform {
  static final DialerPlatformApi dialer = DialerPlatformApi();
  static final ContactsPlatformApi contacts = ContactsPlatformApi();
  static final RecentsPlatformApi recents = RecentsPlatformApi();

  static Future<void> initialize() async {
    CallStateBridge.instance.register();
  }
}
