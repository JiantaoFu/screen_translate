import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../providers/translation_provider.dart';
import '../services/llm_translation_service.dart';
import '../services/model_download_service.dart';
import '../services/onnx_translation_service.dart';

// ─── Language pack display data ───────────────────────────────────────────────

/// BCP-47 language code -> country flag emoji, for the source/target flags
/// shown on each language pack tile. Deriving this from the pair's own
/// source/target codes (rather than a manually-picked single flag per pack)
/// avoids the previous bug where some packs showed their source's flag and
/// others showed their target's — every pack now always shows both.
const Map<String, String> _kLanguageFlags = {
  'en': '🇺🇸',
  'zh': '🇨🇳',
  'ja': '🇯🇵',
  'ko': '🇰🇷',
  'th': '🇹🇭',
  'vi': '🇻🇳',
  'id': '🇮🇩',
  'de': '🇩🇪',
  'es': '🇪🇸',
  'fr': '🇫🇷',
  'ru': '🇷🇺',
  'pt': '🇧🇷',
};

String _flagFor(String bcp) => _kLanguageFlags[bcp] ?? '🏳️';

class _LanguagePack {
  final OnnxLangPair? pair;
  final OnnxPivotPair? pivot;

  const _LanguagePack({required OnnxLangPair pair})
      : pair = pair, pivot = null;
  const _LanguagePack.pivot({required OnnxPivotPair pivot})
      : pair = null, pivot = pivot;

  /// Stable identity used for status/progress tracking — the underlying
  /// pair's key, or a synthesized one for pivots (which have no model files
  /// of their own, just two hops).
  String get key => pair?.key ?? 'pivot:${pivot!.sourceBcp}-${pivot!.targetBcp}';
  String get displayName => pair?.displayName ?? pivot!.displayName;
  String get sourceBcp => pair?.sourceBcp ?? pivot!.sourceBcp;
  String get targetBcp => pair?.targetBcp ?? pivot!.targetBcp;
  String get sourceFlag => _flagFor(sourceBcp);
  String get targetFlag => _flagFor(targetBcp);
}

const _kLanguagePacks = [
  _LanguagePack(pair: OnnxLangPair(key: 'opus-mt-en-zh', sourceBcp: 'en', targetBcp: 'zh', displayName: 'English → Chinese')),
  _LanguagePack(pair: OnnxLangPair(key: 'opus-mt-zh-en', sourceBcp: 'zh', targetBcp: 'en', displayName: 'Chinese → English')),
  _LanguagePack(pair: OnnxLangPair(key: 'opus-mt-ja-en', sourceBcp: 'ja', targetBcp: 'en', displayName: 'Japanese → English')),
  _LanguagePack(pair: OnnxLangPair(key: 'opus-mt-ko-en', sourceBcp: 'ko', targetBcp: 'en', displayName: 'Korean → English', useFp16: true)),
  _LanguagePack(pair: OnnxLangPair(key: 'opus-mt-th-en', sourceBcp: 'th', targetBcp: 'en', displayName: 'Thai → English', useFp16: true)),
  _LanguagePack(pair: OnnxLangPair(key: 'opus-mt-vi-en', sourceBcp: 'vi', targetBcp: 'en', displayName: 'Vietnamese → English')),
  _LanguagePack(pair: OnnxLangPair(key: 'opus-mt-id-en', sourceBcp: 'id', targetBcp: 'en', displayName: 'Indonesian → English', useFp16: true)),
  _LanguagePack(pair: OnnxLangPair(key: 'opus-mt-de-en', sourceBcp: 'de', targetBcp: 'en', displayName: 'German → English')),
  _LanguagePack(pair: OnnxLangPair(key: 'opus-mt-es-en', sourceBcp: 'es', targetBcp: 'en', displayName: 'Spanish → English')),
  _LanguagePack(pair: OnnxLangPair(key: 'opus-mt-fr-en', sourceBcp: 'fr', targetBcp: 'en', displayName: 'French → English')),
  _LanguagePack(pair: OnnxLangPair(key: 'opus-mt-ru-en', sourceBcp: 'ru', targetBcp: 'en', displayName: 'Russian → English')),
  _LanguagePack(pair: OnnxLangPair(key: 'opus-mt-ja-es', sourceBcp: 'ja', targetBcp: 'es', displayName: 'Japanese → Spanish', customRepo: 'fuji246/small-translation')),
  _LanguagePack(pair: OnnxLangPair(key: 'opus-mt-en-es', sourceBcp: 'en', targetBcp: 'es', displayName: 'English → Spanish', customRepo: 'fuji246/small-translation')),
  _LanguagePack.pivot(
    pivot: OnnxPivotPair(
      sourceBcp: 'zh',
      targetBcp: 'es',
      displayName: 'Chinese → Spanish',
      firstHopKey: 'opus-mt-zh-en',
      secondHopKey: 'opus-mt-en-es',
    ),
  ),
  _LanguagePack(pair: OnnxLangPair(key: 'opus-mt-ja-pt', sourceBcp: 'ja', targetBcp: 'pt', displayName: 'Japanese → Portuguese', customRepo: 'fuji246/small-translation')),
  _LanguagePack(pair: OnnxLangPair(key: 'opus-mt-tc-big-en-pt', sourceBcp: 'en', targetBcp: 'pt', displayName: 'English → Portuguese', customRepo: 'fuji246/small-translation')),
  _LanguagePack.pivot(
    pivot: OnnxPivotPair(
      sourceBcp: 'zh',
      targetBcp: 'pt',
      displayName: 'Chinese → Portuguese',
      firstHopKey: 'opus-mt-zh-en',
      secondHopKey: 'opus-mt-tc-big-en-pt',
    ),
  ),
];

// ─── Screen ───────────────────────────────────────────────────────────────────

class TranslationSettingsScreen extends StatefulWidget {
  const TranslationSettingsScreen({Key? key}) : super(key: key);

  @override
  _TranslationSettingsScreenState createState() => _TranslationSettingsScreenState();
}

class _TranslationSettingsScreenState extends State<TranslationSettingsScreen>
    with WidgetsBindingObserver {
  final Map<String, OnnxModelStatus> _packStatus = {};
  final Map<String, double> _packProgress = {};

  /// Packs whose download this screen has already joined (via _downloadPack)
  /// — either because it started the download itself, or because it found
  /// one already in progress on refresh and attached to it for live
  /// progress. Guards against joining the same in-flight download twice.
  final Set<String> _joinedDownloads = {};

  /// Packs that were actively downloading at the moment the app went to
  /// background. Android closes the app's raw network sockets a few
  /// seconds after backgrounding a plain process with no foreground
  /// service (confirmed via logcat: ClientException "Connection closed
  /// while receiving data"), so these reliably end up in OnnxModelStatus
  /// .error shortly after — not from a real network problem, just from
  /// leaving the app. Recorded here so we can pick them back up
  /// automatically the moment the user returns instead of leaving a
  /// dead-end "Failed — tap Retry".
  final Set<String> _interruptedByBackground = {};

  /// Quick-mode (on-device Google ML Kit) per-language download state.
  /// ML Kit's downloadModel() reports no real progress at all, so
  /// _quickProgress is a simulated ramp (see _downloadQuickLang) purely for
  /// perceived feedback — it never claims 100% on its own, only once the
  /// real download actually completes, so it can't lie about being done.
  final Map<String, bool> _quickDownloaded = {};
  final Set<String> _quickDownloading = {};
  final Set<String> _quickError = {};
  final Map<String, double> _quickProgress = {};

  final _apiKeyController = TextEditingController();
  bool _isSavingApiKey = false;
  bool _apiKeyObscured = true;
  bool _showAdvanced = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refreshPackStatus();
    _refreshQuickStatus();
    _loadApiKey();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _apiKeyController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      for (final lp in _kLanguagePacks) {
        if (_packStatus[lp.key] == OnnxModelStatus.downloading) {
          _interruptedByBackground.add(lp.key);
        }
      }
    } else if (state == AppLifecycleState.resumed && _interruptedByBackground.isNotEmpty) {
      final toResume = _kLanguagePacks
          .where((lp) => _interruptedByBackground.contains(lp.key))
          .toList();
      _interruptedByBackground.clear();
      for (final lp in toResume) {
        _downloadPack(lp);
      }
    }
  }

  Future<void> _refreshPackStatus() async {
    final svc = ModelDownloadService();
    for (final lp in _kLanguagePacks) {
      final status = lp.pivot != null
          ? await svc.getOnnxPivotStatus(lp.pivot!)
          : await svc.getOnnxModelStatus(lp.pair!.key);
      // The user may have tapped Download on this exact pack while the
      // await above was in flight, in which case _downloadPack already
      // owns its state — applying this now-stale snapshot on top would
      // clobber the live "downloading" status it just set.
      if (_joinedDownloads.contains(lp.key)) continue;
      if (mounted) setState(() => _packStatus[lp.key] = status);
      // Someone else (e.g. the home screen's language picker) already
      // started this download — join it so this screen gets live progress
      // instead of sitting frozen at 0% until it happens to finish.
      if (status == OnnxModelStatus.downloading) {
        _downloadPack(lp);
      }
    }
  }

  Future<void> _refreshQuickStatus() async {
    final svc = ModelDownloadService();
    for (final code in TranslationProvider.supportedLanguages.keys) {
      final downloaded = await svc.isModelDownloaded(code);
      if (mounted) setState(() => _quickDownloaded[code] = downloaded);
    }
  }

  Future<void> _loadApiKey() async {
    final key = await LLMTranslationService.getStoredApiKey();
    if (key != null && mounted) _apiKeyController.text = key;
  }

  // ── Download / delete ────────────────────────────────────────────────────────

  Future<void> _downloadPack(_LanguagePack lp) async {
    _joinedDownloads.add(lp.key);
    setState(() {
      _packStatus[lp.key] = OnnxModelStatus.downloading;
      _packProgress[lp.key] = 0.0;
    });
    try {
      debugPrint('UI: Awaiting download for ${lp.key}...');
      final onProgress = (double p) {
        if (mounted) setState(() => _packProgress[lp.key] = p);
      };
      if (lp.pivot != null) {
        await ModelDownloadService().downloadOnnxPivot(lp.pivot!, onProgress: onProgress);
      } else {
        await ModelDownloadService().downloadOnnxModel(lp.pair!.key, onProgress: onProgress);
      }
      debugPrint('UI: Download completed for ${lp.key}, updating state to ready...');
      _joinedDownloads.remove(lp.key);
      if (mounted) {
        setState(() {
          _packStatus[lp.key] = OnnxModelStatus.ready;
          _packProgress.remove(lp.key);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${lp.displayName} is ready!'), backgroundColor: Colors.green),
        );
      }
    } catch (e, stack) {
      debugPrint('UI: Download failed for ${lp.key}: $e\n$stack');
      _joinedDownloads.remove(lp.key);
      if (mounted) {
        setState(() {
          _packStatus[lp.key] = OnnxModelStatus.error;
          _packProgress.remove(lp.key);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Download failed. Please check your connection.'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _deletePack(_LanguagePack lp) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Remove language pack?'),
        content: Text('Remove the offline AI pack for ${lp.displayName}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      if (lp.pivot != null) {
        // Only remove the second hop — the first hop (e.g. zh→en) may be
        // independently listed/used elsewhere and shouldn't be silently
        // deleted out from under that.
        await ModelDownloadService().deleteOnnxModel(lp.pivot!.secondHopKey);
      } else {
        await ModelDownloadService().deleteOnnxModel(lp.pair!.key);
      }
      await _refreshPackStatus();
    }
  }

  Future<void> _downloadQuickLang(String code) async {
    setState(() {
      _quickDownloading.add(code);
      _quickError.remove(code);
      _quickProgress[code] = 0.0;
    });
    // ML Kit's downloadModel() exposes no progress callback at all, so a
    // static "Downloading…" spinner can look identical whether it's 1
    // second or 60 seconds in. Simulate a ramp toward 90% instead — capped
    // well short of 100% so it never falsely claims completion — and jump
    // to the real 100% only once downloadModelWithFallback() actually
    // returns below.
    final ticker = Timer.periodic(const Duration(milliseconds: 250), (_) {
      final current = _quickProgress[code] ?? 0.0;
      if (current >= 0.9) return;
      if (mounted) setState(() => _quickProgress[code] = (current + 0.04).clamp(0.0, 0.9));
    });
    try {
      await ModelDownloadService().downloadModelWithFallback(code);
      ticker.cancel();
      if (mounted) {
        setState(() {
          _quickDownloaded[code] = true;
          _quickDownloading.remove(code);
          _quickProgress.remove(code);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${TranslationProvider.supportedLanguages[code] ?? code} is ready!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      ticker.cancel();
      if (mounted) {
        setState(() {
          _quickDownloading.remove(code);
          _quickError.add(code);
          _quickProgress.remove(code);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Download failed. Please check your connection.'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _deleteQuickLang(String code) async {
    final name = TranslationProvider.supportedLanguages[code] ?? code;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Remove language pack?'),
        content: Text('Remove the offline Quick-translation pack for $name?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    final success = await ModelDownloadService().deleteModel(code);
    if (mounted) {
      setState(() => _quickDownloaded[code] = !success);
      if (!success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to remove language pack.'), backgroundColor: Colors.red),
        );
      }
    }
  }

  // ── API Key ──────────────────────────────────────────────────────────────────

  Future<void> _saveApiKey() async {
    final key = _apiKeyController.text.trim();
    if (key.length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid API key.'), backgroundColor: Colors.red),
      );
      return;
    }
    setState(() => _isSavingApiKey = true);
    final svc = LLMTranslationService();
    await svc.saveApiKey(key);
    final valid = await svc.hasValidApiKey();
    if (!mounted) return;
    setState(() => _isSavingApiKey = false);
    if (valid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Connected! Cloud AI is ready.'), backgroundColor: Colors.green),
      );
      Provider.of<TranslationProvider>(context, listen: false).setTranslationMode(TranslationMode.llm);
    } else {
      await svc.clearApiKey();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid API key. Please check and try again.'), backgroundColor: Colors.red),
      );
    }
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // Build
  // ─────────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        title: const Text('Translation Settings'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: Consumer<TranslationProvider>(
        builder: (context, provider, _) {
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
            children: [
              _sectionLabel('TRANSLATION QUALITY'),
              const SizedBox(height: 10),

              // ── Quick ──────────────────────────────────────────────────────
              _modeCard(
                mode: TranslationMode.onDevice,
                selected: provider.translationMode == TranslationMode.onDevice,
                icon: Icons.flash_on_rounded,
                iconColor: const Color(0xFFFF8C00),
                title: 'Quick',
                subtitle: 'Instant · Always available · No setup needed',
                provider: provider,
              ),
              if (provider.translationMode == TranslationMode.onDevice)
                _quickLanguagePacksSection(),
              const SizedBox(height: 10),

              // ── AI Enhanced ────────────────────────────────────────────────
              _modeCard(
                mode: TranslationMode.onnx,
                selected: provider.translationMode == TranslationMode.onnx,
                icon: Icons.memory_rounded,
                iconColor: const Color(0xFF4F46E5),
                title: 'AI Enhanced',
                subtitle: 'Better quality · Works offline · Download a language pack',
                provider: provider,
              ),
              if (provider.translationMode == TranslationMode.onnx)
                _languagePacksSection(),

              const SizedBox(height: 10),

              // ── Cloud AI ────────────────────────────────────────────────────
              _modeCard(
                mode: TranslationMode.llm,
                selected: provider.translationMode == TranslationMode.llm,
                icon: Icons.cloud_rounded,
                iconColor: const Color(0xFF0D9488),
                title: 'Cloud AI',
                subtitle: 'Best quality · Requires internet · API key needed',
                provider: provider,
              ),
              if (provider.translationMode == TranslationMode.llm)
                _cloudAiSection(),

              const SizedBox(height: 32),
              _advancedSection(provider),
            ],
          );
        },
      ),
    );
  }

  // ── Mode card ────────────────────────────────────────────────────────────────

  Widget _modeCard({
    required TranslationMode mode,
    required bool selected,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required TranslationProvider provider,
  }) {
    return GestureDetector(
      onTap: () => provider.setTranslationMode(mode),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: selected
              ? const BorderRadius.only(
                  topLeft: Radius.circular(16), topRight: Radius.circular(16),
                  bottomLeft: Radius.circular(4), bottomRight: Radius.circular(4))
              : BorderRadius.circular(16),
          border: Border.all(
            color: selected ? iconColor.withOpacity(0.6) : Colors.transparent,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: selected ? iconColor.withOpacity(0.15) : Colors.black.withOpacity(0.05),
              blurRadius: selected ? 14 : 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
          child: Row(
            children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          color: selected ? iconColor : Colors.black87,
                        )),
                    const SizedBox(height: 3),
                    Text(subtitle,
                        style: TextStyle(fontSize: 12, color: Colors.grey[600], height: 1.3)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 22, height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: selected ? iconColor : Colors.grey.shade300, width: 2),
                  color: selected ? iconColor : Colors.transparent,
                ),
                child: selected
                    ? const Icon(Icons.check, color: Colors.white, size: 13)
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Language packs section ────────────────────────────────────────────────────

  Widget _languagePacksSection() {
    const indigo = Color(0xFF4F46E5);
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF0EFFF),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
        border: Border.all(color: indigo.withOpacity(0.3), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
            child: Row(
              children: const [
                Icon(Icons.download_for_offline_outlined, color: indigo, size: 16),
                SizedBox(width: 6),
                Text(
                  'Language Packs  ·  ~50 MB each',
                  style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: indigo),
                ),
              ],
            ),
          ),
          ..._kLanguagePacks.map(_buildPackTile),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildPackTile(_LanguagePack lp) {
    const indigo = Color(0xFF4F46E5);
    final status = _packStatus[lp.key] ?? OnnxModelStatus.notDownloaded;
    final progress = _packProgress[lp.key];
    final isReady = status == OnnxModelStatus.ready;
    final isDownloading = status == OnnxModelStatus.downloading;
    final isError = status == OnnxModelStatus.error;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Column(
          children: [
            Row(
              children: [
                Text(lp.sourceFlag, style: const TextStyle(fontSize: 18)),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 2),
                  child: Icon(Icons.arrow_forward, size: 12, color: Colors.grey),
                ),
                Text(lp.targetFlag, style: const TextStyle(fontSize: 18)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(lp.displayName,
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5)),
                      if (isDownloading)
                        Text('Downloading… ${((progress ?? 0) * 100).toStringAsFixed(0)}%',
                            style: const TextStyle(fontSize: 11, color: indigo))
                      else if (isReady)
                        Text('Ready to use',
                            style: TextStyle(fontSize: 11, color: Colors.green[600]))
                      else if (isError)
                        Text('Failed — tap Retry',
                            style: TextStyle(fontSize: 11, color: Colors.red[400])),
                    ],
                  ),
                ),
                if (isDownloading)
                  SizedBox(
                    width: 26, height: 26,
                    child: CircularProgressIndicator(
                      value: progress, strokeWidth: 2.5,
                      color: indigo,
                    ),
                  )
                else if (isReady)
                  GestureDetector(
                    onTap: () => _deletePack(lp),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.green.shade200),
                      ),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(Icons.check_circle_rounded, color: Colors.green[600], size: 14),
                        const SizedBox(width: 4),
                        Text('Ready',
                            style: TextStyle(color: Colors.green[700], fontSize: 12,
                                fontWeight: FontWeight.w600)),
                      ]),
                    ),
                  )
                else
                  GestureDetector(
                    onTap: () => _downloadPack(lp),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: isError ? Colors.red.shade600 : indigo,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(isError ? Icons.refresh : Icons.download_rounded,
                            color: Colors.white, size: 14),
                        const SizedBox(width: 4),
                        Text(isError ? 'Retry' : 'Download',
                            style: const TextStyle(color: Colors.white, fontSize: 12,
                                fontWeight: FontWeight.w600)),
                      ]),
                    ),
                  ),
              ],
            ),
            if (isDownloading && progress != null) ...[
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress, minHeight: 4,
                  backgroundColor: const Color(0xFFE0DFFF),
                  valueColor: const AlwaysStoppedAnimation(indigo),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ── Quick mode language packs section ─────────────────────────────────────────

  Widget _quickLanguagePacksSection() {
    const orange = Color(0xFFFF8C00);
    final codes = TranslationProvider.supportedLanguages.keys.toList();
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFFF5E9),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
        border: Border.all(color: orange.withOpacity(0.3), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
            child: Row(
              children: const [
                Icon(Icons.download_for_offline_outlined, color: orange, size: 16),
                SizedBox(width: 6),
                Text(
                  'Language Packs  ·  ~30 MB each',
                  style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: orange),
                ),
              ],
            ),
          ),
          ...codes.map(_buildQuickLangTile),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildQuickLangTile(String code) {
    const orange = Color(0xFFFF8C00);
    final isReady = _quickDownloaded[code] ?? false;
    final isDownloading = _quickDownloading.contains(code);
    final isError = _quickError.contains(code);
    final progress = _quickProgress[code];
    final name = TranslationProvider.supportedLanguages[code] ?? code;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            Text(_flagFor(code), style: const TextStyle(fontSize: 18)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5)),
                  if (isDownloading)
                    Text('Downloading… ${((progress ?? 0) * 100).toStringAsFixed(0)}%',
                        style: const TextStyle(fontSize: 11, color: orange))
                  else if (isError)
                    Text('Failed — tap Retry', style: TextStyle(fontSize: 11, color: Colors.red[400])),
                ],
              ),
            ),
            if (isDownloading)
              SizedBox(
                width: 26, height: 26,
                child: CircularProgressIndicator(value: progress, strokeWidth: 2.5, color: orange),
              )
            else if (isReady)
              GestureDetector(
                onTap: () => _deleteQuickLang(code),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.check_circle_rounded, color: Colors.green[600], size: 14),
                    const SizedBox(width: 4),
                    Text('Ready',
                        style: TextStyle(color: Colors.green[700], fontSize: 12,
                            fontWeight: FontWeight.w600)),
                  ]),
                ),
              )
            else
              GestureDetector(
                onTap: () => _downloadQuickLang(code),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: isError ? Colors.red.shade600 : orange,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(isError ? Icons.refresh : Icons.download_rounded,
                        color: Colors.white, size: 14),
                    const SizedBox(width: 4),
                    Text(isError ? 'Retry' : 'Download',
                        style: const TextStyle(color: Colors.white, fontSize: 12,
                            fontWeight: FontWeight.w600)),
                  ]),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ── Cloud AI section ──────────────────────────────────────────────────────────

  Widget _cloudAiSection() {
    const teal = Color(0xFF0D9488);
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFEFFEFD),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
        border: Border.all(color: teal.withOpacity(0.3), width: 1.5),
      ),
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Connect your AI account',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: teal)),
          const SizedBox(height: 4),
          RichText(
            text: TextSpan(
              style: TextStyle(fontSize: 12.5, color: Colors.grey[600], height: 1.4),
              children: [
                const TextSpan(text: 'Get a free API key from '),
                TextSpan(
                  text: 'BigModel.cn',
                  style: const TextStyle(color: teal, decoration: TextDecoration.underline),
                  recognizer: TapGestureRecognizer()
                    ..onTap = () => launchUrl(
                          Uri.parse('https://open.bigmodel.cn/'),
                          mode: LaunchMode.externalApplication,
                        ),
                ),
                const TextSpan(text: ' and paste it below.'),
              ],
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _apiKeyController,
            obscureText: _apiKeyObscured,
            decoration: InputDecoration(
              hintText: 'Paste your API key here',
              hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.teal.shade200),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.teal.shade200),
              ),
              focusedBorder: const OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(12)),
                borderSide: BorderSide(color: teal, width: 2),
              ),
              suffixIcon: IconButton(
                icon: Icon(_apiKeyObscured ? Icons.visibility_off : Icons.visibility,
                    color: Colors.grey[400], size: 20),
                onPressed: () => setState(() => _apiKeyObscured = !_apiKeyObscured),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSavingApiKey ? null : _saveApiKey,
              style: ElevatedButton.styleFrom(
                backgroundColor: teal,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: _isSavingApiKey
                  ? const SizedBox(
                      height: 18, width: 18,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Save & Verify',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
            ),
          ),
        ],
      ),
    );
  }

  // ── Advanced ─────────────────────────────────────────────────────────────────

  Widget _advancedSection(TranslationProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () => setState(() => _showAdvanced = !_showAdvanced),
          child: Row(
            children: [
              Text('Advanced',
                  style: TextStyle(
                      fontSize: 12.5, fontWeight: FontWeight.w600,
                      color: Colors.grey[400], letterSpacing: 0.4)),
              const SizedBox(width: 2),
              Icon(
                _showAdvanced ? Icons.expand_less : Icons.expand_more,
                size: 16, color: Colors.grey[400],
              ),
            ],
          ),
        ),
        if (_showAdvanced) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6, offset: const Offset(0, 2)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Text merge sensitivity',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14,
                        color: Colors.grey[800])),
                const SizedBox(height: 4),
                Text(
                  'Controls how nearby text blocks are grouped. Reduce if translation accuracy drops.',
                  style: TextStyle(fontSize: 12, color: Colors.grey[500], height: 1.4),
                ),
                Slider(
                  value: provider.mergeAggressiveness,
                  min: 0.0, max: 3.0, divisions: 30,
                  label: '${provider.mergeAggressiveness.toStringAsFixed(1)}×',
                  activeColor: Colors.blueGrey,
                  onChanged: provider.setMergeAggressiveness,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Precise', style: TextStyle(fontSize: 11, color: Colors.grey[400])),
                    Text('${provider.mergeAggressiveness.toStringAsFixed(1)}×',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                            color: Colors.blueGrey[600])),
                    Text('Aggressive', style: TextStyle(fontSize: 11, color: Colors.grey[400])),
                  ],
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  // ── Helper ───────────────────────────────────────────────────────────────────

  Widget _sectionLabel(String text) => Padding(
        padding: const EdgeInsets.only(left: 2),
        child: Text(text,
            style: TextStyle(
                fontSize: 11.5, fontWeight: FontWeight.w700,
                color: Colors.grey[500], letterSpacing: 0.8)),
      );
}
