library;

enum DocumentType { pdf, epub }

enum DocumentParseStatus { pending, parsing, ready, failed, ocrRequired }

class AgentDocument {
  const AgentDocument({
    required this.id,
    required this.workspaceId,
    required this.displayName,
    required this.sourceUri,
    required this.localPath,
    required this.type,
    required this.fileSize,
    required this.contentHash,
    required this.createdAt,
    required this.updatedAt,
    this.mimeType = '',
    this.title = '',
    this.author = '',
    this.language = '',
    this.pageCount = 0,
    this.sectionCount = 0,
    this.parseStatus = DocumentParseStatus.pending,
    this.parseError,
    this.lastSectionIndex,
  });

  final String id;
  final String workspaceId;
  final String displayName;
  final String sourceUri;
  final String localPath;
  final DocumentType type;
  final String mimeType;
  final int fileSize;
  final String contentHash;
  final String title;
  final String author;
  final String language;
  final int pageCount;
  final int sectionCount;
  final DocumentParseStatus parseStatus;
  final String? parseError;

  /// Last-read section index for position persistence (DOC-07).
  final int? lastSectionIndex;
  final DateTime createdAt;
  final DateTime updatedAt;

  AgentDocument copyWith({
    String? displayName,
    String? localPath,
    String? mimeType,
    int? fileSize,
    String? contentHash,
    String? title,
    String? author,
    String? language,
    int? pageCount,
    int? sectionCount,
    DocumentParseStatus? parseStatus,
    String? parseError,
    bool clearParseError = false,
    int? lastSectionIndex,
    bool clearLastSectionIndex = false,
    DateTime? updatedAt,
  }) => AgentDocument(
    id: id,
    workspaceId: workspaceId,
    displayName: displayName ?? this.displayName,
    sourceUri: sourceUri,
    localPath: localPath ?? this.localPath,
    type: type,
    mimeType: mimeType ?? this.mimeType,
    fileSize: fileSize ?? this.fileSize,
    contentHash: contentHash ?? this.contentHash,
    title: title ?? this.title,
    author: author ?? this.author,
    language: language ?? this.language,
    pageCount: pageCount ?? this.pageCount,
    sectionCount: sectionCount ?? this.sectionCount,
    parseStatus: parseStatus ?? this.parseStatus,
    parseError: clearParseError ? null : parseError ?? this.parseError,
    lastSectionIndex: clearLastSectionIndex
        ? null
        : (lastSectionIndex ?? this.lastSectionIndex),
    createdAt: createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
}

class DocumentSection {
  const DocumentSection({
    required this.id,
    required this.documentId,
    required this.index,
    required this.kind,
    required this.locator,
    required this.plainText,
    this.parentSectionId,
    this.title = '',
    this.metadata = const <String, dynamic>{},
  });

  final String id;
  final String documentId;
  final int index;
  final String? parentSectionId;
  final String kind;
  final String title;
  final String locator;
  final String plainText;
  final Map<String, dynamic> metadata;

  int get charCount => plainText.length;
}
