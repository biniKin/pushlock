package com.example.pushlock.data.repo

import com.example.pushlock.data.local.LockedAppDao
import com.example.pushlock.data.local.LockedAppEntity

class LockedAppRepo(private val lockedAppDao: LockedAppDao) {
    
    suspend fun addApp(app: LockedAppEntity) = lockedAppDao.insertLockedApp(app)
    
    suspend fun updateApp(app: LockedAppEntity) = lockedAppDao.updateLockedApp(app)
    
    suspend fun removeApp(app: LockedAppEntity) = lockedAppDao.deleteLockedApp(app)
    
    suspend fun removeAppByPackageName(packageName: String) = lockedAppDao.deleteByPackageName(packageName)
    
    suspend fun fetchLockedApps(): List<LockedAppEntity> = lockedAppDao.getAllLockedApps()
    
    suspend fun getLockedApp(packageName: String): LockedAppEntity? = lockedAppDao.getLockedApp(packageName)
    
    suspend fun isAppLocked(packageName: String): Boolean {
        return lockedAppDao.getLockedApp(packageName) != null
    }
}