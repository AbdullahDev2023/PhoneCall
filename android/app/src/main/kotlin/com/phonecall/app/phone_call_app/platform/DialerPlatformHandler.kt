package com.phonecall.app.phone_call_app.platform

import android.Manifest
import android.app.Application
import android.app.role.RoleManager
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.provider.Settings
import android.telecom.PhoneAccount
import android.telecom.PhoneAccountHandle
import android.telecom.TelecomManager
import android.util.Log
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat

class DialerPlatformHandler(
    private val application: Application,
) : DialerPlatformApi {
    companion object {
        private const val TAG = "DialerPlatformHandler"
        private const val REQUEST_CORE_PERMISSIONS = 2001
        private const val REQUEST_DEFAULT_DIALER = 2002
    }

    private val telecomManager: TelecomManager by lazy {
        application.getSystemService(TelecomManager::class.java)
    }

    override fun getPermissionState(): PermissionState {
        return PermissionState(
            contactsGranted = hasPermission(Manifest.permission.READ_CONTACTS),
            writeContactsGranted = hasPermission(Manifest.permission.WRITE_CONTACTS),
            callLogGranted = hasPermission(Manifest.permission.READ_CALL_LOG),
            phoneGranted =
                hasPermission(Manifest.permission.CALL_PHONE) &&
                    hasPermission(Manifest.permission.READ_PHONE_STATE),
        )
    }

    override fun requestCorePermissions(): Boolean {
        val activity = ActivityProvider.currentActivity ?: return false
        ActivityCompat.requestPermissions(
            activity,
            arrayOf(
                Manifest.permission.READ_CONTACTS,
                Manifest.permission.WRITE_CONTACTS,
                Manifest.permission.READ_CALL_LOG,
                Manifest.permission.CALL_PHONE,
                Manifest.permission.READ_PHONE_STATE,
                Manifest.permission.ANSWER_PHONE_CALLS,
            ),
            REQUEST_CORE_PERMISSIONS,
        )
        return true
    }

    override fun isDefaultDialer(): Boolean {
        return telecomManager.defaultDialerPackage == application.packageName
    }

    override fun requestDefaultDialerRole(): Boolean {
        if (isDefaultDialer()) {
            Log.i(TAG, "App is already the default dialer.")
            return true
        }
        val activity = ActivityProvider.currentActivity ?: return false
        return runCatching {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                val roleManager = activity.getSystemService(RoleManager::class.java)
                if (roleManager?.isRoleAvailable(RoleManager.ROLE_DIALER) == true) {
                    Log.i(TAG, "Launching RoleManager dialer role request.")
                    val intent = roleManager.createRequestRoleIntent(RoleManager.ROLE_DIALER)
                    activity.startActivityForResult(intent, REQUEST_DEFAULT_DIALER)
                    return@runCatching true
                }
            }

            val dialerIntent =
                Intent(TelecomManager.ACTION_CHANGE_DEFAULT_DIALER).apply {
                    putExtra(
                        TelecomManager.EXTRA_CHANGE_DEFAULT_DIALER_PACKAGE_NAME,
                        application.packageName,
                    )
                }

            val resolvedActivity = dialerIntent.resolveActivity(activity.packageManager)
            if (resolvedActivity != null) {
                Log.i(TAG, "Launching TelecomManager default dialer intent.")
                activity.startActivityForResult(dialerIntent, REQUEST_DEFAULT_DIALER)
                return@runCatching true
            }

            Log.w(TAG, "Default dialer intents unavailable; opening default apps settings.")
            activity.startActivity(
                Intent(Settings.ACTION_MANAGE_DEFAULT_APPS_SETTINGS).apply {
                    addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                },
            )
            true
        }.getOrElse { exception ->
            Log.w(TAG, "Failed to launch default dialer flow.", exception)
            runCatching {
                activity.startActivity(
                    Intent(Settings.ACTION_MANAGE_DEFAULT_APPS_SETTINGS).apply {
                        addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                    },
                )
            }.onFailure { fallbackException ->
                Log.w(TAG, "Fallback default-app settings launch failed.", fallbackException)
            }
            true
        }
    }

    override fun getCallCapableAccounts(): List<SimAccount?> {
        val outgoingHandle = runCatching {
            telecomManager.userSelectedOutgoingPhoneAccount
        }.getOrNull()

        return runCatching {
            telecomManager.callCapablePhoneAccounts.map { handle ->
                val phoneAccount = telecomManager.getPhoneAccount(handle)
                SimAccount(
                    id = encodePhoneAccountHandle(handle),
                    label = phoneAccount?.label?.toString() ?: handle.id,
                    address = phoneAccount?.address?.schemeSpecificPart,
                    isDefault = handle == outgoingHandle,
                )
            }
        }.getOrElse { exception ->
            if (exception is SecurityException) {
                emptyList()
            } else {
                throw exception
            }
        }
    }

    override fun placeCall(number: String, accountId: String?) {
        val uri = Uri.fromParts(PhoneAccount.SCHEME_TEL, number, null)
        val extras = Bundle()
        decodePhoneAccountHandle(accountId)?.let { handle ->
            extras.putParcelable(TelecomManager.EXTRA_PHONE_ACCOUNT_HANDLE, handle)
        }
        telecomManager.placeCall(uri, extras)
    }

    override fun getCurrentCallState(): CallSessionState? {
        return CallCoordinator.currentCallState()
    }

    override fun answerCall() {
        CallCoordinator.answerCall()
    }

    override fun rejectCall() {
        CallCoordinator.rejectCall()
    }

    override fun disconnectCall() {
        CallCoordinator.disconnectCall()
    }

    override fun setMuted(muted: Boolean) {
        CallCoordinator.setMuted(muted)
    }

    override fun setAudioRoute(route: AudioRoute) {
        CallCoordinator.setAudioRoute(route)
    }

    override fun setHold(onHold: Boolean) {
        CallCoordinator.setHold(onHold)
    }

    override fun playDtmfTone(digit: String) {
        CallCoordinator.playDtmfTone(digit)
    }

    override fun stopDtmfTone() {
        CallCoordinator.stopDtmfTone()
    }

    override fun swapCalls() {
        CallCoordinator.swapCalls()
    }

    override fun mergeCalls() {
        CallCoordinator.mergeCalls()
    }

    private fun hasPermission(permission: String): Boolean {
        return ContextCompat.checkSelfPermission(application, permission) ==
            PackageManager.PERMISSION_GRANTED
    }

    private fun encodePhoneAccountHandle(handle: PhoneAccountHandle): String {
        return "${handle.componentName.flattenToShortString()}|${handle.id}"
    }

    private fun decodePhoneAccountHandle(rawValue: String?): PhoneAccountHandle? {
        if (rawValue.isNullOrBlank()) {
            return null
        }
        val parts = rawValue.split('|')
        if (parts.size != 2) {
            return null
        }
        val component = android.content.ComponentName.unflattenFromString(parts[0]) ?: return null
        return PhoneAccountHandle(component, parts[1])
    }
}
