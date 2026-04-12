import 'package:flutter/material.dart';

import '../../core/phone_formatters.dart';
import '../../platform/generated/platform_api.g.dart';

class AppBackdrop extends StatelessWidget {
  const AppBackdrop({super.key, this.child, this.topPadding = 0});

  final Widget? child;
  final double topPadding;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[
            scheme.primary.withValues(alpha: 0.10),
            scheme.surface,
            scheme.surfaceContainerLowest,
          ],
        ),
      ),
      child: Stack(
        children: <Widget>[
          Positioned(
            top: -72 - topPadding,
            right: -48,
            child: _BackdropOrb(color: scheme.primary.withValues(alpha: 0.16)),
          ),
          Positioned(
            top: 180,
            left: -56,
            child: _BackdropOrb(color: scheme.tertiary.withValues(alpha: 0.12)),
          ),
          Positioned(
            bottom: 120,
            right: -40,
            child: _BackdropOrb(
              color: scheme.secondary.withValues(alpha: 0.10),
            ),
          ),
          if (child != null) child!,
        ],
      ),
    );
  }
}

class _BackdropOrb extends StatelessWidget {
  const _BackdropOrb({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 180,
      height: 180,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: <Color>[color, color.withValues(alpha: 0.0)],
        ),
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final titleStyle = Theme.of(
      context,
    ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700);
    final subtitleStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
      color: Theme.of(context).colorScheme.onSurfaceVariant,
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(title, style: titleStyle),
              if (subtitle != null) ...<Widget>[
                const SizedBox(height: 4),
                Text(subtitle!, style: subtitleStyle),
              ],
            ],
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

class AppPill extends StatelessWidget {
  const AppPill({
    super.key,
    required this.label,
    this.icon,
    this.selected = false,
  });

  final String label;
  final IconData? icon;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final foreground =
        selected ? scheme.onPrimaryContainer : scheme.onSurfaceVariant;
    final background =
        selected
            ? scheme.primaryContainer
            : scheme.surfaceContainerHighest.withValues(alpha: 0.85);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color:
              selected
                  ? scheme.primary.withValues(alpha: 0.08)
                  : scheme.outlineVariant.withValues(alpha: 0.55),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (icon != null) ...<Widget>[
            Icon(icon, size: 16, color: foreground),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: foreground,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class SurfaceCard extends StatelessWidget {
  const SurfaceCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: scheme.surface.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.28),
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: scheme.shadow.withValues(alpha: 0.08),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Padding(padding: padding, child: child),
    );
  }
}

class ContactCard extends StatelessWidget {
  const ContactCard({
    super.key,
    required this.contact,
    required this.onTap,
    required this.onCallTap,
  });

  final ContactSummary contact;
  final VoidCallback onTap;
  final VoidCallback onCallTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final displayName = contact.displayName ?? '';
    final title =
        displayName.isNotEmpty
            ? displayName
            : formatPhoneNumber(contact.primaryNumber ?? '');
    final subtitle =
        contact.primaryNumber?.isNotEmpty == true
            ? formatPhoneNumber(contact.primaryNumber!)
            : 'No phone number';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(26),
        onTap: onTap,
        child: SurfaceCard(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            children: <Widget>[
              CircleAvatar(
                radius: 24,
                backgroundColor: scheme.primaryContainer,
                foregroundColor: scheme.onPrimaryContainer,
                child: Text(initialsForName(title)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                        ),
                        if (contact.isStarred == true)
                          Icon(
                            Icons.star_rounded,
                            color: scheme.tertiary,
                            size: 18,
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filledTonal(
                onPressed: onCallTap,
                icon: const Icon(Icons.call),
                visualDensity: VisualDensity.compact,
                style: IconButton.styleFrom(minimumSize: const Size(44, 44)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class RecentCallCard extends StatelessWidget {
  const RecentCallCard({
    super.key,
    required this.recentCall,
    required this.onTap,
    required this.onRedialTap,
  });

  final RecentCall recentCall;
  final VoidCallback onTap;
  final VoidCallback onRedialTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final title =
        recentCall.displayName?.isNotEmpty == true
            ? recentCall.displayName!
            : formatPhoneNumber(recentCall.number ?? '');
    final type = recentCall.type ?? CallType.unknown;
    return Card(
      color: scheme.surface.withValues(alpha: 0.92),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 10,
        ),
        leading: CircleAvatar(
          backgroundColor: _callTypeBackground(context, type),
          foregroundColor: _callTypeForeground(context, type),
          child: Icon(callTypeIcon(type)),
        ),
        title: Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: <Widget>[
              AppPill(
                label: callTypeLabel(type),
                selected: type == CallType.missed,
              ),
              Text(
                formatTimestamp(recentCall.timestampMillis ?? 0),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              if ((recentCall.occurrences ?? 0) > 1)
                AppPill(
                  label: '${recentCall.occurrences} calls',
                  icon: Icons.repeat,
                ),
            ],
          ),
        ),
        trailing: IconButton(
          onPressed: onRedialTap,
          icon: const Icon(Icons.phone),
          style: IconButton.styleFrom(
            backgroundColor: scheme.primaryContainer,
            foregroundColor: scheme.onPrimaryContainer,
          ),
        ),
      ),
    );
  }
}

class DialPadButton extends StatelessWidget {
  const DialPadButton({
    super.key,
    required this.digit,
    required this.onPressed,
    this.subLabel,
    this.onLongPress,
  });

  final String digit;
  final String? subLabel;
  final VoidCallback onPressed;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(26),
        onTap: onPressed,
        onLongPress: onLongPress,
        child: Ink(
          height: 80,
          decoration: BoxDecoration(
            color: scheme.surface.withValues(alpha: 0.96),
            borderRadius: BorderRadius.circular(26),
            border: Border.all(
              color: scheme.outlineVariant.withValues(alpha: 0.26),
            ),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: scheme.shadow.withValues(alpha: 0.06),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text(
                digit,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: scheme.onSurface,
                ),
              ),
              if (subLabel != null)
                Text(
                  subLabel!,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                    letterSpacing: 1.2,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class CallActionButton extends StatelessWidget {
  const CallActionButton({
    super.key,
    required this.icon,
    required this.label,
    required this.enabled,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Opacity(
      opacity: enabled ? 1 : 0.35,
      child: InkWell(
        onTap: enabled ? onPressed : null,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          width: 96,
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: scheme.surface.withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(icon, color: Colors.white),
              const SizedBox(height: 8),
              Text(label, style: const TextStyle(color: Colors.white)),
            ],
          ),
        ),
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: SurfaceCard(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              CircleAvatar(
                radius: 28,
                backgroundColor: scheme.primaryContainer,
                foregroundColor: scheme.onPrimaryContainer,
                child: Icon(icon, size: 28),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class OnboardingCard extends StatelessWidget {
  const OnboardingCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.completed,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final bool completed;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      color: scheme.surface.withValues(alpha: 0.95),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        leading: CircleAvatar(
          backgroundColor:
              completed ? scheme.tertiaryContainer : scheme.primaryContainer,
          foregroundColor:
              completed
                  ? scheme.onTertiaryContainer
                  : scheme.onPrimaryContainer,
          child: Icon(completed ? Icons.check_rounded : icon),
        ),
        title: Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        subtitle: Text(
          subtitle,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
        ),
      ),
    );
  }
}

IconData callTypeIcon(CallType type) {
  return switch (type) {
    CallType.incoming => Icons.call_received,
    CallType.outgoing => Icons.call_made,
    CallType.missed => Icons.call_missed,
    CallType.rejected => Icons.call_end,
    CallType.blocked => Icons.block,
    CallType.voicemail => Icons.voicemail,
    _ => Icons.call,
  };
}

String callTypeLabel(CallType type) {
  return switch (type) {
    CallType.incoming => 'Incoming',
    CallType.outgoing => 'Outgoing',
    CallType.missed => 'Missed',
    CallType.rejected => 'Rejected',
    CallType.blocked => 'Blocked',
    CallType.voicemail => 'Voicemail',
    _ => 'Call',
  };
}

IconData audioRouteIcon(AudioRoute route) {
  return switch (route) {
    AudioRoute.bluetooth => Icons.bluetooth_audio,
    AudioRoute.speaker => Icons.volume_up,
    AudioRoute.wiredHeadset => Icons.headset,
    _ => Icons.hearing,
  };
}

String audioRouteLabel(AudioRoute route) {
  return switch (route) {
    AudioRoute.bluetooth => 'Bluetooth',
    AudioRoute.speaker => 'Speaker',
    AudioRoute.wiredHeadset => 'Headset',
    _ => 'Earpiece',
  };
}

Color _callTypeBackground(BuildContext context, CallType type) {
  final scheme = Theme.of(context).colorScheme;
  return switch (type) {
    CallType.missed => scheme.errorContainer,
    CallType.rejected => scheme.errorContainer,
    CallType.blocked => scheme.errorContainer,
    CallType.incoming => scheme.primaryContainer,
    CallType.outgoing => scheme.tertiaryContainer,
    CallType.voicemail => scheme.secondaryContainer,
    _ => scheme.surfaceContainerHighest,
  };
}

Color _callTypeForeground(BuildContext context, CallType type) {
  final scheme = Theme.of(context).colorScheme;
  return switch (type) {
    CallType.missed => scheme.onErrorContainer,
    CallType.rejected => scheme.onErrorContainer,
    CallType.blocked => scheme.onErrorContainer,
    CallType.incoming => scheme.onPrimaryContainer,
    CallType.outgoing => scheme.onTertiaryContainer,
    CallType.voicemail => scheme.onSecondaryContainer,
    _ => scheme.onSurfaceVariant,
  };
}
