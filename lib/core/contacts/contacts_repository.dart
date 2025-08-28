import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_contacts/flutter_contacts.dart' as fc;

// A tiny view model so UI doesn’t depend on package types.
class ContactView {
  final String id;
  final String displayName;
  final List<String> phones;
  final List<String> emails;
  final Uint8List? avatar;

  ContactView({
    required this.id,
    required this.displayName,
    required this.phones,
    required this.emails,
    this.avatar,
  });
}

class ContactsRepository {
  Future<bool> ensurePermission() async {
    // flutter_contacts handles the platform dialog
    return await fc.FlutterContacts.requestPermission(readonly: true);
  }

  Future<List<ContactView>> fetchAll({bool withAvatars = false}) async {
    final granted = await ensurePermission();
    if (!granted) throw Exception('CONTACTS_PERMISSION_DENIED');

    final contacts = await fc.FlutterContacts.getContacts(
      withProperties: true,         // phones/emails
      withPhoto: withAvatars,       // avatar bytes
    );

    final list = contacts.map((c) {
      final phones = c.phones.map((p) => p.number.trim()).where((s) => s.isNotEmpty).toList();
      final emails = c.emails.map((e) => e.address.trim()).where((s) => s.isNotEmpty).toList();
      return ContactView(
        id: c.id,
        displayName: c.displayName.isNotEmpty ? c.displayName : 'Unknown',
        phones: phones,
        emails: emails,
        avatar: c.photo, // Uint8List?
      );
    }).toList();

    list.sort((a, b) => a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase()));
    return list;
  }
}

// Riverpod provider
final contactsRepoProvider = Provider<ContactsRepository>((ref) => ContactsRepository());