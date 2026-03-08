import 'package:shared_preferences/shared_preferences.dart';

const String _keyOnboardingSeen = 'onboarding_seen';
const String _keyLifeWheelSurveySeen = 'life_wheel_survey_seen';

Future<bool> getOnboardingSeen() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool(_keyOnboardingSeen) ?? false;
}

Future<void> setOnboardingSeen() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool(_keyOnboardingSeen, true);
}

Future<bool> getLifeWheelSurveySeen() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool(_keyLifeWheelSurveySeen) ?? false;
}

Future<void> setLifeWheelSurveySeen() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool(_keyLifeWheelSurveySeen, true);
}
