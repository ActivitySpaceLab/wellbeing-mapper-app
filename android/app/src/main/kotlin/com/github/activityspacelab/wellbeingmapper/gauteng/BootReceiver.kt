package com.github.activityspacelab.wellbeingmapper.gauteng

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log

class BootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (Intent.ACTION_BOOT_COMPLETED == intent.action) {
            Log.d("BootReceiver", "Boot completed - notifications may need to be rescheduled")
            // The app will reschedule notifications when it next starts
        }
    }
}
