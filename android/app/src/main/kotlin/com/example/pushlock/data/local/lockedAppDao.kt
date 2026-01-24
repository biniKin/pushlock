package com.example.pushlock.data.local

import androidx.room.*


@Dao
interface LockedAppDao {
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertLockedApp(app: LockedAppEntity)

    @Update
    suspend fun updateLockedApp(app: LockedAppEntity)

    @Delete
    suspend fun deleteLockedApp(app: LockedAppEntity)

    @Query("SELECT * FROM locked_apps")
    suspend fun getAllLockedApps(): List<LockedAppEntity>

    @Query("SELECT * FROM locked_apps WHERE packageName = :packageName")
    suspend fun getLockedApp(packageName: String): LockedAppEntity?

    @Query("DELETE FROM locked_apps WHERE packageName = :packageName")
    suspend fun deleteByPackageName(packageName: String)
}