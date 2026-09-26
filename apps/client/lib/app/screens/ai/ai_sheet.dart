import 'package:flutter/material.dart';

import '../../services/api_client.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_widgets.dart';
import 'ai_service.dart';

/// Ortak alt sayfa: baslik, ipucu metni, icerik ve kapat dugmesi.
class AiSheet extends StatefulWidget {
  const AiSheet({
    super.key,
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  static Future<T?> show<T>(BuildContext context, {required WidgetBuilder builder}) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: builder,
    );
  }

  @override
  State<AiSheet> createState() => _AiSheetState();
}

class _AiSheetState extends State<AiSheet> {
  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.62,
      minChildSize: 0.35,
      maxChildSize: 0.94,
      builder: (context, controller) => Column(
        children: [
          const SizedBox(height: 8),
          Container(width: 42, height: 4, decoration: BoxDecoration(color: AppInk.divider, borderRadius: BorderRadius.circular(2))),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 12, 4),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
                      const SizedBox(height: 3),
                      Text(widget.subtitle, style: TextStyle(fontSize: 12, color: AppInk.subtle)),
                    ],
                  ),
                ),
                IconButton(onPressed: () => Navigator.of(context).pop(), icon: const Icon(Icons.close), tooltip: 'Kapat'),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: SingleChildScrollView(
              controller: controller,
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
              child: widget.child,
            ),
          ),
        ],
      ),
    );
  }
}

/// Bio duzeltme + buz kirici onerisi (profil ekranindan acilir).
Future<void> showBioCoachSheet(BuildContext context, {required ApiClientPort apiClient, required TextEditingController controller}) {
  return AiSheet.show(
    context,
    builder: (context) => _BioCoachSheet(apiClient: apiClient, controller: controller),
  );
}

class _BioCoachSheet extends StatefulWidget {
  const _BioCoachSheet({required this.apiClient, required this.controller});

  final ApiClientPort apiClient;
  final TextEditingController controller;

  @override
  State<_BioCoachSheet> createState() => _BioCoachSheetState();
}

class _BioCoachSheetState extends State<_BioCoachSheet> {
  bool _busy = false;
  String? _result;
  bool _applied = false;

  Future<void> _run() async {
    setState(() {
      _busy = true;
      _result = null;
      _applied = false;
    });
    final suggestion = await AiService(widget.apiClient).coachBio(widget.controller.text.trim());
    if (!mounted) return;
    setState(() {
      _busy = false;
      _result = suggestion ?? 'Şu an öneri üretilemedi. Kendi cümlelerinle yazmayı dene.';
    });
  }

  void _apply() {
    final text = _result;
    if (text == null) return;
    final firstLine = text.split('\n').firstWhere((line) => line.trim().isNotEmpty, orElse: () => '').trim();
    if (firstLine.isEmpty) return;
    widget.controller.text = firstLine;
    setState(() => _applied = true);
  }

  @override
  Widget build(BuildContext context) {
    return AiSheet(
      title: 'Bana yardım et',
      subtitle: 'Bio’nu düzeltelim ve buz kırıcı cümleler bulalım',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PrimaryButton(
            label: _busy ? 'Düşünüyor…' : 'Öneri getir',
            onPressed: _busy ? null : _run,
          ),
          if (_busy) ...[
            const SizedBox(height: 16),
            const LinearProgressIndicator(),
          ],
          if (_result != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(_result!, style: const TextStyle(height: 1.45)),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: PrimaryButton(
                    label: _applied ? 'Uygulandı' : 'Bio olarak kullan',
                    onPressed: _applied ? null : _apply,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 18),
          Text(
            'Not: Öneriler yapay zekâ üretir. Kendi cümlelerinle yazmak her zaman daha samimi görünür.',
            style: TextStyle(fontSize: 12, color: AppInk.subtle),
          ),
        ],
      ),
    );
  }
}

/// Sohbet icin 3 akilli yanit onerisi.
Future<void> showSmartRepliesSheet(BuildContext context, {required ApiClientPort apiClient, required String conversationId, required void Function(String text) onPick}) {
  return AiSheet.show(
    context,
    builder: (context) => _SmartRepliesSheet(apiClient: apiClient, conversationId: conversationId, onPick: onPick),
  );
}

class _SmartRepliesSheet extends StatefulWidget {
  const _SmartRepliesSheet({required this.apiClient, required this.conversationId, required this.onPick});

  final ApiClientPort apiClient;
  final String conversationId;
  final void Function(String text) onPick;

  @override
  State<_SmartRepliesSheet> createState() => _SmartRepliesSheetState();
}

class _SmartRepliesSheetState extends State<_SmartRepliesSheet> {
  List<String> _suggestions = const [];
  bool _busy = true;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _busy = true);
    final list = await AiService(widget.apiClient).smartReplies(widget.conversationId);
    if (!mounted) return;
    setState(() {
      _suggestions = list;
      _busy = false;
      _loaded = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AiSheet(
      title: 'Akıllı yanıtlar',
      subtitle: 'Son mesajına göre hazır cevaplar',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_busy) const LinearProgressIndicator(),
          if (_loaded && !_busy && _suggestions.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text('Şu an öneri üretilemedi.', style: TextStyle(color: AppInk.subtle)),
              ),
            ),
          for (final suggestion in _suggestions)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Material(
                color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(14),
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () {
                    widget.onPick(suggestion);
                    Navigator.of(context).pop();
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        Expanded(child: Text(suggestion, style: const TextStyle(height: 1.35))),
                        const SizedBox(width: 10),
                        const Icon(Icons.send, size: 18),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          if (_loaded) ...[
            const SizedBox(height: 4),
            TextButton(onPressed: _load, child: const Text('Yenile')),
          ],
        ],
      ),
    );
  }
}

/// Sohbet ozeti.
Future<void> showSummarySheet(BuildContext context, {required ApiClientPort apiClient, required String conversationId}) {
  return AiSheet.show(
    context,
    builder: (context) => _SummarySheet(apiClient: apiClient, conversationId: conversationId),
  );
}

class _SummarySheet extends StatefulWidget {
  const _SummarySheet({required this.apiClient, required this.conversationId});

  final ApiClientPort apiClient;
  final String conversationId;

  @override
  State<_SummarySheet> createState() => _SummarySheetState();
}

class _SummarySheetState extends State<_SummarySheet> {
  bool _busy = true;
  String? _summary;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _busy = true);
    final summary = await AiService(widget.apiClient).summarize(widget.conversationId);
    if (!mounted) return;
    setState(() {
      _summary = summary;
      _busy = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AiSheet(
      title: 'Sohbet özeti',
      subtitle: 'Konuşmanın kısa özeti',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_busy) const LinearProgressIndicator(),
          if (_summary != null) ...[
            const SizedBox(height: 16),
            Text(_summary!, style: const TextStyle(height: 1.5, fontSize: 15)),
          ],
          if (!_busy) ...[
            const SizedBox(height: 16),
            OutlinedButton(onPressed: _load, child: const Text('Yeniden özetle')),
          ],
        ],
      ),
    );
  }
}

/// Profil sayfasinda gosterilen "neden eslestiniz" notu.
class MatchNoteText extends StatefulWidget {
  const MatchNoteText({super.key, required this.apiClient, required this.userId});

  final ApiClientPort apiClient;
  final String userId;

  @override
  State<MatchNoteText> createState() => _MatchNoteTextState();
}

class _MatchNoteTextState extends State<MatchNoteText> {
  String? _note;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _busy = true);
    final note = await AiService(widget.apiClient).matchNote(widget.userId);
    if (!mounted) return;
    setState(() {
      _note = note;
      _busy = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_busy) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 6),
        child: LinearProgressIndicator(minHeight: 2),
      );
    }
    final note = _note;
    if (note == null || note.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.burgundy.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.burgundy.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          const Icon(Icons.auto_awesome, size: 18, color: AppColors.burgundy),
          const SizedBox(width: 8),
          Expanded(child: Text(note, style: const TextStyle(height: 1.35))),
        ],
      ),
    );
  }
}

/// Profil sayfasindan acilan buz kirici onerileri.
Future<void> showIcebreakerSheet(BuildContext context, {required ApiClientPort apiClient, required String userId, required String displayName, required void Function(String text) onPick}) {
  return AiSheet.show(
    context,
    builder: (context) => _IcebreakerSheet(apiClient: apiClient, userId: userId, displayName: displayName, onPick: onPick),
  );
}

class _IcebreakerSheet extends StatefulWidget {
  const _IcebreakerSheet({required this.apiClient, required this.userId, required this.displayName, required this.onPick});

  final ApiClientPort apiClient;
  final String userId;
  final String displayName;
  final void Function(String text) onPick;

  @override
  State<_IcebreakerSheet> createState() => _IcebreakerSheetState();
}

class _IcebreakerSheetState extends State<_IcebreakerSheet> {
  List<String> _openers = const [];
  bool _busy = true;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _busy = true);
    final list = await AiService(widget.apiClient).icebreakers(widget.userId);
    if (!mounted) return;
    setState(() {
      _openers = list;
      _busy = false;
      _loaded = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AiSheet(
      title: '${widget.displayName} için ilk mesaj',
      subtitle: 'Buz kırıcı önerileri',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_busy) const LinearProgressIndicator(),
          if (_loaded && !_busy && _openers.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(child: Text('Öneri üretilemedi.', style: TextStyle(color: AppInk.subtle))),
            ),
          for (final opener in _openers)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Material(
                color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(14),
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () {
                    widget.onPick(opener);
                    Navigator.of(context).pop();
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        Expanded(child: Text(opener, style: const TextStyle(height: 1.35))),
                        const SizedBox(width: 10),
                        const Icon(Icons.waving_hand, size: 18),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
