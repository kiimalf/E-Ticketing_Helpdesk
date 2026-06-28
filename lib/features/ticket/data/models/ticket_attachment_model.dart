class TicketAttachmentModel {
  final String id;
  final String ticketId;
  final String fileName;
  final String fileUrl;
  final String fileType;
  final int fileSize;
  final String uploadedBy;
  final DateTime uploadedAt;

  const TicketAttachmentModel({
    required this.id,
    required this.ticketId,
    required this.fileName,
    required this.fileUrl,
    required this.fileType,
    required this.fileSize,
    required this.uploadedBy,
    required this.uploadedAt,
  });

  bool get isImage => fileType == 'image';

  String get fileSizeLabel {
    if (fileSize < 1024) return '${fileSize}B';
    if (fileSize < 1024 * 1024)
      return '${(fileSize / 1024).toStringAsFixed(1)}KB';
    return '${(fileSize / (1024 * 1024)).toStringAsFixed(1)}MB';
  }

  factory TicketAttachmentModel.fromMap(Map<String, dynamic> map) {
    return TicketAttachmentModel(
      id: map['id'] as String,
      ticketId: map['ticket_id'] as String,
      fileName: map['file_name'] as String,
      fileUrl: map['file_url'] as String,
      fileType: (map['file_type'] as String?) ?? 'file',
      fileSize: (map['file_size'] as int?) ?? 0,
      uploadedBy: map['uploaded_by'] as String,
      uploadedAt: DateTime.parse(map['uploaded_at'] as String),
    );
  }

  Map<String, dynamic> toInsertMap() => {
    'ticket_id': ticketId,
    'file_name': fileName,
    'file_url': fileUrl,
    'file_type': fileType,
    'file_size': fileSize,
    'uploaded_by': uploadedBy,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TicketAttachmentModel && other.id == id);

  @override
  int get hashCode => id.hashCode;
}
