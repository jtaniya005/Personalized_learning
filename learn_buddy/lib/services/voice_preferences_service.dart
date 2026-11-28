import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../config/api_config.dart';

class VoicePreferencesService {
  static const String _keySessionId = 'voice_assistant_session_id';
  static const String _keyBaseUrl = 'voice_assistant_base_url';
  static const String _keyTtsEnabled = 'voice_assistant_tts_enabled';
  static const String _keySpeechRate = 'voice_assistant_speech_rate';
  static const String _keyPitch = 'voice_assistant_pitch';

  final SharedPreferences _prefs;

  VoicePreferencesService(this._prefs);

  static Future<VoicePreferencesService> init() async {
    final prefs = await SharedPreferences.getInstance();
    return VoicePreferencesService(prefs);
  }

  static String getDefaultBaseUrl() {
    return ApiConfig.baseUrl;
  }

  String getSessionId() {
    String? id = _prefs.getString(_keySessionId);
    if (id == null || id.isEmpty) {
      id = const Uuid().v4();
      _prefs.setString(_keySessionId, id);
    }
    return id;
  }

  Future<String> regenerateSessionId() async {
    final newId = const Uuid().v4();
    await _prefs.setString(_keySessionId, newId);
    return newId;
  }

  String getBaseUrl() {
    return _prefs.getString(_keyBaseUrl) ?? getDefaultBaseUrl();
  }

  Future<void> setBaseUrl(String url) async {
    final cleaned = ApiConfig.cleanUrl(url);
    await ApiConfig.setBaseUrl(cleaned);
    await _prefs.setString(_keyBaseUrl, cleaned);
  }

  bool getTtsEnabled() {
    return _prefs.getBool(_keyTtsEnabled) ?? true;
  }

  Future<void> setTtsEnabled(bool enabled) async {
    await _prefs.setBool(_keyTtsEnabled, enabled);
  }

  double getSpeechRate() {
    return _prefs.getDouble(_keySpeechRate) ?? 0.5;
  }

  Future<void> setSpeechRate(double rate) async {
    await _prefs.setDouble(_keySpeechRate, rate);
  }

  double getPitch() {
    return _prefs.getDouble(_keyPitch) ?? 1.0;
  }

  Future<void> setPitch(double pitch) async {
    await _prefs.setDouble(_keyPitch, pitch);
  }
}
