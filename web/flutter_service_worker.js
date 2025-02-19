'use strict';
const MANIFEST = 'flutter-app-manifest';
const TEMP = 'flutter-temp-cache';
const CACHE_NAME = 'flutter-app-cache';

const RESOURCES = {"manifest.json": "6996a297993075e525620806bfbb8c13",
"index.html": "06ee3d6161707f523d4a57a0ed361951",
"/": "06ee3d6161707f523d4a57a0ed361951",
"icons/Icon-512.png": "96e752610906ba2a93c65f8abe1645f1",
"icons/Icon-maskable-192.png": "c457ef57daa1d16f64b27b786ec2ea3c",
"icons/Icon-192.png": "ac9a721a12bbc803b44f645561ecb1e1",
"icons/Icon-maskable-512.png": "301a7604d45b3e739efc881eb04896ea",
"assets/FontManifest.json": "dc3d03800ccca4601324923c0b1d6d57",
"assets/packages/model_viewer_plus/assets/template.html": "8de94ff19fee64be3edffddb412ab63c",
"assets/packages/model_viewer_plus/assets/model-viewer.min.js": "a9dc98f8bf360be897a0898a7395f905",
"assets/packages/cupertino_icons/assets/CupertinoIcons.ttf": "e986ebe42ef785b27164c36a9abc7818",
"assets/NOTICES": "82062100fd4bf092ae9525f121d8a321",
"assets/AssetManifest.json": "f8b13378e414336132941e81bf53df8f",
"assets/assets/3dModels/foenix.glb": "599d465d5a48a1e44ed7c453fc62a6ce",
"assets/assets/3dModels/agent.glb": "e727b5e706947a9efcc733152d5a6ce3",
"assets/assets/3dModels/phoenix_king.glb": "f340d2061221bcf5a945581093cac5e3",
"assets/assets/3dModels/king.glb": "9d97838a5bc88d78ff96283ee650e8b9",
"assets/assets/alamat-ng-tikbalang-cover.jpg": "acea97034a1830d9fd226b87fc9e5947",
"assets/assets/videos/ep13.mp4": "98df3aba13cce9db1909ae68d18551b6",
"assets/assets/videos/ep8.mp4": "aaf38c994daa0425420e4665558d3efd",
"assets/assets/videos/ep2.mp4": "d8d9b7e4aad94f6e45b93b590ee8b8e4",
"assets/assets/videos/ep12.mp4": "e968ed62b26b94e72848c1edd5035e6a",
"assets/assets/videos/ep4.mp4": "f32042389dbe5acee8fb3fdbbde34e44",
"assets/assets/videos/ep16.mp4": "8ebabcc291861d61a317e013687abd5c",
"assets/assets/videos/ep9.mp4": "725cbad40c9bb0bf5a1dd1ca59c50793",
"assets/assets/videos/ep15.mp4": "19c618569f352d720eec8793d3e08db2",
"assets/assets/videos/ep1.mp4": "5e3258dbdfc05712d8f6e80b67f59e94",
"assets/assets/videos/ep14.mp4": "ce69f0c757968d5776fe8ba7a0da6593",
"assets/assets/videos/ep17.mp4": "22b3b46834ffc7af00cf8ddb4b8a653a",
"assets/assets/videos/ep6.mp4": "81315b5b11c2fd963ac0c7c91b31271f",
"assets/assets/videos/ep18.mp4": "77d88a416b32fad6ab8bdd28915dc353",
"assets/assets/videos/aswang.mp4": "bb8e7924685a4994c46f153c3a818051",
"assets/assets/videos/ep11.mp4": "0cb382800dd5a670d7318734b2626d34",
"assets/assets/videos/ep7.mp4": "98e35e41a006f91b7cc5d409711f3da5",
"assets/assets/videos/ep5.mp4": "4f10f6dc7864875b2ab985ce041d3cdd",
"assets/assets/videos/alamat_ng_tikbalang.mp4": "822f644f7df40d9442b6c1a7c2f07df8",
"assets/assets/images/background.png": "c913d794adabe471736ddfcb40390e85",
"assets/assets/images/ibong_adarna/aralin_1.gif": "aec1d7a32bb5f8b6475f1aa14c1dbe3f",
"assets/assets/images/ibong_adarna/aralin_4.gif": "6cf6615a99a93864bde58d3d000c281c",
"assets/assets/images/ibong_adarna/aralin_2.gif": "57f9cb0c507ffcc7588fd444795b88e8",
"assets/assets/images/ibong_adarna/aralin_6.gif": "94437e365e5e447af50c59bf8b3aadea",
"assets/assets/hari_3d.jpg": "5670d5f8d2cf3dffbfeb93ebc4daf676",
"assets/assets/ibong-adarna-cover.jpeg": "0352669aa3adbc2c365eb8a02747a9a7",
"assets/assets/1.png": "997fb9122b5928a1fd36a34513436d9c",
"assets/assets/aswang.jpg": "905a4235650a88b9862c088df1d1d22b",
"assets/assets/ibong_adarna_3d.jpg": "0307595ec4e4ee38821f9b51ffbce307",
"assets/fonts/MaterialIcons-Regular.otf": "ef807a001c0a0a64d4ff351feebf518a",
"assets/shaders/ink_sparkle.frag": "ecc85a2e95f5e9f53123dcaf8cb9b6ce",
"assets/AssetManifest.bin": "c3a58afdd81b243c7202024c485b0af6",
"assets/AssetManifest.bin.json": "8c6896bf309765e80a20c1701b273f4b",
"canvaskit/canvaskit.js.symbols": "efc2cd87d1ff6c586b7d4c7083063a40",
"canvaskit/canvaskit.js": "26eef3024dbc64886b7f48e1b6fb05cf",
"canvaskit/skwasm.wasm": "828c26a0b1cc8eb1adacbdd0c5e8bcfa",
"canvaskit/skwasm.js.symbols": "96263e00e3c9bd9cd878ead867c04f3c",
"canvaskit/skwasm.worker.js": "89990e8c92bcb123999aa81f7e203b1c",
"canvaskit/canvaskit.wasm": "e7602c687313cfac5f495c5eac2fb324",
"canvaskit/skwasm.js": "ac0f73826b925320a1e9b0d3fd7da61c",
"canvaskit/chromium/canvaskit.js.symbols": "e115ddcfad5f5b98a90e389433606502",
"canvaskit/chromium/canvaskit.js": "b7ba6d908089f706772b2007c37e6da4",
"canvaskit/chromium/canvaskit.wasm": "ea5ab288728f7200f398f60089048b48",
"flutter.js": "4b2350e14c6650ba82871f60906437ea",
"favicon.png": "5dcef449791fa27946b3d35ad8803796",
"version.json": "6c46e606a7a231fed4733d06c954ea2b",
"flutter_bootstrap.js": "b8a0780a11f43c587842e01e25c9eb70",
"main.dart.js": "20634f5b7923aab8c4e05cd6b85de974"};
// The application shell files that are downloaded before a service worker can
// start.
const CORE = ["main.dart.js",
"index.html",
"flutter_bootstrap.js",
"assets/AssetManifest.bin.json",
"assets/FontManifest.json"];

// During install, the TEMP cache is populated with the application shell files.
self.addEventListener("install", (event) => {
  self.skipWaiting();
  return event.waitUntil(
    caches.open(TEMP).then((cache) => {
      return cache.addAll(
        CORE.map((value) => new Request(value, {'cache': 'reload'})));
    })
  );
});
// During activate, the cache is populated with the temp files downloaded in
// install. If this service worker is upgrading from one with a saved
// MANIFEST, then use this to retain unchanged resource files.
self.addEventListener("activate", function(event) {
  return event.waitUntil(async function() {
    try {
      var contentCache = await caches.open(CACHE_NAME);
      var tempCache = await caches.open(TEMP);
      var manifestCache = await caches.open(MANIFEST);
      var manifest = await manifestCache.match('manifest');
      // When there is no prior manifest, clear the entire cache.
      if (!manifest) {
        await caches.delete(CACHE_NAME);
        contentCache = await caches.open(CACHE_NAME);
        for (var request of await tempCache.keys()) {
          var response = await tempCache.match(request);
          await contentCache.put(request, response);
        }
        await caches.delete(TEMP);
        // Save the manifest to make future upgrades efficient.
        await manifestCache.put('manifest', new Response(JSON.stringify(RESOURCES)));
        // Claim client to enable caching on first launch
        self.clients.claim();
        return;
      }
      var oldManifest = await manifest.json();
      var origin = self.location.origin;
      for (var request of await contentCache.keys()) {
        var key = request.url.substring(origin.length + 1);
        if (key == "") {
          key = "/";
        }
        // If a resource from the old manifest is not in the new cache, or if
        // the MD5 sum has changed, delete it. Otherwise the resource is left
        // in the cache and can be reused by the new service worker.
        if (!RESOURCES[key] || RESOURCES[key] != oldManifest[key]) {
          await contentCache.delete(request);
        }
      }
      // Populate the cache with the app shell TEMP files, potentially overwriting
      // cache files preserved above.
      for (var request of await tempCache.keys()) {
        var response = await tempCache.match(request);
        await contentCache.put(request, response);
      }
      await caches.delete(TEMP);
      // Save the manifest to make future upgrades efficient.
      await manifestCache.put('manifest', new Response(JSON.stringify(RESOURCES)));
      // Claim client to enable caching on first launch
      self.clients.claim();
      return;
    } catch (err) {
      // On an unhandled exception the state of the cache cannot be guaranteed.
      console.error('Failed to upgrade service worker: ' + err);
      await caches.delete(CACHE_NAME);
      await caches.delete(TEMP);
      await caches.delete(MANIFEST);
    }
  }());
});
// The fetch handler redirects requests for RESOURCE files to the service
// worker cache.
self.addEventListener("fetch", (event) => {
  if (event.request.method !== 'GET') {
    return;
  }
  var origin = self.location.origin;
  var key = event.request.url.substring(origin.length + 1);
  // Redirect URLs to the index.html
  if (key.indexOf('?v=') != -1) {
    key = key.split('?v=')[0];
  }
  if (event.request.url == origin || event.request.url.startsWith(origin + '/#') || key == '') {
    key = '/';
  }
  // If the URL is not the RESOURCE list then return to signal that the
  // browser should take over.
  if (!RESOURCES[key]) {
    return;
  }
  // If the URL is the index.html, perform an online-first request.
  if (key == '/') {
    return onlineFirst(event);
  }
  event.respondWith(caches.open(CACHE_NAME)
    .then((cache) =>  {
      return cache.match(event.request).then((response) => {
        // Either respond with the cached resource, or perform a fetch and
        // lazily populate the cache only if the resource was successfully fetched.
        return response || fetch(event.request).then((response) => {
          if (response && Boolean(response.ok)) {
            cache.put(event.request, response.clone());
          }
          return response;
        });
      })
    })
  );
});
self.addEventListener('message', (event) => {
  // SkipWaiting can be used to immediately activate a waiting service worker.
  // This will also require a page refresh triggered by the main worker.
  if (event.data === 'skipWaiting') {
    self.skipWaiting();
    return;
  }
  if (event.data === 'downloadOffline') {
    downloadOffline();
    return;
  }
});
// Download offline will check the RESOURCES for all files not in the cache
// and populate them.
async function downloadOffline() {
  var resources = [];
  var contentCache = await caches.open(CACHE_NAME);
  var currentContent = {};
  for (var request of await contentCache.keys()) {
    var key = request.url.substring(origin.length + 1);
    if (key == "") {
      key = "/";
    }
    currentContent[key] = true;
  }
  for (var resourceKey of Object.keys(RESOURCES)) {
    if (!currentContent[resourceKey]) {
      resources.push(resourceKey);
    }
  }
  return contentCache.addAll(resources);
}
// Attempt to download the resource online before falling back to
// the offline cache.
function onlineFirst(event) {
  return event.respondWith(
    fetch(event.request).then((response) => {
      return caches.open(CACHE_NAME).then((cache) => {
        cache.put(event.request, response.clone());
        return response;
      });
    }).catch((error) => {
      return caches.open(CACHE_NAME).then((cache) => {
        return cache.match(event.request).then((response) => {
          if (response != null) {
            return response;
          }
          throw error;
        });
      });
    })
  );
}
