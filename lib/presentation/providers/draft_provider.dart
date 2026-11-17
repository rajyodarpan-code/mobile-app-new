import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:rajyo_darpan_publisher/core/storage/local_database.dart';

class LocalDraft {
  final int? localId;
  final String? serverUuid;
  final String title;
  final String content;
  final String? excerpt;
  final String? slug;
  final String? category;
  final List<String> tags;
  final String? seoTitle;
  final String? metaDescription;
  final String? focusKeyword;
  final String? imageAlt;
  final String? localImagePath;
  final int? featuredMediaId;
  final bool isBreaking;
  final bool isFeatured;
  final String syncStatus;
  final String lastModified;

  LocalDraft({
    this.localId,
    this.serverUuid,
    required this.title,
    required this.content,
    this.excerpt,
    this.slug,
    this.category,
    this.tags = const [],
    this.seoTitle,
    this.metaDescription,
    this.focusKeyword,
    this.imageAlt,
    this.localImagePath,
    this.featuredMediaId,
    this.isBreaking = false,
    this.isFeatured = false,
    this.syncStatus = 'draft',
    required this.lastModified,
  });

  Map<String, dynamic> toMap() {
    return {
      'local_id': localId,
      'server_uuid': serverUuid,
      'title': title,
      'content': content,
      'excerpt': excerpt,
      'slug': slug,
      'category': category,
      'tags': jsonEncode(tags),
      'seo_title': seoTitle,
      'meta_description': metaDescription,
      'focus_keyword': focusKeyword,
      'image_alt': imageAlt,
      'local_image_path': localImagePath,
      'featured_media_id': featuredMediaId,
      'is_breaking': isBreaking ? 1 : 0,
      'is_featured': isFeatured ? 1 : 0,
      'sync_status': syncStatus,
      'last_modified': lastModified,
    };
  }

  factory LocalDraft.fromMap(Map<String, dynamic> map) {
    List<String> parsedTags = [];
    if (map['tags'] != null) {
      try {
        parsedTags = List<String>.from(jsonDecode(map['tags']));
      } catch (_) {}
    }

    return LocalDraft(
      localId: map['local_id'],
      serverUuid: map['server_uuid'],
      title: map['title'] ?? '',
      content: map['content'] ?? '',
      excerpt: map['excerpt'],
      slug: map['slug'],
      category: map['category'],
      tags: parsedTags,
      seoTitle: map['seo_title'],
      metaDescription: map['meta_description'],
      focusKeyword: map['focus_keyword'],
      imageAlt: map['image_alt'],
      localImagePath: map['local_image_path'],
      featuredMediaId: map['featured_media_id'],
      isBreaking: map['is_breaking'] == 1,
      isFeatured: map['is_featured'] == 1,
      syncStatus: map['sync_status'] ?? 'draft',
      lastModified: map['last_modified'] ?? '',
    );
  }
}

class DraftProvider with ChangeNotifier {
  List<LocalDraft> _drafts = [];
  bool _isLoading = false;

  List<LocalDraft> get drafts => _drafts;
  bool get isLoading => _isLoading;

  Future<void> loadDrafts() async {
    _isLoading = true;
    notifyListeners();

    try {
      final db = await LocalDatabase.database;
      final maps = await db.query('local_drafts', orderBy: 'local_id DESC');
      _drafts = maps.map((m) => LocalDraft.fromMap(m)).toList();
    } catch (_) {}

    _isLoading = false;
    notifyListeners();
  }

  Future<int> autoSaveDraft(LocalDraft draft) async {
    final db = await LocalDatabase.database;
    final map = draft.toMap();
    
    if (draft.localId != null) {
      await db.update('local_drafts', map, where: 'local_id = ?', whereArgs: [draft.localId]);
      await loadDrafts();
      return draft.localId!;
    } else {
      map.remove('local_id');
      final id = await db.insert('local_drafts', map);
      await loadDrafts();
      return id;
    }
  }

  Future<void> deleteDraft(int localId) async {
    final db = await LocalDatabase.database;
    await db.delete('local_drafts', where: 'local_id = ?', whereArgs: [localId]);
    await loadDrafts();
  }
}
