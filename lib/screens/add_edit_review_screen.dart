import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart'; // Import untuk memilih gambar
import 'dart:io'; // Import untuk menggunakan File
import 'dart:convert'; // Import untuk decoding gambar Base64
import '../api_service.dart';

class AddEditReviewScreen extends StatefulWidget {
  final String username;
  final Map<String, dynamic>? review;

  const AddEditReviewScreen({Key? key, required this.username, this.review}) : super(key: key);

  @override
  _AddEditReviewScreenState createState() => _AddEditReviewScreenState();
}

class _AddEditReviewScreenState extends State<AddEditReviewScreen> {
  final _titleController = TextEditingController();
  final _ratingController = TextEditingController();
  final _commentController = TextEditingController();
  final _apiService = ApiService();
  File? _image; // Variabel untuk menyimpan gambar yang dipilih
  String? _existingImage; // Menyimpan gambar lama (Base64)

  @override
  void initState() {
    super.initState();
    if (widget.review != null) {
      _titleController.text = widget.review!['title'];
      _ratingController.text = widget.review!['rating'].toString();
      _commentController.text = widget.review!['comment'];
      // Memuat gambar lama dari review
      _existingImage = widget.review!['image'];
    }
  }

  // Fungsi untuk memilih gambar dari galeri atau kamera
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery); // Bisa diganti ke ImageSource.camera untuk memilih gambar dari kamera

    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });

      // Memastikan format gambar yang dipilih valid
      final fileExtension = pickedFile.path.split('.').last.toLowerCase();
      if (fileExtension != 'jpg' && fileExtension != 'jpeg' && fileExtension != 'png') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hanya format gambar JPG dan PNG yang diterima.')),
        );
        return;
      }
    }
  }

  // Fungsi untuk menyimpan review dan gambar
  void _saveReview() async {
    final title = _titleController.text.trim();
    final rating = int.tryParse(_ratingController.text) ?? 0;
    final comment = _commentController.text.trim();

    // Validasi input
    if (title.isEmpty || rating < 1 || rating > 10 || comment.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Data tidak valid. Judul, komentar, dan rating (1-10) harus diisi.')),
      );
      return;
    }

    bool success;
    if (widget.review == null) {
      // Menambahkan review baru
      success = await _apiService.addReview(
        widget.username, 
        title, 
        rating, 
        comment, 
        _image // Menambahkan gambar
      );
    } else {
      // Mengupdate review
      success = await _apiService.updateReview(
        widget.review!['_id'], 
        widget.username, 
        title, 
        rating, 
        comment, 
        _image ?? File(''), // Menambahkan gambar baru atau menggunakan gambar lama
        _existingImage,  // Kirim gambar lama jika tidak ada gambar baru
      );
    }

    if (success) {
      Navigator.pop(context, true); // Berhasil, kembali ke layar sebelumnya
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menyimpan review')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditMode = widget.review != null;

    return Scaffold(
      appBar: AppBar(title: Text(isEditMode ? 'Edit Review' : 'Tambah Review')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Title field: Nonaktifkan hanya jika Anda ingin judul tidak bisa diubah
            TextField(
              controller: _titleController,
              decoration: InputDecoration(labelText: 'Judul Film'),
              enabled: true, // Selalu aktif, memungkinkan pengguna untuk mengedit
            ),
            TextField(
              controller: _ratingController,
              decoration: InputDecoration(labelText: 'Rating (1-10)'),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: _commentController,
              decoration: InputDecoration(labelText: 'Komentar'),
            ),
            SizedBox(height: 20),
            // Tombol untuk memilih gambar
            ElevatedButton(
              onPressed: _pickImage,
              child: Text(_image == null ? 'Pilih Gambar' : 'Gambar Terpilih'),
            ),
            // Menampilkan gambar yang dipilih
            if (_image != null)
              Image.file(
                _image!,
                height: 200,
                width: 200,
                fit: BoxFit.cover,
              ),
            // Menampilkan gambar lama jika ada
            if (_existingImage != null && _image == null)
              Image.memory(
                base64Decode(_existingImage!),
                height: 200,
                width: 200,
                fit: BoxFit.cover,
              ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _saveReview,
              child: Text('Simpan'),
            ),
          ],
        ),
      ),
    );
  }
}
