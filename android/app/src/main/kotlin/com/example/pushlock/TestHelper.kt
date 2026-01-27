package com.example.pushlock

import android.content.Context
import com.example.pushlock.data.local.PushLockDatabase
import com.example.pushlock.data.local.LockedAppEntity
import com.example.pushlock.data.repo.LockedAppRepo
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch

/**
 * Helper class for testing the timeout feature
 * Use this to add test apps to the database
 */
object TestHelper {
    
    fun addTestLockedApps(context: Context) {
        val database = PushLockDatabase.getDatabase(context)
        val repo = LockedAppRepo(database.lockedAppDao())
        
        CoroutineScope(Dispatchers.IO).launch {
            // Disabled for now - add test apps manually through the UI
            
            // Add Instagram with 5 second timeout (for testing)
            // repo.addApp(
            //     LockedAppEntity(
            //         packageName = "com.instagram.android",
            //         appName = "Instagram",
            //         timeoutSecond = 5,  // 5 seconds for quick testing
            //         isStrict = false
            //     )
            // )
            
            // Add WhatsApp with 10 second timeout
            // repo.addApp(
            //     LockedAppEntity(
            //         packageName = "com.whatsapp",
            //         appName = "WhatsApp",
            //         timeoutSecond = 10,
            //         isStrict = false
            //     )
            // )
            
            // Add Chrome with 3 second timeout
            // repo.addApp(
            //     LockedAppEntity(
            //         packageName = "com.android.chrome",
            //         appName = "Chrome",
            //         timeoutSecond = 3,
            //         isStrict = false
            //     )
            // )
            
            android.util.Log.d("TEST_HELPER", "Test helper called (no test apps added)")
        }
    }
}
