import 'package:flutter/material.dart';

class FollowersPage extends StatelessWidget {
  const FollowersPage({Key? key}) : super(key: key);

  // Mock veri: Gerçek uygulamada backend'den çekilecek
  static final List<String> mockFollowers = [
    'Follower1',
    'Follower2',
    'Follower3',
    'Follower4',
    'Follower5',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Followers'),
        backgroundColor: Colors.black,
      ),
      backgroundColor: Colors.black,
      body: ListView.builder(
        itemCount: mockFollowers.length,
        itemBuilder: (context, index) {
          final user = mockFollowers[index];
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
