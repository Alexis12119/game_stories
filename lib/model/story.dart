class Story {
  final int id;
  final DateTime createdAt;
  final String storyTitle;

  Story({
    required this.id,
    required this.createdAt,
    required this.storyTitle,
  });

  factory Story.fromJson(Map<String, dynamic> json) {
    return Story(
      id: json['id'],
      createdAt: DateTime.parse(json['created_at']),
      storyTitle: json['story_title'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'created_at': createdAt.toIso8601String(),
      'story_title': storyTitle,
    };
  }

  @override
  String toString() {
    return 'Story(id: $id, createdAt: $createdAt, storyTitle: $storyTitle)';
  }
}
