class AskResponse {
  final String question;
  final String reply;
  final String? audioBase64;
  final String ttsProvider;

  AskResponse({
    required this.question,
    required this.reply,
    this.audioBase64,
    required this.ttsProvider,
  });

  factory AskResponse.fromJson(Map<String, dynamic> json) {
    return AskResponse(
      question: json['question'] as String? ?? '',
      reply: json['reply'] as String? ?? '',
      audioBase64: json['audio_base64'] as String?,
      ttsProvider: json['tts_provider'] as String? ?? 'browser',
    );
  }
}

class ChatResponse {
  final String reply;
  final String? audioBase64;
  final String ttsProvider;

  ChatResponse({
    required this.reply,
    this.audioBase64,
    required this.ttsProvider,
  });

  factory ChatResponse.fromJson(Map<String, dynamic> json) {
    return ChatResponse(
      reply: json['reply'] as String? ?? '',
      audioBase64: json['audio_base64'] as String?,
      ttsProvider: json['tts_provider'] as String? ?? 'browser',
    );
  }
}

class ResetResponse {
  final bool ok;
  final String? sessionId;
  final String message;

  ResetResponse({
    required this.ok,
    this.sessionId,
    required this.message,
  });

  factory ResetResponse.fromJson(Map<String, dynamic> json) {
    return ResetResponse(
      ok: json['ok'] as bool? ?? false,
      sessionId: json['session_id'] as String?,
      message: json['message'] as String? ?? '',
    );
  }
}

class HealthResponse {
  final String status;
  final bool isHealthy;
  final Map<String, dynamic> raw;

  HealthResponse({
    required this.status,
    required this.isHealthy,
    required this.raw,
  });

  factory HealthResponse.fromJson(Map<String, dynamic> json) {
    final statusStr = (json['status'] as String? ?? '').toLowerCase();
    return HealthResponse(
      status: json['status'] as String? ?? 'unknown',
      isHealthy: statusStr == 'healthy' || statusStr == 'ok',
      raw: json,
    );
  }
}
