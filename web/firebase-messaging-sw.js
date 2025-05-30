// web/firebase-messaging-sw.js
importScripts('https://www.gstatic.com/firebasejs/9.22.1/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/9.22.1/firebase-messaging-compat.js');

const firebaseConfig = {
    apiKey: "AIzaSyBS9sf90DIDgyB_X8wiUuh7eyyjUiiApT8", // Таны жинхэнэ config
    authDomain: "mobile-shalgalt.firebaseapp.com",
    projectId: "mobile-shalgalt",
    storageBucket: "mobile-shalgalt.firebasestorage.app",
    messagingSenderId: "258871947207",
    appId: "1:258871947207:web:16afb5adca716845c5f3e2",
    measurementId: "G-BEG0191N1R"
};

// Firebase апп өмнө нь эхлүүлэгдсэн эсэхийг шалгах
if (!firebase.apps.length) {
    firebase.initializeApp(firebaseConfig);
} else {
    firebase.app(); // Хэрэв эхлүүлэгдсэн бол дахин эхлүүлэхгүй
}

const messaging = firebase.messaging();

messaging.onBackgroundMessage(function(payload) {
    console.log('[firebase-messaging-sw.js] Received background message ', payload);

    const notificationTitle = payload.notification?.title || 'Шинэ мэдэгдэл'; // title байхгүй үед default утга
    const notificationOptions = {
        body: payload.notification?.body || 'Танд шинэ мэдэгдэл ирлээ.', // body байхгүй үед default утга
        icon: '/icons/Icon-192.png' // Энд өөрийн icon-ийн замыг зөв заагаарай
    };

    return self.registration.showNotification(notificationTitle, notificationOptions);
});