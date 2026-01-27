package com.example.pushlock.data.local

import androidx.room.Database
import androidx.room.Room
import androidx.room.RoomDatabase
import android.content.Context


@Database(entities = [LockedAppEntity::class, AppStatEntity::class], version = 2, exportSchema = false)
abstract class PushLockDatabase : RoomDatabase() {
    abstract fun lockedAppDao(): LockedAppDao
    abstract fun appStatDao() : AppStatDao

    companion object {
        @Volatile
        private var INSTANCE: PushLockDatabase? = null

        fun getDatabase(context: Context): PushLockDatabase {
            return INSTANCE ?: synchronized(this) {
                val instance = Room.databaseBuilder(
                    context.applicationContext,
                    PushLockDatabase::class.java,
                    "pushlock_database"
                ).build()
                INSTANCE = instance
                instance
            }
        }
    }
}