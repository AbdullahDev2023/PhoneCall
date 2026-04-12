import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/phone_formatters.dart';
import 'phone_controller.dart';
import 'widgets/common_widgets.dart';

Future<void> startCallFromNumber(
  BuildContext context,
  PhoneController controller,
  String number,
) async {
  final accountId = await resolveCallAccount(context, controller);
  await controller.placeCall(number, accountId: accountId);
}

Future<String?> resolveCallAccount(
  BuildContext context,
  PhoneController controller,
) async {
  if (controller.preferredAccountId?.isNotEmpty == true) {
    return controller.preferredAccountId;
  }
  if (controller.simAccounts.length <= 1) {
    return controller.simAccounts.isEmpty
        ? null
        : controller.simAccounts.first.id;
  }

  return showModalBottomSheet<String>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
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
                  title: 'Choose SIM',
                  subtitle: 'Pick the account used to place this call.',
                ),
                const SizedBox(height: 12),
                ...controller.simAccounts.map((account) {
                  return ListTile(
                    leading: const Icon(Icons.sim_card_outlined),
                    title: Text(account.label ?? 'SIM'),
                    subtitle:
                        account.address?.isNotEmpty == true
                            ? Text(account.address!)
                            : null,
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.of(context).pop(account.id ?? ''),
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

Future<void> launchSms(String number) async {
  await launchUrl(Uri.parse('sms:${normalizedDigits(number)}'));
}
