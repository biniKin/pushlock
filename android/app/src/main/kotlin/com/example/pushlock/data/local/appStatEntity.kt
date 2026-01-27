package com.example.pushlock.data.local

import androidx.room.Entity
import androidx.room.PrimaryKey

@Entity(tableName="app_stat", primaryKeys = ["packageName", "date"])

data class AppStatEntity(
    val packageName: String,
    val appName: String,
    val dailyUsageTime: Long,
    val date: String
)