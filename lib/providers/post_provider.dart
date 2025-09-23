import 'package:flutter/foundation.dart';
import '../models/models.dart';
import '../services/api_service.dart';

enum LoadingState { idle, loading, success, error }

class PostProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  List<Post> _posts = [];
  List<User> _users = [];
  Post? _selectedPost;
  LoadingState _loadingState = LoadingState.idle;
  String _errorMessage = '';
  String _searchQuery = '';
  int _currentPage = 1;
  final int _postsPerPage = 10;
  bool _hasMorePosts = true;

  List<Post> get posts => _searchQuery.isEmpty
      ? _posts
      : _posts
          .where((post) =>
              post.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              post.body.toLowerCase().contains(_searchQuery.toLowerCase()))
          .toList();

  List<User> get users => _users;
  Post? get selectedPost => _selectedPost;
  LoadingState get loadingState => _loadingState;
  String get errorMessage => _errorMessage;
  String get searchQuery => _searchQuery;
  int get currentPage => _currentPage;
  bool get hasMorePosts => _hasMorePosts;

  void _setLoadingState(LoadingState state) {
    _loadingState = state;
    notifyListeners();
  }

  void _setError(String message) {
    _errorMessage = message;
    _loadingState = LoadingState.error;
    notifyListeners();
  }

  Future<void> loadPosts({bool refresh = false}) async {
    if (_loadingState == LoadingState.loading) return;

    try {
      if (refresh) {
        _currentPage = 1;
        _posts.clear();
        _hasMorePosts = true;
      }

      _setLoadingState(LoadingState.loading);

      final newPosts = await _apiService.getPosts(
        limit: _postsPerPage,
        page: _currentPage,
      );

      if (refresh) {
        _posts = newPosts;
      } else {
        _posts.addAll(newPosts);
      }

      if (newPosts.length < _postsPerPage) {
        _hasMorePosts = false;
      }

      _loadingState = LoadingState.success;
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
    }
  }

  Future<void> loadMorePosts() async {
    if (!_hasMorePosts || _loadingState == LoadingState.loading) return;

    _currentPage++;
    await loadPosts();
  }

  Future<void> loadUsers() async {
    try {
      _users = await _apiService.getUsers();
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
    }
  }

  Future<void> loadPostById(int id) async {
    try {
      _setLoadingState(LoadingState.loading);
      _selectedPost = await _apiService.getPost(id);
      _loadingState = LoadingState.success;
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
    }
  }

  Future<bool> createPost(Post post) async {
    try {
      _setLoadingState(LoadingState.loading);
      final createdPost = await _apiService.createPost(post);
      
      final newPost = createdPost.copyWith(id: _getNextId());
      _posts.insert(0, newPost);
      
      _loadingState = LoadingState.success;
      notifyListeners();
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    }
  }

  Future<bool> updatePost(Post post) async {
    try {
      _setLoadingState(LoadingState.loading);
      final updatedPost = await _apiService.updatePost(post);
      
      final index = _posts.indexWhere((p) => p.id == post.id);
      if (index != -1) {
        _posts[index] = updatedPost;
      }
      
      if (_selectedPost?.id == post.id) {
        _selectedPost = updatedPost;
      }
      
      _loadingState = LoadingState.success;
      notifyListeners();
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    }
  }

  Future<bool> deletePost(int id) async {
    try {
      _setLoadingState(LoadingState.loading);
      await _apiService.deletePost(id);
      
      _posts.removeWhere((post) => post.id == id);
      
      if (_selectedPost?.id == id) {
        _selectedPost = null;
      }
      
      _loadingState = LoadingState.success;
      notifyListeners();
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    }
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void clearSearch() {
    _searchQuery = '';
    notifyListeners();
  }

  void clearSelectedPost() {
    _selectedPost = null;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = '';
    if (_loadingState == LoadingState.error) {
      _loadingState = LoadingState.idle;
    }
    notifyListeners();
  }

  User? getUserById(int userId) {
    try {
      return _users.firstWhere((user) => user.id == userId);
    } catch (e) {
      return null;
    }
  }

  int _getNextId() {
    if (_posts.isEmpty) return 101;
    final maxId = _posts.map((p) => p.id ?? 0).reduce((a, b) => a > b ? a : b);
    return maxId + 1;
  }
}
