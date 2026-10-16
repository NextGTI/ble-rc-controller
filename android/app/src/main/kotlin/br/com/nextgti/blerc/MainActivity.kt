package br.com.nextgti.blerc

import android.hardware.input.InputManager
import android.os.Build
import android.os.Bundle
import android.os.Handler
import android.view.InputDevice
import android.view.KeyEvent
import android.view.MotionEvent
import android.view.WindowInsetsController
import io.flutter.embedding.android.FlutterActivity
import org.flame_engine.gamepads_android.GamepadsCompatibleActivity

/**
 * Forwards gamepad key/motion events to the `gamepads` plugin
 * (see the plugin's README, "Android Integration").
 */
class MainActivity : FlutterActivity(), GamepadsCompatibleActivity {
    private var keyListener: ((KeyEvent) -> Boolean)? = null
    private var motionListener: ((MotionEvent) -> Boolean)? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        keepNavigationButtonsLight()
    }

    /**
     * The app is dark only, so the Android navigation buttons must be light.
     * On Android 15 and later the system marks the navigation bar as light
     * (dark buttons) on the first layout, after Flutter has asked for light
     * buttons, which leaves them invisible on the dark background. Clear the
     * mark whenever it comes back; reading it each frame costs nothing.
     */
    private fun keepNavigationButtonsLight() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.R) return
        val lightBar = WindowInsetsController.APPEARANCE_LIGHT_NAVIGATION_BARS
        window.decorView.viewTreeObserver.addOnPreDrawListener {
            window.insetsController?.let { c ->
                if (c.systemBarsAppearance and lightBar != 0) c.setSystemBarsAppearance(0, lightBar)
            }
            true
        }
    }

    override fun dispatchGenericMotionEvent(motionEvent: MotionEvent): Boolean {
        if (motionListener?.invoke(motionEvent) == true) return true
        return super.dispatchGenericMotionEvent(motionEvent)
    }

    override fun dispatchKeyEvent(keyEvent: KeyEvent): Boolean {
        if (keyListener?.invoke(keyEvent) == true) return true
        return super.dispatchKeyEvent(keyEvent)
    }

    override fun registerInputDeviceListener(
        listener: InputManager.InputDeviceListener,
        handler: Handler?,
    ) {
        val inputManager = getSystemService(INPUT_SERVICE) as InputManager
        inputManager.registerInputDeviceListener(listener, null)
    }

    override fun registerKeyEventHandler(handler: (KeyEvent) -> Boolean) {
        keyListener = handler
    }

    override fun registerMotionEventHandler(handler: (MotionEvent) -> Boolean) {
        motionListener = handler
    }
}
