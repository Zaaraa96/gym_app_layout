package com.zahra.gym_app

import android.os.Bundle
import androidx.core.splashscreen.SplashScreen.Companion.installSplashScreen
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        // Keep Android 12+ system splash (navy + C) until the first Flutter frame.
        installSplashScreen()
        super.onCreate(savedInstanceState)
    }
}
