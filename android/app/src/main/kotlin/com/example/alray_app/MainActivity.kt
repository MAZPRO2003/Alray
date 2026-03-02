package com.example.alray_app

import android.app.NotificationChannel
import android.app.NotificationManager
import android.os.Build
import android.os.Bundle
import io.flutter.embedding.android.FlutterFragmentActivity

class MainActivity : FlutterFragmentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        createNotificationChannels()
    }

    private fun createNotificationChannels() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val manager = getSystemService(NotificationManager::class.java)

            // Channel for incoming team call alerts
            val callAlertsChannel = NotificationChannel(
                "call_alerts",
                "Call Alerts",
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "Notifications for incoming calls from team members"
            }

            // Channel for post-call note reminders
            val callNotesChannel = NotificationChannel(
                "call_notes",
                "Call Notes Prompt",
                NotificationManager.IMPORTANCE_DEFAULT
            ).apply {
                description = "Reminders to add notes after team calls"
            }

            manager.createNotificationChannel(callAlertsChannel)
            manager.createNotificationChannel(callNotesChannel)
        }
    }
}

