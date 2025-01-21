import 'package:flutter/material.dart';
import '../api_service.dart';
import 'movie_reviews_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _apiService = ApiService();

  // Fungsi untuk menangani prcoses login
  void _login() async {
    final success = await _apiService.loginUser(
      _usernameController.text,
      _passwordController.text,
    );

    if (success) {
      // Arahkan ke layar MovieReviews jika login berhasil
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => MovieReviewsScreen(username: _usernameController.text),
        ),
      );
    } else {
      // Tampilkan pesan error jika login gagal
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Login gagal. Silakan cek username/password.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Login')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Input untuk username
            TextField(
              controller: _usernameController,
              decoration: InputDecoration(labelText: 'Username'),
            ),
            // Input untuk password
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(labelText: 'Password'),
              obscureText: true, // Menyembunyikan password
            ),
            SizedBox(height: 20),
            // Tombol login
            ElevatedButton(
              onPressed: _login,
              child: Text('Login'),
            ),
            // Tombol untuk navigasi ke halaman pendaftaran
            TextButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => RegisterScreen()),
              ),
              child: Text('Belum punya akun? Daftar di sini.'),
            ),
          ],
        ),
      ),
    );
  }
}
