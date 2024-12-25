import 'package:flutter/material.dart';

class FollowingPage extends StatelessWidget {
  const FollowingPage({Key? key}) : super(key: key);

  // Mock veri: Gerçek uygulamada backend'den çekilecek
  static final List<String> mockFollowing = [
    'User1',
    'User2',
    'User3',
    'User4',
    'User5',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Following'),
        backgroundColor: Colors.black,
      ),
      backgroundColor: Colors.black,
      body: ListView.builder(
        itemCount: mockFollowing.length,
        itemBuilder: (context, index) {
          final user = mockFollowing[index];
          return ListTile(
            leading: CircleAvatar(
              backgroundImage: AssetImage('lib/assets/images/profile_photo.jpg'), // Kullanıcı profil fotoğrafı
            ),
            title: Text(
              user,
              style: const TextStyle(color: Colors.white),
            ),
            onTap: () {
              // Kullanıcı profiline yönlendirme (varsa)
              print('$user profiline gidiliyor.');
            },
          );
        },
      ),
    );
  }
}
