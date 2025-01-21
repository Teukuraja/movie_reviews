import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = 'https://crudcrud.com/api/f23b51eee2544e17aeb7c9794d115083';

  // Mengonversi gambar menjadi format Base64
  Future<String> _convertImageToBase64(File image) async {
    try {
      final bytes = await image.readAsBytes();
      return base64Encode(bytes);  // Mengubah gambar ke Base64
    } catch (e) {
      print("Error converting image to Base64: $e");
      return '';  // Mengembalikan string kosong jika gagal
    }
  }

  // Registrasi user baru
  Future<bool> registerUser(String username, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/users'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': username, 'password': password}),
      );
      return response.statusCode == 201;  // Mengembalikan true jika berhasil
    } catch (e) {
      print("Error during user registration: $e");
      return false;
    }
  }

  // Memeriksa apakah username sudah terdaftar
  Future<bool> checkUsernameExists(String username) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/users'));
      if (response.statusCode == 200) {
        final List users = jsonDecode(response.body);
        return users.any((user) => user['username'] == username);  // Mengecek apakah username ada
      }
      return false;
    } catch (e) {
      print("Error checking username existence: $e");
      return false;
    }
  }

  // Login user
  Future<bool> loginUser(String username, String password) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/users'));
      if (response.statusCode == 200) {
        final List users = jsonDecode(response.body);
        return users.any((user) => user['username'] == username && user['password'] == password);
      }
      return false;
    } catch (e) {
      print("Error during user login: $e");
      return false;
    }
  }

  // Mendapatkan review berdasarkan username
  Future<List<dynamic>> getReviews(String username) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/reviews'));
      if (response.statusCode == 200) {
        final List reviews = jsonDecode(response.body);
        return reviews.where((review) => review['username'] == username).toList();  
      }
      return [];
    } catch (e) {
      print("Error getting reviews: $e");
      return [];
    }
  }

  // Menambahkan review baru dengan gambar (Base64)
  Future<bool> addReview(String username, String title, int rating, String comment, File? image) async {
    try {
      var uri = Uri.parse('$baseUrl/reviews');
      var request = http.Request('POST', uri);

      // Menambahkan data review
      request.headers['Content-Type'] = 'application/json';

      String? base64Image;
      if (image != null) {
        base64Image = await _convertImageToBase64(image);  
      } else {
        base64Image = '';  
      }

      request.body = jsonEncode({
        'username': username,
        'title': title,
        'rating': rating.toString(),
        'comment': comment,
        'image': base64Image,
        'liked': false,  // Status 'liked' default ke false
      });

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 201) {
        print("Review berhasil ditambahkan!");
        return true;
      } else {
        print("Gagal menambahkan review. Response: $responseBody");
        return false;
      }
    } catch (e) {
      print('Error adding review: $e');
      return false;
    }
  }

  // Mengupdate review dengan gambar (Base64)
  Future<bool> updateReview(String id, String username, String title, int rating, String comment, File? image, String? existingImage) async {
    try {
      var uri = Uri.parse('$baseUrl/reviews/$id');
      var request = http.Request('PUT', uri);

      // Menambahkan data review
      request.headers['Content-Type'] = 'application/json';

      String? base64Image;
      if (image != null) {
        base64Image = await _convertImageToBase64(image); 
      } else {
        base64Image = existingImage ?? '';  
      }

      request.body = jsonEncode({
        'username': username,
        'title': title,
        'rating': rating.toString(),
        'comment': comment,
        'image': base64Image,
      });

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        print('Review berhasil diperbarui!');
        return true;
      } else {
        print("Gagal memperbarui review. Response: $responseBody");
        return false;
      }
    } catch (e) {
      print('Error updating review: $e');
      return false;
    }
  }

  // Menghapus review berdasarkan ID
  Future<bool> deleteReview(String id) async {
    try {
      final response = await http.delete(Uri.parse('$baseUrl/reviews/$id'));
      return response.statusCode == 200;  
    } catch (e) {
      print('Error deleting review: $e');
      return false;
    }
  }

  // Menyukai review
  Future<bool> likeReview(String reviewId) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/reviews/$reviewId'));

      if (response.statusCode == 200) {
        final review = jsonDecode(response.body);

        bool currentLikeStatus = review['liked'] != null && review['liked'] is bool ? review['liked'] as bool : false;

        review['liked'] = !currentLikeStatus;  // Membalikkan status like

        // Mengirim data update ke server
        final updateResponse = await http.put(
          Uri.parse('$baseUrl/reviews/$reviewId'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'username': review['username'],
            'title': review['title'],
            'rating': review['rating'],
            'comment': review['comment'],
            'image': review['image'],
            'liked': review['liked'],  // Mengirim status like terbaru
          }),
        );

        if (updateResponse.statusCode == 200) {
          print("Status like berhasil diperbarui.");
          return true;
        } else {
          print("Gagal memperbarui status like: ${updateResponse.body}");
          return false;
        }
      }
      print('Review tidak ditemukan');
      return false;
    } catch (e) {
      print('Error liking review: $e');
      return false;
    }
  }
}
