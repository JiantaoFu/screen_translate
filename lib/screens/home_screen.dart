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
                Text(
                  provider.isChineseToEnglish 
                    ? '中文 → English'
                    : 'English → 中文',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 20),
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
                  child: Text(provider.isTranslating ? 'Stop' : 'Start'),
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: provider.switchTranslationDirection,
                  child: const Text('Switch Direction'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
