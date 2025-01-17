import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:screen_translate/providers/translation_provider.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Screen Translate'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Consumer<TranslationProvider>(
        builder: (context, provider, child) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () async {
                    try {
                      if (provider.isTranslating) {
                        provider.stopTranslation();
                      } else {
                        await provider.startTranslation();
                      }
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error: ${e.toString()}')),
                      );
                    }
                  },
                  child: Text(
                    provider.isTranslating ? 'Stop Translation' : 'Start Translation',
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  provider.isTranslating ? 'Translation Active' : 'Translation Inactive',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                if (provider.lastTranslatedText.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  const Text('Last Translation:'),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      provider.lastTranslatedText,
                      style: Theme.of(context).textTheme.bodyLarge,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}
