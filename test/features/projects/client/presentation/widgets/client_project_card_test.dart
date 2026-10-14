import 'package:flutter_test/flutter_test.dart';
import 'package:watad/core/enums/project_status.dart';
import 'package:watad/core/utils/money.dart';
import 'package:watad/features/projects/client/domain/entities/client_project.dart';
import 'package:watad/features/projects/client/presentation/widgets/client_project_card.dart';

import '../../../../../helpers/pump_component.dart';

void main() {
  testWidgets('shows project card details for open project', (tester) async {
    var tapped = 0;
    final project = ClientProject(
      id: 'p1',
      title: 'Residential Villa',
      status: ProjectStatus.open,
      city: 'Riyadh',
      district: 'Al-Yasmin',
      budget: const Money.halalas(50000000),
      pendingOfferCount: 3,
      createdAt: DateTime.utc(2026, 10, 14),
    );

    await pumpComponent(
      tester,
      ClientProjectCard(project: project, onTap: () => tapped++),
    );

    expect(find.text('Residential Villa'), findsOneWidget);
    expect(find.text('Riyadh · Al-Yasmin'), findsOneWidget);
    expect(find.text('موثّق'), findsOneWidget);
    expect(find.text('\u0663 \u0639\u0631\u0648\u0636'), findsOneWidget);

    await tester.tap(find.text('\u0663 \u0639\u0631\u0648\u0636'));
    expect(tapped, 1);
  });

  testWidgets('shows under review status for draft project', (tester) async {
    final project = ClientProject(
      id: 'p2',
      title: 'House Renovation',
      status: ProjectStatus.draft,
      city: 'Jeddah',
      pendingOfferCount: 0,
      createdAt: DateTime.utc(2026, 10, 14),
    );

    await pumpComponent(tester, ClientProjectCard(project: project));

    expect(find.text('House Renovation'), findsOneWidget);
    expect(find.text('قيد المراجعة'), findsOneWidget);
    expect(
      find.text('المشروع قيد المراجعة وهو غير مرئي للمقاولين'),
      findsOneWidget,
    );
  });

  testWidgets('shows rejected status with reupload action', (tester) async {
    var reuploadCount = 0;
    final project = ClientProject(
      id: 'p3',
      title: 'Repairs',
      status: ProjectStatus.cancelled,
      deedStatus: 'rejected',
      rejectionReason: 'اسم المالك لا يطابق الهوية',
      city: 'Dammam',
      pendingOfferCount: 0,
      createdAt: DateTime.utc(2026, 10, 14),
    );

    await pumpComponent(
      tester,
      ClientProjectCard(
        project: project,
        onReuploadDeed: () => reuploadCount++,
      ),
    );

    expect(find.text('مرفوض'), findsOneWidget);
    expect(find.text('اسم المالك لا يطابق الهوية'), findsOneWidget);
    expect(find.text('إعادة الرفع'), findsOneWidget);

    await tester.tap(find.text('إعادة الرفع'));
    expect(reuploadCount, 1);
  });
}
