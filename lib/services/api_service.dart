import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/models.dart';

class ApiService {
  static const String baseUrl = 'https://jsonplaceholder.typicode.com';
  static const String postsEndpoint = '$baseUrl/posts';
  static const String usersEndpoint = '$baseUrl/users';

  static const Map<String, String> headers = {
    'Content-Type': 'application/json; charset=UTF-8',
  };

  Future<List<Post>> getPosts({int? limit, int? page}) async {
    try {
      String url = postsEndpoint;
      if (limit != null) {
        url += '?_limit=$limit';
        if (page != null && page > 1) {
          int start = (page - 1) * limit;
          url += '&_start=$start';
        }
      }

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final List<dynamic> jsonData = json.decode(response.body);
        return jsonData.map((json) => Post.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load posts: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  Future<Post> getPost(int id) async {
    try {
      final response = await http.get(Uri.parse('$postsEndpoint/$id'));

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = json.decode(response.body);
        return Post.fromJson(jsonData);
      } else {
        throw Exception('Failed to load post: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  Future<Post> createPost(Post post) async {
    try {
      final response = await http.post(
        Uri.parse(postsEndpoint),
        headers: headers,
        body: json.encode(post.toJson()),
      );

      if (response.statusCode == 201) {
        final Map<String, dynamic> jsonData = json.decode(response.body);
        return Post.fromJson(jsonData);
      } else {
        throw Exception('Failed to create post: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  Future<Post> updatePost(Post post) async {
    try {
      final response = await http.put(
        Uri.parse('$postsEndpoint/${post.id}'),
        headers: headers,
        body: json.encode(post.toJson()),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = json.decode(response.body);
        return Post.fromJson(jsonData);
      } else {
        throw Exception('Failed to update post: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  Future<bool> deletePost(int id) async {
    try {
      final response = await http.delete(Uri.parse('$postsEndpoint/$id'));

      if (response.statusCode == 200) {
        return true;
      } else {
        throw Exception('Failed to delete post: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  Future<List<User>> getUsers() async {
    try {
      final response = await http.get(Uri.parse(usersEndpoint));

      if (response.statusCode == 200) {
        final List<dynamic> jsonData = json.decode(response.body);
        return jsonData.map((json) => User.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load users: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  Future<User> getUser(int id) async {
    try {
      final response = await http.get(Uri.parse('$usersEndpoint/$id'));

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = json.decode(response.body);
        return User.fromJson(jsonData);
      } else {
        throw Exception('Failed to load user: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  Future<List<Post>> searchPosts(String query) async {
    try {
      final posts = await getPosts();
      return posts.where((post) =>
          post.title.toLowerCase().contains(query.toLowerCase()) ||
          post.body.toLowerCase().contains(query.toLowerCase())).toList();
    } catch (e) {
      throw Exception('Search error: $e');
    }
  }
}
