package com.example.pushlock.data.local

import androidx.room.Entity
import androidx.room.PrimaryKey


@Entity(tableName = "locked_apps")
data class LockedAppEntity(
    @PrimaryKey val packageName: String,
    val appName: String = "",
    val timeoutSecond: Int = 0,
    val isStrict: Boolean = false,
)