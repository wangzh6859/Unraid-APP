import 'package:flutter/material.dart';
import '../api/emby_client.dart';
import '../utils/app_config.dart';

class EmbyProvider extends ChangeNotifier {
  final EmbyClient _api = EmbyClient();
  
  bool isLoading = false;
  String errorMsg = '';
  List<dynamic> latestItems = [];
  
  String currentCategory = ''; // empty means ALL
  final List<Map<String, String>> categories = [
    {'name': '全部', 'value': ''},
    {'name': '电影', 'value': 'Movie'},
    {'name': '剧集', 'value': 'Series'},
    {'name': '动漫', 'value': 'Anime'}, 
  ];

  Future<void> fetchMedia({String? category}) async {
    if (category != null) {
      currentCategory = category;
    }
    
    isLoading = true;
    errorMsg = '';
    notifyListeners();

    final result = await _api.getLatestMedia(itemType: currentCategory);
    
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
    } else {
       errorMsg = '网络无响应';
    }

    isLoading = false;
    notifyListeners();
  }
  
  String getImageUrl(String itemId) {
    if (AppConfig.embyUrl.isEmpty) return '';
    return '${AppConfig.embyUrl}/Items/$itemId/Images/Primary';
  }
  
  String getBackdropUrl(String itemId) {
    if (AppConfig.embyUrl.isEmpty) return '';
    return '${AppConfig.embyUrl}/Items/$itemId/Images/Backdrop';
  }
}
