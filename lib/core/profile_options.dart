/// Opciones de sexo para el perfil.
class ProfileSexOptions {
  ProfileSexOptions._();

  static const Map<String, String> options = {
    'male': 'Masculino',
    'female': 'Femenino',
    'other': 'Otro',
    'prefer_not_to_say': 'Prefiero no decir',
  };

  static String? getLabel(String? value) => value != null ? options[value] : null;
}
