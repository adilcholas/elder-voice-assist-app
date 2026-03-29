import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/contact_model.dart';
import 'role_provider.dart';

class ContactProvider extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  List<ContactModel> _contacts = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<ContactModel> get contacts => List.unmodifiable(_contacts);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  String? _currentUid;

  /// Called by ProxyProvider when RoleProvider changes.
  Future<void> updateDependencies(RoleProvider roleProvider) async {
    final uid = roleProvider.firebaseUser?.uid;
    if (uid == null || uid == _currentUid) return;
    _currentUid = uid;
    await _loadContacts(uid);
  }

  Future<void> _loadContacts(String uid) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final snapshot = await _db
          .collection('users')
          .doc(uid)
          .collection('contacts')
          .orderBy('name')
          .get();

      _contacts = snapshot.docs
          .map((doc) => ContactModel.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      _errorMessage = 'Failed to load contacts: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addContact(ContactModel contact) async {
    if (_currentUid == null) return;
    try {
      final docRef = await _db
          .collection('users')
          .doc(_currentUid)
          .collection('contacts')
          .add(contact.toMap());

      _contacts.add(contact.copyWith(id: docRef.id));
      // Sort alphabetically
      _contacts.sort((a, b) => a.name.compareTo(b.name));
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to add contact: $e';
      notifyListeners();
    }
  }

  Future<void> removeContact(String contactId) async {
    if (_currentUid == null) return;
    try {
      await _db
          .collection('users')
          .doc(_currentUid)
          .collection('contacts')
          .doc(contactId)
          .delete();

      _contacts.removeWhere((c) => c.id == contactId);
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to remove contact: $e';
      notifyListeners();
    }
  }

  /// Fuzzy match by name — used by voice commands ("Call Adil").
  /// Returns null if no match found.
  ContactModel? findByName(String query) {
    if (query.trim().isEmpty) return null;
    final q = query.trim().toLowerCase();

    // 1. Exact match (case-insensitive)
    for (final c in _contacts) {
      if (c.name.toLowerCase() == q) return c;
    }

    // 2. Starts-with match
    for (final c in _contacts) {
      if (c.name.toLowerCase().startsWith(q)) return c;
    }

    // 3. Contains match
    for (final c in _contacts) {
      if (c.name.toLowerCase().contains(q)) return c;
    }

    // 4. Token overlap — spoken name may be partially heard
    final queryTokens = q.split(' ');
    for (final c in _contacts) {
      final nameTokens = c.name.toLowerCase().split(' ');
      final overlap = queryTokens.any((t) => nameTokens.contains(t));
      if (overlap) return c;
    }

    return null;
  }
}
