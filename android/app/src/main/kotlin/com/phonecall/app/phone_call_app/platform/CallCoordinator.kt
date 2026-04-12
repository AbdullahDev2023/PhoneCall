package com.phonecall.app.phone_call_app.platform

import android.telecom.Call
import android.telecom.CallAudioState
import android.telecom.InCallService
import android.telecom.VideoProfile

object CallCoordinator {
    private var inCallService: InCallService? = null
    private var callStateApi: CallStateFlutterApi? = null
    private val trackedCalls = linkedMapOf<Call, Call.Callback>()
    private var currentAudioState: CallAudioState? = null

    fun initialize(api: CallStateFlutterApi) {
        callStateApi = api
    }

    fun attachService(service: InCallService) {
        inCallService = service
        currentAudioState = service.callAudioState
        emitState()
    }

    fun detachService(service: InCallService) {
        if (inCallService === service) {
            inCallService = null
            currentAudioState = null
        }
    }

    fun onCallAdded(call: Call) {
        if (trackedCalls.containsKey(call)) {
            return
        }
        val callback =
            object : Call.Callback() {
                override fun onStateChanged(call: Call, state: Int) {
                    emitState(showFullScreen = state == Call.STATE_RINGING)
                }

                override fun onDetailsChanged(call: Call, details: Call.Details) {
                    emitState(showFullScreen = call.state == Call.STATE_RINGING)
                }

                override fun onConferenceableCallsChanged(call: Call, conferenceableCalls: MutableList<Call>) {
                    emitState()
                }

                override fun onChildrenChanged(call: Call, children: MutableList<Call>) {
                    emitState()
                }

                override fun onParentChanged(call: Call, parent: Call?) {
                    emitState()
                }

                override fun onCallDestroyed(call: Call) {
                    onCallRemoved(call)
                }
            }
        trackedCalls[call] = callback
        call.registerCallback(callback)
        emitState(showFullScreen = call.state == Call.STATE_RINGING)
    }

    fun onCallRemoved(call: Call) {
        trackedCalls.remove(call)?.let(call::unregisterCallback)
        emitState()
    }

    fun onAudioStateChanged(audioState: CallAudioState?) {
        currentAudioState = audioState
        emitState()
    }

    fun currentCallState(): CallSessionState? {
        return primaryCall()?.let { buildState(it, false) }
    }

    fun answerCall() {
        primaryCall()?.answer(VideoProfile.STATE_AUDIO_ONLY)
    }

    fun rejectCall() {
        primaryCall()?.reject(false, null)
    }

    fun disconnectCall() {
        primaryCall()?.disconnect()
    }

    fun setMuted(muted: Boolean) {
        inCallService?.setMuted(muted)
        emitState()
    }

    fun setAudioRoute(route: AudioRoute) {
        val mask =
            when (route) {
                AudioRoute.BLUETOOTH -> CallAudioState.ROUTE_BLUETOOTH
                AudioRoute.SPEAKER -> CallAudioState.ROUTE_SPEAKER
                AudioRoute.WIRED_HEADSET -> CallAudioState.ROUTE_WIRED_HEADSET
                else -> CallAudioState.ROUTE_EARPIECE
            }
        inCallService?.setAudioRoute(mask)
        emitState()
    }

    fun setHold(onHold: Boolean) {
        val call = primaryCall() ?: return
        if (onHold) {
            call.hold()
        } else {
            call.unhold()
        }
    }

    fun playDtmfTone(digit: String) {
        val symbol = digit.firstOrNull() ?: return
        primaryCall()?.playDtmfTone(symbol)
    }

    fun stopDtmfTone() {
        primaryCall()?.stopDtmfTone()
    }

    fun swapCalls() {
        val activeCall = trackedCalls.keys.firstOrNull { it.state == Call.STATE_ACTIVE }
        val heldCall = trackedCalls.keys.firstOrNull { it.state == Call.STATE_HOLDING }
        activeCall?.hold()
        heldCall?.unhold()
    }

    fun mergeCalls() {
        val currentCall = primaryCall() ?: return
        val conferenceable = currentCall.conferenceableCalls.firstOrNull() ?: return
        currentCall.conference(conferenceable)
    }

    private fun primaryCall(): Call? {
        val calls = trackedCalls.keys
        return calls.firstOrNull { it.state == Call.STATE_RINGING }
            ?: calls.firstOrNull { it.state == Call.STATE_ACTIVE }
            ?: calls.firstOrNull { it.state == Call.STATE_DIALING || it.state == Call.STATE_CONNECTING }
            ?: calls.firstOrNull { it.state == Call.STATE_HOLDING }
            ?: calls.firstOrNull { it.state != Call.STATE_DISCONNECTED }
    }

    private fun emitState(showFullScreen: Boolean = false) {
        val state = currentCallState()
        if (state == null) {
            callStateApi?.onCallStateChanged(
                CallSessionState(status = CallStatus.IDLE),
            ) { _ -> }
            return
        }
        val outgoing = state.copy(shouldShowFullScreen = showFullScreen || state.shouldShowFullScreen == true)
        callStateApi?.onCallStateChanged(outgoing) { _ -> }
    }

    private fun buildState(call: Call, showFullScreen: Boolean): CallSessionState {
        val details = call.details
        val canHold =
            details.can(Call.Details.CAPABILITY_HOLD) ||
                details.can(Call.Details.CAPABILITY_SUPPORT_HOLD)
        val supportedAudioRoutes = supportedAudioRoutes(currentAudioState)

        return CallSessionState(
            callId = call.hashCode().toString(),
            number = details.handle?.schemeSpecificPart,
            displayName =
                details.contactDisplayName?.toString()
                    ?: details.callerDisplayName?.toString(),
            photoUri = details.contactPhotoUri?.toString(),
            status = mapCallStatus(call.state),
            isMuted = currentAudioState?.isMuted ?: false,
            canMute = true,
            canHold = canHold,
            isOnHold = call.state == Call.STATE_HOLDING,
            canMerge =
                details.can(Call.Details.CAPABILITY_MERGE_CONFERENCE) ||
                    call.conferenceableCalls.isNotEmpty(),
            canSwap = trackedCalls.keys.count { it.state == Call.STATE_HOLDING || it.state == Call.STATE_ACTIVE } > 1,
            canAnswer = call.state == Call.STATE_RINGING,
            canReject = call.state == Call.STATE_RINGING,
            canDisconnect = call.state != Call.STATE_DISCONNECTED,
            canDtmf = details.can(Call.Details.CAPABILITY_RESPOND_VIA_TEXT).not(),
            isConference = call.details.hasProperty(Call.Details.PROPERTY_CONFERENCE),
            shouldShowFullScreen = showFullScreen || call.state == Call.STATE_RINGING,
            connectTimeMillis = details.connectTimeMillis,
            selectedAudioRoute = mapAudioRoute(currentAudioState?.route),
            availableAudioRoutes = supportedAudioRoutes,
        )
    }

    private fun supportedAudioRoutes(audioState: CallAudioState?): List<AudioRoute> {
        val routes = mutableListOf<AudioRoute>()
        val mask = audioState?.supportedRouteMask ?: CallAudioState.ROUTE_EARPIECE
        if (mask and CallAudioState.ROUTE_EARPIECE != 0) {
            routes.add(AudioRoute.EARPIECE)
        }
        if (mask and CallAudioState.ROUTE_SPEAKER != 0) {
            routes.add(AudioRoute.SPEAKER)
        }
        if (mask and CallAudioState.ROUTE_BLUETOOTH != 0) {
            routes.add(AudioRoute.BLUETOOTH)
        }
        if (mask and CallAudioState.ROUTE_WIRED_HEADSET != 0) {
            routes.add(AudioRoute.WIRED_HEADSET)
        }
        return routes
    }

    private fun mapCallStatus(state: Int): CallStatus {
        return when (state) {
            Call.STATE_RINGING -> CallStatus.RINGING
            Call.STATE_DIALING,
            Call.STATE_CONNECTING,
            Call.STATE_NEW,
            Call.STATE_SELECT_PHONE_ACCOUNT,
            -> CallStatus.DIALING
            Call.STATE_ACTIVE -> CallStatus.ACTIVE
            Call.STATE_HOLDING -> CallStatus.HELD
            Call.STATE_DISCONNECTED,
            Call.STATE_DISCONNECTING,
            -> CallStatus.DISCONNECTED
            else -> CallStatus.IDLE
        }
    }

    private fun mapAudioRoute(routeMask: Int?): AudioRoute {
        return when {
            routeMask == null -> AudioRoute.EARPIECE
            routeMask and CallAudioState.ROUTE_BLUETOOTH != 0 -> AudioRoute.BLUETOOTH
            routeMask and CallAudioState.ROUTE_SPEAKER != 0 -> AudioRoute.SPEAKER
            routeMask and CallAudioState.ROUTE_WIRED_HEADSET != 0 -> AudioRoute.WIRED_HEADSET
            else -> AudioRoute.EARPIECE
        }
    }
}
