import 'package:flutter/material.dart';

import '../../utils/app_theme.dart';

/// Diyet tercihleri, alerjiler, listelerim gibi metin listelerini
/// görüntüleme/düzenleme için kullanılan genel amaçlı ekran.
///
/// [editable] false ise (örn. "Geçmiş Siparişlerim") kullanıcı yalnızca
/// listeyi görüntüler, ekleme/silme yapamaz; çünkü bu veri kullanıcı
/// tarafından değil, sipariş akışı tarafından oluşturulur.
class EditableListScreen extends StatefulWidget {
  final String title;
  final String hintText;
  final List<String> initialItems;
  final bool editable;
  final Future<void> Function(List<String> updatedItems) onSave;

  const EditableListScreen({
    super.key,
    required this.title,
    required this.initialItems,
    required this.onSave,
    this.hintText = 'Yeni öğe ekle...',
    this.editable = true,
  });

  @override
  State<EditableListScreen> createState() => _EditableListScreenState();
}

class _EditableListScreenState extends State<EditableListScreen> {
  late List<String> _items;
  final _inputController = TextEditingController();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _items = List<String>.from(widget.initialItems);
  }

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  void _addItem() {
    final text = _inputController.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _items.add(text);
      _inputController.clear();
    });
  }

  void _removeItem(int index) {
    setState(() => _items.removeAt(index));
  }

  Future<void> _handleSave() async {
    setState(() => _isSaving = true);
    await widget.onSave(_items);
    if (!mounted) return;
    setState(() => _isSaving = false);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          if (widget.editable)
            TextButton(
              onPressed: _isSaving ? null : _handleSave,
              child: _isSaving
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Kaydet'),
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (widget.editable)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _inputController,
                        decoration: InputDecoration(hintText: widget.hintText),
                        onSubmitted: (_) => _addItem(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filled(
                      onPressed: _addItem,
                      icon: const Icon(Icons.add),
                    ),
                  ],
                ),
              ),
            Expanded(
              child: _items.isEmpty
                  ? const Center(
                      child: Text(
                        'Henüz eklenmiş bir öğe yok.',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: _items.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(
                            color: AppColors.sectionBackground,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              Expanded(child: Text(_items[index])),
                              if (widget.editable)
                                InkWell(
                                  onTap: () => _removeItem(index),
                                  child: const Icon(Icons.close,
                                      size: 20,
                                      color: AppColors.textSecondary),
                                ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
