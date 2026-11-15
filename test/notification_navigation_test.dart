import 'package:flutter_test/flutter_test.dart';
import 'package:viplens/services/notification_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() {
    NotificationService.setReviewNavigationHandler(null);
  });

  test('review notification dispatches the review navigation handler', () {
    var openedReview = false;
    NotificationService.setReviewNavigationHandler(() => openedReview = true);

    NotificationService.handleNotificationPayload('review');

    expect(openedReview, isTrue);
  });

  testWidgets('queues a review notification received during cold start', (
    tester,
  ) async {
    var openedReview = false;
    NotificationService.handleNotificationPayload('review');
    NotificationService.setReviewNavigationHandler(() => openedReview = true);

    await tester.pump();

    expect(openedReview, isTrue);
  });

  test('unknown notification payload does not open the review screen', () {
    var openedReview = false;
    NotificationService.setReviewNavigationHandler(() => openedReview = true);

    NotificationService.handleNotificationPayload('unknown');

    expect(openedReview, isFalse);
  });
}
