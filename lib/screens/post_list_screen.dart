import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/post_provider.dart';
import '../models/models.dart';
import 'post_detail_screen.dart';
import 'post_form_screen.dart';

class PostListScreen extends StatefulWidget {
  const PostListScreen({super.key});

  @override
  State<PostListScreen> createState() => _PostListScreenState();
}

class _PostListScreenState extends State<PostListScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<PostProvider>();
      provider.loadPosts(refresh: true);
      provider.loadUsers();
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent) {
      context.read<PostProvider>().loadMorePosts();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        titleSpacing: 16,
        toolbarHeight: 56,
        title: Consumer<PostProvider>(
          builder: (_, provider, __) => Row(
            children: [
              const Text('Posts!'),
              const SizedBox(width: 12),
              Expanded(
                child: _SearchField(
                  controller: _searchController,
                  value: provider.searchQuery,
                  onChanged: provider.setSearchQuery,
                  onClear: () {
                    _searchController.clear();
                    provider.clearSearch();
                  },
                ),
              ),
            ],
          ),
        ),
      ),

      body: Consumer<PostProvider>(
        builder: (context, provider, _) {
          return CustomScrollView(
            controller: _scrollController,
            slivers: [
              SliverToBoxAdapter(
                child: _buildPostList(provider),
              ),
            ],
          );
        },
      ),

      floatingActionButton: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: Color.fromARGB(65, 107, 99, 255),
            ),
            child: FloatingActionButton(
              onPressed: () => _navigateToForm(context),
              backgroundColor: Colors.transparent,
              elevation: 0,
              child: const Icon(Icons.add, color: Colors.white, size: 28),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPostList(PostProvider provider) {
    if (provider.loadingState == LoadingState.loading && provider.posts.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 80),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (provider.loadingState == LoadingState.error) {
      return _statusCard(
        icon: Icons.error_outline_rounded,
        iconColor: Colors.red[400],
        title: 'Oops! Something went wrong',
        message: provider.errorMessage,
        action: ElevatedButton(
          onPressed: () => provider.loadPosts(refresh: true),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white),
          child: const Text('Try Again'),
        ),
      );
    }

    final posts = provider.posts;
    if (posts.isEmpty) {
      return _statusCard(
        icon: Icons.inbox_rounded,
        iconColor: const Color(0x80FFFFFF),
        title: 'No posts found',
        message: 'Try adjusting your search or create a new post',
      );
    }

    return RefreshIndicator(
      onRefresh: () => provider.loadPosts(refresh: true),
      child: ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        itemCount: posts.length + (provider.hasMorePosts ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == posts.length) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(),
              ),
            );
          }
          return _buildPostCard(posts[index], provider);
        },
      ),
    );
  }

  Widget _buildPostCard(Post post, PostProvider provider) {
    final user = provider.getUserById(post.userId);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [Color(0xFF1E1E1E), Color(0xCC2A2A2A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: const [BoxShadow(color: Color(0x4D000000), blurRadius: 15, offset: Offset(0, 5))],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => _navigateToDetail(context, post.id!),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: const Color.fromARGB(99, 107, 99, 255),
                      ),
                      child: CircleAvatar(
                        backgroundColor: Colors.transparent,
                        radius: 22,
                        child: Text(
                          (user?.name.isNotEmpty ?? false) ? user!.name[0].toUpperCase() : 'U',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(user?.name ?? 'Unknown User',
                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: Colors.white)),
                          Text('@${user?.username ?? 'unknown'}',
                              style: const TextStyle(color: Colors.white60, fontSize: 14)),
                        ],
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: const Color(0x0DFFFFFF),
                      ),
                      child: PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert_rounded, color: Colors.white70, size: 20),
                        onSelected: (value) {
                          if (value == 'edit') _navigateToForm(context, post: post);
                          if (value == 'delete') _showDeleteDialog(context, post, provider);
                        },
                        itemBuilder: (_) => const [
                          PopupMenuItem(
                            value: 'edit',
                            child: Row(children: [
                              Icon(Icons.edit_rounded, size: 18),
                              SizedBox(width: 8),
                              Text('Edit'),
                            ]),
                          ),
                          PopupMenuItem(
                            value: 'delete',
                            child: Row(children: [
                              Icon(Icons.delete_rounded, size: 18, color: Colors.red),
                              SizedBox(width: 8),
                              Text('Delete', style: TextStyle(color: Colors.red)),
                            ]),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  post.title,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, height: 1.3, color: Colors.white),
                ),
                const SizedBox(height: 12),
                Text(
                  post.body,
                  style: const TextStyle(color: Colors.white70, height: 1.5, fontSize: 15),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 24),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 64, color: iconColor ?? Colors.grey[400]),
            const SizedBox(height: 16),
            Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
            if (message != null) ...[
              const SizedBox(height: 8),
              Text(message, style: const TextStyle(color: Colors.white70), textAlign: TextAlign.center),
            ],
            if (action != null) ...[const SizedBox(height: 24), action],
          ],
        ),
      ),
    );
  }

  void _navigateToDetail(BuildContext context, int postId) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => PostDetailScreen(postId: postId)));
  }

  void _navigateToForm(BuildContext context, {Post? post}) {
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
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Post deleted successfully')),
                );
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

class _SearchField extends StatelessWidget {
  final TextEditingController controller;
  final String value;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  const _SearchField({
    required this.controller,
    required this.value,
    required this.onChanged,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 36,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: const Color(0x1AFFFFFF),
        border: Border.all(color: const Color(0x33FFFFFF), width: 1),
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: const TextStyle(color: Colors.white, fontSize: 14),
        decoration: InputDecoration(
          hintText: 'Search posts...',
          hintStyle: const TextStyle(color: Color(0x99FFFFFF), fontSize: 14),
          prefixIcon: const Icon(Icons.search_rounded, color: Color(0xCCFFFFFF), size: 20),
          suffixIcon: value.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear_rounded, color: Color(0xCCFFFFFF), size: 18),
                  onPressed: onClear,
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
      ),
    );
    }
}
