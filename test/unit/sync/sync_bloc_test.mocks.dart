// Mocks for SyncBloc tests
// Manual implementation instead of code generation

import 'dart:async';
import 'dart:typed_data';
import 'package:mockito/mockito.dart';
import 'package:ztd_password_manager/services/sync_service.dart';
import 'package:ztd_password_manager/core/sync/webdav_sync.dart';

class MockSyncService extends Mock implements SyncService {
  @override
  Stream<SyncProgress> get syncProgress => Stream.empty();

  @override
  Future<void> initialize() async {}

  @override
  Future<void> addNode(WebDavNode node) async {}

  @override
  Future<void> removeNode(String name) async {}

  @override
  Future<List<WebDavNode>> getNodes() async => [];

  @override
  Future<SyncResult> syncAll() async => SyncResult.success(
        nodeResults: {},
        totalDownloaded: 0,
        totalUploaded: 0,
        conflicts: [],
      );

  @override
  void dispose() {}
}
