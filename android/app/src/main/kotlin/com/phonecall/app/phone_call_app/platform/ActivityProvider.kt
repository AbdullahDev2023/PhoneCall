package com.phonecall.app.phone_call_app.platform

import android.app.Activity
import android.app.Application
import android.os.Bundle

object ActivityProvider : Application.ActivityLifecycleCallbacks {
    private var registered = false
    var currentActivity: Activity? = null
        private set

    fun register(application: Application) {
        if (registered) {
            return
        }
        registered = true
        application.registerActivityLifecycleCallbacks(this)
    }

    override fun onActivityCreated(activity: Activity, savedInstanceState: Bundle?) {
        currentActivity = activity
    }

    override fun onActivityStarted(activity: Activity) {
        currentActivity = activity
    }

    override fun onActivityResumed(activity: Activity) {
        currentActivity = activity
    }

    override fun onActivityPaused(activity: Activity) {
        if (currentActivity === activity) {
            currentActivity = null
        }
    }

    override fun onActivityStopped(activity: Activity) = Unit

    override fun onActivitySaveInstanceState(activity: Activity, outState: Bundle) = Unit

    override fun onActivityDestroyed(activity: Activity) {
        if (currentActivity === activity) {
            currentActivity = null
        }
    }
}
