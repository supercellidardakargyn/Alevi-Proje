import 'package:flutter/material.dart';

import '../app/services/api_client.dart';
import '../app/theme/app_theme.dart';
import '../app/widgets/app_widgets.dart';

/// Destek talebi detayi: kullanici mesaji, yapay zeka taslagi, yanit + kapatma.
class TicketDetailScreen extends StatefulWidget {
  const TicketDetailScreen({super.key, required this.apiClient, required this.ticket});

  final ApiClientPort apiClient;
  final Map<String, dynamic> ticket;

  @override
  State<TicketDetailScreen> createState() => _TicketDetailScreenState();
}

class _TicketDetailScreenState extends State<TicketDetailScreen> {
  final _replyController = TextEditingController();
  bool _busy = false;
  late Map<String, dynamic> _ticket;

  @override
  void initState() {
    super.initState();
    _ticket = Map<String, dynamic>.from(widget.ticket);
    final draft = (_ticket['aiDraft'] ?? '').toString();
    if (draft.isNotEmpty) _replyController.text = draft;
  }

  @override
  void dispose() {
    _replyController.dispose();
    super.dispose();
  }

  Future<void> _reply() async {
    final message = _replyController.text.trim();
    if (message.isEmpty || _busy) return;
    setState(() => _busy = true);
    try {
      final result = await widget.apiClient.post("/v1/admin/tickets/${_ticket['id']}/reply", body: {'message': message});
      final data = result['data'];
      if (!mounted) return;
      setState(() => _ticket = (data is Map ? data : _ticket).cast<String, dynamic>());
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Yanıt gönderildi.')));
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message ?? 'Gönderilemedi')));
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gönderilemedi')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _close() async {
    setState(() => _busy = true);
    try {
      final result = await widget.apiClient.post("/v1/admin/tickets/${_ticket['id']}/close");
      final data = result['data'];
      if (!mounted) return;
      setState(() => _ticket = (data is Map ? data : _ticket).cast<String, dynamic>());
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Talep kapatıldı.')));
      Navigator.of(context).maybePop();
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message ?? 'Kapatılamadı (önce yanıtlayın)')));
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Kapatılamadı')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = (_ticket['user'] as Map?) ?? const {};
    final draft = (_ticket['aiDraft'] ?? '').toString();
    final reply = (_ticket['reply'] ?? '').toString();
    final status = (_ticket['status'] ?? '').toString();
    return Scaffold(
      appBar: AppBar(title: const Text('Destek talebi')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text((_ticket['subject'] ?? '').toString(), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  Text('${(user['displayName'] ?? 'Üye')} · $status', style: TextStyle(color: AppInk.subtle, fontSize: 12)),
                  const SizedBox(height: 12),
                  Text((_ticket['body'] ?? '').toString(), style: const TextStyle(height: 1.4)),
                ],
              ),
            ),
          ),
          if (draft.isNotEmpty) ...[
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('YAPAY ZEKA TASLAĞI', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppInk.subtle)),
                    const SizedBox(height: 6),
                    Text(draft, style: const TextStyle(height: 1.4)),
                  ],
                ),
              ),
            ),
          ],
          if (reply.isNotEmpty) ...[
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('GÖNDERİLEN YANIT', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppInk.subtle)),
                    const SizedBox(height: 6),
                    Text(reply, style: const TextStyle(height: 1.4)),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 16),
          TextField(
            controller: _replyController,
            maxLines: 5,
            decoration: const InputDecoration(labelText: 'Yanıt yazın…', hintText: 'Kullanıcıya yanıt'),
          ),
          const SizedBox(height: 12),
          PrimaryButton(label: _busy ? 'Gönderiliyor…' : 'Yanıtı gönder', onPressed: _busy ? null : _reply),
          const SizedBox(height: 10),
          OutlinedButton(
            onPressed: _busy ? null : _close,
            style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(50), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
            child: const Text('Talebi kapat'),
          ),
        ],
      ),
    );
  }
}
