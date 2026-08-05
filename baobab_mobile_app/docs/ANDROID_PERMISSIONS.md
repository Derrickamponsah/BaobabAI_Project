# Android / iOS permissions

After running `flutter create .` inside `mobile/`, add the permissions the
app needs (camera, gallery, internet).

## Android — `android/app/src/main/AndroidManifest.xml`

Add inside `<manifest>` (above `<application>`):

```xml
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.CAMERA"/>
<uses-permission android:name="android.permission.READ_MEDIA_IMAGES"/>
```

If your API runs over plain HTTP (e.g. during development), also allow
cleartext traffic on the `<application>` tag:

```xml
<application
    android:usesCleartextTraffic="true"
    ... >
```

Minimum SDK: set `minSdkVersion 21` in `android/app/build.gradle`.

## iOS — `ios/Runner/Info.plist`

```xml
<key>NSCameraUsageDescription</key>
<string>Take a photo of a baobab tree to estimate its dimensions.</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>Select a baobab photo to estimate its dimensions.</string>
<key>NSAppTransportSecurity</key>
<dict>
  <key>NSAllowsArbitraryLoads</key>
  <true/>
</dict>
```
