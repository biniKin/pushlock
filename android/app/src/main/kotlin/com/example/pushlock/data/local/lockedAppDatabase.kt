package com.example.pushlock.data.local

import androidx.room.Database
import androidx.room.Room
import androidx.room.RoomDatabase
import android.content.Context


@Database(entities = [LockedAppEntity::class], version = 1, exportSchema = false)
abstract class LockedAppDatabase : RoomDatabase() {
    abstract fun lockedAppDao(): LockedAppDao

    companion object {
        @Volatile
        private var INSTANCE: LockedAppDatabase? = null

        fun getDatabase(context: Context): LockedAppDatabase {
            return INSTANCE ?: synchronized(this) {
                val instance = Room.databaseBuilder(
                    context.applicationContext,
                    LockedAppDatabase::class.java,
                    "locked_app_database"
                ).build()
                INSTANCE = instance
                instance
            }
        }
    }
}