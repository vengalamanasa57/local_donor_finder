
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyCD3kdQK4Ij0yMDbaUjep5YqXnI8xJsFdM',
    appId: '1:750300984684:web:9e90e367fce163f37d2f49',
    messagingSenderId: '750300984684',
    projectId: 'local-donor-finder',
    authDomain: 'local-donor-finder.firebaseapp.com',
    storageBucket: 'local-donor-finder.firebasestorage.app',
    measurementId: 'G-VCPTJ2YJET',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBuqI7QYuEk8jrETBc5ePPkL4OXZwoe1x0',
    appId: '1:750300984684:ios:faf8ac908387c7fd7d2f49',
    messagingSenderId: '750300984684',
    projectId: 'local-donor-finder',
    storageBucket: 'local-donor-finder.firebasestorage.app',
    androidClientId: '750300984684-ouse58ohse88map2p1kliengkvpqip1n.apps.googleusercontent.com',
    iosBundleId: 'com.example.localDonorFinder',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyBuqI7QYuEk8jrETBc5ePPkL4OXZwoe1x0',
    appId: '1:750300984684:ios:faf8ac908387c7fd7d2f49',
    messagingSenderId: '750300984684',
    projectId: 'local-donor-finder',
    storageBucket: 'local-donor-finder.firebasestorage.app',
    androidClientId: '750300984684-ouse58ohse88map2p1kliengkvpqip1n.apps.googleusercontent.com',
    iosBundleId: 'com.example.localDonorFinder',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyCD3kdQK4Ij0yMDbaUjep5YqXnI8xJsFdM',
    appId: '1:750300984684:web:3ea8d3a4e0630f8d7d2f49',
    messagingSenderId: '750300984684',
    projectId: 'local-donor-finder',
    authDomain: 'local-donor-finder.firebaseapp.com',
    storageBucket: 'local-donor-finder.firebasestorage.app',
    measurementId: 'G-FZCV1JJG9Z',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCN2fHkR2xn8y99xZcjD4UeThFi4oprXgw',
    appId: '1:750300984684:android:e000a162e500efcd7d2f49',
    messagingSenderId: '750300984684',
    projectId: 'local-donor-finder',
    storageBucket: 'local-donor-finder.firebasestorage.app',
  );

}