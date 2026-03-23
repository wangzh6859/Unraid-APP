import 'package:flutter/material.dart';
import '../api/emby_client.dart';
import 'package:shared_preferences/shared_preferences.dart';

class EmbyProvider extends ChangeNotifier {
  final EmbyClient _api = EmbyClient();
  
  bool isLoading = false;
  String errorMsg = '';
  List<dynamic> latestItems = [];
  String baseUrl = '';

  Future<void> fetchMedia() async {
    isLoading = true;
    errorMsg = '';
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    baseUrl = prefs.getString('emby_url') ?? '';

    final result = await _api.getLatestMedia();
    
    if (result != null) {
      if (result.containsKey('error')) {
        errorMsg = result['error'];
        latestItems = [];
      } else {
        final data = result['data'];
        if (data != null && data['Items'] != null) {
          latestItems = data['Items'];
        }
      }
    }

    isLoading = false;
    notifyListeners();
  }
  
  String getImageUrl(String itemId) {
    if (baseUrl.isEmpty) return '';
    return '$baseUrl/Items/$itemId/Images/Primary';
  }
}
