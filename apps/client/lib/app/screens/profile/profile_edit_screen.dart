
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../services/api_client.dart';
import '../../services/session.dart';
import '../../theme/app_theme.dart';
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
  final _districtController = TextEditingController();
  final _interestController = TextEditingController();
  List<String> _interests = const [];
  List<String> _photos = const [];
  bool _loading = true;
  bool _saving = false;
  bool _uploading = false;
  bool _galleryBusy = false;
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
    _districtController.dispose();
    _interestController.dispose();
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
        _districtController.text = (data['district'] ?? '').toString();
        _avatarUrl = data['avatarUrl']?.toString();
        final tags = (data['interests'] as List? ?? const []).map((tag) => tag.toString()).toList();
        final photos = (data['photos'] as List? ?? const []).map((url) => url.toString()).where((url) => url.isNotEmpty).toList();
        setState(() {
          _interests = tags;
          _photos = photos;
        });
      }
    } catch (_) {
      // Cevrimdisi modda bos form.
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _addInterest() {
    final tag = _interestController.text.trim();
    if (tag.isEmpty || _interests.length >= 10 || _interests.contains(tag)) return;
    setState(() {
      _interests = [..._interests, tag];
      _interestController.clear();
    });
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

  Future<void> _addPhoto() async {
    if (_photos.length >= 6) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('En fazla 6 fotoğraf ekleyebilirsin.')));
      return;
    }
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 1024, imageQuality: 85);
    if (picked == null) return;
    setState(() => _galleryBusy = true);
    try {
      final bytes = await picked.readAsBytes();
      final result = await widget.apiClient.upload('/v1/media/profile/photos', 'photo', bytes, 'photo.jpg');
      final data = result['data'];
      final photos = (data is Map ? data['photos'] as List? : null)?.map((url) => url.toString()).toList();
      if (!mounted) return;
      if (photos == null) throw const ApiException(502, 'Yükleme başarısız');
      setState(() => _photos = photos);
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message ?? 'Yükleme başarısız')));
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Yükleme başarısız')));
    } finally {
      if (mounted) setState(() => _galleryBusy = false);
    }
  }

  Future<void> _removePhoto(String url) async {
    setState(() => _galleryBusy = true);
    try {
      final result = await widget.apiClient.delete('/v1/media/profile/photos', body: {'url': url});
      final data = result['data'];
      final photos = (data is Map ? data['photos'] as List? : null)?.map((item) => item.toString()).toList();
      if (!mounted) return;
      setState(() => _photos = photos ?? _photos.where((item) => item != url).toList());
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Silinemedi.')));
    } finally {
      if (mounted) setState(() => _galleryBusy = false);
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
        'district': _districtController.text.trim().isEmpty ? null : _districtController.text.trim(),
        'interests': _interests,
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
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text('Galeri (en fazla 6)', style: TextStyle(fontWeight: FontWeight.w700)),
                      ),
                      const SizedBox(height: 8),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: 8, mainAxisSpacing: 8),
                        itemCount: _photos.length >= 6 ? _photos.length : _photos.length + 1,
                        itemBuilder: (context, index) {
                          if (index >= _photos.length) {
                            return GestureDetector(
                              onTap: _galleryBusy ? null : _addPhoto,
                              child: Container(
                                decoration: BoxDecoration(color: Colors.black12, borderRadius: BorderRadius.circular(12)),
                                child: _galleryBusy
                                    ? const Center(child: CircularProgressIndicator())
                                    : const Icon(Icons.add_a_photo_outlined, color: AppColors.burgundy, size: 30),
                              ),
                            );
                          }
                          final url = _photos[index];
                          final resolved = Session.resolveAvatar(url);
                          return Stack(
                            fit: StackFit.expand,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: resolved == null
                                    ? const ColoredBox(color: Colors.black12)
                                    : Image.network(resolved, headers: Session.authHeaders, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const ColoredBox(color: Colors.black12)),
                              ),
                              Positioned(
                                top: 2,
                                right: 2,
                                child: GestureDetector(
                                  onTap: _galleryBusy ? null : () => _removePhoto(url),
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                                    child: const Icon(Icons.close, color: Colors.white, size: 16),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
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
                        controller: _districtController,
                        decoration: const InputDecoration(labelText: 'İlçe (opsiyonel)', prefixIcon: Icon(Icons.map_outlined)),
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _bioController,
                        maxLines: 4,
                        maxLength: 500,
                        decoration: const InputDecoration(labelText: 'Hakkında (beğenmek için en az 20 karakter gerekli)', hintText: 'Kendini kısaca tanıt...'),
                      ),
                      const SizedBox(height: 14),
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text('İlgi alanların (en fazla 10)', style: TextStyle(fontWeight: FontWeight.w700)),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final tag in _interests)
                            Chip(
                              label: Text(tag),
                              deleteIcon: const Icon(Icons.close, size: 16),
                              onDeleted: () => setState(() => _interests = _interests.where((item) => item != tag).toList()),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _interestController,
                              textInputAction: TextInputAction.done,
                              onSubmitted: (_) => _addInterest(),
                              decoration: const InputDecoration(labelText: 'Yeni ilgi alanı ekle', hintText: 'örn. Bağlama'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton.filled(onPressed: _addInterest, icon: const Icon(Icons.add), tooltip: 'Ekle'),
                        ],
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
