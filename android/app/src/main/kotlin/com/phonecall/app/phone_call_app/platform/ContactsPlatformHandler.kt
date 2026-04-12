package com.phonecall.app.phone_call_app.platform

import android.app.Application
import android.content.ContentProviderOperation
import android.content.ContentUris
import android.content.ContentValues
import android.provider.ContactsContract

class ContactsPlatformHandler(
    private val application: Application,
) : ContactsPlatformApi {
    private val resolver = application.contentResolver

    override fun searchContacts(query: String): List<ContactSummary?> {
        val results = linkedMapOf<String, ContactSummary>()
        val uri = ContactsContract.CommonDataKinds.Phone.CONTENT_URI
        val projection =
            arrayOf(
                ContactsContract.CommonDataKinds.Phone.CONTACT_ID,
                ContactsContract.CommonDataKinds.Phone.LOOKUP_KEY,
                ContactsContract.CommonDataKinds.Phone.DISPLAY_NAME_PRIMARY,
                ContactsContract.CommonDataKinds.Phone.NUMBER,
                ContactsContract.CommonDataKinds.Phone.PHOTO_URI,
                ContactsContract.CommonDataKinds.Phone.STARRED,
            )
        val selection =
            if (query.isBlank()) {
                null
            } else {
                "${ContactsContract.CommonDataKinds.Phone.DISPLAY_NAME_PRIMARY} LIKE ? OR ${ContactsContract.CommonDataKinds.Phone.NUMBER} LIKE ?"
            }
        val args =
            if (query.isBlank()) {
                null
            } else {
                arrayOf("%$query%", "%$query%")
            }

        resolver.query(
            uri,
            projection,
            selection,
            args,
            "${ContactsContract.CommonDataKinds.Phone.STARRED} DESC, ${ContactsContract.CommonDataKinds.Phone.DISPLAY_NAME_PRIMARY} COLLATE NOCASE ASC",
        )?.use { cursor ->
            val idIndex = cursor.getColumnIndexOrThrow(ContactsContract.CommonDataKinds.Phone.CONTACT_ID)
            val lookupIndex = cursor.getColumnIndexOrThrow(ContactsContract.CommonDataKinds.Phone.LOOKUP_KEY)
            val displayNameIndex =
                cursor.getColumnIndexOrThrow(ContactsContract.CommonDataKinds.Phone.DISPLAY_NAME_PRIMARY)
            val numberIndex = cursor.getColumnIndexOrThrow(ContactsContract.CommonDataKinds.Phone.NUMBER)
            val photoUriIndex = cursor.getColumnIndexOrThrow(ContactsContract.CommonDataKinds.Phone.PHOTO_URI)
            val starredIndex = cursor.getColumnIndexOrThrow(ContactsContract.CommonDataKinds.Phone.STARRED)

            while (cursor.moveToNext()) {
                val contactId = cursor.getLong(idIndex).toString()
                if (results.containsKey(contactId)) {
                    continue
                }
                results[contactId] =
                    ContactSummary(
                        id = contactId,
                        lookupKey = cursor.getString(lookupIndex),
                        displayName =
                            cursor.getString(displayNameIndex)
                                ?: cursor.getString(numberIndex)
                                ?: "Unknown",
                        photoUri = cursor.getString(photoUriIndex),
                        isStarred = cursor.getInt(starredIndex) == 1,
                        primaryNumber = cursor.getString(numberIndex),
                    )
            }
        }

        return results.values.toList()
    }

    override fun getContact(id: String): ContactDetail? {
        val contactId = id.toLongOrNull() ?: return null
        var lookupKey: String? = null
        var displayName: String? = null
        var photoUri: String? = null
        var isStarred = false

        val exists =
            resolver.query(
                ContentUris.withAppendedId(ContactsContract.Contacts.CONTENT_URI, contactId),
                arrayOf(
                    ContactsContract.Contacts._ID,
                    ContactsContract.Contacts.LOOKUP_KEY,
                    ContactsContract.Contacts.DISPLAY_NAME_PRIMARY,
                    ContactsContract.Contacts.PHOTO_URI,
                    ContactsContract.Contacts.STARRED,
                ),
                null,
                null,
                null,
            )?.use { cursor ->
                if (!cursor.moveToFirst()) {
                    false
                } else {
                    lookupKey =
                        cursor.getString(
                            cursor.getColumnIndexOrThrow(ContactsContract.Contacts.LOOKUP_KEY),
                        )
                    displayName =
                        cursor.getString(
                            cursor.getColumnIndexOrThrow(
                                ContactsContract.Contacts.DISPLAY_NAME_PRIMARY,
                            ),
                        )
                    photoUri =
                        cursor.getString(
                            cursor.getColumnIndexOrThrow(ContactsContract.Contacts.PHOTO_URI),
                        )
                    isStarred =
                        cursor.getInt(
                            cursor.getColumnIndexOrThrow(ContactsContract.Contacts.STARRED),
                        ) == 1
                    true
                }
            } ?: false
        if (!exists) {
            return null
        }

        var givenName: String? = null
        var familyName: String? = null
        var company: String? = null
        val phoneNumbers = mutableListOf<PhoneNumberEntry?>()
        val emailAddresses = mutableListOf<EmailEntry?>()

        resolver.query(
            ContactsContract.Data.CONTENT_URI,
            arrayOf(
                ContactsContract.Data.MIMETYPE,
                ContactsContract.CommonDataKinds.StructuredName.GIVEN_NAME,
                ContactsContract.CommonDataKinds.StructuredName.FAMILY_NAME,
                ContactsContract.CommonDataKinds.Organization.COMPANY,
                ContactsContract.CommonDataKinds.Phone.NUMBER,
                ContactsContract.CommonDataKinds.Phone.TYPE,
                ContactsContract.CommonDataKinds.Phone.LABEL,
                ContactsContract.CommonDataKinds.Phone.NORMALIZED_NUMBER,
                ContactsContract.CommonDataKinds.Email.ADDRESS,
                ContactsContract.CommonDataKinds.Email.TYPE,
                ContactsContract.CommonDataKinds.Email.LABEL,
            ),
            "${ContactsContract.Data.CONTACT_ID} = ?",
            arrayOf(id),
            null,
        )?.use { cursor ->
            val mimeIndex = cursor.getColumnIndexOrThrow(ContactsContract.Data.MIMETYPE)
            while (cursor.moveToNext()) {
                when (cursor.getString(mimeIndex)) {
                    ContactsContract.CommonDataKinds.StructuredName.CONTENT_ITEM_TYPE -> {
                        givenName =
                            cursor.getString(
                                cursor.getColumnIndexOrThrow(
                                    ContactsContract.CommonDataKinds.StructuredName.GIVEN_NAME,
                                ),
                            )
                        familyName =
                            cursor.getString(
                                cursor.getColumnIndexOrThrow(
                                    ContactsContract.CommonDataKinds.StructuredName.FAMILY_NAME,
                                ),
                            )
                    }
                    ContactsContract.CommonDataKinds.Organization.CONTENT_ITEM_TYPE -> {
                        company =
                            cursor.getString(
                                cursor.getColumnIndexOrThrow(
                                    ContactsContract.CommonDataKinds.Organization.COMPANY,
                                ),
                            )
                    }
                    ContactsContract.CommonDataKinds.Phone.CONTENT_ITEM_TYPE -> {
                        val type =
                            cursor.getInt(
                                cursor.getColumnIndexOrThrow(
                                    ContactsContract.CommonDataKinds.Phone.TYPE,
                                ),
                            )
                        val customLabel =
                            cursor.getString(
                                cursor.getColumnIndexOrThrow(
                                    ContactsContract.CommonDataKinds.Phone.LABEL,
                                ),
                            )
                        phoneNumbers.add(
                            PhoneNumberEntry(
                                label =
                                    ContactsContract.CommonDataKinds.Phone
                                        .getTypeLabel(application.resources, type, customLabel)
                                        .toString(),
                                number =
                                    cursor.getString(
                                        cursor.getColumnIndexOrThrow(
                                            ContactsContract.CommonDataKinds.Phone.NUMBER,
                                        ),
                                    ),
                                normalizedNumber =
                                    cursor.getString(
                                        cursor.getColumnIndexOrThrow(
                                            ContactsContract.CommonDataKinds.Phone.NORMALIZED_NUMBER,
                                        ),
                                    ),
                            ),
                        )
                    }
                    ContactsContract.CommonDataKinds.Email.CONTENT_ITEM_TYPE -> {
                        val type =
                            cursor.getInt(
                                cursor.getColumnIndexOrThrow(
                                    ContactsContract.CommonDataKinds.Email.TYPE,
                                ),
                            )
                        val customLabel =
                            cursor.getString(
                                cursor.getColumnIndexOrThrow(
                                    ContactsContract.CommonDataKinds.Email.LABEL,
                                ),
                            )
                        emailAddresses.add(
                            EmailEntry(
                                label =
                                    ContactsContract.CommonDataKinds.Email
                                        .getTypeLabel(application.resources, type, customLabel)
                                        .toString(),
                                address =
                                    cursor.getString(
                                        cursor.getColumnIndexOrThrow(
                                            ContactsContract.CommonDataKinds.Email.ADDRESS,
                                        ),
                                    ),
                            ),
                        )
                    }
                }
            }
        }

        return ContactDetail(
            id = contactId.toString(),
            lookupKey = lookupKey,
            givenName = givenName,
            familyName = familyName,
            displayName = displayName,
            company = company,
            photoUri = photoUri,
            isStarred = isStarred,
            phoneNumbers = phoneNumbers,
            emailAddresses = emailAddresses,
        )
    }

    override fun saveContact(contact: EditableContact): ContactDetail {
        val existingContactId = contact.contactId
        val rawContactId = existingContactId?.let(::findRawContactId)
        val operations = mutableListOf<ContentProviderOperation>()

        val currentRawContactId: Long
        val insertAtIndex: Int

        if (rawContactId == null) {
            insertAtIndex = operations.size
            operations.add(
                ContentProviderOperation.newInsert(ContactsContract.RawContacts.CONTENT_URI)
                    .withValue(ContactsContract.RawContacts.ACCOUNT_TYPE, null)
                    .withValue(ContactsContract.RawContacts.ACCOUNT_NAME, null)
                    .build(),
            )
            currentRawContactId = -1L
        } else {
            insertAtIndex = -1
            currentRawContactId = rawContactId
            operations.add(
                ContentProviderOperation.newDelete(ContactsContract.Data.CONTENT_URI)
                    .withSelection(
                        "${ContactsContract.Data.RAW_CONTACT_ID} = ?",
                        arrayOf(rawContactId.toString()),
                    )
                    .build(),
            )
        }

        fun rawContactReference(builder: ContentProviderOperation.Builder): ContentProviderOperation.Builder {
            return if (currentRawContactId == -1L) {
                builder.withValueBackReference(ContactsContract.Data.RAW_CONTACT_ID, insertAtIndex)
            } else {
                builder.withValue(ContactsContract.Data.RAW_CONTACT_ID, currentRawContactId)
            }
        }

        operations.add(
            rawContactReference(
                ContentProviderOperation.newInsert(ContactsContract.Data.CONTENT_URI),
            )
                .withValue(
                    ContactsContract.Data.MIMETYPE,
                    ContactsContract.CommonDataKinds.StructuredName.CONTENT_ITEM_TYPE,
                )
                .withValue(
                    ContactsContract.CommonDataKinds.StructuredName.GIVEN_NAME,
                    contact.givenName,
                )
                .withValue(
                    ContactsContract.CommonDataKinds.StructuredName.FAMILY_NAME,
                    contact.familyName,
                )
                .build(),
        )

        if (!contact.company.isNullOrBlank()) {
            operations.add(
                rawContactReference(
                    ContentProviderOperation.newInsert(ContactsContract.Data.CONTENT_URI),
                )
                    .withValue(
                        ContactsContract.Data.MIMETYPE,
                        ContactsContract.CommonDataKinds.Organization.CONTENT_ITEM_TYPE,
                    )
                    .withValue(
                        ContactsContract.CommonDataKinds.Organization.COMPANY,
                        contact.company,
                    )
                    .build(),
            )
        }

        contact.phoneNumbers.orEmpty().filterNotNull().forEach { phone ->
            operations.add(
                rawContactReference(
                    ContentProviderOperation.newInsert(ContactsContract.Data.CONTENT_URI),
                )
                    .withValue(
                        ContactsContract.Data.MIMETYPE,
                        ContactsContract.CommonDataKinds.Phone.CONTENT_ITEM_TYPE,
                    )
                    .withValue(ContactsContract.CommonDataKinds.Phone.NUMBER, phone.number)
                    .withValue(ContactsContract.CommonDataKinds.Phone.TYPE, ContactsContract.CommonDataKinds.Phone.TYPE_MOBILE)
                    .withValue(ContactsContract.CommonDataKinds.Phone.LABEL, phone.label)
                    .withValue(
                        ContactsContract.CommonDataKinds.Phone.NORMALIZED_NUMBER,
                        phone.normalizedNumber,
                    )
                    .build(),
            )
        }

        contact.emailAddresses.orEmpty().filterNotNull().forEach { email ->
            operations.add(
                rawContactReference(
                    ContentProviderOperation.newInsert(ContactsContract.Data.CONTENT_URI),
                )
                    .withValue(
                        ContactsContract.Data.MIMETYPE,
                        ContactsContract.CommonDataKinds.Email.CONTENT_ITEM_TYPE,
                    )
                    .withValue(ContactsContract.CommonDataKinds.Email.ADDRESS, email.address)
                    .withValue(ContactsContract.CommonDataKinds.Email.TYPE, ContactsContract.CommonDataKinds.Email.TYPE_HOME)
                    .withValue(ContactsContract.CommonDataKinds.Email.LABEL, email.label)
                    .build(),
            )
        }

        val results = resolver.applyBatch(ContactsContract.AUTHORITY, ArrayList(operations))
        val savedContactId =
            if (currentRawContactId == -1L) {
                val newRawContactId =
                    ContentUris.parseId(results.first().uri ?: error("Missing raw contact uri"))
                findContactIdForRawContact(newRawContactId)
            } else {
                existingContactId?.toLongOrNull()
            } ?: error("Unable to resolve saved contact")

        val values = ContentValues().apply {
            put(ContactsContract.Contacts.STARRED, if (contact.isStarred == true) 1 else 0)
        }
        resolver.update(
            ContentUris.withAppendedId(ContactsContract.Contacts.CONTENT_URI, savedContactId),
            values,
            null,
            null,
        )

        return getContact(savedContactId.toString()) ?: error("Unable to load saved contact")
    }

    override fun deleteContact(id: String) {
        val contactId = id.toLongOrNull() ?: return
        resolver.delete(
            ContentUris.withAppendedId(ContactsContract.Contacts.CONTENT_URI, contactId),
            null,
            null,
        )
    }

    override fun toggleFavorite(id: String, isStarred: Boolean) {
        val contactId = id.toLongOrNull() ?: return
        val values = ContentValues().apply {
            put(ContactsContract.Contacts.STARRED, if (isStarred) 1 else 0)
        }
        resolver.update(
            ContentUris.withAppendedId(ContactsContract.Contacts.CONTENT_URI, contactId),
            values,
            null,
            null,
        )
    }

    private fun findRawContactId(contactId: String): Long? {
        resolver.query(
            ContactsContract.RawContacts.CONTENT_URI,
            arrayOf(ContactsContract.RawContacts._ID),
            "${ContactsContract.RawContacts.CONTACT_ID} = ?",
            arrayOf(contactId),
            "${ContactsContract.RawContacts._ID} ASC",
        )?.use { cursor ->
            if (cursor.moveToFirst()) {
                return cursor.getLong(cursor.getColumnIndexOrThrow(ContactsContract.RawContacts._ID))
            }
        }
        return null
    }

    private fun findContactIdForRawContact(rawContactId: Long): Long? {
        resolver.query(
            ContactsContract.RawContacts.CONTENT_URI,
            arrayOf(ContactsContract.RawContacts.CONTACT_ID),
            "${ContactsContract.RawContacts._ID} = ?",
            arrayOf(rawContactId.toString()),
            null,
        )?.use { cursor ->
            if (cursor.moveToFirst()) {
                return cursor.getLong(cursor.getColumnIndexOrThrow(ContactsContract.RawContacts.CONTACT_ID))
            }
        }
        return null
    }
}
