import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/post_provider.dart';
import '../models/models.dart';

class PostFormScreen extends StatefulWidget {
  final Post? post;
  const PostFormScreen({super.key, this.post});

  @override
  State<PostFormScreen> createState() => _PostFormScreenState();
}

class _PostFormScreenState extends State<PostFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  final _titleFocusNode = FocusNode();
  final _bodyFocusNode = FocusNode();

  int _selectedUserId = 1;
  bool _isLoading = false;

  bool get _isEditing => widget.post != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      _titleController.text = widget.post!.title;
      _bodyController.text = widget.post!.body;
      _selectedUserId = widget.post!.userId;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    _titleFocusNode.dispose();
    _bodyFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isEditing ? 'Edit Post' : 'Create Post',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22, color: Colors.white),
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _savePost,
            child: Text(
              'Save',
              style: TextStyle(
                color: _isLoading ? Colors.white54 : Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _headerCard(),
              const SizedBox(height: 16),
              _userSelection(),
              const SizedBox(height: 16),
              _titleField(),
              const SizedBox(height: 16),
              _bodyField(),
              const SizedBox(height: 32),
              _actionButtons(),
            ],
          ),
        ),
      ),
    );
  }

  // ---------- PANELS ----------

  Widget _glassPanel({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [Color(0xFF1E1E1E), Color(0xCC2A2A2A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: const [BoxShadow(color: Color(0x4D000000), blurRadius: 15, offset: Offset(0, 5))],
      ),
      child: child,
    );
  }

  Widget _sectionTitle(IconData icon, String text, {bool required = false}) {
    return Row(
      children: [
        Icon(icon, color: Colors.white70, size: 20),
        const SizedBox(width: 8),
        Text(text, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
        if (required) const Text(' *', style: TextStyle(color: Colors.red)),
      ],
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0x80FFFFFF)),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0x1AFFFFFF)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0x1AFFFFFF)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color.fromARGB(255, 0, 21, 255), width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red, width: 2),
      ),
      filled: true,
      fillColor: const Color(0x0DFFFFFF),
      contentPadding: const EdgeInsets.all(16),
    );
  }

  // ---------- SECTIONS ----------

  Widget _headerCard() {
    return _glassPanel(
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: const Color(0x37001555), borderRadius: BorderRadius.circular(12)),
            child: Icon(_isEditing ? Icons.edit_rounded : Icons.add_rounded, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(
                _isEditing ? 'Edit Your Post' : 'Create New Post',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              Text(
                _isEditing ? 'Update the content of your post' : 'Share your thoughts with the world',
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _userSelection() {
    return Consumer<PostProvider>(
      builder: (_, provider, __) {
        final users = provider.users;
        return _glassPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionTitle(Icons.person_rounded, 'Author'),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0x1AFFFFFF)),
                  borderRadius: BorderRadius.circular(12),
                  color: const Color(0x0DFFFFFF),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    value: _selectedUserId,
                    isExpanded: true,
                    dropdownColor: const Color(0xFF1E1E1E),
                    onChanged: (v) => setState(() => _selectedUserId = v ?? _selectedUserId),
                    items: (users.isNotEmpty
                            ? users
                            : [User(id: _selectedUserId, name: 'User #$_selectedUserId', username: 'user', email: 'user@example.com')])
                        .map((u) => DropdownMenuItem<int>(
                              value: u.id,
                              child: Row(
                                children: [
                                  Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(8),
                                      color: const Color(0x37001555),
                                    ),
                                    child: CircleAvatar(
                                      radius: 16,
                                      backgroundColor: Colors.transparent,
                                      child: Text(
                                        u.name.substring(0, 1).toUpperCase(),
                                        style: const TextStyle(
                                            color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(u.name, style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.white)),
                                        Text('@${u.username}', style: const TextStyle(color: Colors.white60, fontSize: 12)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ))
                        .toList(),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _titleField() {
    return _glassPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(Icons.title_rounded, 'Title', required: true),
          const SizedBox(height: 16),
          TextFormField(
            controller: _titleController,
            focusNode: _titleFocusNode,
            style: const TextStyle(color: Colors.white),
            decoration: _inputDecoration('Enter post title...'),
            validator: (v) {
              final value = v?.trim() ?? '';
              if (value.isEmpty) return 'Title is required';
              if (value.length < 3) return 'Title must be at least 3 characters long';
              if (value.length > 100) return 'Title must be less than 100 characters';
              return null;
            },
            textInputAction: TextInputAction.next,
            onFieldSubmitted: (_) => FocusScope.of(context).requestFocus(_bodyFocusNode),
          ),
        ],
      ),
    );
  }

  Widget _bodyField() {
    return _glassPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(Icons.article_rounded, 'Content', required: true),
          const SizedBox(height: 16),
          TextFormField(
            controller: _bodyController,
            focusNode: _bodyFocusNode,
            maxLines: 8,
            style: const TextStyle(color: Colors.white),
            decoration: _inputDecoration('Write your post content here...'),
            validator: (v) {
              final value = v?.trim() ?? '';
              if (value.isEmpty) return 'Content is required';
              if (value.length < 10) return 'Content must be at least 10 characters long';
              if (value.length > 1000) return 'Content must be less than 1000 characters';
              return null;
            },
            textInputAction: TextInputAction.done,
          ),
        ],
      ),
    );
  }

  Widget _actionButtons() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _savePost,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0x550015FF),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
                  )
                : Text(_isEditing ? 'Update Post' : 'Create Post',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: OutlinedButton(
            onPressed: _isLoading ? null : () => Navigator.pop(context),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0x33FFFFFF)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Cancel', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white70)),
          ),
        ),
      ],
    );
  }

  // ---------- SAVE ----------

  Future<void> _savePost() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final provider = context.read<PostProvider>();
      final post = Post(
        id: _isEditing ? widget.post!.id : null,
        userId: _selectedUserId,
        title: _titleController.text.trim(),
        body: _bodyController.text.trim(),
      );

      final success = _isEditing ? await provider.updatePost(post) : await provider.createPost(post);

      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isEditing ? 'Post updated successfully' : 'Post created successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
