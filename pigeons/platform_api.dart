import 'package:pigeon/pigeon.dart';

@ConfigurePigeon(
  PigeonOptions(
    dartOut: 'lib/platform/generated/platform_api.g.dart',
    dartPackageName: 'phone_call_app',
    kotlinOut:
        'android/app/src/main/kotlin/com/phonecall/app/phone_call_app/platform/PlatformApi.g.kt',
    kotlinOptions: KotlinOptions(
      package: 'com.phonecall.app.phone_call_app.platform',
    ),
  ),
)
class PlatformApiConfiguration {
  String? marker;
}

enum CallLogFilter { all, missed }

enum CallType {
  unknown,
  incoming,
  outgoing,
  missed,
  rejected,
  blocked,
  voicemail,
}

enum CallStatus { idle, ringing, dialing, active, held, disconnected }

enum AudioRoute { earpiece, speaker, bluetooth, wiredHeadset }

class PermissionState {
  bool? contactsGranted;
  bool? writeContactsGranted;
  bool? callLogGranted;
  bool? phoneGranted;
}

class SimAccount {
  String? id;
  String? label;
  String? address;
  bool? isDefault;
}

class PhoneNumberEntry {
  String? label;
  String? number;
  String? normalizedNumber;
}

class EmailEntry {
  String? label;
  String? address;
}

class ContactSummary {
  String? id;
  String? lookupKey;
  String? displayName;
  String? photoUri;
  bool? isStarred;
  String? primaryNumber;
}

class ContactDetail {
  String? id;
  String? lookupKey;
  String? givenName;
  String? familyName;
  String? displayName;
  String? company;
  String? photoUri;
  bool? isStarred;
  List<PhoneNumberEntry?>? phoneNumbers;
  List<EmailEntry?>? emailAddresses;
}

class EditableContact {
  String? contactId;
  String? givenName;
  String? familyName;
  String? company;
  bool? isStarred;
  List<PhoneNumberEntry?>? phoneNumbers;
  List<EmailEntry?>? emailAddresses;
}

class RecentCall {
  String? id;
  String? number;
  String? displayName;
  String? photoUri;
  String? contactId;
  int? timestampMillis;
  int? durationSeconds;
  CallType? type;
  String? accountId;
  int? occurrences;
}

class CallSessionState {
  String? callId;
  String? number;
  String? displayName;
  String? photoUri;
  CallStatus? status;
  bool? isMuted;
  bool? canMute;
  bool? canHold;
  bool? isOnHold;
  bool? canMerge;
  bool? canSwap;
  bool? canAnswer;
  bool? canReject;
  bool? canDisconnect;
  bool? canDtmf;
  bool? isConference;
  bool? shouldShowFullScreen;
  int? connectTimeMillis;
  AudioRoute? selectedAudioRoute;
  List<AudioRoute?>? availableAudioRoutes;
}

@HostApi()
abstract class DialerPlatformApi {
  PermissionState getPermissionState();
  bool requestCorePermissions();
  bool isDefaultDialer();
  bool requestDefaultDialerRole();
  List<SimAccount?> getCallCapableAccounts();
  void placeCall(String number, String? accountId);
  CallSessionState? getCurrentCallState();
  void answerCall();
  void rejectCall();
  void disconnectCall();
  void setMuted(bool muted);
  void setAudioRoute(AudioRoute route);
  void setHold(bool onHold);
  void playDtmfTone(String digit);
  void stopDtmfTone();
  void swapCalls();
  void mergeCalls();
}

@HostApi()
abstract class ContactsPlatformApi {
  List<ContactSummary?> searchContacts(String query);
  ContactDetail? getContact(String id);
  ContactDetail saveContact(EditableContact contact);
  void deleteContact(String id);
  void toggleFavorite(String id, bool isStarred);
}

@HostApi()
abstract class RecentsPlatformApi {
  List<RecentCall?> getRecentCalls(CallLogFilter filter);
  RecentCall? getCallDetails(String id);
}

@FlutterApi()
abstract class CallStateFlutterApi {
  void onCallStateChanged(CallSessionState state);
}
