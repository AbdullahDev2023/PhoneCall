package com.phonecall.app.phone_call_app.telecom

import android.content.Intent
import android.telecom.Call
import android.telecom.CallAudioState
import android.telecom.InCallService
import com.phonecall.app.phone_call_app.MainActivity
import com.phonecall.app.phone_call_app.platform.CallCoordinator

class PhoneCallInCallService : InCallService() {
    override fun onCreate() {
        super.onCreate()
        CallCoordinator.attachService(this)
    }

    override fun onDestroy() {
        CallCoordinator.detachService(this)
        super.onDestroy()
    }

    override fun onCallAdded(call: Call) {
        super.onCallAdded(call)
        CallCoordinator.onCallAdded(call)
        launchCallUi(showFullScreen = true)
    }

    override fun onCallRemoved(call: Call) {
        super.onCallRemoved(call)
        CallCoordinator.onCallRemoved(call)
    }

    override fun onBringToForeground(showDialpad: Boolean) {
        super.onBringToForeground(showDialpad)
        launchCallUi(showFullScreen = true)
    }

    override fun onCallAudioStateChanged(audioState: CallAudioState?) {
        super.onCallAudioStateChanged(audioState)
        CallCoordinator.onAudioStateChanged(audioState)
    }

    private fun launchCallUi(showFullScreen: Boolean) {
        val intent =
            Intent(this, MainActivity::class.java).apply {
                flags =
                    Intent.FLAG_ACTIVITY_NEW_TASK or
                        Intent.FLAG_ACTIVITY_SINGLE_TOP or
                        Intent.FLAG_ACTIVITY_CLEAR_TOP
                putExtra(MainActivity.EXTRA_OPEN_CALL_UI, showFullScreen)
            }
        startActivity(intent)
    }
}
