class Notice {
  final String id;
  final String messageId;
  final String subject;
  final String from;
  final DateTime date;
  final String bodyText;
  final String bodyHtml;
  final String category;
  final List<Attachment> attachments;
  final bool isImportant;

  Notice({
    required this.id,
    required this.messageId,
    required this.subject,
    required this.from,
    required this.date,
    required this.bodyText,
    required this.bodyHtml,
    required this.category,
    required this.attachments,
    required this.isImportant,
  });

  factory Notice.fromJson(Map<String, dynamic> json) {
    return Notice(
      id: json['id'] ?? '',
      messageId: json['messageId'] ?? '',
      subject: json['subject'] ?? 'No Subject',
      from: json['from'] ?? '',
      date: json['date'] != null ? DateTime.parse(json['date']) : DateTime.now(),
      bodyText: json['bodyText'] ?? '',
      bodyHtml: json['bodyHtml'] ?? '',
      category: json['category'] ?? 'Academic',
      attachments: (json['attachments'] as List<dynamic>?)
              ?.map((item) => Attachment.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [],
      isImportant: json['isImportant'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'messageId': messageId,
      'subject': subject,
      'from': from,
      'date': date.toIso8601String(),
      'bodyText': bodyText,
      'bodyHtml': bodyHtml,
      'category': category,
      'attachments': attachments.map((x) => x.toJson()).toList(),
      'isImportant': isImportant,
    };
  }
}

class Attachment {
  final String name;
  final String url;
  final String mimeType;

  Attachment({
    required this.name,
    required this.url,
    required this.mimeType,
  });

  factory Attachment.fromJson(Map<String, dynamic> json) {
    return Attachment(
      name: json['name'] ?? '',
      url: json['url'] ?? '',
      mimeType: json['mimeType'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'url': url,
      'mimeType': mimeType,
    };
  }
}
