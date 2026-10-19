import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:watad/features/projects/client/datasource/remote/client_projects_remote_data_source.dart';
import 'package:watad/features/projects/client/domain/entities/client_new_project.dart';

void main() {
  group('ClientProjectsRemoteDataSourceImpl', () {
    late SupabaseClient fakeClient;
    late ClientProjectsRemoteDataSourceImpl dataSource;

    setUp(() {
      fakeClient = SupabaseClient('https://example.supabase.co', 'anon_key');
      dataSource = ClientProjectsRemoteDataSourceImpl(fakeClient);
    });

    test('createProject throws FileSystemException when photo file does not exist on device', () async {
      const project = ClientNewProject(
        title: 'Villa Construction',
        city: 'Riyadh',
        photos: ['/non/existent/path/photo_123.jpg'],
      );

      expect(
        () => dataSource.createProject(project),
        throwsA(
          isA<FileSystemException>().having(
            (e) => e.message,
            'message',
            'Project photo not found on device',
          ),
        ),
      );
    });

    test('createProject throws FileSystemException when deed file does not exist on device', () async {
      const project = ClientNewProject(
        title: 'Villa Construction',
        city: 'Riyadh',
        deedFilePath: '/non/existent/path/deed_123.pdf',
      );

      expect(
        () => dataSource.createProject(project),
        throwsA(
          isA<FileSystemException>().having(
            (e) => e.message,
            'message',
            'Project ownership deed file not found on device',
          ),
        ),
      );
    });
  });
}
