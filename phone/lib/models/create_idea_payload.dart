/// Payload for creating a new idea via the agent workflow API.
///
/// Fields match the `pa idea` CLI exactly (idea.ts in personal-assistant).
library;

class CreateIdeaPayload {
  final String title; // required
  final String category;
  final String effort;
  final String? what;
  final String? why;
  final String? who;
  final String? notes;
  final List<String> tags;

  const CreateIdeaPayload({
    required this.title,
    this.category = 'personal',
    this.effort = 'M',
    this.what,
    this.why,
    this.who,
    this.notes,
    this.tags = const [],
  });

  Map<String, dynamic> toJson() => {
        'title': title,
        'category': category,
        'effort': effort,
        if (what != null && what!.isNotEmpty) 'what': what,
        if (why != null && why!.isNotEmpty) 'why': why,
        if (who != null && who!.isNotEmpty) 'who': who,
        if (notes != null && notes!.isNotEmpty) 'notes': notes,
        if (tags.isNotEmpty) 'tags': tags,
      };
}
