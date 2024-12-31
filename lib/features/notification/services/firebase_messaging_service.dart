/// https://stackoverflow.com/questions/37407366/firebase-fcm-notifications-click-action-payload
/// https://firebase.google.com/docs/cloud-messaging/android/client

// lib/features/notification/services/firebase_messaging_service.dart

/* import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';

public class MyFirebaseMessagingService extends FirebaseMessagingService {

    private static final String TAG = "MyFirebaseMsgService";

    @Override
    public void onMessageReceived(RemoteMessage remoteMessage) {
      String message = "";
      obj = remoteMessage.getData().get("text");
      if (obj != null) {
        try {
          message = obj.toString();
        } catch (Exception e) {
          message = "";
          e.printStackTrace();
        }
      }

      String link = "";
      obj = remoteMessage.getData().get("link");
      if (obj != null) {
        try {
          link = (String) obj;
        } catch (Exception e) {
          link = "";
          e.printStackTrace();
        }
      }

      Intent intent;
      PendingIntent pendingIntent;
      if (link.equals("")) { // Simply run your activity
        intent = new Intent(this, MainActivity.class);
        intent.addFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP);
      } else { // open a link
        String url = "";
        if (!link.equals("")) {
          intent = new Intent(Intent.ACTION_VIEW);
          intent.setData(Uri.parse(link));
          intent.addFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP);
        }
      }
      pendingIntent = PendingIntent.getActivity(this, 0 /* Request code */, intent,
          PendingIntent.FLAG_ONE_SHOT);


      NotificationCompat.Builder notificationBuilder = null;

      try {
        notificationBuilder = new NotificationCompat.Builder(this)
            .setSmallIcon(R.drawable.ic_notif_symulti)          // don't need to pass icon with your message if it's already in your app !
            .setContentTitle(URLDecoder.decode(getString(R.string.app_name), "UTF-8"))
            .setContentText(URLDecoder.decode(message, "UTF-8"))
            .setAutoCancel(true)
            .setSound(RingtoneManager.getDefaultUri(RingtoneManager.TYPE_NOTIFICATION))
            .setContentIntent(pendingIntent);
        } catch (UnsupportedEncodingException e) {
          e.printStackTrace();
        }

        if (notificationBuilder != null) {
          NotificationManager notificationManager =
              (NotificationManager) getSystemService(Context.NOTIFICATION_SERVICE);
          notificationManager.notify(id, notificationBuilder.build());
        } else {
          Log.d(TAG, "error NotificationManager");
        }
      }
    }
}
*/
