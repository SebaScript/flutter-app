import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/post_provider.dart';
import '../models/models.dart';
import 'post_form_screen.dart';

class PostDetailScreen extends StatefulWidget {
  final int postId;
  const PostDetailScreen({super.key, required this.postId});

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PostProvider>().loadPostById(widget.postId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Post Details'),
        centerTitle: true,
        actions: [
          Consumer<PostProvider>(
            builder: (_, provider, __) {
              final post = provider.selectedPost;
              if (post == null) return const SizedBox.shrink();
              return PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'edit') _navigateToEdit(context, post);
                  if (value == 'delete') _showDeleteDialog(context, post, provider);
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(
                    value: 'edit',
                    child: Row(children: [Icon(Icons.edit, size: 18), SizedBox(width: 8), Text('Edit Post')]),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(children: [
                      Icon(Icons.delete, size: 18, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Delete Post', style: TextStyle(color: Colors.red)),
                    ]),
                  ),
                ],
              );
            },
          ),
        ],
      ),

      body: Consumer<PostProvider>(
        builder: (_, provider, __) {
          switch (provider.loadingState) {
            case LoadingState.loading:
              return const Center(child: CircularProgressIndicator());
            case LoadingState.error:
              return _statusCard(
                icon: Icons.error_outline,
                iconColor: Colors.red[300],
                title: 'Failed to load post',
                message: provider.errorMessage,
                action: ElevatedButton(
                  onPressed: () => provider.loadPostById(widget.postId),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white),
                  child: const Text('Try Again'),
                ),
              );
            case LoadingState.idle:
            default:
              final post = provider.selectedPost;
              if (post == null) {
                return _statusCard(
                  icon: Icons.search_off,
                  iconColor: Colors.grey[400],
                  title: 'Post not found',
                  message: 'The post you are looking for does not exist.',
                );
              }
              return _buildPostDetail(post, provider);
          }
        },
      ),

      floatingActionButton: Consumer<PostProvider>(
        builder: (_, provider, __) {
          final post = provider.selectedPost;
          if (post == null) return const SizedBox.shrink();
          return ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: const Color(0xFF6C63FF).withOpacity(0.8),
                  border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
                ),
                child: FloatingActionButton(
                  onPressed: () => _navigateToEdit(context, post),
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  child: const Icon(Icons.edit, color: Colors.white, size: 28),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ---------- UI SECTIONS ----------

  Widget _buildPostDetail(Post post, PostProvider provider) {
    final user = provider.getUserById(post.userId);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeaderCard(post, user),
          const SizedBox(height: 16),
          _buildContentCard(post),
          const SizedBox(height: 16),
          _buildMetadataCard(post, user),
        ],
      ),
    );
  }

  Widget _buildHeaderCard(Post post, User? user) {
    return _glassPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: const Color(0x37001555),
                ),
                child: CircleAvatar(
                  backgroundColor: Colors.transparent,
                  radius: 30,
                  child: Text(
                    (user?.name.isNotEmpty ?? false) ? user!.name[0].toUpperCase() : 'U',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 24),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(user?.name ?? 'Unknown User',
                        style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                    Text('@${user?.username ?? 'unknown'}', style: const TextStyle(color: Color(0xCCFFFFFF), fontSize: 14)),
                    if (user?.email != null) ...[
                      const SizedBox(height: 4),
                      Text(user!.email, style: const TextStyle(color: Color(0xB3FFFFFF), fontSize: 12)),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), color: const Color(0x37001555)),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.article_rounded, size: 16, color: Colors.white),
              const SizedBox(width: 6),
              Text('Post #${post.id}',
                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _buildContentCard(Post post) {
    return _glassPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(Icons.article_rounded, 'Content'),
          const SizedBox(height: 16),
          _fieldBlock(label: 'Title', child: Text(post.title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, height: 1.3, color: Colors.white))),
          const SizedBox(height: 16),
          _fieldBlock(label: 'Body', child: Text(post.body, style: const TextStyle(fontSize: 16, height: 1.6, color: Colors.white70))),
        ],
      ),
    );
  }

  Widget _buildMetadataCard(Post post, User? user) {
    return _glassPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(Icons.info_outline_rounded, 'Information'),
          const SizedBox(height: 16),
          _infoRow('Post ID', '#${post.id}', Icons.tag),
          _infoRow('User ID', '#${post.userId}', Icons.person),
          if (user?.phone != null) _infoRow('Phone', user!.phone!, Icons.phone),
          if (user?.website != null) _infoRow('Website', user!.website!, Icons.language),
          if (user?.company?.name != null) _infoRow('Company', user!.company!.name, Icons.business),
        ],
      ),
    );
  }

  // ---------- SMALL HELPERS ----------

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

  Widget _sectionTitle(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: Colors.white70, size: 24),
        const SizedBox(width: 8),
        Text(text, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
      ],
    );
  }

  Widget _fieldBlock({required String label, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0x0DFFFFFF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0x1AFFFFFF), width: 1),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white60, letterSpacing: 0.5)),
        const SizedBox(height: 8),
        child,
      ]),
    );
  }

  Widget _infoRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.white60),
          const SizedBox(width: 12),
          Text('$label:', style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.white70)),
          const SizedBox(width: 8),
          Expanded(child: Text(value, style: const TextStyle(color: Colors.white))),
        ],
      ),
    );
  }

  Widget _statusCard({
    required IconData icon,
    Color? iconColor,
    required String title,
    String? message,
    Widget? action,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 64, color: iconColor ?? Colors.grey[400]),
            const SizedBox(height: 16),
            Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.grey[600])),
            if (message != null) ...[
              const SizedBox(height: 8),
              Text(message, style: TextStyle(color: Colors.grey[500]), textAlign: TextAlign.center),
            ],
            if (action != null) ...[const SizedBox(height: 24), action],
          ],
        ),
      ),
    );
  }

  // ---------- NAV / DIALOG ----------

  void _navigateToEdit(BuildContext context, Post post) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => PostFormScreen(post: post)));
  }

  void _showDeleteDialog(BuildContext context, Post post, PostProvider provider) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Post'),
        content: Text('Are you sure you want to delete "${post.title}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await provider.deletePost(post.id!);
              if (success && context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Post deleted successfully')));
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
