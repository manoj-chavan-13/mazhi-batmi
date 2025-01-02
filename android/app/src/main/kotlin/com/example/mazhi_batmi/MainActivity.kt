package com.example.mazhi_batmi

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.os.Build
import androidx.core.app.NotificationCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.MethodChannel


class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.notifications/notify"
    private var lastMessage: String? = "demo" // Initialize with a default value

    override fun onCreate(savedInstanceState: android.os.Bundle?) {
        super.onCreate(savedInstanceState)

        MethodChannel(flutterEngine!!.dartExecutor, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "showNotification") {
                // Get the custom message passed from Flutter
                val message = call.argument<String>("message")

                // Only show the notification if the message is not null and different from the lastMessage
                if (message != null && message != lastMessage) {
                    showNotification(message)
                    result.success("Notification sent with message: $message")
                    lastMessage = message // Update the lastMessage variable
                } else if (message == null) {
                    result.error("INVALID_MESSAGE", "Message cannot be null", null)
                } else {
                    // Skip sending the notification if the message is the same
                    result.success("Notification not sent (message is the same)")
                }
            } else {
                result.notImplemented()
            }
        }
    }

    private fun showNotification(message: String) {
        // Get the NotificationManager system service
        val notificationManager = getSystemService(NOTIFICATION_SERVICE) as NotificationManager

        // Create a notification channel for Android 8.0+ (Oreo) if needed
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                "default", // Channel ID
                "Default Channel", // Channel name
                NotificationManager.IMPORTANCE_DEFAULT
            )
            notificationManager.createNotificationChannel(channel)
        }

        // Build the notification with the custom message
        val notification = NotificationCompat.Builder(this, "default")
            .setContentTitle("New Post Alert!") // Clearer notification title
            .setContentText(message) // Use the custom message here
            .setSmallIcon(R.drawable.logo) // Custom notification icon (use your own drawable)
            .setPriority(NotificationCompat.PRIORITY_DEFAULT) // Set the priority of the notification
            .setAutoCancel(true) // Dismiss notification when clicked
            .setDefaults(Notification.DEFAULT_ALL) // Add default settings like sound, vibration, etc.
            .build()

        // Send the notification
        notificationManager.notify(0, notification)
    }
}
