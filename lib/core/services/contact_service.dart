import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:fuzzywuzzy/fuzzywuzzy.dart';
import 'package:permission_handler/permission_handler.dart';

class ContactService {
  List<Contact> _contacts = [];

  List<Contact> get contacts => _contacts;

  Future<List<Contact>> loadContacts() async {
    if (await Permission.contacts.request().isGranted) {
      final fetched = await FlutterContacts.getContacts(withProperties: true);
      _contacts = fetched.where((c) => c.phones.isNotEmpty).toList();
      return _contacts;
    } else {
      throw Exception("Izin kontak tidak diberikan");
    }
  }

  Map<String, double> findContactScores(String spokenInput) {
    if (_contacts.isEmpty) return {};

    final normalizedSpoken =
        spokenInput.toLowerCase().replaceAll(RegExp(r'[^\w\s]'), '').trim();
    Map<String, double> scores = {};

    for (var contact in _contacts) {
      final name = contact.displayName
          .toLowerCase()
          .replaceAll(RegExp(r'[^\w\s]'), '')
          .trim();
      // use tokenSetRatio for more robust matching of short names vs full names
      double score = tokenSetRatio(normalizedSpoken, name).toDouble();
      scores[contact.displayName] = score;
    }
    return scores;
  }

  List<MapEntry<String, double>> getTopMatches(String spokenInput,
      {double threshold = 75.0}) {
    final scores = findContactScores(spokenInput);
    return scores.entries.where((entry) => entry.value > threshold).toList()
      ..sort((a, b) => b.value.compareTo(a.value));
  }
}
