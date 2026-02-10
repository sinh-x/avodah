import 'package:avodah_core/avodah_core.dart';
import 'package:avodah_mcp/services/project_service.dart';
import 'package:avodah_mcp/services/task_service.dart';
import 'package:avodah_mcp/storage/database_opener.dart';
import 'package:test/test.dart';

void main() {
  late AppDatabase db;
  late HybridLogicalClock clock;
  late ProjectService service;
  late TaskService taskService;

  setUp(() {
    db = openMemoryDatabase();
    clock = HybridLogicalClock(nodeId: 'test-node');
    service = ProjectService(db: db, clock: clock);
    taskService = TaskService(db: db, clock: clock);
  });

  tearDown(() async {
    await db.close();
  });

  group('add', () {
    test('creates project with title and returns it', () async {
      final project = await service.add(title: 'Backend API');

      expect(project.id, isNotEmpty);
      expect(project.title, equals('Backend API'));
      expect(project.isArchived, isFalse);
      expect(project.createdTimestamp, isNotNull);
    });

    test('creates project with icon', () async {
      final project = await service.add(title: 'Frontend', icon: 'web');

      expect(project.icon, equals('web'));
    });

    test('persists project to database', () async {
      final project = await service.add(title: 'Persist me');

      final fetched = await service.show(project.id);
      expect(fetched.title, equals('Persist me'));
    });
  });

  group('list', () {
    test('returns active projects by default', () async {
      await service.add(title: 'Project 1');
      await service.add(title: 'Project 2');

      final projects = await service.list();

      expect(projects, hasLength(2));
    });

    test('excludes archived projects by default', () async {
      final project = await service.add(title: 'Will be archived');
      await service.add(title: 'Still active');

      // Archive the project
      project.isArchived = true;
      await db
          .into(db.projects)
          .insertOnConflictUpdate(project.toDriftCompanion());

      final projects = await service.list();

      expect(projects, hasLength(1));
      expect(projects.first.title, equals('Still active'));
    });

    test('includes archived projects with includeArchived', () async {
      final project = await service.add(title: 'Will be archived');
      await service.add(title: 'Still active');

      project.isArchived = true;
      await db
          .into(db.projects)
          .insertOnConflictUpdate(project.toDriftCompanion());

      final projects = await service.list(includeArchived: true);

      expect(projects, hasLength(2));
    });

    test('excludes deleted projects', () async {
      final project = await service.add(title: 'Will be deleted');
      await service.add(title: 'Still active');

      project.delete();
      await db
          .into(db.projects)
          .insertOnConflictUpdate(project.toDriftCompanion());

      final projects = await service.list(includeArchived: true);

      expect(projects, hasLength(1));
      expect(projects.first.title, equals('Still active'));
    });

    test('returns empty list when no projects', () async {
      final projects = await service.list();

      expect(projects, isEmpty);
    });
  });

  group('show', () {
    test('finds project by exact ID', () async {
      final created = await service.add(title: 'Find me');

      final found = await service.show(created.id);

      expect(found.id, equals(created.id));
      expect(found.title, equals('Find me'));
    });

    test('finds project by prefix', () async {
      final created = await service.add(title: 'Find by prefix');

      final found = await service.show(created.id.substring(0, 8));

      expect(found.id, equals(created.id));
    });

    test('throws ProjectNotFoundException for unknown ID', () async {
      expect(
        () => service.show('nonexistent-id'),
        throwsA(isA<ProjectNotFoundException>()),
      );
    });

    test('throws AmbiguousProjectIdException for ambiguous prefix', () async {
      await service.add(title: 'Project A');
      await service.add(title: 'Project B');

      // Empty prefix matches all
      expect(
        () => service.show(''),
        throwsA(isA<AmbiguousProjectIdException>()),
      );
    });
  });

  group('taskCount', () {
    test('returns count of active tasks for project', () async {
      final project = await service.add(title: 'My Project');
      await taskService.add(title: 'Task 1', projectId: project.id);
      await taskService.add(title: 'Task 2', projectId: project.id);

      final count = await service.taskCount(project.id);

      expect(count, equals(2));
    });

    test('excludes done tasks', () async {
      final project = await service.add(title: 'My Project');
      final task = await taskService.add(
          title: 'Will be done', projectId: project.id);
      await taskService.add(title: 'Still active', projectId: project.id);
      await taskService.done(task.id);

      final count = await service.taskCount(project.id);

      expect(count, equals(1));
    });

    test('returns 0 for project with no tasks', () async {
      final project = await service.add(title: 'Empty Project');

      final count = await service.taskCount(project.id);

      expect(count, equals(0));
    });
  });
}
