import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/contact_model.dart';
import 'role_provider.dart';

class ContactProvider extends ChangeNotifier {
  List<ContactModel> _contacts = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<ContactModel> get contacts => List.unmodifiable(_contacts);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  String? _currentUid;

  /// Called by ProxyProvider when RoleProvider changes.
  Future<void> updateDependencies(RoleProvider roleProvider) async {
    // If caregiver is logged in, use linked elder's UID if available, else own UID.
    final uid = roleProvider.isCaregiver 
        ? (roleProvider.profile?.linkedUserId ?? roleProvider.firebaseUser?.uid) 
        : roleProvider.firebaseUser?.uid;

    if (uid == null || uid == _currentUid) return;
    _currentUid = uid;
    await _loadContacts(uid);
  }

  String _getStorageKey(String uid) => 'contacts_$uid';

  Future<void> _loadContacts(String uid) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final key = _getStorageKey(uid);
      final jsonString = prefs.getString(key);

      if (jsonString != null) {
        final List<dynamic> decoded = jsonDecode(jsonString);
        _contacts = decoded.map((item) {
          final id = item['id'] as String;
          return ContactModel.fromMap(item as Map<String, dynamic>, id);
        }).toList();
      } else {
        _contacts = [];
      }
      
      _contacts.sort((a, b) => a.name.compareTo(b.name));
    } catch (e) {
      _errorMessage = 'Failed to load local contacts: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _saveContactsToLocal(String uid) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = _getStorageKey(uid);
      
      final encoded = jsonEncode(_contacts.map((c) {
        final map = c.toMap();
        map['id'] = c.id; // ensure ID is saved
        return map;
      }).toList());
      
      await prefs.setString(key, encoded);
    } catch (e) {
      _errorMessage = 'Failed to save contacts locally: $e';
      notifyListeners();
    }
  }

  Future<void> addContact(ContactModel contact) async {
    if (_currentUid == null) return;
    try {
      // Generate a simple ID
      final newContact = contact.copyWith(
          id: DateTime.now().millisecondsSinceEpoch.toString());
          
      _contacts.add(newContact);
      _contacts.sort((a, b) => a.name.compareTo(b.name));
      
      await _saveContactsToLocal(_currentUid!);
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to add contact: $e';
      notifyListeners();
    }
  }

  Future<void> removeContact(String contactId) async {
    if (_currentUid == null) return;
    try {
      _contacts.removeWhere((c) => c.id == contactId);
      await _saveContactsToLocal(_currentUid!);
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to remove contact: $e';
      notifyListeners();
    }
  }

  /// Fuzzy match by name or relationship.
  /// Returns null if no match found.
  ContactModel? findByName(String query) {
    if (query.trim().isEmpty) return null;
    final q = query.trim().toLowerCase();

    debugPrint('[ContactProvider] findByName("$q"), contacts: ${_contacts.length}');
    for (final c in _contacts) {
      debugPrint('  -> ${c.name} (${c.relationship}) ${c.phone}');
    }

    // 0. Translate Hindi/Malayalam relationship words to English
    const relationshipTranslations = {
      // Hindi
      'beta': 'son', 'bete': 'son', 'beti': 'daughter',
      'dost': 'friend', 'doctor': 'doctor',
      'बेटा': 'son', 'बेटे': 'son', 'बेटी': 'daughter',
      'डॉक्टर': 'doctor', 'दोस्त': 'friend',
      // Malayalam
      'mone': 'son', 'mon': 'son', 'mole': 'daughter', 'mol': 'daughter',
      'doctore': 'doctor',
      'മകൻ': 'son', 'മകൾ': 'daughter',
    };
    final translatedQ = relationshipTranslations[q] ?? q;

    // 1. Exact match on relationship (e.g. "son", "daughter", "caregiver")
    for (final c in _contacts) {
      if (c.relationship.toLowerCase() == translatedQ) {
        debugPrint('  => Matched by relationship: ${c.name}');
        return c;
      }
    }

    // 2. Exact name match (case-insensitive)
    for (final c in _contacts) {
      if (c.name.toLowerCase() == q) {
        debugPrint('  => Matched by exact name: ${c.name}');
        return c;
      }
    }

    // 3. Starts-with match
    for (final c in _contacts) {
      if (c.name.toLowerCase().startsWith(q)) {
        debugPrint('  => Matched by starts-with: ${c.name}');
        return c;
      }
    }

    // 4. Contains match
    for (final c in _contacts) {
      if (c.name.toLowerCase().contains(q)) {
        debugPrint('  => Matched by contains: ${c.name}');
        return c;
      }
    }

    // 5. Token overlap — spoken name may be partially heard
    final queryTokens = q.split(' ');
    for (final c in _contacts) {
      final nameTokens = c.name.toLowerCase().split(' ');
      final overlap = queryTokens.any((t) => nameTokens.contains(t));
      if (overlap) {
        debugPrint('  => Matched by token overlap: ${c.name}');
        return c;
      }
    }

    debugPrint('  => No match found for "$q"');
    return null;
  }
}
