import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/phone_formatters.dart';
import '../../platform/generated/platform_api.g.dart';
import '../call_actions.dart';
import '../phone_controller.dart';
import '../widgets/common_widgets.dart';
import 'contact_screens.dart';

class InCallScreen extends StatelessWidget {
  const InCallScreen({super.key, required this.controller});

  final PhoneController controller;

  @override
  Widget build(BuildContext context) {
    final state = controller.callState;
    if (state == null) {
      return const SizedBox.shrink();
    }

    final availableRoutes =
        state.availableAudioRoutes?.whereType<AudioRoute>() ??
        const <AudioRoute>[];
    final title =
        (state.displayName?.isNotEmpty ?? false)
            ? state.displayName!
            : formatPhoneNumber(state.number ?? 'Unknown');
    final subtitle = switch (state.status) {
      CallStatus.ringing => 'Incoming call',
      CallStatus.dialing => 'Calling…',
      CallStatus.active => 'In call',
      CallStatus.held => 'On hold',
      CallStatus.disconnected => 'Call ended',
      _ => 'PhoneCall',
    };

    final hasAnswerControls =
        (state.canAnswer ?? false) || (state.canReject ?? false);

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      child: Column(
        children: <Widget>[
          AppPill(
            label: subtitle,
            icon: state.status == CallStatus.active ? Icons.call : Icons.phone,
            selected: state.status == CallStatus.active,
          ),
          const SizedBox(height: 22),
          CircleAvatar(
            radius: 46,
            backgroundColor: Colors.white.withValues(alpha: 0.12),
            child: Text(
              initialsForName(title),
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(color: Colors.white70),
          ),
          if ((state.connectTimeMillis ?? 0) > 0 &&
              state.status == CallStatus.active) ...<Widget>[
            const SizedBox(height: 8),
            AppPill(
              label: _elapsedLabel(state.connectTimeMillis ?? 0),
              icon: Icons.timer_outlined,
              selected: true,
            ),
          ],
          const SizedBox(height: 28),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 12,
            runSpacing: 12,
            children: <Widget>[
              CallActionButton(
                icon: state.isMuted == true ? Icons.mic_off : Icons.mic,
                label: state.isMuted == true ? 'Unmute' : 'Mute',
                enabled: state.canMute ?? false,
                onPressed: () => controller.setMuted(!(state.isMuted ?? false)),
              ),
              CallActionButton(
                icon: audioRouteIcon(
                  state.selectedAudioRoute ?? AudioRoute.earpiece,
                ),
                label: audioRouteLabel(
                  state.selectedAudioRoute ?? AudioRoute.earpiece,
                ),
                enabled: availableRoutes.isNotEmpty,
                onPressed:
                    () => _showAudioRouteSheet(
                      context,
                      controller,
                      availableRoutes,
                    ),
              ),
              CallActionButton(
                icon: state.isOnHold == true ? Icons.play_arrow : Icons.pause,
                label: state.isOnHold == true ? 'Resume' : 'Hold',
                enabled: state.canHold ?? false,
                onPressed: () => controller.setHold(!(state.isOnHold ?? false)),
              ),
              CallActionButton(
                icon: Icons.swap_calls,
                label: 'Swap',
                enabled: state.canSwap ?? false,
                onPressed: controller.swapCalls,
              ),
              CallActionButton(
                icon: Icons.merge_type,
                label: 'Merge',
                enabled: state.canMerge ?? false,
                onPressed: controller.mergeCalls,
              ),
            ],
          ),
          const SizedBox(height: 18),
          if (state.canDtmf ?? false)
            SurfaceCard(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const SectionHeader(
                    title: 'Keypad',
                    subtitle: 'Tap digits to send DTMF tones during the call.',
                  ),
                  const SizedBox(height: 14),
                  _InCallDialPad(controller: controller),
                ],
              ),
            ),
          const SizedBox(height: 20),
          if (hasAnswerControls)
            Row(
              children: <Widget>[
                Expanded(
                  child: FilledButton.tonalIcon(
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFFFE6E3),
                      foregroundColor: const Color(0xFFB3261E),
                      minimumSize: const Size.fromHeight(56),
                    ),
                    onPressed: controller.rejectCall,
                    icon: const Icon(Icons.call_end),
                    label: const Text('Decline'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF1E8E3E),
                      minimumSize: const Size.fromHeight(56),
                    ),
                    onPressed: controller.answerCall,
                    icon: const Icon(Icons.call),
                    label: const Text('Answer'),
                  ),
                ),
              ],
            )
          else
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFB3261E),
                minimumSize: const Size.fromHeight(56),
              ),
              onPressed: controller.disconnectCall,
              icon: const Icon(Icons.call_end),
              label: const Text('End call'),
            ),
        ],
      ),
    );
  }

  String _elapsedLabel(int connectTimeMillis) {
    final elapsed =
        DateTime.now()
            .difference(DateTime.fromMillisecondsSinceEpoch(connectTimeMillis))
            .inSeconds;
    return formatDuration(elapsed);
  }

  Future<void> _showAudioRouteSheet(
    BuildContext context,
    PhoneController controller,
    Iterable<AudioRoute> routes,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: SurfaceCard(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.black12,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const SectionHeader(
                    title: 'Audio route',
                    subtitle: 'Choose where the call audio should play.',
                  ),
                  const SizedBox(height: 12),
                  ...routes.map((route) {
                    return ListTile(
                      leading: Icon(audioRouteIcon(route)),
                      title: Text(audioRouteLabel(route)),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        Navigator.of(context).pop();
                        controller.setAudioRoute(route);
                      },
                    );
                  }),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class CallDetailScreen extends StatefulWidget {
  const CallDetailScreen({
    super.key,
    required this.controller,
    required this.initialCall,
  });

  final PhoneController controller;
  final RecentCall initialCall;

  @override
  State<CallDetailScreen> createState() => _CallDetailScreenState();
}

class _CallDetailScreenState extends State<CallDetailScreen> {
  late Future<RecentCall?> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.controller.loadCallDetails(widget.initialCall.id ?? '');
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<RecentCall?>(
      future: _future,
      builder: (context, snapshot) {
        final call = snapshot.data ?? widget.initialCall;
        return Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(title: const Text('Call details')),
          body: Stack(
            children: <Widget>[
              const AppBackdrop(),
              ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
                children: <Widget>[
                  SurfaceCard(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        CircleAvatar(
                          radius: 34,
                          backgroundColor:
                              Theme.of(context).colorScheme.primaryContainer,
                          foregroundColor:
                              Theme.of(context).colorScheme.onPrimaryContainer,
                          child: Text(
                            initialsForName(
                              call.displayName?.isNotEmpty == true
                                  ? call.displayName!
                                  : call.number ?? '',
                            ),
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 22,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          call.displayName?.isNotEmpty == true
                              ? call.displayName!
                              : formatPhoneNumber(call.number ?? ''),
                          style: Theme.of(context).textTheme.headlineMedium
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          formatPhoneNumber(call.number ?? ''),
                          style: Theme.of(
                            context,
                          ).textTheme.bodyMedium?.copyWith(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: <Widget>[
                            AppPill(
                              label: callTypeLabel(
                                call.type ?? CallType.unknown,
                              ),
                              icon: callTypeIcon(call.type ?? CallType.unknown),
                              selected:
                                  (call.type ?? CallType.unknown) ==
                                  CallType.missed,
                            ),
                            AppPill(
                              label: formatTimestamp(call.timestampMillis ?? 0),
                              icon: Icons.schedule,
                            ),
                            if ((call.occurrences ?? 0) > 1)
                              AppPill(
                                label: '${call.occurrences} calls',
                                icon: Icons.repeat,
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  SurfaceCard(
                    child: Column(
                      children: <Widget>[
                        ListTile(
                          leading: const Icon(Icons.timer_outlined),
                          title: const Text('Duration'),
                          subtitle: Text(
                            formatDuration(call.durationSeconds ?? 0),
                          ),
                        ),
                        const Divider(height: 1),
                        ListTile(
                          leading: const Icon(Icons.call_outlined),
                          title: const Text('Type'),
                          subtitle: Text(
                            callTypeLabel(call.type ?? CallType.unknown),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    onPressed:
                        () => startCallFromNumber(
                          context,
                          widget.controller,
                          call.number ?? '',
                        ),
                    icon: const Icon(Icons.call),
                    label: const Text('Call back'),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () => launchSms(call.number ?? ''),
                    icon: const Icon(Icons.message_outlined),
                    label: const Text('Send message'),
                  ),
                  const SizedBox(height: 12),
                  if ((call.contactId?.isNotEmpty ?? false))
                    OutlinedButton.icon(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder:
                                (_) => ContactDetailScreen(
                                  controller: widget.controller,
                                  contactId: call.contactId!,
                                ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.person_outline),
                      label: const Text('Open contact'),
                    )
                  else
                    OutlinedButton.icon(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder:
                                (_) => ContactEditorScreen(
                                  controller: widget.controller,
                                  initialContact: ContactDetail(
                                    id: '',
                                    lookupKey: '',
                                    givenName: '',
                                    familyName: '',
                                    displayName: '',
                                    company: null,
                                    photoUri: null,
                                    isStarred: false,
                                    phoneNumbers: <PhoneNumberEntry>[
                                      PhoneNumberEntry(
                                        label: 'Mobile',
                                        number: call.number ?? '',
                                        normalizedNumber: normalizedDigits(
                                          call.number ?? '',
                                        ),
                                      ),
                                    ],
                                    emailAddresses: const <EmailEntry>[],
                                  ),
                                ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.person_add_alt_1),
                      label: const Text('Create contact'),
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key, required this.controller});

  final PhoneController controller;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final selectedAccount = controller.preferredAccountId ?? '';
        return Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(title: const Text('Settings')),
          body: Stack(
            children: <Widget>[
              const AppBackdrop(),
              ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
                children: <Widget>[
                  SurfaceCard(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        const SectionHeader(
                          title: 'Setup',
                          subtitle: 'Keep the dialer role and access in sync.',
                        ),
                        const SizedBox(height: 16),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          value: controller.isDefaultDialer,
                          onChanged:
                              (_) => controller.requestDefaultDialerRole(),
                          title: const Text('Default phone app'),
                          subtitle: Text(
                            controller.isDefaultDialer
                                ? 'PhoneCall is your current dialer'
                                : 'Tap to request dialer role',
                          ),
                        ),
                        const Divider(height: 1),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Permissions'),
                          subtitle: Text(
                            controller.hasCorePermissions
                                ? 'Contacts, call log, and phone permissions granted'
                                : 'Grant the required access for contacts and calls',
                          ),
                          trailing: TextButton(
                            onPressed: controller.requestCorePermissions,
                            child: const Text('Manage'),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  SurfaceCard(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        const SectionHeader(
                          title: 'Cloud sync',
                          subtitle:
                              'Call logs are grouped on the server by device ID.',
                        ),
                        const SizedBox(height: 16),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: CircleAvatar(
                            backgroundColor:
                                Theme.of(context).colorScheme.primaryContainer,
                            foregroundColor:
                                Theme.of(
                                  context,
                                ).colorScheme.onPrimaryContainer,
                            child: const Icon(Icons.phone_android_outlined),
                          ),
                          title: Text(controller.effectiveDeviceName),
                          subtitle: Text(
                            controller.hasServerSync
                                ? 'Device ID ${controller.shortDeviceId}'
                                : 'Device not registered yet',
                          ),
                          trailing: IconButton.filledTonal(
                            onPressed: controller.refreshServerDeviceProfile,
                            icon: const Icon(Icons.refresh),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: <Widget>[
                            Expanded(
                              child: SelectableText(
                                controller.serverBaseUrl,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ),
                            TextButton(
                              onPressed: () async {
                                await launchUrl(
                                  Uri.parse(
                                    '${controller.serverBaseUrl}/admin',
                                  ),
                                  mode: LaunchMode.externalApplication,
                                );
                              },
                              child: const Text('Open dashboard'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        TextButton.icon(
                          onPressed: controller.syncRecentCallsToServer,
                          icon: const Icon(Icons.sync),
                          label: const Text('Sync call logs now'),
                        ),
                        if (controller.lastSyncError != null) ...<Widget>[
                          const SizedBox(height: 8),
                          Text(
                            controller.lastSyncError!,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                        ],
                        if (controller.lastCallLogSyncAt != null) ...<Widget>[
                          const SizedBox(height: 8),
                          Text(
                            'Last synced ${controller.lastCallLogSyncAt}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  SurfaceCard(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        const SectionHeader(
                          title: 'Calling',
                          subtitle: 'Fine-tune how outgoing calls are placed.',
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          value: selectedAccount,
                          items: <DropdownMenuItem<String>>[
                            const DropdownMenuItem<String>(
                              value: '',
                              child: Text('Always ask'),
                            ),
                            ...controller.simAccounts.map((account) {
                              return DropdownMenuItem<String>(
                                value: account.id ?? '',
                                child: Text(account.label ?? 'SIM'),
                              );
                            }),
                          ],
                          decoration: const InputDecoration(
                            labelText: 'Preferred SIM',
                          ),
                          onChanged: (value) {
                            controller.savePreferredAccount(
                              value == null || value.isEmpty ? null : value,
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  FilledButton.tonalIcon(
                    onPressed: controller.refreshAll,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Refresh device data'),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _InCallDialPad extends StatelessWidget {
  const _InCallDialPad({required this.controller});

  final PhoneController controller;

  @override
  Widget build(BuildContext context) {
    const digits = <List<String>>[
      <String>['1', '2', '3'],
      <String>['4', '5', '6'],
      <String>['7', '8', '9'],
      <String>['*', '0', '#'],
    ];

    return Column(
      children:
          digits.map((row) {
            return Row(
              children:
                  row.map((digit) {
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: DialPadButton(
                          digit: digit,
                          onPressed: () => controller.playDtmfTone(digit),
                        ),
                      ),
                    );
                  }).toList(),
            );
          }).toList(),
    );
  }
}
