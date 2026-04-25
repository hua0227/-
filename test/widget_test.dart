import 'package:flutter_test/flutter_test.dart';
import 'package:physics_experiment_platform/src/repository/experiment_repository.dart';
import 'package:physics_experiment_platform/src/ui/virtual_physics_app.dart';

void main() {
  testWidgets('shows the virtual experiment library', (tester) async {
    await tester.pumpWidget(
      VirtualPhysicsApp(
        repository: ExperimentRepository(persistenceEnabled: false),
      ),
    );
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('物理实验虚仿平台'), findsOneWidget);
    expect(find.textContaining('毛细管电泳'), findsWidgets);
    expect(find.text('导入 .pexp'), findsOneWidget);
  });
}
