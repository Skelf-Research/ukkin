import 'package:flutter/material.dart';
import 'web_view_model.dart';

class BrowserState with ChangeNotifier {
  List<WebViewModel> _tabs = [];
  List<WebViewModel> get tabs => _tabs;

  int _currentTabIndex = 0;
  int get currentTabIndex => _currentTabIndex;

  bool _isIncognito = false;
  bool get isIncognito => _isIncognito;

  WebViewModel get currentTab => _tabs[_currentTabIndex];

  void addNewTab({String url = 'https://www.google.com'}) {
    _tabs.add(WebViewModel(url: url, isIncognito: _isIncognito));
    _currentTabIndex = _tabs.length - 1;
    notifyListeners();
  }

  void closeTab(int index) {
    _tabs.removeAt(index);
    if (_currentTabIndex >= _tabs.length) {
      _currentTabIndex = _tabs.length - 1;
    }
    if (_tabs.isEmpty) {
      addNewTab();
    }
    notifyListeners();
  }

  void switchToTab(int index) {
    _currentTabIndex = index;
    notifyListeners();
  }

  void toggleIncognito() {
    _isIncognito = !_isIncognito;
    notifyListeners();
  }
}
