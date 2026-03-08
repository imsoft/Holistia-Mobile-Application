/// Constantes globales de la app.
/// Centraliza URLs, nombres de bucket, RPCs y regex para evitar magic strings.
abstract final class AppConstants {
  // ── URLs legales ──────────────────────────────────────────────────────────
  static const String privacyPolicyUrl = 'https://holistia.io/privacy';
  static const String termsUrl = 'https://holistia.io/terms';

  // ── Deep-link / OAuth ─────────────────────────────────────────────────────
  static const String oauthRedirectUrl = 'io.holistia.mobile://login-callback';

  // ── Supabase Storage buckets ──────────────────────────────────────────────
  static const String avatarsBucket = 'avatars';
  static const String postImagesBucket = 'post-images';
  static const String placesBucket = 'places';

  // ── Supabase RPCs ─────────────────────────────────────────────────────────
  static const String deleteUserRpc = 'delete_user';

  // ── Validación de username ────────────────────────────────────────────────
  /// 3-30 caracteres: letras minúsculas, números y guión bajo.
  static final RegExp usernameRegex = RegExp(r'^[a-z0-9_]{3,30}$');
  static const int usernameMinLength = 3;
  static const int usernameMaxLength = 30;
}
