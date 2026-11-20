import 'package:uuid/uuid.dart';

enum MessageSender { user, assistant, system }

enum MessageStatus { sending, sent, error }

class VoiceChatMessage {
  final String id;
  final String text;
  final MessageSender sender;
  final DateTime timestamp;
  final MessageStatus status;
  final bool isVoice;
  final String? audioBase64;
  final String? ttsProvider;
  final String? errorMessage;

  VoiceChatMessage({
    String? id,
    required this.text,
    required this.sender,
    DateTime? timestamp,
    this.status = MessageStatus.sent,
    this.isVoice = false,
    this.audioBase64,
    this.ttsProvider,
    this.errorMessage,
  })  : id = id ?? const Uuid().v4(),
        timestamp = timestamp ?? DateTime.now();

  bool get isUser => sender == MessageSender.user;
  bool get isAssistant => sender == MessageSender.assistant;
  bool get isSystem => sender == MessageSender.system;

  VoiceChatMessage copyWith({
    String? id,
    String? text,
    MessageSender? sender,
    DateTime? timestamp,
    MessageStatus? status,
    bool? isVoice,
    String? audioBase64,
    String? ttsProvider,
    String? errorMessage,
  }) {
    return VoiceChatMessage(
      id: id ?? this.id,
      text: text ?? this.text,
      sender: sender ?? this.sender,
      timestamp: timestamp ?? this.timestamp,
      status: status ?? this.status,
      isVoice: isVoice ?? this.isVoice,
      audioBase64: audioBase64 ?? this.audioBase64,
      ttsProvider: ttsProvider ?? this.ttsProvider,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'text': text,
        'sender': sender.name,
        'timestamp': timestamp.toIso8601String(),
        'status': status.name,
        'isVoice': isVoice,
        'audioBase64': audioBase64,
        'ttsProvider': ttsProvider,
        'errorMessage': errorMessage,
      };

  factory VoiceChatMessage.fromJson(Map<String, dynamic> json) => VoiceChatMessage(
        id: json['id'] as String?,
        text: json['text'] as String? ?? '',
        sender: MessageSender.values.firstWhere(
          (e) => e.name == json['sender'],
          orElse: () => MessageSender.assistant,
        ),
        timestamp: json['timestamp'] != null
            ? DateTime.tryParse(json['timestamp'] as String) ?? DateTime.now()
            : DateTime.now(),
        status: MessageStatus.values.firstWhere(
          (e) => e.name == json['status'],
          orElse: () => MessageStatus.sent,
        ),
        isVoice: json['isVoice'] as bool? ?? false,
        audioBase64: json['audioBase64'] as String?,
        ttsProvider: json['ttsProvider'] as String?,
        errorMessage: json['errorMessage'] as String?,
      );
}
