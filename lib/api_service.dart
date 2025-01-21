import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = 'https://crudcrud.com/api/f23b51eee2544e17aeb7c9794d115083';

  // Fungsi untuk mengonversi gambar menjadi Base64
  Future<String> _convertImageToBase64(File image) async {
    try {
      final bytes = await image.readAsBytes();
      return base64Encode(bytes);  // Mengubah gambar ke format Base64
    } catch (e) {
      print("Error converting image to Base64: $e");
      return '';  // Jika gagal konversi, mengembalikan string kosong
    }
  }

  // Fungsi untuk registrasi user
  Future<bool> registerUser(String username, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/users'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': username, 'password': password}),
      );
      return response.statusCode == 201;
    } catch (e) {
      print("Error during user registration: $e");
      return false;
    }
  }

  // Fungsi untuk memeriksa apakah username sudah ada
  Future<bool> checkUsernameExists(String username) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/users'));
      if (response.statusCode == 200) {
        final List users = jsonDecode(response.body);
        return users.any((user) => user['username'] == username);
      }
      return false;
    } catch (e) {
      print("Error checking username existence: $e");
      return false;
    }
  }

  // Fungsi untuk login user
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

  // Fungsi untuk mendapatkan review berdasarkan username
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

  // Fungsi untuk menambahkan review baru dengan gambar (Base64)
  Future<bool> addReview(String username, String title, int rating, String comment, File? image) async {
    try {
      var uri = Uri.parse('$baseUrl/reviews');
      var request = http.Request('POST', uri);

      // Menambahkan data lainnya
      request.headers['Content-Type'] = 'application/json';

      String? base64Image;
      if (image != null) {
        base64Image = await _convertImageToBase64(image);  // Mengirim gambar baru
      } else {
        base64Image = '';  // Tidak ada gambar, kirim string kosong
      }

      // Log data yang akan dikirim
      print("Data yang dikirim: title=$title, rating=$rating, comment=$comment, image=$base64Image");

      request.body = jsonEncode({
        'username': username,
        'title': title,
        'rating': rating.toString(),
        'comment': comment,
        'image': base64Image,
        'liked': false,  // Set default 'liked' ke false saat menambahkan review
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

  // Fungsi untuk mengupdate review dengan gambar (Base64)
  Future<bool> updateReview(String id, String username, String title, int rating, String comment, File? image, String? existingImage) async {
    try {
      var uri = Uri.parse('$baseUrl/reviews/$id');
      var request = http.Request('PUT', uri);

      // Menambahkan data lainnya
      request.headers['Content-Type'] = 'application/json';

      String? base64Image;
      if (image != null) {
        base64Image = await _convertImageToBase64(image);  // Mengirim gambar baru
      } else {
        base64Image = existingImage ?? '';  // Jika tidak ada gambar baru, kirim gambar lama atau string kosong
      }

      // Log data yang akan dikirim
      print("Data yang dikirim untuk update: title=$title, rating=$rating, comment=$comment, image=$base64Image, username=$username");

      request.body = jsonEncode({
        'username': username,  // Menambahkan username
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

  // Fungsi untuk menghapus review
  Future<bool> deleteReview(String id) async {
    try {
      final response = await http.delete(Uri.parse('$baseUrl/reviews/$id'));
      return response.statusCode == 200;
    } catch (e) {
      print('Error deleting review: $e');
      return false;
    }
  }

  // Fungsi untuk like review
  Future<bool> likeReview(String reviewId) async {
    try {
      // Mengambil review berdasarkan ID
      final response = await http.get(Uri.parse('$baseUrl/reviews/$reviewId'));

      if (response.statusCode == 200) {
        final review = jsonDecode(response.body);

        // Menangani nilai null pada liked, memastikan nilai bool yang valid
        bool currentLikeStatus = review['liked'] != null && review['liked'] is bool ? review['liked'] as bool : false;

        // Ubah status liked menjadi kebalikan dari nilai saat ini
        review['liked'] = !currentLikeStatus;

        // Kirimkan data yang sudah diubah ke server untuk update status 'liked'
        final updateResponse = await http.put(
          Uri.parse('$baseUrl/reviews/$reviewId'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'username': review['username'],
            'title': review['title'],
            'rating': review['rating'],
            'comment': review['comment'],
            'image': review['image'],
            'liked': review['liked'],  // Mengirim status liked yang baru
          }),
        );

        if (updateResponse.statusCode == 200) {
          print("Status like berhasil diperbarui.");
          return true;  // Jika berhasil memperbarui status
        } else {
          print("Gagal memperbarui status like: ${updateResponse.body}");
          return false;
        }
      }
      print('Review tidak ditemukan');
      return false;  // Jika review tidak ditemukan
    } catch (e) {
      print('Error liking review: $e');
      return false;
    }
  }
}
