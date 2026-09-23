
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../services/api_client.dart';
import '../../widgets/app_widgets.dart';

class ProfileEditScreen extends StatefulWidget {
  const ProfileEditScreen({super.key, required this.apiClient});

  final ApiClientPort apiClient;

  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _bioController = TextEditingController();
  final _cityController = TextEditingController();
  bool _loading = true;
  bool _saving = false;
  bool _uploading = false;
  String? _avatarUrl;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final result = await widget.apiClient.get('/v1/profile/me');
      final data = result['data'];
      if (data is Map && mounted) {
        _nameController.text = (data['displayName'] ?? '').toString();
        _bioController.text = (data['bio'] ?? '').toString();
        _cityController.text = (data['city'] ?? '').toString();
        _avatarUrl = data['avatarUrl']?.toString();
      }
    } catch (_) {
      // Cevrimdisi modda bos form.
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _pickAvatar() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 1024, imageQuality: 85);
    if (picked == null) return;
    setState(() => _uploading = true);
    try {
      final bytes = await picked.readAsBytes();
      final result = await widget.apiClient.upload('/v1/profile/avatar', 'avatar', bytes, 'avatar.jpg');
      final data = result['data'];
      final url = (data is Map ? data['avatarUrl']?.toString() : null);
      if (!mounted) return;
      if (url == null || url.isEmpty) throw const ApiException(502, 'Yükleme başarısız');
      setState(() => _avatarUrl = url);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profil fotoğrafın güncellendi.')));
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message ?? 'Yükleme başarısız')));
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Yükleme başarısız')));
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _saving) return;
    setState(() => _saving = true);
    try {
      await widget.apiClient.patch('/v1/profile/me', body: {
        'displayName': _nameController.text.trim(),
        'bio': _bioController.text.trim().isEmpty ? null : _bioController.text.trim(),
        'city': _cityController.text.trim().isEmpty ? null : _cityController.text.trim(),
      },);
      if (!mounted) return;
      Navigator.of(context).pop(true);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profilin kaydedildi.')));
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message ?? 'Kaydedilemedi')));
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Kaydedilemedi')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profili düzenle')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      GestureDetector(
                        onTap: _uploading ? null : _pickAvatar,
                        child: Semantics(
                          button: true,
                          label: 'Profil fotoğrafı seç',
                          child: _avatarUrl != null && _avatarUrl!.isNotEmpty
                              ? AvatarCircle(name: _nameController.text, size: 96, online: false, avatarUrl: _avatarUrl)
                              : Stack(
                                alignment: Alignment.center,
                                children: [
                                  AvatarCircle(name: _nameController.text, size: 96, online: false),
                                  Container(
                                    width: 96,
                                    height: 96,
                                    decoration: BoxDecoration(color: Colors.black38, borderRadius: BorderRadius.circular(48)),
                                    child: _uploading
                                        ? const CircularProgressIndicator(color: Colors.white)
                                        : const Icon(Icons.camera_alt, color: Colors.white, size: 30),
                                  ),
                                ],
                              ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextButton(onPressed: _uploading ? null : _pickAvatar, child: const Text('Fotoğraf seç')),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(labelText: 'Görünen ad'),
                        validator: (value) => value == null || value.trim().length < 2 ? 'En az 2 karakter.' : null,
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _cityController,
                        decoration: const InputDecoration(labelText: 'Şehir', prefixIcon: Icon(Icons.location_on_outlined)),
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _bioController,
                        maxLines: 4,
                        maxLength: 500,
                        decoration: const InputDecoration(labelText: 'Hakkında', hintText: 'Kendini kısaca tanıt...'),
                      ),
                      const SizedBox(height: 20),
                      PrimaryButton(label: _saving ? 'Kaydediliyor…' : 'Kaydet', onPressed: _saving ? null : _save),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}
