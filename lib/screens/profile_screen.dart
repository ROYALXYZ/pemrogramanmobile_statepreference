import 'package:flutter/material.dart';

import '../models/validators.dart';
import '../providers/user_provider.dart';
import '../widgets/custom_text_field.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _emailController;

  bool _controllersInitialized = false;
  bool _isSaving = false;
  String? _emailAsyncError;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_controllersInitialized) return;

    final provider = UserProvider.of(context);
    _nameController = TextEditingController(text: provider.user.name);
    _emailController = TextEditingController(text: provider.user.email);
    _controllersInitialized = true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    setState(() => _emailAsyncError = null);

    if (!_formKey.currentState!.validate()) return;

    final provider = UserProvider.of(context);
    final inputEmail = _emailController.text.trim();

    // Duplicate email check: allow if same as current user's email
    final isAvailable = await provider.isEmailAvailable(inputEmail);
    if (!mounted) return;
    if (!isAvailable) {
      setState(() {
        _emailAsyncError = 'Email sudah digunakan oleh akun lain';
      });
      _formKey.currentState!.validate();
      return;
    }

    setState(() => _isSaving = true);

    final updatedUser = provider.user.copyWith(
      name: _nameController.text.trim(),
      email: inputEmail,
      isLoggedIn: true,
    );

    final success = await provider.updateUser(updatedUser);

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profil berhasil disimpan'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gagal menyimpan profil ke penyimpanan'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Apakah Anda yakin ingin logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Logout', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await UserProvider.of(context).logout();
      if (!mounted) return;
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = UserProvider.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil'),
        actions: [
          if (provider.user.isLoggedIn)
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: _logout,
              tooltip: 'Logout',
            ),
        ],
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 16),
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: theme.colorScheme.primary,
                      child: Icon(
                        Icons.person,
                        size: 60,
                        color: theme.colorScheme.onPrimary,
                      ),
                    ),
                    const SizedBox(height: 24),
                    CustomTextField(
                      controller: _nameController,
                      labelText: 'Nama',
                      prefixIcon: Icons.person,
                      validator: Validators.name,
                    ),
                    const SizedBox(height: 16),
                    CustomTextField(
                      controller: _emailController,
                      labelText: 'Email',
                      prefixIcon: Icons.email,
                      keyboardType: TextInputType.emailAddress,
                      errorText: _emailAsyncError,
                      validator: Validators.email,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: _isSaving ? null : _saveProfile,
                      icon: _isSaving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.save),
                      label: Text(_isSaving ? 'Menyimpan...' : 'Simpan Profil'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: theme.colorScheme.onPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Card(
                      color: Colors.amber.shade50,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.info, color: Colors.amber[800]),
                                const SizedBox(width: 8),
                                const Text(
                                  'Catatan Keamanan',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Data disimpan di SharedPreferences (plaintext). '
                              'Jangan simpan password atau data sensitif di sini. '
                              'Gunakan secure storage untuk data sensitif.',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const _FavoritesSection(),
                  ],
                ),
              ),
            ),
    );
  }
}

class _FavoritesSection extends StatefulWidget {
  const _FavoritesSection();

  @override
  State<_FavoritesSection> createState() => _FavoritesSectionState();
}

class _FavoritesSectionState extends State<_FavoritesSection> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = UserProvider.of(context);
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Favorites',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                decoration: const InputDecoration(
                  hintText: 'Tambah favorit...',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.add_circle),
              onPressed: () {
                final text = _controller.text.trim();
                if (text.isNotEmpty) {
                  provider.addFavorite(text);
                  _controller.clear();
                }
              },
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (provider.favorites.isEmpty)
          Text('Belum ada favorit.', style: theme.textTheme.bodySmall)
        else
          ...provider.favorites.map(
            (fav) => ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              title: Text(fav),
              trailing: IconButton(
                icon: const Icon(
                  Icons.remove_circle_outline,
                  color: Colors.red,
                ),
                onPressed: () => provider.removeFavorite(fav),
              ),
            ),
          ),
      ],
    );
  }
}
