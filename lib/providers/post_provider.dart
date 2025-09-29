import 'package:flutter/foundation.dart';
import '../models/models.dart';
import '../services/api_service.dart';

class PostProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  List<Post> _posts = [];
  List<User> _users = [];
  Post? _selectedPost;
  bool _isLoading = false;
  String _errorMessage = '';
  String _searchQuery = '';

  List<Post> get posts => _searchQuery.isEmpty
      ? _posts
      : _posts.where((post) =>
          post.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          post.body.toLowerCase().contains(_searchQuery.toLowerCase())).toList();

  List<User> get users => _users;
  Post? get selectedPost => _selectedPost;
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;
  String get searchQuery => _searchQuery;

  Future<void> loadPosts() async {
    if (_isLoading) return;

    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      _posts = await _apiService.getPosts();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadUsers() async {
    try {
      _users = await _apiService.getUsers();
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<void> loadPostById(int id) async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      _selectedPost = await _apiService.getPost(id);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createPost(Post post) async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      final createdPost = await _apiService.createPost(post);
      _posts.insert(0, createdPost);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updatePost(Post post) async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      final updatedPost = await _apiService.updatePost(post);

      final index = _posts.indexWhere((p) => p.id == post.id);
      if (index != -1) {
        _posts[index] = updatedPost;
      }

      if (_selectedPost?.id == post.id) {
        _selectedPost = updatedPost;
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> deletePost(int id) async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      await _apiService.deletePost(id);
      _posts.removeWhere((post) => post.id == id);

      if (_selectedPost?.id == id) {
        _selectedPost = null;
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
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

  User? getUserById(int userId) {
    try {
      return _users.firstWhere((user) => user.id == userId);
    } catch (e) {
      return null;
    }
  }
}
