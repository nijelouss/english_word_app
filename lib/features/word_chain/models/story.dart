class Story {
  final int? id;
  final String contentEN;
  final String? contentTR;
  final String? imagePath;
  final String wordList;
  final String wordIDs;
  final String displayMode;
  final String createdAt;

  Story({
    this.id,
    required this.contentEN,
    this.contentTR,
    this.imagePath,
    required this.wordList,
    required this.wordIDs,
    this.displayMode = 'both',
    required this.createdAt,
  });

  factory Story.fromMap(Map<String, dynamic> map) {
    return Story(
      id: map['StoryID'] as int?,
      contentEN: map['ContentEN'] as String,
      contentTR: map['ContentTR'] as String?,
      imagePath: map['ImagePath'] as String?,
      wordList: map['WordList'] as String,
      wordIDs: map['WordIDs'] as String,
      displayMode: (map['DisplayMode'] as String?) ?? 'both',
      createdAt: map['CreatedAt'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'StoryID': id,
      'ContentEN': contentEN,
      'ContentTR': contentTR,
      'ImagePath': imagePath,
      'WordList': wordList,
      'WordIDs': wordIDs,
      'DisplayMode': displayMode,
      'CreatedAt': createdAt,
    };
  }
}
