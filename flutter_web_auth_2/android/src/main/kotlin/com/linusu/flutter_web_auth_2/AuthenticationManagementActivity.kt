package com.linusu.flutter_web_auth_2

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Bundle
import androidx.browser.customtabs.CustomTabsIntent

class AuthenticationManagementActivity(
) : Activity() {
    companion object {
        const val KEY_AUTH_STARTED: String = "authStarted"
        const val KEY_AUTH_URI: String = "authUri"
        const val KEY_AUTH_OPTION_INTENT_FLAGS: String = "authOptionsIntentFlags"
        const val KEY_AUTH_OPTION_TARGET_PACKAGE: String = "authOptionsTargetPackage"

        fun createResponseHandlingIntent(context: Context): Intent {
            val intent = Intent(context, AuthenticationManagementActivity::class.java)
            intent.addFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP or Intent.FLAG_ACTIVITY_SINGLE_TOP)
            return intent
        }
    }
    private var authStarted: Boolean = false
    private lateinit var authenticationUri: Uri
    private var intentFlags: Int = 0
    private var targetPackage: String? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        if (savedInstanceState == null) {
            extractState(intent.extras)
        } else {
            extractState(savedInstanceState)
        }
    }

    override fun onResume() {
        super.onResume()

        if (!authStarted) {
            val intent = CustomTabsIntent.Builder().build()
            intent.intent.addFlags(intentFlags)

            if (targetPackage != null) {
                intent.intent.setPackage(targetPackage)
            }
            intent.launchUrl(this, authenticationUri)
            authStarted = true
            return
        }
        /* If the authentication was already started and we've returned here, the user either
         * completed or cancelled authentication.
         * Either way we want to return to our original flutter activity, so just finish here
         */
        finish()
    }

    override fun onNewIntent(intent: Intent?) {
        super.onNewIntent(intent)
        setIntent(intent);
    }

    override fun onSaveInstanceState(outState: Bundle) {
        super.onSaveInstanceState(outState)
        outState.putBoolean(KEY_AUTH_STARTED, authStarted)
        outState.putParcelable(KEY_AUTH_URI, authenticationUri)
        outState.putInt(KEY_AUTH_OPTION_INTENT_FLAGS, intentFlags)
        outState.putString(
            KEY_AUTH_OPTION_TARGET_PACKAGE,
            targetPackage
        )
    }

    private fun extractState(state: Bundle?) {
        if (state == null) {
            finish()
            return
        }
        authStarted = state.getBoolean(KEY_AUTH_STARTED, false)
        authenticationUri = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            state.getParcelable(KEY_AUTH_URI, Uri::class.java)
        } else {
            @Suppress("deprecation")
            state.getParcelable(KEY_AUTH_URI)
        } ?: throw IllegalStateException("Authentication URI is null")
        intentFlags = state.getInt(KEY_AUTH_OPTION_INTENT_FLAGS, 0)
        targetPackage = state.getString(KEY_AUTH_OPTION_TARGET_PACKAGE)
    }
}
