import 'package:flutter/material.dart';
import '../api_service.dart';
import 'add_edit_review_screen.dart';

class MovieReviewsScreen extends StatefulWidget {
  final String username;

  const MovieReviewsScreen({Key? key, required this.username}) : super(key: key);

  @override
  _MovieReviewsScreenState createState() => _MovieReviewsScreenState();
}

class _MovieReviewsScreenState extends State<MovieReviewsScreen> {
  final _apiService = ApiService();
  List<dynamic> _reviews = [];

  @override
  void initState() {
    super.initState();
    _loadReviews();
  }

  Future<void> _loadReviews() async {
    final reviews = await _apiService.getReviews(widget.username);
    setState(() {
      _reviews = reviews;
    });
  }

  void _deleteReview(String id) async {
    final success = await _apiService.deleteReview(id);
    if (success) {
      _loadReviews();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menghapus review')),
      );
    }
  }

  void _likeReview(String id, int index) async {
    try {
      final success = await _apiService.likeReview(id);  
      if (success) {
        setState(() {
          _reviews[index]['liked'] = _reviews[index]['liked'] != null ? !_reviews[index]['liked'] : true;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menyukai review')),
        );
      }
    } catch (e) {
      print('Error saat menyukai review: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Terjadi kesalahan: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Review Film Saya'),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AddEditReviewScreen(username: widget.username),
                ),
              );
              if (result == true) _loadReviews();  // Reload reviews after saving
            },
          ),
        ],
      ),
      body: _reviews.isEmpty
          ? Center(child: Text('Belum ada review. Tambahkan sekarang!'))
          : ListView.builder(
              itemCount: _reviews.length,
              itemBuilder: (context, index) {
                final review = _reviews[index];
                return Dismissible(
                  key: Key(review['_id']),
                  direction: DismissDirection.horizontal,
                  onDismissed: (direction) {
                    if (direction == DismissDirection.startToEnd) {
                      // Edit action
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AddEditReviewScreen(
                            username: widget.username,
                            review: review,
                          ),
                        ),
                      );
                    } else if (direction == DismissDirection.endToStart) {
                      // Delete action
                      _deleteReview(review['_id']);
                    }

                    // Remove the dismissed review from the list immediately after dismissal
                    setState(() {
                      _reviews.removeAt(index);
                    });
                  },
                  background: Container(
                    color: Colors.green,
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 16.0),
                      child: Icon(Icons.edit, color: Colors.white),
                    ),
                  ),
                  secondaryBackground: Container(
                    color: Colors.red,
                    alignment: Alignment.centerRight,
                    child: Padding(
                      padding: const EdgeInsets.only(right: 16.0),
                      child: Icon(Icons.delete, color: Colors.white),
                    ),
                  ),
                  child: Card(
                    margin: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                    elevation: 5,
                    child: ListTile(
                      contentPadding: EdgeInsets.all(8.0),
                      title: Text(
                        review['title'],
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.star, size: 18, color: Colors.amber),
                              Text('${review['rating']} / 10', style: TextStyle(fontSize: 14)),
                            ],
                          ),
                          SizedBox(height: 8),
                          Text(
                            review['comment'] ?? 'Tidak ada komentar',
                            style: TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                      isThreeLine: true,
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          GestureDetector(
                            onTap: () => _likeReview(review['_id'], index),
                            child: AnimatedSwitcher(
                              duration: Duration(milliseconds: 300),
                              child: Icon(
                                review['liked'] == true
                                    ? Icons.favorite
                                    : Icons.favorite_border,
                                key: ValueKey<bool>(review['liked'] ?? false),
                                color: review['liked'] == true ? Colors.red : Colors.grey,
                                size: 28,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
