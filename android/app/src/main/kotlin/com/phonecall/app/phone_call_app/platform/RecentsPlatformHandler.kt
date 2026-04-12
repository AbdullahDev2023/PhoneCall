package com.phonecall.app.phone_call_app.platform

import android.app.Application
import android.content.ContentUris
import android.net.Uri
import android.provider.CallLog
import android.provider.ContactsContract

class RecentsPlatformHandler(
    private val application: Application,
) : RecentsPlatformApi {
    private val resolver = application.contentResolver

    override fun getRecentCalls(filter: CallLogFilter): List<RecentCall?> {
        val recentCalls = mutableListOf<RecentCall>()
        val projection =
            arrayOf(
                CallLog.Calls._ID,
                CallLog.Calls.NUMBER,
                CallLog.Calls.CACHED_NAME,
                CallLog.Calls.CACHED_PHOTO_URI,
                CallLog.Calls.CACHED_LOOKUP_URI,
                CallLog.Calls.DATE,
                CallLog.Calls.DURATION,
                CallLog.Calls.TYPE,
                CallLog.Calls.PHONE_ACCOUNT_ID,
            )
        val selection =
            if (filter == CallLogFilter.MISSED) {
                "${CallLog.Calls.TYPE} = ?"
            } else {
                null
            }
        val args =
            if (filter == CallLogFilter.MISSED) {
                arrayOf(CallLog.Calls.MISSED_TYPE.toString())
            } else {
                null
            }

        resolver.query(
            CallLog.Calls.CONTENT_URI,
            projection,
            selection,
            args,
            "${CallLog.Calls.DATE} DESC",
        )?.use { cursor ->
            val idIndex = cursor.getColumnIndexOrThrow(CallLog.Calls._ID)
            val numberIndex = cursor.getColumnIndexOrThrow(CallLog.Calls.NUMBER)
            val cachedNameIndex = cursor.getColumnIndexOrThrow(CallLog.Calls.CACHED_NAME)
            val photoUriIndex = cursor.getColumnIndexOrThrow(CallLog.Calls.CACHED_PHOTO_URI)
            val lookupUriIndex = cursor.getColumnIndexOrThrow(CallLog.Calls.CACHED_LOOKUP_URI)
            val dateIndex = cursor.getColumnIndexOrThrow(CallLog.Calls.DATE)
            val durationIndex = cursor.getColumnIndexOrThrow(CallLog.Calls.DURATION)
            val typeIndex = cursor.getColumnIndexOrThrow(CallLog.Calls.TYPE)
            val accountIdIndex = cursor.getColumnIndexOrThrow(CallLog.Calls.PHONE_ACCOUNT_ID)

            while (cursor.moveToNext()) {
                val call =
                    RecentCall(
                        id = cursor.getLong(idIndex).toString(),
                        number = cursor.getString(numberIndex) ?: "",
                        displayName = cursor.getString(cachedNameIndex),
                        photoUri = cursor.getString(photoUriIndex),
                        contactId = resolveContactId(cursor.getString(lookupUriIndex)),
                        timestampMillis = cursor.getLong(dateIndex),
                        durationSeconds = cursor.getLong(durationIndex),
                        type = mapCallType(cursor.getInt(typeIndex)),
                        accountId = cursor.getString(accountIdIndex),
                        occurrences = 1,
                    )

                val previous = recentCalls.lastOrNull()
                val shouldGroup =
                    previous?.let {
                        it.number == call.number &&
                            it.type == call.type &&
                            isSameDay(it.timestampMillis, call.timestampMillis)
                    } == true
                if (shouldGroup && previous != null) {
                    recentCalls[recentCalls.lastIndex] =
                        previous.copy(occurrences = (previous.occurrences ?: 1L) + 1L)
                } else {
                    recentCalls.add(call)
                }
            }
        }

        return recentCalls
    }

    override fun getCallDetails(id: String): RecentCall? {
        resolver.query(
            CallLog.Calls.CONTENT_URI,
            arrayOf(
                CallLog.Calls._ID,
                CallLog.Calls.NUMBER,
                CallLog.Calls.CACHED_NAME,
                CallLog.Calls.CACHED_PHOTO_URI,
                CallLog.Calls.CACHED_LOOKUP_URI,
                CallLog.Calls.DATE,
                CallLog.Calls.DURATION,
                CallLog.Calls.TYPE,
                CallLog.Calls.PHONE_ACCOUNT_ID,
            ),
            "${CallLog.Calls._ID} = ?",
            arrayOf(id),
            null,
        )?.use { cursor ->
            if (!cursor.moveToFirst()) {
                return null
            }
            return RecentCall(
                id = cursor.getLong(cursor.getColumnIndexOrThrow(CallLog.Calls._ID)).toString(),
                number = cursor.getString(cursor.getColumnIndexOrThrow(CallLog.Calls.NUMBER)) ?: "",
                displayName = cursor.getString(cursor.getColumnIndexOrThrow(CallLog.Calls.CACHED_NAME)),
                photoUri = cursor.getString(cursor.getColumnIndexOrThrow(CallLog.Calls.CACHED_PHOTO_URI)),
                contactId = resolveContactId(cursor.getString(cursor.getColumnIndexOrThrow(CallLog.Calls.CACHED_LOOKUP_URI))),
                timestampMillis = cursor.getLong(cursor.getColumnIndexOrThrow(CallLog.Calls.DATE)),
                durationSeconds = cursor.getLong(cursor.getColumnIndexOrThrow(CallLog.Calls.DURATION)),
                type = mapCallType(cursor.getInt(cursor.getColumnIndexOrThrow(CallLog.Calls.TYPE))),
                accountId = cursor.getString(cursor.getColumnIndexOrThrow(CallLog.Calls.PHONE_ACCOUNT_ID)),
                occurrences = 1,
            )
        }
        return null
    }

    private fun mapCallType(type: Int): CallType {
        return when (type) {
            CallLog.Calls.INCOMING_TYPE -> CallType.INCOMING
            CallLog.Calls.OUTGOING_TYPE -> CallType.OUTGOING
            CallLog.Calls.MISSED_TYPE -> CallType.MISSED
            CallLog.Calls.REJECTED_TYPE -> CallType.REJECTED
            CallLog.Calls.BLOCKED_TYPE -> CallType.BLOCKED
            CallLog.Calls.VOICEMAIL_TYPE -> CallType.VOICEMAIL
            else -> CallType.UNKNOWN
        }
    }

    private fun resolveContactId(lookupUriString: String?): String? {
        if (lookupUriString.isNullOrBlank()) {
            return null
        }
        return try {
            val uri = Uri.parse(lookupUriString)
            val resolvedUri = ContactsContract.Contacts.lookupContact(resolver, uri) ?: return null
            ContentUris.parseId(resolvedUri).toString()
        } catch (_: Throwable) {
            null
        }
    }

    private fun isSameDay(firstTimestamp: Long?, secondTimestamp: Long?): Boolean {
        if (firstTimestamp == null || secondTimestamp == null) {
            return false
        }
        val firstDay = firstTimestamp / (24L * 60L * 60L * 1000L)
        val secondDay = secondTimestamp / (24L * 60L * 60L * 1000L)
        return firstDay == secondDay
    }
}
