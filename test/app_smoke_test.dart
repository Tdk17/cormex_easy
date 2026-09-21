import 'package:cormex_easy/core/config/app_environment.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('o ambiente padrão mantém dados QA isolados da produção', () {
    final environment = AppEnvironment.fromDefines();

    expect(environment.flavor, AppFlavor.qa);
    expect(environment.useQaData, isTrue);
    expect(environment.hasApi, isFalse);
  });
}
