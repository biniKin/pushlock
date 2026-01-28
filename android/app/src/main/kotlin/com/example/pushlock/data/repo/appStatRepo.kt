package com.example.pushlock.data.repo

import com.example.pushlock.data.local.AppStatDao
import com.example.pushlock.data.local.AppStatEntity


class AppStatRepo(private val appStatDao: AppStatDao){
    suspend fun upsert(app: AppStatEntity) = appStatDao.upsert(app)

    suspend fun appStatForDay(packageName: String, date: String): AppStatEntity? = appStatDao.getAppStatForDay(packageName, date)

    suspend fun appsStatForDay(date: String): List<AppStatEntity> = appStatDao.getAppsStatForDay(date)

    suspend fun deleteOldStat(beforeDate: String) = appStatDao.deleteOldStat(beforeDate)

    suspend fun getTotalUsageForDay(date: String): Long? = appStatDao.getTotalUsageForDay(date)

    suspend fun getAppStatBetweenDates(startDate: String, endDate: String, packageName: String): List<AppStatEntity> = appStatDao.getAppStatBetweenDates(startDate, endDate, packageName)
}