// The OneSignal Web SDK's service worker: it receives the pushes while the
// site is closed (ARCHITECTURE.md §13). OneSignal looks for it at the root
// of the site, under this name.
importScripts("https://cdn.onesignal.com/sdks/web/v16/OneSignalSDK.sw.js");
