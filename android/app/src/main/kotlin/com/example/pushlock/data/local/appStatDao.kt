package com.example.pushlock.data.local

import androidx.room.*

@Dao
interface AppStatDao {
    // insert and update 
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun upsert(app: AppStatEntity)

    // query for usage stat of one app
    @Query("""
        SELECT * FROM app_stat
        WHERE packageName = :packageName AND date = :date
        LIMIT 1
    """)
    suspend fun getAppStatForDay(
        packageName: String, 
        date: String
    ): AppStatEntity?

    // query for a list of apps at specific date
    @Query("""
        SELECT * FROM app_stat
        WHERE date = :date
        ORDER BY dailyUsageTime DESC
    """)
    suspend fun getAppsStatForDay(date: String): List<AppStatEntity>

    // query to delete app stat after some date
    @Query("""
        DELETE FROM app_stat
        WHERE date < :beforeDate
    
    """)
    suspend fun deleteOldStat(beforeDate: String)

    // total usage time for summary
    @Query("""
        SELECT SUM(dailyUsageTime)
        FROM app_stat
        WHERE date = :date
    """)
    suspend fun getTotalUsageForDay(date: String): Long?

    // Get usage for an app across multiple days
    @Query("""
        SELECT * FROM app_stat
        WHERE date BETWEEN :startDate AND :endDate
        AND packageName = :packageName
        ORDER BY date ASC
    """)
    suspend fun getAppStatBetweenDates(
        startDate: String, 
        endDate: String, 
        packageName: String
    ): List<AppStatEntity>

}