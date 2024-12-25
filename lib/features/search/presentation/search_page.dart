import 'package:flutter/material.dart';

class SearchPage extends StatefulWidget {
  @override
  _SearchPageState createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  // Controller for the search input
  TextEditingController _searchController = TextEditingController();

  // Mock data: List of games using provided assets
  static const List<Map<String, String>> _allGames = [
    {
      'name': 'Mystic Quest',
      'image': 'lib/assets/images/mock_games/game1.jpg',
    },
    {
      'name': 'Shadow Realm',
      'image': 'lib/assets/images/mock_games/game2.jpg',
    },
    {
      'name': 'Galactic Wars',
      'image': 'lib/assets/images/mock_games/game3.jpg',
    },
    {
      'name': 'Dragon Slayer',
      'image': 'lib/assets/images/mock_games/game4.jpg',
    },
    {
      'name': 'Cyber Knights',
      'image': 'lib/assets/images/mock_games/game5.jpg',
    },
    {
      'name': 'Pixel Adventures',
      'image': 'lib/assets/images/mock_games/game6.jpg',
    },
    // Add more games as needed
  ];

  // List to hold the filtered search results
  List<Map<String, String>> _searchResults = [];

  @override
  void initState() {
    super.initState();
    // Initialize search results with all games
    _searchResults = _allGames;
    // Listen to changes in the search input
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    // Dispose the controller when the widget is disposed
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  /// Method to handle changes in the search input
  void _onSearchChanged() {
    String query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _searchResults = _allGames;
      } else {
        _searchResults = _allGames
            .where((game) => game['name']!.toLowerCase().contains(query))
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Set the page background to black
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: Text(
          'Search Games',
          style: TextStyle(color: Colors.white, fontSize: 24),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Search Bar
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                controller: _searchController,
                style: TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Search for games...',
                  hintStyle: TextStyle(color: Colors.white54),
                  prefixIcon: Icon(Icons.search, color: Colors.white54),
                  filled: true,
                  fillColor: Colors.grey[800],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30.0),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            // Display search results
            Expanded(
              child: _searchResults.isNotEmpty
                  ? ListView.builder(
                      itemCount: _searchResults.length,
                      itemBuilder: (context, index) {
                        return _buildGameItem(_searchResults[index]);
                      },
                    )
                  : Center(
                      child: Text(
                        'No results found.',
                        style: TextStyle(color: Colors.white54, fontSize: 18),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  /// Widget to build each game item in the search results
  Widget _buildGameItem(Map<String, String> game) {
    return ListTile(
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(8.0),
        child: Image.asset(
          game['image']!,
          width: 50,
          height: 50,
          fit: BoxFit.cover,
        ),
      ),
      title: Text(
        game['name']!,
        style: TextStyle(color: Colors.white, fontSize: 18),
      ),
      trailing: Icon(Icons.arrow_forward_ios, color: Colors.white54),
      onTap: () {
        // Implement navigation to game details or other actions
        print('Selected game: ${game['name']}');
        // Example: Navigate to a GameDetailPage (to be implemented)
        // Navigator.push(
        //   context,
        //   MaterialPageRoute(builder: (context) => GameDetailPage(game: game)),
        // );
      },
    );
  }
}
