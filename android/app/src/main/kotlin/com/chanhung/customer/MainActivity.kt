package com.chanhung.customer

import androidx.credentials.CredentialManager
import androidx.credentials.GetCredentialRequest
import androidx.credentials.GetPublicKeyCredentialOption
import androidx.credentials.PublicKeyCredential
import androidx.credentials.exceptions.GetCredentialException
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch

class MainActivity : FlutterFragmentActivity() {
    private val passkeyChannel = "chanhung/passkey"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, passkeyChannel)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "getCredential" -> {
                        val requestJson = call.argument<String>("requestJson")
                        if (requestJson.isNullOrBlank()) {
                            result.error(
                                "PASSKEY_REQUEST_EMPTY",
                                "Missing passkey request",
                                null
                            )
                        } else {
                            getPasskeyCredential(requestJson, result)
                        }
                    }

                    else -> result.notImplemented()
                }
            }
    }

    private fun getPasskeyCredential(requestJson: String, result: MethodChannel.Result) {
        val credentialManager = CredentialManager.create(this)
        val passkeyOption = GetPublicKeyCredentialOption(requestJson = requestJson)
        val credentialRequest = GetCredentialRequest(
            credentialOptions = listOf(passkeyOption),
            preferImmediatelyAvailableCredentials = false
        )

        CoroutineScope(Dispatchers.Main).launch {
            try {
                val response = credentialManager.getCredential(
                    context = this@MainActivity,
                    request = credentialRequest
                )
                val credential = response.credential
                if (credential is PublicKeyCredential) {
                    result.success(credential.authenticationResponseJson)
                } else {
                    result.error(
                        "PASSKEY_UNEXPECTED_CREDENTIAL",
                        "No passkey credential was returned",
                        null
                    )
                }
            } catch (error: GetCredentialException) {
                result.error(
                    "PASSKEY_ERROR",
                    error.message ?: "Passkey sign-in failed",
                    null
                )
            } catch (error: Throwable) {
                result.error(
                    "PASSKEY_ERROR",
                    error.message ?: "Passkey sign-in failed",
                    null
                )
            }
        }
    }
}
