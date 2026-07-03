import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants/api_keys.dart';
import '../models/workout_models.dart';

class GoogleDriveService {
  GoogleDriveService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;
  static const _baseUrl = 'www.googleapis.com';

  /// Fetches all video files from a specific folder ID
  Future<List<ExerciseModel>> fetchFolderVideos(String folderId) async {
    final uri = Uri.https(_baseUrl, '/drive/v3/files', {
      'key': ApiKeys.googleDriveApi,
      'q':
          "'$folderId' in parents and trashed=false and (mimeType contains 'video/' or name contains '.mp4' or name contains '.mov')",
      'fields':
          'files(id,name,mimeType,thumbnailLink,webContentLink,createdTime)',
      'pageSize': '1000',
      'orderBy': 'name',
    });

    final response = await _client.get(uri);
    if (response.statusCode != 200) {
      throw Exception('Failed to fetch Drive videos: ${response.body}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final files = data['files'] as List<dynamic>? ?? [];

    return files.map((file) {
      final map = file as Map<String, dynamic>;
      final id = map['id'] as String? ?? '';
      final name = map['name'] as String? ?? 'Untitled exercise';
      final thumb = (map['thumbnailLink'] as String? ?? '').replaceAll(
        '=s220',
        '=s400',
      );

      return ExerciseModel(
        id: id,
        name: _cleanFileName(name),
        instruction: 'Control the movement and maintain form',
        sets: 4,
        reps: '8–10',
        restSeconds: 30,
        videoUrl:
            'https://www.googleapis.com/drive/v3/files/$id?alt=media&key=${ApiKeys.googleDriveApi}',
        thumbnailUrl: thumb.isNotEmpty ? thumb : null,
      );
    }).toList();
  }

  /// Fetches all subfolders from a parent folder ID
  Future<List<Map<String, String>>> fetchSubfolders(String parentId) async {
    final uri = Uri.https(_baseUrl, '/drive/v3/files', {
      'key': ApiKeys.googleDriveApi,
      'q':
          "'$parentId' in parents and trashed=false and mimeType = 'application/vnd.google-apps.folder'",
      'fields': 'files(id,name)',
      'pageSize': '1000',
      'orderBy': 'name',
    });

    final response = await _client.get(uri);
    if (response.statusCode != 200) {
      throw Exception('Failed to fetch Drive subfolders: ${response.body}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final files = data['files'] as List<dynamic>? ?? [];

    return files.map((file) {
      final map = file as Map<String, dynamic>;
      return {
        'id': map['id'] as String? ?? '',
        'name': map['name'] as String? ?? 'Untitled folder',
      };
    }).toList();
  }

  String _cleanFileName(String fileName) {
    String name = fileName.replaceAll(RegExp(r'^[-\s]+'), '');
    final dotIndex = name.lastIndexOf('.');
    if (dotIndex > 0) name = name.substring(0, dotIndex);
    name = name.replaceAll(RegExp(r'[_-]'), ' ');
    return name
        .split(' ')
        .where((w) => w.isNotEmpty)
        .map((w) => w[0].toUpperCase() + w.substring(1).toLowerCase())
        .join(' ');
  }

  /// Converts a standard Google Drive URL to a direct API media streaming URL
  static String getDirectVideoUrl(String originalUrl) {
    if (originalUrl.isEmpty) return '';
    
    // If it's already an API media link, just return it (but ensure key is there)
    if (originalUrl.contains('googleapis.com/drive/v3/files/')) {
      if (!originalUrl.contains('key=')) {
        final separator = originalUrl.contains('?') ? '&' : '?';
        return '$originalUrl${separator}key=${ApiKeys.googleDriveApi}';
      }
      return originalUrl;
    }

    String? fileId;
    
    // Extract ID from different formats
    if (originalUrl.contains('/file/d/')) {
      fileId = originalUrl.split('/file/d/').last.split('/').first;
    } else if (originalUrl.contains('id=')) {
      fileId = originalUrl.split('id=').last.split('&').first;
    } else if (originalUrl.contains('uc?export=download')) {
      // already a direct link format, but let's standardize to API
      fileId = originalUrl.split('id=').last.split('&').first;
    }

    if (fileId != null && fileId.isNotEmpty) {
      return 'https://www.googleapis.com/drive/v3/files/$fileId?alt=media&key=${ApiKeys.googleDriveApi}';
    }

    return originalUrl; // Fallback
  }

  /// Fetches metadata (like thumbnailLink) for a single file ID
  Future<Map<String, String?>> fetchFileMetadata(String fileId) async {
    final uri = Uri.https(_baseUrl, '/drive/v3/files/$fileId', {
      'key': ApiKeys.googleDriveApi,
      'fields': 'thumbnailLink,webContentLink',
    });

    final response = await _client.get(uri);
    if (response.statusCode != 200) {
      throw Exception('Failed to fetch file metadata: ${response.body}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final thumb = (data['thumbnailLink'] as String? ?? '').replaceAll(
      '=s220',
      '=s600', // Request higher resolution for cards
    );

    return {
      'thumbnailUrl': thumb.isNotEmpty ? thumb : null,
      'videoUrl': 'https://www.googleapis.com/drive/v3/files/$fileId?alt=media&key=${ApiKeys.googleDriveApi}',
    };
  }

  void dispose() {
    _client.close();
  }
}
