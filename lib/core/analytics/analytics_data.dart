/*import '../../features/analytics/presentation/analytics_screen.dart';
/* ---------------- Data model ---------------- */

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

/* ---------------- Small widgets ---------------- */

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
} */