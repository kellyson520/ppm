import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:ztd_password_manager/blocs/sync/sync_bloc.dart';
import 'package:ztd_password_manager/services/sync_service.dart';
import 'package:ztd_password_manager/core/sync/webdav_sync.dart';

@GenerateMocks([SyncService])
import 'sync_bloc_test.mocks.dart';

void main() {
  late MockSyncService mockSyncService;

  setUp(() {
    mockSyncService = MockSyncService();

    when(mockSyncService.syncProgress).thenAnswer((_) => Stream.empty());
    when(mockSyncService.getNodes()).thenAnswer((_) async => <WebDavNode>[]);
  });

  group('SyncBloc', () {
    blocTest<SyncBloc, SyncState>(
      'emits loading state when SyncNodesRequested is added',
      build: () {
        when(mockSyncService.getNodes())
            .thenAnswer((_) async => <WebDavNode>[]);
        return SyncBloc(syncService: mockSyncService);
      },
      act: (bloc) => bloc.add(SyncNodesRequested()),
      expect: () => [
        const SyncState(isLoading: true),
        const SyncState(isLoading: false, nodes: []),
      ],
      verify: (_) {
        verify(mockSyncService.getNodes()).called(1);
      },
    );

    blocTest<SyncBloc, SyncState>(
      'emits nodes when SyncNodesRequested succeeds',
      build: () {
        final nodes = [
          WebDavNode(
            name: 'Test Server',
            url: 'https://test.com/webdav',
            username: 'user',
            password: 'pass',
          ),
        ];
        when(mockSyncService.getNodes()).thenAnswer((_) async => nodes);
        return SyncBloc(syncService: mockSyncService);
      },
      act: (bloc) => bloc.add(SyncNodesRequested()),
      expect: () => [
        const SyncState(isLoading: true),
        isA<SyncState>()
            .having((s) => s.isLoading, 'isLoading', false)
            .having((s) => s.nodes.length, 'nodes.length', 1),
      ],
    );

    blocTest<SyncBloc, SyncState>(
      'emits error when SyncNodesRequested fails',
      build: () {
        when(mockSyncService.getNodes())
            .thenThrow(Exception('Database error'));
        return SyncBloc(syncService: mockSyncService);
      },
      act: (bloc) => bloc.add(SyncNodesRequested()),
      expect: () => [
        const SyncState(isLoading: true),
        isA<SyncState>()
            .having((s) => s.isLoading, 'isLoading', false)
            .having((s) => s.error, 'error', isNotNull),
      ],
    );

    blocTest<SyncBloc, SyncState>(
      'emits loading state when SyncStarted',
      build: () {
        when(mockSyncService.syncAll()).thenAnswer(
          (_) async => SyncResult.success(
            nodeResults: {},
            totalDownloaded: 0,
            totalUploaded: 0,
            conflicts: [],
          ),
        );
        return SyncBloc(syncService: mockSyncService);
      },
      act: (bloc) => bloc.add(SyncStarted()),
      expect: () => [
        const SyncState(isLoading: true),
        const SyncState(isLoading: false),
      ],
    );

    blocTest<SyncBloc, SyncState>(
      'emits error when SyncStarted fails',
      build: () {
        when(mockSyncService.syncAll())
            .thenAnswer((_) async => SyncResult.failure(error: 'No nodes'));
        return SyncBloc(syncService: mockSyncService);
      },
      act: (bloc) => bloc.add(SyncStarted()),
      expect: () => [
        const SyncState(isLoading: true),
        isA<SyncState>()
            .having((s) => s.isLoading, 'isLoading', false)
            .having((s) => s.error, 'error', 'No nodes'),
      ],
    );

    blocTest<SyncBloc, SyncState>(
      'adds node when SyncNodeAdded is dispatched',
      build: () {
        final node = WebDavNode(
          name: 'New Node',
          url: 'https://new.com/dav',
          username: 'u',
          password: 'p',
        );
        when(mockSyncService.addNode(node)).thenAnswer((_) async {});
        when(mockSyncService.getNodes()).thenAnswer((_) async => [node]);
        return SyncBloc(syncService: mockSyncService);
      },
      act: (bloc) {
        final node = WebDavNode(
          name: 'New Node',
          url: 'https://new.com/dav',
          username: 'u',
          password: 'p',
        );
        bloc.add(SyncNodeAdded(node));
      },
      expect: () => [
        const SyncState(isLoading: true),
        isA<SyncState>()
            .having((s) => s.isLoading, 'isLoading', false)
            .having((s) => s.nodes.length, 'nodes.length', 1),
      ],
    );

    blocTest<SyncBloc, SyncState>(
      'removes node when SyncNodeRemoved is dispatched',
      build: () {
        when(mockSyncService.removeNode('Test Node'))
            .thenAnswer((_) async {});
        when(mockSyncService.getNodes()).thenAnswer((_) async => <WebDavNode>[]);
        return SyncBloc(syncService: mockSyncService);
      },
      act: (bloc) => bloc.add(const SyncNodeRemoved('Test Node')),
      expect: () => [
        const SyncState(isLoading: true),
        isA<SyncState>()
            .having((s) => s.isLoading, 'isLoading', false)
            .having((s) => s.nodes, 'nodes', isEmpty),
      ],
    );

    blocTest<SyncBloc, SyncState>(
      'updates progress when SyncProgressUpdated is dispatched',
      build: () {
        return SyncBloc(syncService: mockSyncService);
      },
      act: (bloc) {
        final progress = SyncProgress(
          status: SyncStatus.inProgress,
          message: 'Syncing...',
          progress: 50.0,
        );
        bloc.add(SyncProgressUpdated(progress));
      },
      expect: () => [
        isA<SyncState>()
            .having((s) => s.currentProgress?.progress, 'progress', 50.0)
            .having((s) => s.currentProgress?.status, 'status', SyncStatus.inProgress),
      ],
    );

    test('SyncState copyWith works correctly', () {
      const state = SyncState(
        isLoading: true,
        error: 'test error',
      );

      final copied = state.copyWith(isLoading: false);

      expect(copied.isLoading, isFalse);
      expect(copied.error, equals('test error'));
    });

    test('SyncState props includes all fields', () {
      const state = SyncState(
        nodes: [],
        isLoading: true,
        error: 'error',
      );

      expect(state.props, contains(state.nodes));
      expect(state.props, contains(state.isLoading));
      expect(state.props, contains(state.error));
    });
  });
}
