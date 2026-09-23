import 'package:flutter_test/flutter_test.dart';

import 'package:alevi_client/app/app.dart';
import 'package:alevi_client/app/config/app_config.dart';
import 'package:alevi_client/app/services/api_client.dart';
import 'package:alevi_client/app/services/secure_storage.dart';

void main() {
  testWidgets('Alevi onboarding renders the 18+ safety message', (tester) async {
    await tester.pumpWidget(
      AleviApp(
        config: AppConfig.fromEnvironment(),
        apiClient: MockApiClient(),
        storage: InMemorySecureStorage(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Bağ kurmanın daha iyi yolu'), findsOneWidget);
    expect(find.textContaining('18+'), findsNothing);
  });
}
