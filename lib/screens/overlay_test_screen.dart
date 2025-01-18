import 'package:flutter/material.dart';
import '../services/overlay_service.dart';

class OverlayTestScreen extends StatefulWidget {
  const OverlayTestScreen({super.key});

  @override
  State<OverlayTestScreen> createState() => _OverlayTestScreenState();
}

class _OverlayTestScreenState extends State<OverlayTestScreen> with WidgetsBindingObserver {
  final OverlayService _overlayService = OverlayService();
  bool _hasPermission = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkPermission();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkPermission();
    }
  }

  Future<void> _checkPermission() async {
    final hasPermission = await _overlayService.checkOverlayPermission();
    if (mounted) {
      setState(() {
        _hasPermission = hasPermission;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Overlay Test'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Overlay Permission: ${_hasPermission ? "Granted" : "Not Granted"}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                await _overlayService.requestOverlayPermission();
              },
              child: const Text('Request Overlay Permission'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _hasPermission
                  ? () {
                      _overlayService.showTranslationOverlay('Test Translation Overlay');
                    }
                  : null,
              child: const Text('Show Overlay'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _hasPermission
                  ? () {
                      _overlayService.hideTranslationOverlay();
                    }
                  : null,
              child: const Text('Hide Overlay'),
            ),
          ],
        ),
      ),
    );
  }
}
