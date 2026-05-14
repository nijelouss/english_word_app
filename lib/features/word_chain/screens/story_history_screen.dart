import 'package:flutter/material.dart';
import 'package:english_word_app/features/word_chain/models/story.dart';
import 'package:english_word_app/database/database_helper.dart';
import 'package:english_word_app/features/word_chain/screens/story_result_screen.dart';

class StoryHistoryScreen extends StatefulWidget {
  const StoryHistoryScreen({super.key});

  @override
  State<StoryHistoryScreen> createState() => _StoryHistoryScreenState();
}

class _StoryHistoryScreenState extends State<StoryHistoryScreen> {
  late Future<List<Story>> _future;

  @override
  void initState() {
    super.initState();
    _future = DatabaseHelper.instance.getStories();
  }

  void _refresh() {
    setState(() {
      _future = DatabaseHelper.instance.getStories();
    });
  }

  Future<void> _delete(int id) async {
    await DatabaseHelper.instance.deleteStory(id);
    _refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Geçmiş Hikayelerim')),
      body: FutureBuilder<List<Story>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Henüz hikaye yok'));
          }

          final stories = snapshot.data!;

          return ListView.builder(
            itemCount: stories.length,
            itemBuilder: (context, index) {
              final story = stories[index];
              final preview = story.contentEN.length > 50
                  ? '${story.contentEN.substring(0, 50)}...'
                  : story.contentEN;

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => StoryResultScreen(story: story),
                    ),
                  ),
                  title: Text(preview),
                  subtitle: Text(story.createdAt.substring(0, 10)),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => _delete(story.id!),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
