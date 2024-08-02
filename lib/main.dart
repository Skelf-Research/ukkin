import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'model_download_service.dart';
import 'splash_screen.dart';
import 'llm_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final database = await openDatabase(
    join(await getDatabasesPath(), 'browser.db'),
    onCreate: (db, version) async {
      await db.execute('CREATE TABLE bookmarks(id INTEGER PRIMARY KEY, url TEXT)');
      await db.execute('CREATE TABLE history(id INTEGER PRIMARY KEY, url TEXT, title TEXT, timestamp TEXT)');
      await db.execute('CREATE VIRTUAL TABLE page_content USING fts4(url, content)');
    },
    version: 1,
  );

  final downloadService = ModelDownloadService();
  runApp(BrowserApp(database: database, downloadService: downloadService));
}

class BrowserApp extends StatelessWidget {
  final Database database;
  final ModelDownloadService downloadService;

  BrowserApp({required this.database, required this.downloadService});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ukkin : Privacy first AI-Browser',
      theme: ThemeData(primarySwatch: Colors.blue, brightness: Brightness.light),
      darkTheme: ThemeData(primarySwatch: Colors.blue, brightness: Brightness.dark),
      themeMode: ThemeMode.system,
      home: SplashScreen(downloadService: downloadService, database: database),
    );
  }
}