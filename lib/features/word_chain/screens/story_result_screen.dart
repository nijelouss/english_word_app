import 'dart:io';
import 'package:flutter/material.dart';
import 'package:english_word_app/features/word_chain/models/story.dart';
import 'package:english_word_app/features/word_chain/screens/story_history_screen.dart';

class StoryResultScreen extends StatelessWidget {
  final Story story;

  const StoryResultScreen({super.key, required this.story});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Hikayen')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Görsel
            story.imagePath != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(
                      File(story.imagePath!),
                      width: double.infinity,
                      height: 200,
                      fit: BoxFit.cover,
                    ),
                  )
                : Container(
                    width: double.infinity,
                    height: 200,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.image,
                      size: 64,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
            const SizedBox(height: 24),

            // Hikaye metni
            if (story.displayMode == 'EN' || story.displayMode == 'EN+TR') ...[
              Text(story.contentEN),
              const SizedBox(height: 16),
            ],
            if (story.displayMode == 'EN+TR') ...[
              const Divider(),
              const SizedBox(height: 8),
            ],
            if ((story.displayMode == 'TR' || story.displayMode == 'EN+TR') &&
                story.contentTR != null) ...[
              Text(story.contentTR!),
              const SizedBox(height: 24),
            ],

            // Kullanılan kelimeler
            Wrap(
              spacing: 8,
              children: story.wordList
                  .split(', ')
                  .map((word) => Chip(label: Text(word)))
                  .toList(),
            ),
            const SizedBox(height: 24),

            // Butonlar
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const StoryHistoryScreen(),
                  ),
                ),
                child: const Text('Geçmiş Hikayeler'),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Yeni Hikaye'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
