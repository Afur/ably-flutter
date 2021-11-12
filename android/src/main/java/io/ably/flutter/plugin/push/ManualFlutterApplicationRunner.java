package io.ably.flutter.plugin.push;

import static io.ably.flutter.plugin.generated.PlatformConstants.PlatformMethod.pushOnBackgroundMessage;
import static io.ably.flutter.plugin.generated.PlatformConstants.PlatformMethod.pushSetOnBackgroundMessage;

import android.content.Context;
import android.content.Intent;
import android.util.Log;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;

import com.google.firebase.messaging.RemoteMessage;

import io.ably.flutter.plugin.AblyMessageCodec;
import io.ably.flutter.plugin.util.CipherParamsStorage;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.embedding.engine.dart.DartExecutor;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.StandardMethodCodec;

/**
 * This class is used when the application was terminated when the push notification is received.
 * See [PushMessagingEventHandlers.java] to see where push notifications being handled whilst the
 * app is in the background or the foreground.
 *
 * This class can generified to launch the app manually for any purpose, but currently it
 * launches the Flutter application and sends it a RemoteMessage.
 */
public class ManualFlutterApplicationRunner implements MethodChannel.MethodCallHandler {
  private static final String TAG = ManualFlutterApplicationRunner.class.getName();
  private final FirebaseMessagingReceiver broadcastReceiver;
  private final RemoteMessage remoteMessage;
  private final MethodChannel backgroundMethodChannel;

  @NonNull
  private final FlutterEngine flutterEngine;
  // Launch the users Flutter app and pass it the RemoteMessage.
  // Use this when noo existing Flutter Activity is running.
  public ManualFlutterApplicationRunner(Context context, FirebaseMessagingReceiver receiver, Intent intent) {
    this.broadcastReceiver = receiver;
    this.remoteMessage = new RemoteMessage(intent.getExtras());
    flutterEngine = new FlutterEngine(context, null);
    DartExecutor executor = flutterEngine.getDartExecutor();
    backgroundMethodChannel = new MethodChannel(executor.getBinaryMessenger(), "io.ably.flutter.plugin.background", new StandardMethodCodec(new AblyMessageCodec(new CipherParamsStorage())));
    backgroundMethodChannel.setMethodCallHandler(this);
    // Get and launch the users app isolate manually:
    executor.executeDartEntrypoint(DartExecutor.DartEntrypoint.createDefault());
    // Even though lifecycle parameter is @NonNull, the implementation `FlutterEngineConnectionRegistry`
    // does not use it, because it is a bug in the API design. See https://github.com/flutter/flutter/issues/90316
    flutterEngine.getBroadcastReceiverControlSurface().attachToBroadcastReceiver(receiver, null);
  }

  @Override
  public void onMethodCall(@NonNull MethodCall call, @NonNull MethodChannel.Result result) {
    if (call.method.equals(pushSetOnBackgroundMessage)) {
      // This signals that the manually spawned app is ready to receive a message to handle.
      // We ask the user to set the background message handler early on.
      backgroundMethodChannel.invokeMethod(pushOnBackgroundMessage, remoteMessage, new MethodChannel.Result() {
            @Override
            public void success(@Nullable Object result) {
              finish();
            }

            @Override
            public void error(String errorCode, @Nullable String errorMessage, @Nullable Object errorDetails) {
              Log.e(TAG, String.format("pushOnBackgroundMessage method call from Java to Dart returned error.\n " +
                  "errorCode: %s\n" +
                  "errorMessage: %s\n" +
                  "errorDetails: %s\n", errorCode, errorMessage, errorDetails));
              finish();
            }

            @Override
            public void notImplemented() {
              Log.e(TAG, "Method: pushOnBackgroundMessage did not receive message on dart side. " +
                  "Either the binding has not been initialized or the method call handler was not registered to receive this method.");
              finish();
            }
          }
      );
    } else {
      result.notImplemented();
    }
  }

  private void finish() {
    flutterEngine.getBroadcastReceiverControlSurface().detachFromBroadcastReceiver();
    flutterEngine.destroy();
    broadcastReceiver.finish();
  }
}
