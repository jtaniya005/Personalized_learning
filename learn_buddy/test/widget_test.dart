import 'package:flutter_test/flutter_test.dart';
import 'package:learn_buddy_app/models/mock_data.dart';

void main() {
  test('LearnBuddy ChatMessage smoke test', () {
    const msg = ChatMessage('Hello Buddy', true, isVoice: true);
    expect(msg.text, 'Hello Buddy');
    expect(msg.isUser, true);
    expect(msg.isVoice, true);
  });
}
