import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../localization.dart';
import '../services/cloud_service.dart';
import '../services/settings_service.dart';
import '../widgets/rest_timer_bar.dart' show formatClock;

class SettingsTab extends StatelessWidget {
  const SettingsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const headingStyle = TextStyle(fontSize: 18, fontWeight: FontWeight.bold);

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(translate('Account'), style: headingStyle),
              const SizedBox(height: 8),
              const _AccountSection(),
              const Divider(),
              const SizedBox(height: 16),
              Text(translate('Appearance'), style: headingStyle),
              const SizedBox(height: 16),
              ValueListenableBuilder<ThemeMode>(
                valueListenable: themeNotifier,
                builder: (context, mode, _) => ListTile(
                  title: Text(translate('Light Mode')),
                  trailing: Switch(
                    value: mode == ThemeMode.light,
                    onChanged: (value) =>
                        themeNotifier.value = value ? ThemeMode.light : ThemeMode.dark,
                    activeColor: theme.primaryColor,
                  ),
                ),
              ),
              const Divider(),
              const SizedBox(height: 16),
              Text(translate('Language'), style: headingStyle),
              const SizedBox(height: 16),
              ValueListenableBuilder<String>(
                valueListenable: languageNotifier,
                builder: (context, lang, _) => Column(
                  children: [
                    for (final option in const [('en', 'English'), ('ar', 'Arabic')])
                      ListTile(
                        title: Text(translate(option.$2)),
                        trailing: Radio<String>(
                          value: option.$1,
                          groupValue: lang,
                          onChanged: (value) {
                            if (value != null) languageNotifier.value = value;
                          },
                          activeColor: theme.primaryColor,
                        ),
                      ),
                  ],
                ),
              ),
              const Divider(),
              const SizedBox(height: 16),
              Text(translate('Training'), style: headingStyle),
              const SizedBox(height: 16),
              ValueListenableBuilder<int>(
                valueListenable: SettingsService.restSeconds,
                builder: (context, seconds, _) => ListTile(
                  title: Text(translate('Default rest time')),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline),
                        onPressed: seconds > 15
                            ? () => SettingsService.restSeconds.value = seconds - 15
                            : null,
                      ),
                      Text(
                        formatClock(seconds),
                        style: TextStyle(
                          color: theme.primaryColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline),
                        onPressed: seconds < 600
                            ? () => SettingsService.restSeconds.value = seconds + 15
                            : null,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            translate('Made by Rashed Al-Awamleh'),
            style: TextStyle(color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.5)),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }
}

class _AccountSection extends StatefulWidget {
  const _AccountSection();

  @override
  State<_AccountSection> createState() => _AccountSectionState();
}

class _AccountSectionState extends State<_AccountSection> {
  bool _busy = false;

  Future<void> _signIn() async {
    setState(() => _busy = true);
    final error = await CloudService.signInWithGoogle();
    if (!mounted) return;
    setState(() => _busy = false);
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${translate('Sign-in failed')}: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (!CloudService.available) {
      return ListTile(
        leading: const Icon(Icons.cloud_off),
        title: Text(translate('Cloud backup')),
        subtitle: Text(translate('Cloud backup is not set up in this build.')),
      );
    }

    return ListenableBuilder(
      listenable: Listenable.merge([CloudService.currentUser, CloudService.syncState]),
      builder: (context, _) {
        final user = CloudService.currentUser.value;

        if (user == null) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ListTile(
                leading: const Icon(Icons.cloud_upload_outlined),
                title: Text(translate('Back up your workouts')),
                subtitle: Text(
                  translate('Sign in to keep your data safe and restore it on any device.'),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _busy ? null : _signIn,
                    icon: _busy
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.login),
                    label: Text(translate('Sign in with Google')),
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
          );
        }

        return _signedInTile(theme, user);
      },
    );
  }

  Widget _signedInTile(ThemeData theme, User user) {
    final state = CloudService.syncState.value;
    final (IconData icon, String label) = switch (state) {
      SyncState.synced => (Icons.cloud_done, translate('Backed up')),
      SyncState.syncing => (Icons.cloud_sync, translate('Syncing…')),
      SyncState.error => (Icons.cloud_off, translate('Sync failed')),
      SyncState.signedOut => (Icons.cloud_off, ''),
    };
    final name = user.displayName ?? user.email ?? '';

    return Column(
      children: [
        ListTile(
          leading: CircleAvatar(
            backgroundImage: user.photoURL == null ? null : NetworkImage(user.photoURL!),
            child: user.photoURL == null
                ? Text(name.isEmpty ? '?' : name.characters.first.toUpperCase())
                : null,
          ),
          title: Text(name),
          subtitle: Row(
            children: [
              Icon(icon,
                  size: 14,
                  color: state == SyncState.error ? Colors.redAccent : theme.primaryColor),
              const SizedBox(width: 4),
              Text(label),
            ],
          ),
        ),
        if (state == SyncState.error)
          ValueListenableBuilder<String?>(
            valueListenable: CloudService.syncError,
            builder: (context, error, _) => error == null
                ? const SizedBox.shrink()
                : Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: Text(
                      error,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.redAccent, fontSize: 12),
                    ),
                  ),
          ),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            if (state == SyncState.error)
              TextButton.icon(
                onPressed: CloudService.retrySync,
                icon: const Icon(Icons.refresh),
                label: Text(translate('Retry')),
              ),
            TextButton.icon(
              onPressed: CloudService.signOut,
              icon: const Icon(Icons.logout),
              label: Text(translate('Sign out')),
            ),
          ],
        ),
      ],
    );
  }
}
