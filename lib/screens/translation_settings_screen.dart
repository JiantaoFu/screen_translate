import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../providers/translation_provider.dart';
import '../services/llm_translation_service.dart';
import '../services/model_download_service.dart';
import '../services/onnx_translation_service.dart';

// ─── Language pack display data ───────────────────────────────────────────────

class _LanguagePack {
  final OnnxLangPair pair;
  final String flag;
  const _LanguagePack({required this.pair, required this.flag});
}

const _kLanguagePacks = [
  _LanguagePack(pair: OnnxLangPair(key: 'opus-mt-en-zh', sourceBcp: 'en', targetBcp: 'zh', displayName: 'English → Chinese'), flag: '🇨🇳'),
  _LanguagePack(pair: OnnxLangPair(key: 'opus-mt-zh-en', sourceBcp: 'zh', targetBcp: 'en', displayName: 'Chinese → English'), flag: '🇨🇳'),
  _LanguagePack(pair: OnnxLangPair(key: 'opus-mt-ja-en', sourceBcp: 'ja', targetBcp: 'en', displayName: 'Japanese → English'), flag: '🇯🇵'),
  _LanguagePack(pair: OnnxLangPair(key: 'opus-mt-ko-en', sourceBcp: 'ko', targetBcp: 'en', displayName: 'Korean → English', useFp16: true), flag: '🇰🇷'),
  _LanguagePack(pair: OnnxLangPair(key: 'opus-mt-th-en', sourceBcp: 'th', targetBcp: 'en', displayName: 'Thai → English', useFp16: true), flag: '🇹🇭'),
  _LanguagePack(pair: OnnxLangPair(key: 'opus-mt-vi-en', sourceBcp: 'vi', targetBcp: 'en', displayName: 'Vietnamese → English'), flag: '🇻🇳'),
  _LanguagePack(pair: OnnxLangPair(key: 'opus-mt-id-en', sourceBcp: 'id', targetBcp: 'en', displayName: 'Indonesian → English', useFp16: true), flag: '🇮🇩'),
  _LanguagePack(pair: OnnxLangPair(key: 'opus-mt-de-en', sourceBcp: 'de', targetBcp: 'en', displayName: 'German → English'), flag: '🇩🇪'),
  _LanguagePack(pair: OnnxLangPair(key: 'opus-mt-es-en', sourceBcp: 'es', targetBcp: 'en', displayName: 'Spanish → English'), flag: '🇪🇸'),
  _LanguagePack(pair: OnnxLangPair(key: 'opus-mt-fr-en', sourceBcp: 'fr', targetBcp: 'en', displayName: 'French → English'), flag: '🇫🇷'),
  _LanguagePack(pair: OnnxLangPair(key: 'opus-mt-ru-en', sourceBcp: 'ru', targetBcp: 'en', displayName: 'Russian → English'), flag: '🇷🇺'),
];

// ─── Screen ───────────────────────────────────────────────────────────────────

class TranslationSettingsScreen extends StatefulWidget {
  const TranslationSettingsScreen({Key? key}) : super(key: key);

  @override
  _TranslationSettingsScreenState createState() => _TranslationSettingsScreenState();
}

class _TranslationSettingsScreenState extends State<TranslationSettingsScreen> {
  final Map<String, OnnxModelStatus> _packStatus = {};
  final Map<String, double> _packProgress = {};

  final _apiKeyController = TextEditingController();
  bool _isSavingApiKey = false;
  bool _apiKeyObscured = true;
  bool _showAdvanced = false;

  @override
  void initState() {
    super.initState();
    _refreshPackStatus();
    _loadApiKey();
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    super.dispose();
  }

  Future<void> _refreshPackStatus() async {
    final svc = ModelDownloadService();
    for (final lp in _kLanguagePacks) {
      final status = await svc.getOnnxModelStatus(lp.pair.key);
      if (mounted) setState(() => _packStatus[lp.pair.key] = status);
    }
  }

  Future<void> _loadApiKey() async {
    final key = await LLMTranslationService.getStoredApiKey();
    if (key != null && mounted) _apiKeyController.text = key;
  }

  // ── Download / delete ────────────────────────────────────────────────────────

  Future<void> _downloadPack(_LanguagePack lp) async {
    setState(() {
      _packStatus[lp.pair.key] = OnnxModelStatus.downloading;
      _packProgress[lp.pair.key] = 0.0;
    });
    try {
      debugPrint('UI: Awaiting download for ${lp.pair.key}...');
      await ModelDownloadService().downloadOnnxModel(
        lp.pair.key,
        onProgress: (p) {
          if (mounted) setState(() => _packProgress[lp.pair.key] = p);
        },
      );
      debugPrint('UI: Download completed for ${lp.pair.key}, updating state to ready...');
      if (mounted) {
        setState(() {
          _packStatus[lp.pair.key] = OnnxModelStatus.ready;
          _packProgress.remove(lp.pair.key);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${lp.pair.displayName} is ready!'), backgroundColor: Colors.green),
        );
      }
    } catch (e, stack) {
      debugPrint('UI: Download failed for ${lp.pair.key}: $e\n$stack');
      if (mounted) {
        setState(() {
          _packStatus[lp.pair.key] = OnnxModelStatus.error;
          _packProgress.remove(lp.pair.key);
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
        content: Text('Remove the offline AI pack for ${lp.pair.displayName}?'),
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
      await ModelDownloadService().deleteOnnxModel(lp.pair.key);
      await _refreshPackStatus();
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
    final status = _packStatus[lp.pair.key] ?? OnnxModelStatus.notDownloaded;
    final progress = _packProgress[lp.pair.key];
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
                Text(lp.flag, style: const TextStyle(fontSize: 20)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(lp.pair.displayName,
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
