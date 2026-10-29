import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/user.dart';

class UserProvider extends InheritedWidget {
  final User user;
  final Future<bool> Function(User) updateUser;
  final Future<void> Function() logout;
  final bool isLoading;
  final bool isDarkMode;
  final int visitCount;
  final List<String> favorites;
  final Future<void> Function(bool) setDarkMode;
  final Future<void> Function(String) addFavorite;
  final Future<void> Function(String) removeFavorite;
  final Future<bool> Function(String) isEmailAvailable;

  const UserProvider({
    super.key,
    required this.user,
    required this.updateUser,
    required this.logout,
    required this.isLoading,
    required this.isDarkMode,
    required this.visitCount,
    required this.favorites,
    required this.setDarkMode,
    required this.addFavorite,
    required this.removeFavorite,
    required this.isEmailAvailable,
    required super.child,
  });

  static UserProvider of(BuildContext context) {
    final provider = context.dependOnInheritedWidgetOfExactType<UserProvider>();
    assert(provider != null, 'UserProvider not found in context');
    return provider!;
  }

  @override
  bool updateShouldNotify(UserProvider oldWidget) =>
      oldWidget.user.name != user.name ||
      oldWidget.user.email != user.email ||
      oldWidget.user.isLoggedIn != user.isLoggedIn ||
      oldWidget.isLoading != isLoading ||
      oldWidget.isDarkMode != isDarkMode ||
      oldWidget.visitCount != visitCount ||
      oldWidget.favorites.length != favorites.length ||
      !oldWidget.favorites.asMap().entries.every(
        (entry) => favorites[entry.key] == entry.value,
      );
}

class UserProviderWrapper extends StatefulWidget {
  final Widget child;

  const UserProviderWrapper({super.key, required this.child});

  @override
  State<UserProviderWrapper> createState() => _UserProviderWrapperState();
}

class _UserProviderWrapperState extends State<UserProviderWrapper> {
  User _user = User(name: '', email: '');
  bool _isLoading = true;
  bool _isDarkMode = false;
  int _visitCount = 0;
  List<String> _favorites = [];

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final visits = (prefs.getInt('visit_count') ?? 0) + 1;
      await prefs.setInt('visit_count', visits);
      if (!mounted) return;
      setState(() {
        _user = User(
          name: prefs.getString('user_name') ?? '',
          email: prefs.getString('user_email') ?? '',
          isLoggedIn: prefs.getBool('is_logged_in') ?? false,
        );
        _isDarkMode = prefs.getBool('is_dark_mode') ?? false;
        _visitCount = visits;
        _favorites = prefs.getStringList('favorites') ?? [];
        _isLoading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<bool> _updateUser(User newUser) async {
    if (mounted) setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_name', newUser.name);
      await prefs.setString('user_email', newUser.email);
      await prefs.setBool('is_logged_in', newUser.isLoggedIn);
      final emails = prefs.getStringList('registered_emails') ?? [];
      final normalizedEmail = newUser.email.toLowerCase();
      if (!emails.contains(normalizedEmail)) emails.add(normalizedEmail);
      await prefs.setStringList('registered_emails', emails);
      if (!mounted) return false;
      setState(() {
        _user = newUser;
        _isLoading = false;
      });
      return true;
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
      return false;
    }
  }

  Future<void> _logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('user_name');
      await prefs.setBool('is_logged_in', false);
      if (mounted) {
        setState(() => _user = _user.copyWith(name: '', isLoggedIn: false));
      }
    } catch (_) {
      // Keep the in-memory user intact when persistence fails.
    }
  }

  Future<bool> _isEmailAvailable(String value) async {
    final candidate = value.trim().toLowerCase();
    if (candidate.isEmpty) return false;
    if (candidate == _user.email.trim().toLowerCase()) return true;
    try {
      final prefs = await SharedPreferences.getInstance();
      final emails = prefs.getStringList('registered_emails') ?? [];
      return !emails.contains(candidate);
    } catch (_) {
      return false;
    }
  }

  Future<void> _setDarkMode(bool value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_dark_mode', value);
      if (mounted) setState(() => _isDarkMode = value);
    } catch (_) {
      // Leave the displayed setting unchanged when persistence fails.
    }
  }

  Future<void> _saveFavorites(List<String> values) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('favorites', values);
      if (mounted) setState(() => _favorites = values);
    } catch (_) {
      // Leave the displayed list unchanged when persistence fails.
    }
  }

  Future<void> _addFavorite(String value) async {
    final favorite = value.trim();
    if (favorite.isNotEmpty && !_favorites.contains(favorite)) {
      await _saveFavorites([..._favorites, favorite]);
    }
  }

  Future<void> _removeFavorite(String value) async {
    await _saveFavorites(_favorites.where((item) => item != value).toList());
  }

  @override
  Widget build(BuildContext context) => UserProvider(
    user: _user,
    updateUser: _updateUser,
    logout: _logout,
    isLoading: _isLoading,
    isDarkMode: _isDarkMode,
    visitCount: _visitCount,
    favorites: _favorites,
    setDarkMode: _setDarkMode,
    addFavorite: _addFavorite,
    removeFavorite: _removeFavorite,
    isEmailAvailable: _isEmailAvailable,
    child: widget.child,
  );
}
