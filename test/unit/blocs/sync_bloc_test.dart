/// SyncBloc 状态机测试 — WebDAV 同步管理
library;

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:ztd_password_manager/blocs/sync/sync_bloc.dart';
import 'package:ztd_password_manager/services/sync_service.dart';
import 'package:ztd_password_manager/core/sync/webdav_sync.dart';

import 'sync_bloc_test.mocks.dart';

WebDavNode _makeNode(String name) {
  return WebDavNode(name: name, url: 'https://example.com/dav', username: 'user', password: 'pass');
}

@GenerateMocks([SyncService])
void main() {
  late MockSyncService mockSyncService;
  late SyncBloc syncBloc;

  setUp(() {
    mockSyncService = MockSyncService();
    // 默认: syncProgress 返回空流，避免订阅 null
    when(mockSyncService.syncProgress).thenAnswer((_) => const Stream.empty());
    syncBloc = SyncBloc(syncService: mockSyncService);
  });

  tearDown(() {
    syncBloc.close();
  });

  // ==================== [1] 获取节点列表 ====================

  group('SyncNodesRequested', () {
    final nodes = [_makeNode('node-1'), _makeNode('node-2')];

    blocTest<SyncBloc, SyncState>(
      '成功获取节点 → isLoading→nodes loaded',
      build: () {
        when(mockSyncService.getNodes()).thenAnswer((_) async => nodes);
        return syncBloc;
      },
      act: (b) => b.add(SyncNodesRequested()),
      expect: () => [
        predicate<SyncState>((s) => s.isLoading == true),
        predicate<SyncState>(
          (s) => s.isLoading == false && s.nodes.length == 2 && s.error == null,
        ),
      ],
    );

    blocTest<SyncBloc, SyncState>(
      '获取节点失败 → isLoading→error',
      build: () {
        when(mockSyncService.getNodes()).thenThrow(Exception('Network error'));
        return syncBloc;
      },
      act: (b) => b.add(SyncNodesRequested()),
      expect: () => [
        predicate<SyncState>((s) => s.isLoading == true),
        predicate<SyncState>(
          (s) => s.isLoading == false && (s.error ?? '').contains('internal error'),
        ),
      ],
    );
  });

  // ==================== [2] 开始同步 ====================

  group('SyncStarted', () {
    final successResult = SyncResult.success(
      nodeResults: const {},
      totalDownloaded: 10,
      totalUploaded: 2,
      conflicts: [],
    );
    final failureResult = SyncResult.failure(error: 'Connection refused');

    blocTest<SyncBloc, SyncState>(
      '同步成功 → isLoading→idle',
      build: () {
        when(mockSyncService.syncAll()).thenAnswer((_) async => successResult);
        return syncBloc;
      },
      act: (b) => b.add(SyncStarted()),
      expect: () => [
        predicate<SyncState>((s) => s.isLoading == true),
        predicate<SyncState>((s) => s.isLoading == false && s.error == null),
      ],
    );

    blocTest<SyncBloc, SyncState>(
      '同步失败 → isLoading→error',
      build: () {
        when(mockSyncService.syncAll()).thenAnswer((_) async => failureResult);
        return syncBloc;
      },
      act: (b) => b.add(SyncStarted()),
      expect: () => [
        predicate<SyncState>((s) => s.isLoading == true),
        predicate<SyncState>(
          (s) => s.isLoading == false && (s.error ?? '').contains('internal error'),
        ),
      ],
    );

    blocTest<SyncBloc, SyncState>(
      '同步抛出异常 → isLoading→error',
      build: () {
        when(mockSyncService.syncAll()).thenThrow(Exception('Unexpected crash'));
        return syncBloc;
      },
      act: (b) => b.add(SyncStarted()),
      expect: () => [
        predicate<SyncState>((s) => s.isLoading == true),
        predicate<SyncState>(
          (s) => s.isLoading == false && (s.error ?? '').contains('internal error'),
        ),
      ],
    );
  });

  // ==================== [3] 添加同步节点 ====================

  group('SyncNodeAdded', () {
    final node = _makeNode('new-node');
    final nodes = [node];

    blocTest<SyncBloc, SyncState>(
      '添加节点成功 → isLoading→nodes updated',
      build: () {
        when(mockSyncService.addNode(node)).thenAnswer((_) async {});
        when(mockSyncService.getNodes()).thenAnswer((_) async => nodes);
        return syncBloc;
      },
      act: (b) => b.add(SyncNodeAdded(node)),
      expect: () => [
        predicate<SyncState>((s) => s.isLoading == true),
        predicate<SyncState>(
          (s) => s.isLoading == false && s.nodes.length == 1 && s.nodes.first.name == 'new-node',
        ),
      ],
      verify: (_) {
        verify(mockSyncService.addNode(node)).called(1);
        verify(mockSyncService.getNodes()).called(1);
      },
    );

    blocTest<SyncBloc, SyncState>(
      '添加节点失败 → error',
      build: () {
        when(mockSyncService.addNode(node)).thenThrow(Exception('Invalid URL'));
        return syncBloc;
      },
      act: (b) => b.add(SyncNodeAdded(node)),
      expect: () => [
        predicate<SyncState>((s) => s.isLoading == true),
        predicate<SyncState>(
          (s) => s.isLoading == false && (s.error ?? '').contains('internal error'),
        ),
      ],
    );
  });

  // ==================== [4] 移除同步节点 ====================

  group('SyncNodeRemoved', () {
    blocTest<SyncBloc, SyncState>(
      '移除节点成功 → isLoading→nodes empty',
      build: () {
        when(mockSyncService.removeNode('old-node')).thenAnswer((_) async {});
        when(mockSyncService.getNodes()).thenAnswer((_) async => []);
        return syncBloc;
      },
      act: (b) => b.add(const SyncNodeRemoved('old-node')),
      expect: () => [
        predicate<SyncState>((s) => s.isLoading == true),
        predicate<SyncState>((s) => s.isLoading == false && s.nodes.isEmpty),
      ],
      verify: (_) => verify(mockSyncService.removeNode('old-node')).called(1),
    );

    blocTest<SyncBloc, SyncState>(
      '移除节点失败 → error',
      build: () {
        when(mockSyncService.removeNode('old-node')).thenThrow(Exception('Node not found'));
        return syncBloc;
      },
      act: (b) => b.add(const SyncNodeRemoved('old-node')),
      expect: () => [
        predicate<SyncState>((s) => s.isLoading == true),
        predicate<SyncState>(
          (s) => s.isLoading == false && (s.error ?? '').contains('internal error'),
        ),
      ],
    );
  });

  // ==================== [5] 进度更新 ====================

  group('SyncProgressUpdated', () {
    blocTest<SyncBloc, SyncState>(
      '进度更新 → currentProgress 更新',
      build: () => syncBloc,
      act: (b) => b.add(SyncProgressUpdated(SyncProgress(
        status: SyncStatus.inProgress,
        message: 'Syncing file-5...',
        progress: 0.5,
        downloadedCount: 5,
        uploadedCount: 2,
        currentNode: 'file-5',
      ))),
      expect: () => [
        predicate<SyncState>(
          (s) => s.currentProgress?.status == SyncStatus.inProgress
              && s.currentProgress?.progress == 0.5
              && s.currentProgress?.currentNode == 'file-5'
              && s.currentProgress?.downloadedCount == 5,
        ),
      ],
    );
  });
}
