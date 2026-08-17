import 'dart:convert';
import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase_config.dart';

/// Thin wrapper around Supabase for the NeumoAI-D app.
///
/// All methods are no-ops (return null / empty) when Supabase is not
/// configured, so the app stays fully functional offline and in tests.
class SupabaseService {
  static SupabaseService? _instance;

  factory SupabaseService() => _instance ??= SupabaseService._();

  SupabaseService._();

  bool get _enabled => SupabaseConfig.isConfigured && Supabase.instance.isInitialized;

  SupabaseClient get _client => Supabase.instance.client;

  /// Initializes the Supabase client. Safe to call multiple times.
  Future<void> init() async {
    if (!SupabaseConfig.isConfigured) return;
    if (Supabase.instance.isInitialized) return;
    await Supabase.initialize(
      url: SupabaseConfig.url,
      publishableKey: SupabaseConfig.anonKey,
    );
  }

  /// Uploads a cough audio file to the `audio` bucket and returns the storage
  /// path (e.g. `<childId>/cough.wav`) for the `audio_url` column, or null if
  /// Supabase is not configured.
  Future<String?> uploadAudio({
    required String childId,
    required File audioFile,
  }) async {
    if (!_enabled) return null;
    final path = '$childId/cough_${DateTime.now().millisecondsSinceEpoch}.wav';
    try {
      await _client.storage.from('audio').upload(path, audioFile);
      return path;
    } catch (_) {
      return null;
    }
  }

  /// Inserts a screening row into the `screenings` table.
  Future<void> insertScreening(Map<String, dynamic> row) async {
    if (!_enabled) return;
    try {
      await _client.from('screenings').insert(row);
    } catch (_) {}
  }

  /// Fetches screenings for a child (or all if [childId] is null).
  Future<List<Map<String, dynamic>>> fetchScreenings({String? childId}) async {
    if (!_enabled) return const [];
    try {
      final builder = _client.from('screenings').select();
      var query = childId == null ? builder : builder.eq('child_id', childId);
      final rows = await query.order('created_at');
      return rows.map((r) => Map<String, dynamic>.from(r)).toList();
    } catch (_) {
      return const [];
    }
  }

  /// Marks a screening as synced with the server.
  Future<void> markSynced(String id) async {
    if (!_enabled) return;
    try {
      await _client.from('screenings').update({'status': 'synced'}).eq('id', id);
    } catch (_) {}
  }
}

/// Convenience JSON helpers shared across the app.
String jsonEncodePretty(Object? value) => const JsonEncoder.withIndent('  ').convert(value);
