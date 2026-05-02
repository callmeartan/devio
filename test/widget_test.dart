import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:devio/blocs/auth/auth_cubit.dart';
import 'package:devio/models/chat_message.dart';
import 'package:devio/repositories/chat_repository.dart';

void main() {
  test('local-first auth starts with an authenticated local session', () {
    final authCubit = AuthCubit();

    expect(authCubit.state.toString(), contains('AuthState.authenticated'));
    expect(authCubit.state.toString(), contains(AuthCubit.localUserId));

    authCubit.close();
  });

  test('chat repository persists messages without a remote user account',
      () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final repository = ChatRepository(prefs: prefs);

    await repository.sendMessage(
      ChatMessage.create(
        chatId: 'local-chat',
        senderId: AuthCubit.localUserId,
        content: 'Hello from local mode',
        isAI: false,
      ),
    );

    final histories = await repository.getChatHistories();

    expect(histories, hasLength(1));
    expect(histories.single['id'], 'local-chat');
    expect(histories.single['title'], 'Hello from local...');

    repository.dispose();
  });
}
