import 'package:flutter/services.dart';
import 'package:pushlock/model/appStatModel.dart';

class AppStatService {
  static const platform = MethodChannel("com.example.pushlock/app_lock");

  // getAppStatForDay: package name and date. for single app
  Future<Appstatmodel?> getAppStatForDay(
    String packageName,
    String date,
  ) async {
    try {
      final result = await platform.invokeMethod("app_stat_for_day", {
        'packageName': packageName,
        'date': date,
      });

      if (result != null) {
        return Appstatmodel.fromJson(result);
      }
      return null;
    } catch (e) {
      print("Error getting app stat for day: $e");
      return null;
    }
  }

  // getAppsStatForDay: date. list of apps on that date
  Future<List<Appstatmodel>> getAppsStatForDay(String date) async {
    try {
      final result = await platform.invokeMethod('apps_stat_for_day', date);

      if (result != null && result is List) {
        return Appstatmodel.fromJsonList(result);
      }
      return [];
    } catch (e) {
      print("Error getting apps stat for day: $e");
      return [];
    }
  }

  // getTotalUsageForDay: date. long of milliseconds
  Future<int> getTotalUsageForDay(String date) async {
    try {
      final result = await platform.invokeMethod("total_usage_for_day", date);
      return result ?? 0;
    } catch (e) {
      print("Error getting total usage for day: $e");
      return 0;
    }
  }

  // getAppStatBetweenDates: start date, end date and package name
  Future<List<Appstatmodel>> getAppStatBetweenDates(
    String startDate,
    String endDate,
    String packageName,
  ) async {
    try {
      final result = await platform.invokeMethod('app_stat_between_dates', {
        'startDate': startDate,
        'endDate': endDate,
        'packageName': packageName,
      });

      if (result != null && result is List) {
        return Appstatmodel.fromJsonList(result);
      }
      return [];
    } catch (e) {
      print("Error getting app stat between dates: $e");
      return [];
    }
  }

  // deleteOldStat: before date.
  Future<bool> deleteOldStat(String beforeDate) async {
    try {
      final result = await platform.invokeMethod("delete_old_stat", beforeDate);
      return result ?? false;
    } catch (e) {
      print("Error deleting old stat: $e");
      return false;
    }
  }
}
