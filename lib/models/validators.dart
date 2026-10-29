/// Shared input rules used by the profile form.
class Validators {
  static final RegExp _emailPattern = RegExp(r'^[\w.+-]+@[\w-]+(\.[\w-]+)+$');

  /// Rejects inputs that could be rendered as HTML/script when displayed.
  static bool containsDangerousMarkup(String value) {
    final lower = value.toLowerCase();
    return lower.contains('<') ||
        lower.contains('>') ||
        lower.contains('javascript:') ||
        lower.contains('data:') ||
        RegExp(r'on\w+\s*=').hasMatch(lower);
  }

  static String? name(String? value) {
    final name = value?.trim() ?? '';
    if (name.isEmpty) return 'Nama tidak boleh kosong';
    if (name.length > 50) return 'Nama maksimal 50 karakter';
    if (containsDangerousMarkup(name)) {
      return 'Nama mengandung karakter berbahaya';
    }
    return null;
  }

  static String? email(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) return 'Email tidak boleh kosong';
    if (containsDangerousMarkup(email)) {
      return 'Email mengandung karakter berbahaya';
    }
    if (!_emailPattern.hasMatch(email)) return 'Format email tidak valid';
    return null;
  }
}
