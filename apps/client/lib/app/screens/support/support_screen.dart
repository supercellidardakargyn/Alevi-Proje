import 'package:flutter/material.dart';

import '../../services/api_client.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_widgets.dart';

class SupportScreen extends StatefulWidget {
  const SupportScreen({super.key, required this.apiClient});

  final ApiClientPort apiClient;

  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen> {
  List<Map<String, dynamic>> _tickets = const [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await widget.apiClient.get('/v1/support');
      final data = result['data'];
      final raw = (data is List ? data : const []).cast<Map<String, dynamic>>();
      if (!mounted) return;
      setState(() => _tickets = raw);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message ?? 'Talepler yüklenemedi');
    } catch (_) {
      if (mounted) setState(() => _error = 'Talepler yüklenemedi');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _create() async {
    final subjectController = TextEditingController();
    final bodyController = TextEditingController();
    final created = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Yeni destek talebi'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: subjectController, decoration: const InputDecoration(labelText: 'Konu')),
              const SizedBox(height: 12),
              TextField(controller: bodyController, maxLines: 4, decoration: const InputDecoration(labelText: 'Sorunu anlat (en az 10 karakter)')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Vazgeç')),
          FilledButton(
            onPressed: () async {
              if (subjectController.text.trim().length < 3 || bodyController.text.trim().length < 10) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Konu ve en az 10 karakter açıklama gerekli.')));
                return;
              }
              try {
                await widget.apiClient.post('/v1/support', body: {
                  'subject': subjectController.text.trim(),
                  'body': bodyController.text.trim(),
                },);
                if (context.mounted) Navigator.pop(context, true);
              } on ApiException catch (e) {
                if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message ?? 'Gönderilemedi')));
              } catch (_) {
                if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gönderilemedi')));
              }
            },
            child: const Text('Gönder'),
          ),
        ],
      ),
    );
    if (created == true) {
      _load();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Talebin alındı. Yanıtı buradan takip et.')));
    }
  }

  String _statusLabel(String status) {
    return switch (status) {
      'OPEN' => 'Açık',
      'ANSWERED' => 'Yanıtlandı',
      'CLOSED' => 'Kapandı',
      _ => status,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Destek talepleri')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _create,
        icon: const Icon(Icons.add),
        label: const Text('Yeni talep'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_error!, style: const TextStyle(color: AppColors.muted)),
                      TextButton(onPressed: _load, child: const Text('Tekrar dene')),
                    ],
                  ),
                )
              : _tickets.isEmpty
                  ? const EmptyState(
                      icon: Icons.support_agent_outlined,
                      title: 'Talebin yok',
                      body: 'Sorun yaşarsan buradan yaz, ekibimiz yanıtlasın.',
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(20),
                      itemCount: _tickets.length,
                      itemBuilder: (context, index) {
                        final ticket = _tickets[index];
                        final status = (ticket['status'] ?? '').toString();
                        final reply = (ticket['reply'] as String?) ?? '';
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(child: Text((ticket['subject'] ?? '').toString(), style: const TextStyle(fontWeight: FontWeight.w800))),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: status == 'OPEN' ? const Color(0xFFFBF0DC) : const Color(0xFFE4F2EB),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(_statusLabel(status), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text((ticket['body'] ?? '').toString(), style: const TextStyle(color: AppColors.muted)),
                                if (reply.isNotEmpty) ...[
                                  const SizedBox(height: 12),
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(color: const Color(0xFFE4F2EB), borderRadius: BorderRadius.circular(12)),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text('Destek yanıtı', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
                                        const SizedBox(height: 4),
                                        Text(reply),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        );
                      },
                    ),
    );
  }
}
