import 'package:pushlock/service/appStatService.dart';
import 'package:pushlock/model/appStatModel.dart';

class AppStatsRepository {
  final AppStatService _appStatService = AppStatService();

  Future<List<Appstatmodel>> getTodayStats() async {
    try {
      final today = _getTodayDate();
      return await _appStatService.getAppsStatForDay(today);
    } catch (e) {
      print("Error getting today's stats: $e");
      return [];
    }
  }

  Future<Appstatmodel?> getAppStatForDay(
    String packageName,
    String date,
  ) async {
    try {
      return await _appStatService.getAppStatForDay(packageName, date);
    } catch (e) {
      print("Error getting app stat for day: $e");
      return null;
    }
  }

  Future<List<Appstatmodel>> getAppsStatForDay(String date) async {
    try {
      return await _appStatService.getAppsStatForDay(date);
    } catch (e) {
      print("Error getting apps stat for day: $e");
      return [];
    }
  }

  Future<int> getTotalUsageForDay(String date) async {
    try {
      return await _appStatService.getTotalUsageForDay(date);
    } catch (e) {
      print("Error getting total usage for day: $e");
      return 0;
    }
  }

  Future<List<Appstatmodel>> getAppStatBetweenDates(
    String startDate,
    String endDate,
    String packageName,
  ) async {
    try {
      return await _appStatService.getAppStatBetweenDates(
        startDate,
        endDate,
        packageName,
      );
    } catch (e) {
      print("Error getting app stat between dates: $e");
      return [];
    }
  }

  Future<bool> deleteOldStat(String beforeDate) async {
    try {
      return await _appStatService.deleteOldStat(beforeDate);
    } catch (e) {
      print("Error deleting old stat: $e");
      return false;
    }
  }

  String _getTodayDate() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }
}
