import 'package:flutter/material.dart';

import '../call_actions.dart';
import '../phone_controller.dart';
import '../widgets/common_widgets.dart';
import 'call_screens.dart';
import 'contact_screens.dart';

class FavoritesTab extends StatelessWidget {
  const FavoritesTab({super.key, required this.controller});

  final PhoneController controller;

  @override
  Widget build(BuildContext context) {
    final favorites = controller.favoriteContacts;
    if (favorites.isEmpty) {
      return const EmptyState(
        icon: Icons.star_border,
        title: 'No favorites yet',
        subtitle:
            'Mark people as favorites from the contact screen for faster calling.',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 96),
      itemCount: favorites.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final contact = favorites[index];
        return ContactCard(
          contact: contact,
          onTap:
              () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder:
                      (_) => ContactDetailScreen(
                        controller: controller,
                        contactId: contact.id ?? '',
                      ),
                ),
              ),
          onCallTap:
              () => startCallFromNumber(
                context,
                controller,
                contact.primaryNumber ?? '',
              ),
        );
      },
    );
  }
}

class RecentsTab extends StatelessWidget {
  const RecentsTab({super.key, required this.controller});

  final PhoneController controller;

  @override
  Widget build(BuildContext context) {
    final recentCalls = controller.visibleRecentCalls;
    if (recentCalls.isEmpty) {
      return const EmptyState(
        icon: Icons.history_toggle_off,
        title: 'No recent calls',
        subtitle: 'Your latest call activity will appear here.',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 96),
      itemCount: recentCalls.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final recentCall = recentCalls[index];
        return RecentCallCard(
          recentCall: recentCall,
          onTap:
              () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder:
                      (_) => CallDetailScreen(
                        controller: controller,
                        initialCall: recentCall,
                      ),
                ),
              ),
          onRedialTap:
              () => startCallFromNumber(
                context,
                controller,
                recentCall.number ?? '',
              ),
        );
      },
    );
  }
}

class ContactsTab extends StatelessWidget {
  const ContactsTab({super.key, required this.controller});

  final PhoneController controller;

  @override
  Widget build(BuildContext context) {
    final contacts = controller.visibleContacts;
    if (contacts.isEmpty) {
      return const EmptyState(
        icon: Icons.people_outline,
        title: 'No contacts found',
        subtitle: 'Add a new contact or adjust your search.',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 96),
      itemCount: contacts.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final contact = contacts[index];
        return ContactCard(
          contact: contact,
          onTap:
              () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder:
                      (_) => ContactDetailScreen(
                        controller: controller,
                        contactId: contact.id ?? '',
                      ),
                ),
              ),
          onCallTap:
              () => startCallFromNumber(
                context,
                controller,
                contact.primaryNumber ?? '',
              ),
        );
      },
    );
  }
}

class KeypadTab extends StatelessWidget {
  const KeypadTab({super.key, required this.controller});

  final PhoneController controller;

  static const List<List<String>> _dialpadRows = <List<String>>[
    <String>['1', '2', '3'],
    <String>['4', '5', '6'],
    <String>['7', '8', '9'],
    <String>['*', '0', '#'],
  ];

  static const Map<String, String> _subLabels = <String, String>{
    '2': 'ABC',
    '3': 'DEF',
    '4': 'GHI',
    '5': 'JKL',
    '6': 'MNO',
    '7': 'PQRS',
    '8': 'TUV',
    '9': 'WXYZ',
    '0': '+',
  };

  @override
  Widget build(BuildContext context) {
    final suggestions = controller.keypadSuggestions;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      child: Column(
        children: <Widget>[
          SurfaceCard(
            padding: const EdgeInsets.all(18),
            child: Column(
              children: <Widget>[
                const SectionHeader(
                  title: 'Dial pad',
                  subtitle:
                      'Enter a number or use the smart contact suggestions.',
                ),
                const SizedBox(height: 16),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        controller.formattedKeypadInput.isEmpty
                            ? 'Enter number'
                            : controller.formattedKeypadInput,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                    IconButton.filledTonal(
                      onPressed:
                          controller.keypadInput.isEmpty
                              ? null
                              : controller.removeLastDigit,
                      icon: const Icon(Icons.backspace_outlined),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (suggestions.isNotEmpty) ...<Widget>[
            const SizedBox(height: 16),
            SurfaceCard(
              padding: const EdgeInsets.all(4),
              child: Column(
                children: <Widget>[
                  const ListTile(
                    title: Text('Suggested contacts'),
                    subtitle: Text(
                      'Matches based on number and T9-style search.',
                    ),
                  ),
                  const Divider(height: 1),
                  ListView.separated(
                    padding: const EdgeInsets.all(4),
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: suggestions.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final suggestion = suggestions[index];
                      return ContactCard(
                        contact: suggestion,
                        onTap:
                            () => Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder:
                                    (_) => ContactDetailScreen(
                                      controller: controller,
                                      contactId: suggestion.id ?? '',
                                    ),
                              ),
                            ),
                        onCallTap:
                            () => startCallFromNumber(
                              context,
                              controller,
                              suggestion.primaryNumber ??
                                  controller.keypadInput,
                            ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ] else
            const Spacer(),
          const SizedBox(height: 16),
          for (final row in _dialpadRows) ...<Widget>[
            Row(
              children:
                  row.map((digit) {
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(6),
                        child: DialPadButton(
                          digit: digit,
                          subLabel: _subLabels[digit],
                          onPressed: () => controller.appendDigit(digit),
                          onLongPress:
                              digit == '0'
                                  ? () => controller.appendDigit('+')
                                  : null,
                        ),
                      ),
                    );
                  }).toList(),
            ),
            const SizedBox(height: 4),
          ],
          const SizedBox(height: 8),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(56),
            ),
            onPressed:
                controller.keypadInput.isEmpty
                    ? null
                    : () => startCallFromNumber(
                      context,
                      controller,
                      controller.keypadInput,
                    ),
            icon: const Icon(Icons.call),
            label: const Text('Call'),
          ),
        ],
      ),
    );
  }
}
