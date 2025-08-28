import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../core/contacts/contacts_repository.dart';

class ContactsScreen extends ConsumerStatefulWidget {
  const ContactsScreen({super.key});
  @override
  ConsumerState<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends ConsumerState<ContactsScreen> {
  final _scroll = ScrollController();
  final _searchCtrl = TextEditingController();

  List<ContactView> _all = [];
  List<ContactView> _shown = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
    _searchCtrl.addListener(_applyFilter);
  }

  @override
  void dispose() {
    _scroll.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  // --- Data & filtering ---

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final repo = ref.read(contactsRepoProvider);
      final data = await repo.fetchAll(withAvatars: false);

      // Sort alphabetically by displayName (case-insensitive)
      data.sort((a, b) => a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase()));

      if (!mounted) return;
      setState(() {
        _all = data;
        _shown = data;
      });
    } catch (e) {
      if (!mounted) return;
      if (e.toString().contains('CONTACTS_PERMISSION_DENIED')) {
        setState(() => _error = 'Permission denied. Enable Contacts access in Settings.');
      } else {
        setState(() => _error = 'Failed to load contacts.');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _applyFilter() {
    final q = _searchCtrl.text.trim().toLowerCase();
    if (q.isEmpty) {
      setState(() => _shown = List<ContactView>.from(_all));
      return;
    }
    final filtered = _all.where((c) {
      final name = c.displayName.toLowerCase();
      final hitName = name.contains(q);
      final hitPhone = c.phones.any((p) => p.toLowerCase().contains(q));
      final hitEmail = c.emails.any((e) => e.toLowerCase().contains(q));
      return hitName || hitPhone || hitEmail;
    }).toList();

    // keep list sorted after filter
    filtered.sort((a, b) => a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase()));

    setState(() => _shown = filtered);
  }

  // --- Actions ---

  Future<void> _call(String number) async {
    final uri = Uri(scheme: 'tel', path: number);
    await launchUrl(uri);
  }

  Future<void> _sms(String number) async {
    final uri = Uri(scheme: 'sms', path: number);
    await launchUrl(uri);
  }

  Future<void> _email(String email) async {
    final uri = Uri(scheme: 'mailto', path: email);
    await launchUrl(uri);
  }

  Future<void> _copy(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Copied to clipboard')),
    );
  }

  // --- Bottom sheets ---

  void _openContactSheet(ContactView c) {
    final primaryPhone = c.phones.isNotEmpty ? c.phones.first : null;
    final primaryEmail = c.emails.isNotEmpty ? c.emails.first : null;

    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) {
        return SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              bottom: MediaQuery.of(context).viewInsets.bottom + 16,
              top: 6,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // --- Header
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF7F8FE),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x223D5CFF),
                              blurRadius: 10,
                              offset: Offset(0, 6),
                            ),
                          ],
                        ),
                        child: CircleAvatar(
                          radius: 26,
                          backgroundColor: const Color(0xFFEAEAFF),
                          child: Text(
                            (c.displayName.isNotEmpty ? c.displayName[0] : '?').toUpperCase(),
                            style: const TextStyle(
                              color: Color(0xFF3D5CFF),
                              fontWeight: FontWeight.w800,
                              fontSize: 20,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          c.displayName,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1F1F39),
                            height: 1.2,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // --- Primary actions
                if (primaryPhone != null || primaryEmail != null)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      if (primaryPhone != null)
                        _BigAction(
                          icon: Icons.call_rounded,
                          label: 'Call',
                          onTap: () => _call(primaryPhone),
                        ),
                      if (primaryPhone != null)
                        _BigAction(
                          icon: Icons.message_rounded,
                          label: 'Message',
                          onTap: () => _sms(primaryPhone),
                        ),
                      if (primaryEmail != null)
                        _BigAction(
                          icon: Icons.email_rounded,
                          label: 'Email',
                          onTap: () => _email(primaryEmail),
                        ),
                    ],
                  ),
                if (primaryPhone != null || primaryEmail != null) ...[
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 10,
                    runSpacing: 8,
                    alignment: WrapAlignment.center,
                    children: [
                      if (primaryPhone != null)
                        _ActionChipPill(
                          icon: Icons.copy_rounded,
                          label: 'Copy number',
                          onTap: () => _copy(primaryPhone),
                        ),
                      if (primaryEmail != null)
                        _ActionChipPill(
                          icon: Icons.copy_rounded,
                          label: 'Copy email',
                          onTap: () => _copy(primaryEmail),
                        ),
                    ],
                  ),
                ],

                const SizedBox(height: 10),

                // --- Phones
                if (c.phones.isNotEmpty)
                  _SectionCard(
                    title: 'Phone',
                    children: c.phones
                        .map(
                          (p) => ListTile(
                        dense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                        leading: const Icon(Icons.call_outlined, color: Color(0xFF3D5CFF)),
                        title: Text(p, maxLines: 1, overflow: TextOverflow.ellipsis),
                        trailing: IconButton(
                          icon: const Icon(Icons.message_outlined),
                          onPressed: () => _sms(p),
                        ),
                        onTap: () => _call(p),
                      ),
                    )
                        .toList(),
                  ),

                // --- Emails
                if (c.emails.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  _SectionCard(
                    title: 'Email',
                    children: c.emails
                        .map(
                          (e) => ListTile(
                        dense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                        leading: const Icon(Icons.mail_outline, color: Color(0xFF3D5CFF)),
                        title: Text(e, maxLines: 1, overflow: TextOverflow.ellipsis),
                        onTap: () => _email(e),
                      ),
                    )
                        .toList(),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  void _openMyProfileSheet(User? me) {
    if (me == null) return;
    final name = (me.displayName ?? 'Me').trim();
    final email = (me.email ?? '').trim();
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: (me.photoURL != null)
                      ? Image.network(me.photoURL!, width: 42, height: 42, fit: BoxFit.cover)
                      : Container(
                    width: 42,
                    height: 42,
                    color: const Color(0xFFEAEAFF),
                    child: const Icon(Icons.person, color: Color(0xFF3D5CFF)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1F1F39),
                    ),
                  ),
                ),
              ],
            ),
            if (email.isNotEmpty) ...[
              const SizedBox(height: 10),
              _InfoTile(
                icon: Icons.mail_outline,
                text: email,
                onTap: () => _email(email),
              ),
            ],
            const SizedBox(height: 6),
          ],
        ),
      ),
    );
  }

  // --- UI ---

  @override
  Widget build(BuildContext context) {
    final padTop = MediaQuery.of(context).padding.top;
    const double kHeaderBump = 8; // push header a touch lower

    final user = FirebaseAuth.instance.currentUser;
    final hasMe = user != null;

    // Tap outside to dismiss keyboard
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Column(
          children: [
            // Header
            Padding(
              padding: EdgeInsets.fromLTRB(16, padTop + 12 + kHeaderBump, 16, 6),
              child: Row(
                children: [
                  const Text(
                    ' Contacts',
                    style: TextStyle(
                      fontSize: 35,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1F1F39),
                    ),
                  ),
                  const Spacer(),
                  Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.asset(
                        'assets/images/avatar.png',
                        width: 36,
                        height: 52,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Search
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
              child: TextField(
                controller: _searchCtrl,
                decoration: InputDecoration(
                  hintText: 'Search contacts',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: (_searchCtrl.text.isEmpty)
                      ? null
                      : IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _searchCtrl.clear();
                      _applyFilter();
                    },
                  ),
                  filled: true,
                  fillColor: const Color(0xFFF5F6FA),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                ),
              ),
            ),

            // Small info row (count)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 6),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  _loading
                      ? 'Loading…'
                      : _error != null
                      ? ''
                      : '${_shown.length} contact${_shown.length == 1 ? '' : 's'}',
                  style: const TextStyle(color: Colors.black54, fontSize: 12.5),
                ),
              ),
            ),

            // List / states
            Expanded(
              child: RefreshIndicator(
                onRefresh: _load,
                child: _loading
                    ? ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: const [
                    SizedBox(height: 200),
                    Center(child: CircularProgressIndicator()),
                  ],
                )
                    : (_error != null)
                    ? ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    const SizedBox(height: 120),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        children: [
                          const Icon(Icons.contacts, size: 42, color: Color(0xFF3D5CFF)),
                          const SizedBox(height: 12),
                          Text(
                            _error!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.black54),
                          ),
                          const SizedBox(height: 10),
                          if (Platform.isAndroid || Platform.isIOS)
                            TextButton(
                              onPressed: openAppSettings,
                              child: const Text('Open Settings'),
                            ),
                        ],
                      ),
                    ),
                  ],
                )
                    : (_shown.isEmpty)
                    ? ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: const [
                    SizedBox(height: 200),
                    Center(child: Text('No contacts matched')),
                  ],
                )
                    : ListView.separated(
                  controller: _scroll,
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  itemCount: _shown.length + (hasMe ? 1 : 0),
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, i) {
                    if (hasMe && i == 0) {
                      return _MyProfileTile(onTap: () => _openMyProfileSheet(user));
                    }

                    final idx = hasMe ? i - 1 : i;
                    final c = _shown[idx];

                    final subtitle = c.phones.isNotEmpty
                        ? c.phones.first
                        : (c.emails.isNotEmpty ? c.emails.first : '');

                    // Alphabet header logic
                    final currentLetter = _alpha(c.displayName);
                    final prevLetter = (idx > 0)
                        ? _alpha(_shown[idx - 1].displayName)
                        : '';

                    final showHeader = (idx == 0) || currentLetter != prevLetter;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (showHeader) _AlphaHeader(letter: currentLetter),
                        _ContactRowCard(
                          name: c.displayName,
                          subtitle: subtitle,
                          onTap: () => _openContactSheet(c),
                          onCall: c.phones.isNotEmpty ? () => _call(c.phones.first) : null,
                          onMsg: c.phones.isNotEmpty ? () => _sms(c.phones.first) : null,
                          onMail: c.emails.isNotEmpty ? () => _email(c.emails.first) : null,
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _alpha(String name) {
    final t = name.trim();
    if (t.isEmpty) return '#';
    final ch = t[0].toUpperCase();
    final isLetter = RegExp(r'[A-Z]').hasMatch(ch);
    return isLetter ? ch : '#';
  }
}

// --- Small UI Widgets ---

class _AvatarCircle extends StatelessWidget {
  const _AvatarCircle({required this.initial, this.radius = 22});
  final String initial;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: const Color(0xFFEAEAFF),
      child: Text(
        initial.toUpperCase(),
        style: const TextStyle(color: Color(0xFF3D5CFF), fontWeight: FontWeight.w800),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);
  final String text;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          text,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            color: Color(0xFF1F1F39),
          ),
        ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.text,
    this.trailing,
    this.onTap,
  });
  final IconData icon;
  final String text;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: const Color(0xFF3D5CFF)),
      title: Text(text, maxLines: 1, overflow: TextOverflow.ellipsis),
      trailing: trailing,
      onTap: onTap,
    );
  }
}

class _ActionChip extends StatelessWidget {
  const _ActionChip({required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFEAEAFF),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: const Color(0xFF3D5CFF)),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Color(0xFF3D5CFF),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MyProfileTile extends StatelessWidget {
  const _MyProfileTile({required this.onTap});
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F7FB),
        borderRadius: BorderRadius.circular(14),
      ),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        leading: const Icon(Icons.person, color: Color(0xFF3D5CFF)),
        title: const Text(
          'My profile',
          style: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF1F1F39)),
        ),
        trailing: const Icon(Icons.keyboard_arrow_right_rounded),
        onTap: onTap,
      ),
    );
  }
}

class _ContactRowCard extends StatelessWidget {
  const _ContactRowCard({
    required this.name,
    required this.subtitle,
    required this.onTap,
    this.onCall,
    this.onMsg,
    this.onMail,
  });
  final String name;
  final String subtitle;
  final VoidCallback onTap;
  final VoidCallback? onCall;
  final VoidCallback? onMsg;
  final VoidCallback? onMail;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      elevation: 0,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            boxShadow: const [
              BoxShadow(color: Color(0x0F000000), blurRadius: 8, offset: Offset(0, 3)),
            ],
            color: Colors.white,
          ),
          child: Row(
            children: [
              _AvatarCircle(initial: name.isNotEmpty ? name[0] : '?', radius: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1F1F39),
                      ),
                    ),
                    if (subtitle.isNotEmpty)
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.black54),
                      ),
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (onCall != null)
                    IconButton(
                      tooltip: 'Call',
                      icon: const Icon(Icons.call_rounded, color: Color(0xFF3D5CFF)),
                      onPressed: onCall,
                    ),
                  if (onMsg != null)
                    IconButton(
                      tooltip: 'Message',
                      icon: const Icon(Icons.message_rounded, color: Color(0xFF3D5CFF)),
                      onPressed: onMsg,
                    ),
                  if (onMail != null)
                    IconButton(
                      tooltip: 'Email',
                      icon: const Icon(Icons.email_rounded, color: Color(0xFF3D5CFF)),
                      onPressed: onMail,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.children});
  final String title;
  final List<Widget> children;
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF7F8FE),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE9ECFF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // title
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
            child: Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: Color(0xFF1F1F39),
              ),
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE9ECFF)),
          // items
          ...children,
        ],
      ),
    );
  }
}

class _BigAction extends StatelessWidget {
  const _BigAction({required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        width: 98,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFEAEAFF),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: const Color(0xFF3D5CFF)),
            const SizedBox(height: 6),
            Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Color(0xFF3D5CFF),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionChipPill extends StatelessWidget {
  const _ActionChipPill({required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F2F8),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0xFFE3E6F6)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: const Color(0xFF3D5CFF)),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                color: Color(0xFF3D5CFF),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Letter section header (A, B, C....)
class _AlphaHeader extends StatelessWidget {
  const _AlphaHeader({required this.letter});
  final String letter;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 12, 6, 4),
      child: Text(
        letter,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: Colors.black54,
        ),
      ),
    );
  }
}