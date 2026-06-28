import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:eticketing_helpdesk/core/constants/app_constants.dart';
import 'package:eticketing_helpdesk/core/theme/app_theme.dart';
import 'package:eticketing_helpdesk/core/widgets/app_widgets.dart';
import 'package:eticketing_helpdesk/features/ticket/presentation/providers/ticket_provider.dart';

class CreateTicketPage extends ConsumerStatefulWidget {
  const CreateTicketPage({super.key});

  @override
  ConsumerState<CreateTicketPage> createState() => _CreateTicketPageState();
}

class _CreateTicketPageState extends ConsumerState<CreateTicketPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _picker = ImagePicker();

  TicketPriority _priority = TicketPriority.medium;
  String? _category;
  final List<File> _attachments = [];

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  // ─── Ambil foto dari kamera ─────────────────────────────────
  Future<void> _pickCamera() async {
    final xf = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 80,
    );
    if (xf != null) setState(() => _attachments.add(File(xf.path)));
  }

  // ─── Pilih foto dari galeri ─────────────────────────────────
  Future<void> _pickGallery() async {
    final xf = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (xf != null) setState(() => _attachments.add(File(xf.path)));
  }

  // ─── Pilih file (PDF, DOC, dll) ─────────────────────────────
  Future<void> _pickFile() async {
    // ignore: undefined_getter
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx', 'xls', 'xlsx', 'txt'],
    );
    if (result?.files.single.path != null) {
      setState(() => _attachments.add(File(result!.files.single.path!)));
    }
  }

  void _showAttachmentSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Tambah Lampiran',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            _attachOption(
              icon: Icons.camera_alt_rounded,
              color: AppColors.primary,
              label: 'Ambil Foto (Kamera)',
              sub: 'Foto langsung dari kamera',
              onTap: () {
                Navigator.pop(context);
                _pickCamera();
              },
            ),
            _attachOption(
              icon: Icons.photo_library_rounded,
              color: AppColors.statusOpen,
              label: 'Pilih dari Galeri',
              sub: 'Gambar tersimpan di galeri',
              onTap: () {
                Navigator.pop(context);
                _pickGallery();
              },
            ),
            _attachOption(
              icon: Icons.attach_file_rounded,
              color: AppColors.statusInProgress,
              label: 'Pilih File',
              sub: 'PDF, DOC, XLS, dll',
              onTap: () {
                Navigator.pop(context);
                _pickFile();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _attachOption({
    required IconData icon,
    required Color color,
    required String label,
    required String sub,
    required VoidCallback onTap,
  }) => ListTile(
    leading: Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, color: color),
    ),
    title: Text(label),
    subtitle: Text(sub),
    onTap: onTap,
  );

  Future<void> _onSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_category == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pilih kategori terlebih dahulu'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final ok = await ref
        .read(createTicketProvider.notifier)
        .submit(
          title: _titleCtrl.text.trim(),
          description: _descCtrl.text.trim(),
          priority: _priority,
          category: _category!,
          attachments: _attachments,
        );

    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Tiket berhasil dibuat!'),
          backgroundColor: AppColors.statusResolved,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      Navigator.pop(context);
    } else {
      final err = ref.read(createTicketProvider).error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            err?.toString().replaceAll('Exception: ', '') ??
                'Gagal membuat tiket',
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLoading = ref.watch(createTicketProvider).isLoading;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Buat Tiket Baru'),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Judul ────────────────────────────────────
              Text('Judul Masalah *', style: theme.textTheme.titleSmall),
              const SizedBox(height: 8),
              TextFormField(
                controller: _titleCtrl,
                decoration: const InputDecoration(
                  hintText: 'Deskripsikan masalah secara singkat...',
                  prefixIcon: Icon(Icons.title_rounded),
                ),
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'Judul wajib diisi' : null,
              ),
              const SizedBox(height: 20),

              // ── Kategori ──────────────────────────────────
              Text('Kategori *', style: theme.textTheme.titleSmall),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: _category,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.category_outlined),
                  hintText: 'Pilih kategori',
                ),
                items: kTicketCategories
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (v) => setState(() => _category = v),
                validator: (v) => v == null ? 'Pilih kategori' : null,
              ),
              const SizedBox(height: 20),

              // ── Prioritas ─────────────────────────────────
              Text('Prioritas *', style: theme.textTheme.titleSmall),
              const SizedBox(height: 10),
              Row(
                children: TicketPriority.values.map((p) {
                  final color = switch (p) {
                    TicketPriority.low => AppColors.priorityLow,
                    TicketPriority.medium => AppColors.priorityMedium,
                    TicketPriority.high => AppColors.priorityHigh,
                    TicketPriority.critical => AppColors.priorityCritical,
                  };
                  final sel = _priority == p;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _priority = p),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: sel
                              ? color.withValues(alpha: 0.15)
                              : Colors.transparent,
                          border: Border.all(
                            color: sel ? color : theme.dividerColor,
                            width: sel ? 2 : 1,
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              p.label,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: sel
                                    ? FontWeight.w700
                                    : FontWeight.normal,
                                color: sel
                                    ? color
                                    : theme.textTheme.bodySmall?.color,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),

              // ── Deskripsi ─────────────────────────────────
              Text('Deskripsi *', style: theme.textTheme.titleSmall),
              const SizedBox(height: 8),
              TextFormField(
                controller: _descCtrl,
                maxLines: 6,
                decoration: const InputDecoration(
                  hintText:
                      'Jelaskan masalah secara detail...\n\n• Kapan masalah terjadi\n• Error yang muncul\n• Sudah dicoba apa',
                  alignLabelWithHint: true,
                ),
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'Deskripsi wajib diisi' : null,
              ),
              const SizedBox(height: 20),

              // ── Lampiran ──────────────────────────────────
              Text('Lampiran', style: theme.textTheme.titleSmall),
              const SizedBox(height: 8),

              // Preview
              if (_attachments.isNotEmpty) ...[
                SizedBox(
                  height: 90,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _attachments.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 8),
                    itemBuilder: (_, i) {
                      final file = _attachments[i];
                      final isImg = [
                        '.jpg',
                        '.jpeg',
                        '.png',
                        '.webp',
                      ].any((e) => file.path.toLowerCase().endsWith(e));
                      return Stack(
                        children: [
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: theme.dividerColor.withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: theme.dividerColor),
                              image: isImg
                                  ? DecorationImage(
                                      image: FileImage(file),
                                      fit: BoxFit.cover,
                                    )
                                  : null,
                            ),
                            child: !isImg
                                ? const Center(
                                    child: Icon(
                                      Icons.insert_drive_file_rounded,
                                      size: 32,
                                      color: AppColors.primary,
                                    ),
                                  )
                                : null,
                          ),
                          Positioned(
                            top: 2,
                            right: 2,
                            child: GestureDetector(
                              onTap: () =>
                                  setState(() => _attachments.removeAt(i)),
                              child: Container(
                                width: 20,
                                height: 20,
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.close_rounded,
                                  size: 12,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                const SizedBox(height: 8),
              ],

              OutlinedButton.icon(
                onPressed: _showAttachmentSheet,
                icon: const Icon(Icons.attach_file_rounded),
                label: const Text('Tambah Lampiran'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 46),
                ),
              ),

              const SizedBox(height: 32),
              LoadingButton(
                label: 'Kirim Tiket',
                isLoading: isLoading,
                onPressed: _onSubmit,
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
