import 'package:flutter_test/flutter_test.dart';
import 'package:voice_assistant_app/models/chat_message.dart';

void main() {
  test('ChatMessage serialization test', () {
    final msg = ChatMessage(
      text: 'Hello assistant',
      sender: MessageSender.user,
      isVoice: true,
    );

    expect(msg.text, 'Hello assistant');
    expect(msg.isUser, true);
    expect(msg.isVoice, true);

    final json = msg.toJson();
    final deserialized = ChatMessage.fromJson(json);
    expect(deserialized.text, 'Hello assistant');
    expect(deserialized.isUser, true);
    expect(deserialized.isVoice, true);
  });
}
