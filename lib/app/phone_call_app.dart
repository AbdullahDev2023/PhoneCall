import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'phone_controller.dart';
import 'screens/call_screens.dart';
import 'screens/contact_screens.dart';
import 'screens/home_tabs.dart';
import 'widgets/common_widgets.dart';

class PhoneCallApp extends StatefulWidget {
  const PhoneCallApp({super.key, required this.controller});

  final PhoneController controller;

  @override
  State<PhoneCallApp> createState() => _PhoneCallAppState();
}

class _PhoneCallAppState extends State<PhoneCallApp> {
  @override
  void dispose() {
    widget.controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'PhoneCall',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2563EB),
          brightness: Brightness.light,
          surface: const Color(0xFFF6F8FC),
          surfaceContainerHighest: const Color(0xFFEAF0FA),
        ),
        scaffoldBackgroundColor: const Color(0xFFF6F8FC),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          centerTitle: false,
          toolbarHeight: 72,
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          margin: EdgeInsets.zero,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          color: const Color(0xFFFDFEFF),
        ),
        iconTheme: const IconThemeData(size: 22),
        listTileTheme: ListTileThemeData(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 6,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: const Color(0xFFFDFEFF).withValues(alpha: 0.92),
          elevation: 0,
          indicatorColor: const Color(0xFFDCE7FF),
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          iconTheme: WidgetStateProperty.resolveWith<IconThemeData?>((states) {
            return IconThemeData(
              color:
                  states.contains(WidgetState.selected)
                      ? const Color(0xFF1447C5)
                      : const Color(0xFF5A6478),
            );
          }),
          labelTextStyle: WidgetStateProperty.resolveWith<TextStyle?>((states) {
            return TextStyle(
              color:
                  states.contains(WidgetState.selected)
                      ? const Color(0xFF1447C5)
                      : const Color(0xFF5A6478),
              fontWeight: FontWeight.w600,
            );
          }),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(56),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            minimumSize: const Size.fromHeight(56),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(56),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(minimumSize: const Size.fromHeight(44)),
        ),
        chipTheme: ChipThemeData(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFFFDFEFF),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(color: Color(0xFFD8E1F0)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(color: Color(0xFFD8E1F0)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.6),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
      ),
      home: HomeScreen(controller: widget.controller),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.controller});

  final PhoneController controller;

  static const List<String> _titles = <String>[
    'Favorites',
    'Recents',
    'Contacts',
    'Keypad',
  ];

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        if (controller.isInitializing) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (controller.needsOnboarding) {
          return OnboardingScreen(controller: controller);
        }

        final tabIndex = controller.selectedTabIndex;
        final title = _titles[tabIndex];
        final subtitle = switch (tabIndex) {
          0 => 'Quick access to your most important people',
          1 => 'A clear timeline of incoming and outgoing activity',
          2 => 'Browse, search, and manage every contact',
          _ => 'A clean dial pad with smart suggestions',
        };

        return Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            scrolledUnderElevation: 0,
            toolbarHeight: 76,
            titleSpacing: 20,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            actions: <Widget>[
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: IconButton.filledTonal(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => SettingsScreen(controller: controller),
                      ),
                    );
                  },
                  icon: const Icon(Icons.settings_outlined),
                ),
              ),
            ],
            bottom: PreferredSize(
              preferredSize: Size.fromHeight(tabIndex == 1 ? 164 : 116),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Column(
                  children: <Widget>[
                    if (tabIndex != 3)
                      SurfaceCard(
                        padding: const EdgeInsets.all(6),
                        child: TextField(
                          onChanged: controller.updateSearchQuery,
                          decoration: InputDecoration(
                            hintText:
                                tabIndex == 1
                                    ? 'Search call history'
                                    : 'Search contacts and numbers',
                            prefixIcon: const Icon(Icons.search),
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            filled: false,
                          ),
                        ),
                      ),
                    if (tabIndex == 1) ...<Widget>[
                      const SizedBox(height: 12),
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: SegmentedButton<bool>(
                              segments: const <ButtonSegment<bool>>[
                                ButtonSegment<bool>(
                                  value: false,
                                  label: Text('All'),
                                  icon: Icon(Icons.history),
                                ),
                                ButtonSegment<bool>(
                                  value: true,
                                  label: Text('Missed'),
                                  icon: Icon(Icons.call_missed),
                                ),
                              ],
                              selected: <bool>{controller.showMissedOnly},
                              onSelectionChanged: (selection) {
                                controller.setShowMissedOnly(selection.first);
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          body: Stack(
            children: <Widget>[
              const AppBackdrop(),
              SafeArea(
                top: false,
                child: IndexedStack(
                  index: controller.selectedTabIndex,
                  children: <Widget>[
                    FavoritesTab(controller: controller),
                    RecentsTab(controller: controller),
                    ContactsTab(controller: controller),
                    KeypadTab(controller: controller),
                  ],
                ),
              ),
              if (controller.hasActiveCall)
                Positioned.fill(
                  child: Material(
                    color: Colors.black.withValues(alpha: 0.84),
                    child: SafeArea(
                      child: InCallScreen(controller: controller),
                    ),
                  ),
                ),
            ],
          ),
          floatingActionButton:
              controller.selectedTabIndex == 2
                  ? FloatingActionButton.extended(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder:
                              (_) =>
                                  ContactEditorScreen(controller: controller),
                        ),
                      );
                    },
                    icon: const Icon(Icons.person_add_alt_1),
                    label: const Text('New contact'),
                  )
                  : null,
          bottomNavigationBar: NavigationBar(
            selectedIndex: controller.selectedTabIndex,
            onDestinationSelected: controller.setSelectedTab,
            destinations: const <NavigationDestination>[
              NavigationDestination(
                icon: Icon(Icons.star_border),
                selectedIcon: Icon(Icons.star),
                label: 'Favorites',
              ),
              NavigationDestination(
                icon: Icon(Icons.access_time),
                selectedIcon: Icon(Icons.access_time_filled),
                label: 'Recents',
              ),
              NavigationDestination(
                icon: Icon(Icons.people_outline),
                selectedIcon: Icon(Icons.people),
                label: 'Contacts',
              ),
              NavigationDestination(
                icon: Icon(Icons.dialpad_outlined),
                selectedIcon: Icon(Icons.dialpad),
                label: 'Keypad',
              ),
            ],
          ),
        );
      },
    );
  }
}

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key, required this.controller});

  final PhoneController controller;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final completedCount =
            <bool>[
              controller.contactsGranted,
              controller.callLogGranted,
              controller.phoneGranted,
              controller.isDefaultDialer,
            ].where((value) => value).length;

        return Scaffold(
          backgroundColor: Colors.transparent,
          body: Stack(
            children: <Widget>[
              const AppBackdrop(),
              SafeArea(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
                  children: <Widget>[
                    AppPill(
                      label: '$completedCount of 4 ready',
                      icon: Icons.verified_outlined,
                      selected: completedCount == 4,
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'Make PhoneCall feel like the real dialer.',
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Finish a few permissions and choose PhoneCall as your default phone app to unlock contacts, recents, and in-call controls.',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 24),
                    SurfaceCard(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          SectionHeader(
                            title: 'Setup checklist',
                            subtitle: 'Complete these once to unlock the app.',
                          ),
                          const SizedBox(height: 16),
                          OnboardingCard(
                            title: 'Contacts access',
                            subtitle:
                                controller.contactsGranted
                                    ? 'Ready'
                                    : 'Needed for your contact list and editing.',
                            completed: controller.contactsGranted,
                            icon: Icons.person_outline,
                          ),
                          const SizedBox(height: 12),
                          OnboardingCard(
                            title: 'Call history access',
                            subtitle:
                                controller.callLogGranted
                                    ? 'Ready'
                                    : 'Needed for recents and call details.',
                            completed: controller.callLogGranted,
                            icon: Icons.history,
                          ),
                          const SizedBox(height: 12),
                          OnboardingCard(
                            title: 'Phone controls',
                            subtitle:
                                controller.phoneGranted
                                    ? 'Ready'
                                    : 'Needed to place and manage calls.',
                            completed: controller.phoneGranted,
                            icon: Icons.call_outlined,
                          ),
                          const SizedBox(height: 12),
                          OnboardingCard(
                            title: 'Default phone app',
                            subtitle:
                                controller.isDefaultDialer
                                    ? 'Ready'
                                    : 'Needed for incoming and ongoing call UI.',
                            completed: controller.isDefaultDialer,
                            icon: Icons.phone_android,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed: () async {
                        await controller.requestCorePermissions();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Requested core permissions.'),
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.verified_user_outlined),
                      label: const Text('Grant permissions'),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: () async {
                        final launched =
                            await controller.requestDefaultDialerRole();
                        if (!context.mounted) {
                          return;
                        }

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              launched
                                  ? 'Opening the default phone app chooser or settings.'
                                  : 'Could not open the default phone app chooser on this device.',
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.phone_callback_outlined),
                      label: const Text('Set as default phone app'),
                    ),
                    const SizedBox(height: 12),
                    TextButton.icon(
                      onPressed: () async {
                        await controller.refreshAll();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Status refreshed.')),
                          );
                        }
                      },
                      icon: const Icon(Icons.refresh),
                      label: const Text('Refresh status'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
