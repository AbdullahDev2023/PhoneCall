import 'package:flutter/material.dart';

import '../../core/phone_formatters.dart';
import '../../platform/generated/platform_api.g.dart';
import '../call_actions.dart';
import '../phone_controller.dart';
import '../widgets/common_widgets.dart';

class ContactDetailScreen extends StatefulWidget {
  const ContactDetailScreen({
    super.key,
    required this.controller,
    required this.contactId,
  });

  final PhoneController controller;
  final String contactId;

  @override
  State<ContactDetailScreen> createState() => _ContactDetailScreenState();
}

class _ContactDetailScreenState extends State<ContactDetailScreen> {
  late Future<ContactDetail?> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.controller.loadContactDetail(widget.contactId);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ContactDetail?>(
      future: _future,
      builder: (context, snapshot) {
        final contact = snapshot.data;
        return Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            title: const Text('Contact'),
            actions: <Widget>[
              if (contact != null)
                IconButton(
                  onPressed: () async {
                    await Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder:
                            (_) => ContactEditorScreen(
                              controller: widget.controller,
                              initialContact: contact,
                            ),
                      ),
                    );
                    if (!mounted) {
                      return;
                    }
                    setState(() {
                      _future = widget.controller.loadContactDetail(
                        widget.contactId,
                      );
                    });
                  },
                  icon: const Icon(Icons.edit_outlined),
                ),
            ],
          ),
          body: Stack(
            children: <Widget>[
              const AppBackdrop(),
              snapshot.connectionState != ConnectionState.done
                  ? const Center(child: CircularProgressIndicator())
                  : contact == null
                  ? const EmptyState(
                    icon: Icons.person_off_outlined,
                    title: 'Contact not found',
                    subtitle: 'This contact may have been removed.',
                  )
                  : ListView(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
                    children: <Widget>[
                      SurfaceCard(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Row(
                              children: <Widget>[
                                CircleAvatar(
                                  radius: 34,
                                  backgroundColor:
                                      Theme.of(
                                        context,
                                      ).colorScheme.primaryContainer,
                                  foregroundColor:
                                      Theme.of(
                                        context,
                                      ).colorScheme.onPrimaryContainer,
                                  child: Text(
                                    initialsForName(contact.displayName ?? ''),
                                    style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                                const Spacer(),
                                IconButton.filledTonal(
                                  onPressed: () async {
                                    await Navigator.of(context).push(
                                      MaterialPageRoute<void>(
                                        builder:
                                            (_) => ContactEditorScreen(
                                              controller: widget.controller,
                                              initialContact: contact,
                                            ),
                                      ),
                                    );
                                    if (!mounted) {
                                      return;
                                    }
                                    setState(() {
                                      _future = widget.controller
                                          .loadContactDetail(widget.contactId);
                                    });
                                  },
                                  icon: const Icon(Icons.edit_outlined),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              contact.displayName ?? '',
                              style: Theme.of(context).textTheme.headlineMedium
                                  ?.copyWith(fontWeight: FontWeight.w800),
                            ),
                            if ((contact.company?.isNotEmpty ??
                                false)) ...<Widget>[
                              const SizedBox(height: 6),
                              Text(
                                contact.company!,
                                style: Theme.of(
                                  context,
                                ).textTheme.bodyMedium?.copyWith(
                                  color:
                                      Theme.of(
                                        context,
                                      ).colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                            const SizedBox(height: 16),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: <Widget>[
                                AppPill(
                                  label:
                                      contact.isStarred == true
                                          ? 'Favorite'
                                          : 'Contact',
                                  icon:
                                      contact.isStarred == true
                                          ? Icons.star
                                          : Icons.person_outline,
                                  selected: contact.isStarred == true,
                                ),
                                if ((contact.phoneNumbers ??
                                        const <PhoneNumberEntry?>[])
                                    .whereType<PhoneNumberEntry>()
                                    .isNotEmpty)
                                  AppPill(
                                    label:
                                        '${(contact.phoneNumbers ?? const <PhoneNumberEntry?>[]).whereType<PhoneNumberEntry>().length} numbers',
                                    icon: Icons.call_outlined,
                                  ),
                                if ((contact.emailAddresses ??
                                        const <EmailEntry?>[])
                                    .whereType<EmailEntry>()
                                    .isNotEmpty)
                                  AppPill(
                                    label:
                                        '${(contact.emailAddresses ?? const <EmailEntry?>[]).whereType<EmailEntry>().length} emails',
                                    icon: Icons.alternate_email,
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      if ((contact.phoneNumbers ?? const <PhoneNumberEntry?>[])
                          .whereType<PhoneNumberEntry>()
                          .isNotEmpty)
                        SurfaceCard(
                          padding: const EdgeInsets.all(4),
                          child: Column(
                            children:
                                (contact.phoneNumbers ??
                                        const <PhoneNumberEntry?>[])
                                    .whereType<PhoneNumberEntry>()
                                    .map((number) {
                                      return ListTile(
                                        leading: const Icon(
                                          Icons.call_outlined,
                                        ),
                                        title: Text(
                                          formatPhoneNumber(
                                            number.number ?? '',
                                          ),
                                        ),
                                        subtitle: Text(number.label ?? ''),
                                        trailing: Wrap(
                                          spacing: 8,
                                          children: <Widget>[
                                            IconButton.filledTonal(
                                              onPressed:
                                                  () => startCallFromNumber(
                                                    context,
                                                    widget.controller,
                                                    number.number ?? '',
                                                  ),
                                              icon: const Icon(Icons.phone),
                                            ),
                                            IconButton.filledTonal(
                                              onPressed:
                                                  () => launchSms(
                                                    number.number ?? '',
                                                  ),
                                              icon: const Icon(
                                                Icons.message_outlined,
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    })
                                    .toList(),
                          ),
                        ),
                      if ((contact.emailAddresses ?? const <EmailEntry?>[])
                          .whereType<EmailEntry>()
                          .isNotEmpty) ...<Widget>[
                        const SizedBox(height: 20),
                        SurfaceCard(
                          padding: const EdgeInsets.all(4),
                          child: Column(
                            children:
                                (contact.emailAddresses ??
                                        const <EmailEntry?>[])
                                    .whereType<EmailEntry>()
                                    .map(
                                      (email) => ListTile(
                                        leading: const Icon(
                                          Icons.alternate_email,
                                        ),
                                        title: Text(email.address ?? ''),
                                        subtitle: Text(email.label ?? ''),
                                      ),
                                    )
                                    .toList(),
                          ),
                        ),
                      ],
                      const SizedBox(height: 20),
                      FilledButton.tonalIcon(
                        onPressed: () async {
                          await widget.controller.toggleFavorite(
                            contact.id ?? '',
                            !(contact.isStarred ?? false),
                          );
                          if (!mounted) {
                            return;
                          }
                          setState(() {
                            _future = widget.controller.loadContactDetail(
                              widget.contactId,
                            );
                          });
                        },
                        icon: Icon(
                          contact.isStarred == true
                              ? Icons.star
                              : Icons.star_border,
                        ),
                        label: Text(
                          contact.isStarred == true
                              ? 'Remove from favorites'
                              : 'Add to favorites',
                        ),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: () async {
                          await widget.controller.deleteContact(
                            contact.id ?? '',
                          );
                          if (context.mounted) {
                            Navigator.of(context).pop();
                          }
                        },
                        icon: const Icon(Icons.delete_outline),
                        label: const Text('Delete contact'),
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

class ContactEditorScreen extends StatefulWidget {
  const ContactEditorScreen({
    super.key,
    required this.controller,
    this.initialContact,
  });

  final PhoneController controller;
  final ContactDetail? initialContact;

  @override
  State<ContactEditorScreen> createState() => _ContactEditorScreenState();
}

class _ContactEditorScreenState extends State<ContactEditorScreen> {
  late final TextEditingController _givenNameController;
  late final TextEditingController _familyNameController;
  late final TextEditingController _companyController;
  late final List<_EditableField> _phoneFields;
  late final List<_EditableField> _emailFields;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final contact = widget.initialContact;
    _givenNameController = TextEditingController(
      text: contact?.givenName ?? '',
    );
    _familyNameController = TextEditingController(
      text: contact?.familyName ?? '',
    );
    _companyController = TextEditingController(text: contact?.company ?? '');
    _phoneFields =
        ((contact?.phoneNumbers ?? const <PhoneNumberEntry?>[])
            .whereType<PhoneNumberEntry>()
            .map(
              (phone) => _EditableField(
                label: phone.label ?? '',
                value: phone.number ?? '',
              ),
            )).toList();
    _emailFields =
        ((contact?.emailAddresses ?? const <EmailEntry?>[])
            .whereType<EmailEntry>()
            .map(
              (email) => _EditableField(
                label: email.label ?? '',
                value: email.address ?? '',
              ),
            )).toList();

    if (_phoneFields.isEmpty) {
      _phoneFields.add(_EditableField(label: 'Mobile'));
    }
    if (_emailFields.isEmpty) {
      _emailFields.add(_EditableField(label: 'Email'));
    }
  }

  @override
  void dispose() {
    _givenNameController.dispose();
    _familyNameController.dispose();
    _companyController.dispose();
    for (final field in _phoneFields) {
      field.dispose();
    }
    for (final field in _emailFields) {
      field.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(
          widget.initialContact == null ? 'New contact' : 'Edit contact',
        ),
      ),
      body: Stack(
        children: <Widget>[
          const AppBackdrop(),
          SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
              children: <Widget>[
                SurfaceCard(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      const SectionHeader(
                        title: 'Name',
                        subtitle:
                            'Start with a clear identity for the contact.',
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _givenNameController,
                        textCapitalization: TextCapitalization.words,
                        decoration: const InputDecoration(
                          labelText: 'First name',
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _familyNameController,
                        textCapitalization: TextCapitalization.words,
                        decoration: const InputDecoration(
                          labelText: 'Last name',
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _companyController,
                        textCapitalization: TextCapitalization.words,
                        decoration: const InputDecoration(labelText: 'Company'),
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
                        title: 'Phone numbers',
                        subtitle:
                            'Add one or more numbers with friendly labels.',
                      ),
                      const SizedBox(height: 16),
                      for (final field in _phoneFields) ...<Widget>[
                        Row(
                          children: <Widget>[
                            Expanded(
                              flex: 2,
                              child: TextField(
                                controller: field.labelController,
                                decoration: const InputDecoration(
                                  labelText: 'Label',
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 4,
                              child: TextField(
                                controller: field.valueController,
                                keyboardType: TextInputType.phone,
                                decoration: const InputDecoration(
                                  labelText: 'Number',
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed:
                                  _phoneFields.length == 1
                                      ? null
                                      : () => setState(() {
                                        field.dispose();
                                        _phoneFields.remove(field);
                                      }),
                              icon: const Icon(Icons.remove_circle_outline),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                      ],
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton.icon(
                          onPressed:
                              () => setState(() {
                                _phoneFields.add(
                                  _EditableField(label: 'Mobile'),
                                );
                              }),
                          icon: const Icon(Icons.add),
                          label: const Text('Add number'),
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
                        title: 'Email addresses',
                        subtitle:
                            'Useful for work profiles or alternate contact paths.',
                      ),
                      const SizedBox(height: 16),
                      for (final field in _emailFields) ...<Widget>[
                        Row(
                          children: <Widget>[
                            Expanded(
                              flex: 2,
                              child: TextField(
                                controller: field.labelController,
                                decoration: const InputDecoration(
                                  labelText: 'Label',
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 4,
                              child: TextField(
                                controller: field.valueController,
                                keyboardType: TextInputType.emailAddress,
                                decoration: const InputDecoration(
                                  labelText: 'Email',
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed:
                                  _emailFields.length == 1
                                      ? null
                                      : () => setState(() {
                                        field.dispose();
                                        _emailFields.remove(field);
                                      }),
                              icon: const Icon(Icons.remove_circle_outline),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                      ],
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton.icon(
                          onPressed:
                              () => setState(() {
                                _emailFields.add(
                                  _EditableField(label: 'Email'),
                                );
                              }),
                          icon: const Icon(Icons.add),
                          label: const Text('Add email'),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: _isSaving ? null : _saveContact,
                  icon:
                      _isSaving
                          ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                          : const Icon(Icons.save_outlined),
                  label: const Text('Save contact'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _saveContact() async {
    final hasName =
        _givenNameController.text.trim().isNotEmpty ||
        _familyNameController.text.trim().isNotEmpty;
    final phoneEntries =
        _phoneFields
            .where((field) => field.valueController.text.trim().isNotEmpty)
            .map(
              (field) => PhoneNumberEntry(
                label:
                    field.labelController.text.trim().isEmpty
                        ? 'Mobile'
                        : field.labelController.text.trim(),
                number: field.valueController.text.trim(),
                normalizedNumber: normalizedDigits(
                  field.valueController.text.trim(),
                ),
              ),
            )
            .toList();
    final emailEntries =
        _emailFields
            .where((field) => field.valueController.text.trim().isNotEmpty)
            .map(
              (field) => EmailEntry(
                label:
                    field.labelController.text.trim().isEmpty
                        ? 'Email'
                        : field.labelController.text.trim(),
                address: field.valueController.text.trim(),
              ),
            )
            .toList();

    if (!hasName && phoneEntries.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Add a name or at least one phone number to save.'),
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    final contact = EditableContact(
      contactId: widget.initialContact?.id,
      givenName: _givenNameController.text.trim(),
      familyName: _familyNameController.text.trim(),
      company:
          _companyController.text.trim().isEmpty
              ? null
              : _companyController.text.trim(),
      isStarred: widget.initialContact?.isStarred ?? false,
      phoneNumbers: phoneEntries,
      emailAddresses: emailEntries,
    );

    await widget.controller.saveContact(contact);
    if (!mounted) {
      return;
    }
    Navigator.of(context).pop();
  }
}

class _EditableField {
  _EditableField({String label = '', String value = ''})
    : labelController = TextEditingController(text: label),
      valueController = TextEditingController(text: value);

  final TextEditingController labelController;
  final TextEditingController valueController;

  void dispose() {
    labelController.dispose();
    valueController.dispose();
  }
}
