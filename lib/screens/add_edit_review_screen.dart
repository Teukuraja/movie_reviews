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
  File? _image; // Menyimpan gambar yang dipilih
  String? _existingImage; // Menyimpan gambar lama dalam format Base64

  @override
  void initState() {
    super.initState();
    if (widget.review != null) {
      _titleController.text = widget.review!['title'];
      _ratingController.text = widget.review!['rating'].toString();
      _commentController.text = widget.review!['comment'];
      _existingImage = widget.review!['image']; // Memuat gambar lama jika ada
    }
  }

  // Fungsi untuk memilih gambar dari galeri
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery); 

    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path); // Menyimpan gambar yang dipilih
      });

      // Cek format gambar yang dipilih
      final fileExtension = pickedFile.path.split('.').last.toLowerCase();
      if (fileExtension != 'jpg' && fileExtension != 'jpeg' && fileExtension != 'png') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hanya format gambar JPG dan PNG yang diterima.'))
        );
        return;
      }
    }
  }

  // Fungsi untuk menyimpan atau mengupdate review
  void _saveReview() async {
    final title = _titleController.text.trim();
    final rating = int.tryParse(_ratingController.text) ?? 0;
    final comment = _commentController.text.trim();

    // Validasi input
    if (title.isEmpty || rating < 1 || rating > 10 || comment.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Data tidak valid. Judul, komentar, dan rating (1-10) harus diisi.'))
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
      // Mengupdate review yang ada
      success = await _apiService.updateReview(
        widget.review!['_id'],
        widget.username,
        title,
        rating,
        comment,
        _image != null ? _image : null, // Kirim gambar baru jika ada
        _existingImage,  // Kirim gambar lama jika tidak ada gambar baru
      );
    }

    if (success) {
      Navigator.pop(context, true); // Kembali ke layar sebelumnya jika berhasil
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menyimpan review'))
      );
    }
  }

  // Fungsi untuk menampilkan gambar yang dipilih atau fallback gambar lama
  Widget _displayImage() {
    if (_image != null) {
      return Image.file(
        _image!,
        height: 200,
        width: 200,
        fit: BoxFit.cover,
      );
    } else if (_existingImage != null && _existingImage!.isNotEmpty) {
      try {
        // Dekode gambar lama jika ada
        final decodedImage = base64Decode(_existingImage!);
        return Image.memory(
          decodedImage,
          height: 200,
          width: 200,
          fit: BoxFit.cover,
        );
      } catch (e) {
        print("Error decoding image: $e");
        return Text("Gambar tidak valid.");
      }
    } else {
      return Text("Tidak ada gambar.");
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
            // Input untuk judul review
            TextField(
              controller: _titleController,
              decoration: InputDecoration(labelText: 'Judul Film'),
              enabled: true, // Selalu aktif
            ),
            // Input untuk rating (1-10)
            TextField(
              controller: _ratingController,
              decoration: InputDecoration(labelText: 'Rating (1-10)'),
              keyboardType: TextInputType.number,
            ),
            // Input untuk komentar review
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
            // Menampilkan gambar yang dipilih atau gambar lama
            _displayImage(),
            SizedBox(height: 20),
            // Tombol untuk menyimpan review
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
