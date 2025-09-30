import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'model_download_service.dart';
import 'browser_home.dart';
import 'package:sqflite/sqflite.dart';

class SetupScreen extends StatelessWidget {
  final Database database;

  SetupScreen({required this.database});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(40.0),
          child: Consumer<ModelDownloadService>(
            builder: (context, downloadService, child) {
              if (downloadService.isModelReady) {
                _finishSetup(context);
              }

              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.smart_toy_outlined, size: 100, color: Colors.blue),
                  SizedBox(height: 20),
                  Text(
                    'Welcome to Ukkin',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Your private AI-powered browser',
                    style: TextStyle(fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 40),
                  if (downloadService.isDownloading)
                    Column(
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 20),
                        Text(downloadService.downloadStatus),
                      ],
                    )
                  else
                    ElevatedButton(
                      child: Text('Download Model'),
                      onPressed: () {
                        downloadService.downloadModel();
                      },
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  void _finishSetup(BuildContext context) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('first_time', false);
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => BrowserHome(database: database)),
    );
  }
}
