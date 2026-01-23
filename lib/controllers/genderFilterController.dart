import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '/models/genderModel.dart';

/// Controller untuk mengelola state filter gender dalam matching
class GenderFilterController with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Gender _selectedGender = Gender.semua;
  bool _isLoading = false;
  String? _errorMessage;

  Gender get selectedGender => _selectedGender;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Mendapatkan string gender untuk filter query Firebase
  String? get searchGenderString =>
      GenderFilter.toFirebaseString(_selectedGender);

  GenderFilterController() {
    _auth.authStateChanges().listen((User? user) {
      if (user != null) {
        loadGenderPreference();
      } else {
        _selectedGender = Gender.semua;
        notifyListeners();
      }
    });

    if (_auth.currentUser != null) {
      loadGenderPreference();
    }
  }

  /// Memuat preferensi gender dari Firebase
  Future<void> loadGenderPreference() async {
    _isLoading = true;
    notifyListeners();

    try {
      final user = _auth.currentUser;
      if (user == null) {
        _isLoading = false;
        notifyListeners();
        return;
      }

      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        final searchGenderValue = data['searchGender'] as String?;
        _selectedGender = GenderFilter.fromFirebaseString(searchGenderValue);
      }

      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Gagal memuat preferensi gender: $e';
      print('Error loading gender preference: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Mengubah filter gender dan menyimpan ke Firebase
  Future<void> setGenderFilter(Gender gender) async {
    if (_selectedGender == gender) return;

    _selectedGender = gender;
    notifyListeners();

    try {
      final user = _auth.currentUser;
      if (user == null) return;

      await _firestore.collection('users').doc(user.uid).set({
        'searchGender': GenderFilter.toFirebaseString(gender),
      }, SetOptions(merge: true));

      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Gagal menyimpan preferensi gender: $e';
      print('Error saving gender preference: $e');
    }
  }

  /// Reset filter ke default (Semua)
  void resetFilter() {
    _selectedGender = Gender.semua;
    notifyListeners();
  }

  void clearErrorMessage() {
    _errorMessage = null;
    notifyListeners();
  }
}
