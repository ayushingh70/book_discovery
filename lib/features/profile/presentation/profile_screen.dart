import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:package_info_plus/package_info_plus.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen>
    with SingleTickerProviderStateMixin {
  // --- Local/animation ---
  late final AnimationController _cardCtrl;
  late final Animation<double> _cardAnim;
  bool _glowAvatar = false;
  String _appVersion = '—';

  // --- Auth / DB ---
  final _auth = FirebaseAuth.instance;
  late final DatabaseReference _userRef;

  // --- Profile state backed by Realtime DB ---
  _UserProfile? _profile; // null while loading
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _cardCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    )..forward();
    _cardAnim = CurvedAnimation(parent: _cardCtrl, curve: Curves.easeOutCubic);
    _loadVersion();

    final uid = _auth.currentUser!.uid;
    _userRef = FirebaseDatabase.instance.ref('users/$uid');

    _loadProfile();
  }

  Future<void> _loadVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      if (!mounted) return;
      setState(() => _appVersion = info.version);
    } catch (_) {/* keep dash */}
  }

  Future<void> _loadProfile() async {
    setState(() {
      _loading = true;
    });

    final u = _auth.currentUser!;
    final snap = await _userRef.get();

    if (!snap.exists) {
      // Seed from FirebaseAuth defaults
      final seeded = _UserProfile(
        name: u.displayName ?? '',
        email: u.email ?? '',
        photoBase64: null, // Start with null; Auth photoURL not copied as bytes
      );
      await _userRef.set(seeded.toMap());
      if (!mounted) return;
      setState(() {
        _profile = seeded;
        _loading = false;
      });
      return;
    }

    final map = Map<String, dynamic>.from(snap.value as Map);
    final loaded = _UserProfile.fromMap(map);

    // If email missing in DB, patch it so it shows consistently
    if ((loaded.email ?? '').isEmpty && (u.email ?? '').isNotEmpty) {
      loaded.email = u.email;
      await _userRef.update({'email': u.email});
    }

    if (!mounted) return;
    setState(() {
      _profile = loaded;
      _loading = false;
    });
  }

  @override
  void dispose() {
    _cardCtrl.dispose();
    super.dispose();
  }

  // --- Helpers ---
  User get _user => _auth.currentUser!;

  String _firstName() {
    final fromDb = _profile?.name?.trim() ?? '';
    if (fromDb.isNotEmpty) return fromDb.split(' ').first;

    final dn = (_user.displayName ?? '').trim();
    if (dn.isNotEmpty) return dn.split(' ').first;

    final em = (_user.email ?? '').trim();
    if (em.contains('@')) return em.split('@').first;

    return 'User';
  }

  ImageProvider _avatarProvider() {
    if (_profile?.photoBase64 != null && _profile!.photoBase64!.isNotEmpty) {
      final bytes = base64Decode(_profile!.photoBase64!);
      return MemoryImage(bytes);
    }
    if (_user.photoURL != null && _user.photoURL!.isNotEmpty) {
      return NetworkImage(_user.photoURL!);
    }
    return const AssetImage('assets/images/avatar.png');
  }

  String _fmtDate(DateTime? d) {
    if (d == null) return '—';
    return '${d.day.toString().padLeft(2, '0')}/'
        '${d.month.toString().padLeft(2, '0')}/'
        '${d.year}';
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _copy(String label, String value) async {
    if (value.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: value));
    _snack('$label copied');
  }

  // --- Photo: Gallery only, store as base64 in Realtime DB ---
  Future<void> _changePhoto() async {
    // iOS Photos permission (Android 13+ system picker generally OK, but harmless)
    if (Platform.isIOS) {
      final ph = await Permission.photos.request();
      if (!ph.isGranted) {
        _snack('Photo permission denied');
        return;
      }
    }

    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 80, // keep reasonable size
    );
    if (picked == null) return;

    final bytes = await picked.readAsBytes();
    final b64 = base64Encode(bytes);

    // Update DB
    await _userRef.update({'photoBase64': b64});
    setState(() {
      _profile = (_profile ?? _UserProfile()).copyWith(photoBase64: b64);
      _glowAvatar = true;
    });
    await Future.delayed(const Duration(milliseconds: 350));
    if (mounted) setState(() => _glowAvatar = false);

    _snack('Profile photo updated');
  }

  // --- Name edit: update Auth + Realtime DB ---
  Future<void> _editName() async {
    final controller = TextEditingController(text: _profile?.name ?? _user.displayName ?? '');
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (ctx) {
        final bottom = MediaQuery.of(ctx).viewInsets.bottom;
        return AnimatedPadding(
          duration: const Duration(milliseconds: 180),
          padding: EdgeInsets.only(bottom: bottom),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const _SheetTitle('Edit name'),
                const SizedBox(height: 8),
                TextField(
                  controller: controller,
                  autofocus: true,
                  textInputAction: TextInputAction.done,
                  decoration: const InputDecoration(
                    hintText: 'Your name',
                    border: OutlineInputBorder(),
                  ),
                  onSubmitted: (_) => Navigator.pop(ctx, true),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF3D5CFF),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Save'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );

    if (ok == true) {
      final newName = controller.text.trim();

      // Update Auth displayName
      await _user.updateDisplayName(newName);

      // Update DB (also seed email if missing)
      final payload = <String, Object?>{
        'name': newName,
        if ((_profile?.email ?? '').isEmpty && (_user.email ?? '').isNotEmpty)
          'email': _user.email,
      };
      await _userRef.update(payload);

      await _user.reload();

      if (!mounted) return;
      setState(() {
        _profile = (_profile ?? _UserProfile()).copyWith(
          name: newName,
          email: _profile?.email ?? _user.email,
        );
      });

      _snack('Name updated');
    }
  }

  // --- Misc actions ---
  Future<void> _openGoogleAccount() async {
    final uri = Uri.parse('https://myaccount.google.com/');
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _confirmLogout({bool switchAccount = false}) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(switchAccount ? 'Switch account' : 'Logout'),
        content: Text(
          switchAccount
              ? 'We’ll sign you out so you can log in with a different account.'
              : 'Are you sure you want to logout?',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Back')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3D5CFF),
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: Text(switchAccount ? 'Continue' : 'Logout'),
          ),
        ],
      ),
    );

    if (ok == true) {
      await _auth.signOut();
      if (!mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (_) => false);
    }
  }

  Future<void> _contactSupport() async {
    final email = Uri(
      scheme: 'mailto',
      path: 'aniketom70@gmail.com', // TODO Change to support email
      query: Uri.encodeQueryComponent('subject=Support request&body=Hi, I need help with...'),
    );
    await launchUrl(email);
  }

  Future<void> _openPolicy() async {
    final uri = Uri.parse('https://example.com/privacy'); // replace
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _refresh() async {
    await _user.reload();
    await _loadProfile();
    await Future.delayed(const Duration(milliseconds: 300));
  }

  // --- UI ---
  @override
  Widget build(BuildContext context) {
    final padTop = MediaQuery.of(context).padding.top;
    final meta = _user.metadata;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refresh,
          child: ListView(
            padding: EdgeInsets.fromLTRB(16, padTop == 0 ? 12 : 4, 16, 24),
            children: [
              const Text(
                'Profile',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1F1F39),
                ),
              ),
              const SizedBox(height: 16),

              if (_loading)
                const Center(child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 80),
                  child: CircularProgressIndicator(),
                ))
              else ...[
                // Top card
                ScaleTransition(
                  scale: _cardAnim,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: const [
                        BoxShadow(color: Color(0x143D5CFF), blurRadius: 18, offset: Offset(0, 10)),
                        BoxShadow(color: Color(0x08000000), blurRadius: 6, offset: Offset(0, 2)),
                      ],
                    ),
                    child: Row(
                      children: [
                        Hero(
                          tag: 'user_avatar',
                          child: GestureDetector(
                            onTap: _changePhoto,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 220),
                              padding: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: _glowAvatar
                                    ? const [
                                  BoxShadow(
                                    color: Color(0x443D5CFF),
                                    blurRadius: 16,
                                    spreadRadius: 2,
                                  )
                                ]
                                    : const [],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(14),
                                child: Image(
                                  image: _avatarProvider(),
                                  width: 64,
                                  height: 64,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DefaultTextStyle(
                            style: const TextStyle(color: Color(0xFF1F1F39)),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 200),
                                  child: Text(
                                    _firstName(),
                                    key: ValueKey(_profile?.name ?? _user.displayName ?? ''),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _profile?.email ?? _user.email ?? '',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(color: Colors.black54),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          onPressed: _changePhoto,
                          icon: const Icon(Icons.photo_outlined, size: 18),
                          label: const Text('Change'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF3D5CFF),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 14),

                // Quick stats
                FadeTransition(
                  opacity: _cardAnim,
                  child: _SettingsCard(
                    children: [
                      _StatRow(
                        icon: Icons.event_available_outlined,
                        label: 'Joined',
                        value: _fmtDate(meta.creationTime),
                      ),
                      const Divider(height: 1, color: Color(0xFFEFF1FA)),
                      _StatRow(
                        icon: Icons.schedule_outlined,
                        label: 'Last sign-in',
                        value: _fmtDate(meta.lastSignInTime),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Settings / actions
                _SettingsCard(
                  children: [
                    _SettingTile(
                      icon: Icons.edit_outlined,
                      title: 'Edit name',
                      subtitle: 'Update your display name',
                      onTap: _editName,
                    ),
                    _SettingTile(
                      icon: Icons.copy_rounded,
                      title: 'Copy email',
                      subtitle: 'Quickly copy your account email',
                      onTap: () => _copy('Email', _profile?.email ?? _user.email ?? ''),
                    ),
                    _SettingTile(
                      icon: Icons.manage_accounts_rounded,
                      title: 'Manage Google Account',
                      subtitle: 'Open your Google account settings',
                      onTap: _openGoogleAccount,
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                _SettingsCard(
                  children: [
                    _SettingTile(
                      icon: Icons.privacy_tip_outlined,
                      title: 'Privacy policy',
                      subtitle: 'How we handle your data',
                      onTap: _openPolicy,
                    ),
                    _SettingTile(
                      icon: Icons.help_outline_rounded,
                      title: 'Contact support',
                      subtitle: 'Email our support team',
                      onTap: _contactSupport,
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // App version (static)
                _SettingsCard(
                  children: [
                    ListTile(
                      leading: Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: const Color(0xFFEAEAFF),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.info_outline, color: Color(0xFF3D5CFF)),
                      ),
                      title: const Text('App version', style: TextStyle(fontWeight: FontWeight.w600)),
                      trailing: Text(
                        _appVersion,
                        style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w600),
                      ),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                _SettingsCard(
                  children: [
                    _SettingTile(
                      icon: Icons.account_circle_outlined,
                      title: 'Switch account',
                      subtitle: 'Sign out and log in to a different account',
                      onTap: () => _confirmLogout(switchAccount: true),
                    ),
                    _SettingTile(
                      icon: Icons.logout_rounded,
                      title: 'Logout',
                      subtitle: 'Sign out of your account',
                      destructive: true,
                      onTap: _confirmLogout,
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// --- Data model ---

class _UserProfile {
  final String? name;
  String? email;
  final String? photoBase64;

  _UserProfile({this.name, this.email, this.photoBase64});

  _UserProfile copyWith({String? name, String? email, String? photoBase64}) {
    return _UserProfile(
      name: name ?? this.name,
      email: email ?? this.email,
      photoBase64: photoBase64 ?? this.photoBase64,
    );
  }

  Map<String, Object?> toMap() => {
    'name': name,
    'email': email,
    'photoBase64': photoBase64,
  };

  factory _UserProfile.fromMap(Map<String, dynamic> map) => _UserProfile(
    name: (map['name'] ?? '') as String,
    email: (map['email'] ?? '') as String,
    photoBase64: (map['photoBase64'] ?? '') as String?,
  );
}

// --- Small widgets ---

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Color(0x143D5CFF), blurRadius: 18, offset: Offset(0, 10)),
          BoxShadow(color: Color(0x08000000), blurRadius: 6, offset: Offset(0, 2)),
        ],
      ),
      child: Column(children: children),
    );
  }
}

class _SettingTile extends StatelessWidget {
  const _SettingTile({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.onTap,
    this.destructive = false,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final titleStyle = TextStyle(
      fontWeight: FontWeight.w600,
      color: destructive ? const Color(0xFFE53935) : const Color(0xFF1F1F39),
    );

    return ListTile(
      leading: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: destructive ? const Color(0xFFFCEBEE) : const Color(0xFFEAEAFF),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          icon,
          color: destructive ? const Color(0xFFE53935) : const Color(0xFF3D5CFF),
        ),
      ),
      title: Text(title, style: titleStyle),
      subtitle: subtitle != null
          ? Text(subtitle!, style: const TextStyle(color: Colors.black54))
          : null,
      trailing: const Icon(Icons.chevron_right_rounded, color: Colors.black26),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      onTap: onTap,
    );
  }
}

class _SheetTitle extends StatelessWidget {
  const _SheetTitle(this.text);
  final String text;
  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontFamily: 'Poppins',
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: Color(0xFF1F1F39),
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({required this.icon, required this.label, required this.value});
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: const Color(0xFFEAEAFF),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: const Color(0xFF3D5CFF)),
      ),
      title: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
      trailing: Text(
        value,
        style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w600),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    );
  }
}