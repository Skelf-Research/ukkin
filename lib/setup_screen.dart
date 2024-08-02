import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'model_download_service.dart';
import 'browser_home.dart';
import 'package:sqflite/sqflite.dart';

class SetupScreen extends StatefulWidget {
  final ModelDownloadService downloadService;
  final Database database;

  SetupScreen({required this.downloadService, required this.database});

  @override
  _SetupScreenState createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  int _currentPage = 0;
  final PageController _pageController = PageController();

  final List<Map<String, String>> _pages = [
    {
      'title': 'Welcome to AI-Powered Browser',
      'description': 'Experience a new way of browsing with built-in AI assistance.',
      'image': 'assets/welcome.png',
    },
    {
      'title': 'Privacy-Focused',
      'description': 'Your data stays on your device. No tracking, no ads.',
      'image': 'assets/privacy.png',
    },
    {
      'title': 'Intelligent Search',
      'description': 'Get context-aware results from your open tabs and web searches.',
      'image': 'assets/search.png',
    },
    {
      'title': 'Offline AI Assistant',
      'description': 'Chat with an AI that understands your browsing context, even offline.',
      'image': 'assets/assistant.png',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: _pages.length,
            onPageChanged: (int page) {
              setState(() {
                _currentPage = page;
              });
            },
            itemBuilder: (context, index) {
              return _buildPage(
                title: _pages[index]['title']!,
                description: _pages[index]['description']!,
                imagePath: _pages[index]['image']!,
              );
            },
          ),
          Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    _pages.length,
                    (index) => _buildDot(index),
                  ),
                ),
                SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    TextButton(
                      child: Text('Skip'),
                      onPressed: () => _finishSetup(context),
                    ),
                    if (_currentPage == _pages.length - 1)
                      ElevatedButton(
                        child: Text('Get Started'),
                        onPressed: () => _finishSetup(context),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPage({required String title, required String description, required String imagePath}) {
    return Padding(
      padding: const EdgeInsets.all(40.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            imagePath,
            height: 200,
            width: 200,
            fit: BoxFit.contain,
          ),
          SizedBox(height: 40),
          Text(
            title,
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 20),
          Text(
            description,
            style: TextStyle(fontSize: 16),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildDot(int index) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4),
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _currentPage == index ? Colors.blue : Colors.grey,
      ),
    );
  }

  void _finishSetup(BuildContext context) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('first_time', false);
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => BrowserHome(downloadService: widget.downloadService, database: widget.database)),
    );
  }
}