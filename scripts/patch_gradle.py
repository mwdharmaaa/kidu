import glob
import os

IC_SHUFFLE_XML = """<vector xmlns:android="http://schemas.android.com/apk/res/android"
    android:width="24dp"
    android:height="24dp"
    android:viewportWidth="24"
    android:viewportHeight="24">
  <path
      android:fillColor="#FFFFFFFF"
      android:pathData="M10.59,9.17L5.41,4 4,5.41l5.17,5.17 1.42,-1.41zM14.5,4l2.04,2.04L4,18.59 5.41,20 17.96,7.46 20,9.5V4h-5.5zm0.33,9.41l-1.41,1.41 3.13,3.13L14.5,20H20v-5.5l-2.04,2.04 -3.13,-3.13z"/>
</vector>
"""

IC_REPEAT_XML = """<vector xmlns:android="http://schemas.android.com/apk/res/android"
    android:width="24dp"
    android:height="24dp"
    android:viewportWidth="24"
    android:viewportHeight="24">
  <path
      android:fillColor="#FFFFFFFF"
      android:pathData="M7,7h10v3l4,-4 -4,-4v3H5v6h2V7zm10,10H7v-3l-4,4 4,4v-3h12v-6h-2v4z"/>
</vector>
"""

IC_REPEAT_ONE_XML = """<vector xmlns:android="http://schemas.android.com/apk/res/android"
    android:width="24dp"
    android:height="24dp"
    android:viewportWidth="24"
    android:viewportHeight="24">
  <path
      android:fillColor="#FFFFFFFF"
      android:pathData="M7,7h10v3l4,-4 -4,-4v3H5v6h2V7zm10,10H7v-3l-4,4 4,4v-3h12v-6h-2v4zm-4,-2V9h-1l-2,1v1h1.5v4H13z"/>
</vector>
"""

def patch():
    # 1. Update android/app/build.gradle
    app_gradle = "android/app/build.gradle"
    if os.path.exists(app_gradle):
        with open(app_gradle, "r", encoding="utf-8") as f:
            content = f.read()
        content = content.replace("JavaVersion.VERSION_1_8", "JavaVersion.VERSION_17")
        content = content.replace("jvmTarget = '1.8'", "jvmTarget = '17'")
        content = content.replace('jvmTarget = "1.8"', 'jvmTarget = "17"')
        with open(app_gradle, "w", encoding="utf-8") as f:
            f.write(content)
        print(f"[OK] Patched {app_gradle} to Java 17")

    # 2. Inject vector drawables into android/app/src/main/res/drawable/
    drawable_dir = "android/app/src/main/res/drawable"
    os.makedirs(drawable_dir, exist_ok=True)
    with open(os.path.join(drawable_dir, "ic_shuffle.xml"), "w", encoding="utf-8") as f:
        f.write(IC_SHUFFLE_XML)
    with open(os.path.join(drawable_dir, "ic_repeat.xml"), "w", encoding="utf-8") as f:
        f.write(IC_REPEAT_XML)
    with open(os.path.join(drawable_dir, "ic_repeat_one.xml"), "w", encoding="utf-8") as f:
        f.write(IC_REPEAT_ONE_XML)
    print(f"[OK] Injected notification vector drawables into {drawable_dir}")

    # 3. Patch on_audio_query_android in pub-cache
    pub_cache = os.path.expanduser("~/.pub-cache")
    for path in glob.glob(f"{pub_cache}/hosted/pub.dev/on_audio_query_android-*/android/build.gradle"):
        with open(path, "r", encoding="utf-8") as f:
            content = f.read()
        
        if "namespace" not in content:
            patch_block = """android {
    namespace "com.lucasjosino.on_audio_query"
    compileOptions {
        sourceCompatibility JavaVersion.VERSION_17
        targetCompatibility JavaVersion.VERSION_17
    }
    kotlinOptions {
        jvmTarget = "17"
    }"""
            content = content.replace("android {", patch_block, 1)
            with open(path, "w", encoding="utf-8") as f:
                f.write(content)
            print(f"[OK] Patched on_audio_query at {path}")

    # 4. Upgrade any other plugins in pub-cache with JavaVersion.VERSION_1_8 to 17
    for path in glob.glob(f"{pub_cache}/hosted/pub.dev/*/android/build.gradle"):
        with open(path, "r", encoding="utf-8") as f:
            content = f.read()
        if "JavaVersion.VERSION_1_8" in content:
            content = content.replace("JavaVersion.VERSION_1_8", "JavaVersion.VERSION_17")
            with open(path, "w", encoding="utf-8") as f:
                f.write(content)
            print(f"[OK] Upgraded Java version to 17 in {path}")

    # 5. Patch AudioService.java for notification shuffle and loop support
    for path in glob.glob(f"{pub_cache}/hosted/pub.dev/audio_service-*/android/src/main/java/com/ryanheise/audioservice/AudioService.java"):
        with open(path, "r", encoding="utf-8") as f:
            content = f.read()

        old_create_action = """    NotificationCompat.Action createAction(String resource, String label, long actionCode) {
        int iconId = getResourceId(resource);
        return new NotificationCompat.Action(iconId, label,
                buildMediaButtonPendingIntent(actionCode));
    }"""

        new_create_action = """    public static final String ACTION_TOGGLE_SHUFFLE = "com.ryanheise.audioservice.action.TOGGLE_SHUFFLE";
    public static final String ACTION_TOGGLE_REPEAT = "com.ryanheise.audioservice.action.TOGGLE_REPEAT";

    NotificationCompat.Action createAction(String resource, String label, long actionCode) {
        int iconId = getResourceId(resource);
        PendingIntent intent = buildMediaButtonPendingIntent(actionCode);
        if (intent == null) {
            String lower = (label != null ? label : "").toLowerCase();
            Intent customIntent = new Intent(this, AudioService.class);
            int flags = 0;
            if (Build.VERSION.SDK_INT >= 23) {
                flags |= PendingIntent.FLAG_IMMUTABLE;
            }
            if (lower.contains("shuffle") || lower.contains("acak")) {
                customIntent.setAction(ACTION_TOGGLE_SHUFFLE);
                intent = PendingIntent.getService(this, 1001, customIntent, flags);
            } else if (lower.contains("repeat") || lower.contains("loop") || lower.contains("ulang") || lower.contains("satu") || lower.contains("semua") || lower.contains("urutan")) {
                customIntent.setAction(ACTION_TOGGLE_REPEAT);
                intent = PendingIntent.getService(this, 1002, customIntent, flags);
            }
        }
        return new NotificationCompat.Action(iconId, label, intent);
    }"""

        old_on_start = """    @Override
    public int onStartCommand(final Intent intent, int flags, int startId) {
        MediaButtonReceiver.handleIntent(mediaSession, intent);
        return START_NOT_STICKY;
    }"""

        new_on_start = """    @Override
    public int onStartCommand(final Intent intent, int flags, int startId) {
        if (intent != null) {
            String action = intent.getAction();
            if (ACTION_TOGGLE_SHUFFLE.equals(action)) {
                if (mediaSessionCallback != null) {
                    int nextShuffle = (this.shuffleMode == PlaybackStateCompat.SHUFFLE_MODE_ALL)
                            ? PlaybackStateCompat.SHUFFLE_MODE_NONE
                            : PlaybackStateCompat.SHUFFLE_MODE_ALL;
                    mediaSessionCallback.onSetShuffleMode(nextShuffle);
                }
                return START_NOT_STICKY;
            } else if (ACTION_TOGGLE_REPEAT.equals(action)) {
                if (mediaSessionCallback != null) {
                    int nextRepeat;
                    if (this.repeatMode == PlaybackStateCompat.REPEAT_MODE_NONE) {
                        nextRepeat = PlaybackStateCompat.REPEAT_MODE_ALL;
                    } else if (this.repeatMode == PlaybackStateCompat.REPEAT_MODE_ALL) {
                        nextRepeat = PlaybackStateCompat.REPEAT_MODE_ONE;
                    } else {
                        nextRepeat = PlaybackStateCompat.REPEAT_MODE_NONE;
                    }
                    mediaSessionCallback.onSetRepeatMode(nextRepeat);
                }
                return START_NOT_STICKY;
            }
        }
        MediaButtonReceiver.handleIntent(mediaSession, intent);
        return START_NOT_STICKY;
    }"""

        if old_create_action in content:
            content = content.replace(old_create_action, new_create_action)
            print(f"[OK] Patched createAction in {path}")
        if old_on_start in content:
            content = content.replace(old_on_start, new_on_start)
            print(f"[OK] Patched onStartCommand in {path}")

        with open(path, "w", encoding="utf-8") as f:
            f.write(content)

    # 6. Patch just_audio_background.dart for full media notification bar controls
    for path in glob.glob(f"{pub_cache}/hosted/pub.dev/just_audio_background-*/lib/just_audio_background.dart"):
        with open(path, "r", encoding="utf-8") as f:
            content = f.read()

        # Wrap around skipToNext and skipToPrevious
        old_next = """  @override
  Future<void> skipToNext() async {
    if (hasNext) {
      await skipToQueueItem(nextIndex!);
    }
  }"""
        new_next = """  @override
  Future<void> skipToNext() async {
    if (hasNext && nextIndex != null) {
      await skipToQueueItem(nextIndex!);
    } else if (effectiveIndices.isNotEmpty) {
      await skipToQueueItem(effectiveIndices.first);
    }
  }"""
        if old_next in content:
            content = content.replace(old_next, new_next)
            print(f"[OK] Patched skipToNext in {path}")

        old_prev = """  @override
  Future<void> skipToPrevious() async {
    if (hasPrevious) {
      await skipToQueueItem(previousIndex!);
    }
  }"""
        new_prev = """  @override
  Future<void> skipToPrevious() async {
    if (hasPrevious && previousIndex != null) {
      await skipToQueueItem(previousIndex!);
    } else if (effectiveIndices.isNotEmpty) {
      await skipToQueueItem(effectiveIndices.last);
    }
  }"""
        if old_prev in content:
            content = content.replace(old_prev, new_prev)
            print(f"[OK] Patched skipToPrevious in {path}")

        # Controls list: Shuffle, Previous, Play/Pause, Next, Loop (Remove Stop button!)
        old_broadcast = """  void _broadcastState() {
    final controls = [
      if (hasPrevious) MediaControl.skipToPrevious,
      if (_playing) MediaControl.pause else MediaControl.play,
      MediaControl.stop,
      if (hasNext) MediaControl.skipToNext,
    ];"""

        new_broadcast = """  void _broadcastState() {
    final shuffleControl = MediaControl(
      androidIcon: 'drawable/ic_shuffle',
      label: _shuffleMode == AudioServiceShuffleMode.all ? 'Acak (Aktif)' : 'Acak (Mati)',
      action: MediaAction.setShuffleMode,
    );
    final repeatControl = MediaControl(
      androidIcon: _repeatMode == AudioServiceRepeatMode.one
          ? 'drawable/ic_repeat_one'
          : 'drawable/ic_repeat',
      label: _repeatMode == AudioServiceRepeatMode.one
          ? 'Ulang Satu'
          : (_repeatMode == AudioServiceRepeatMode.all ? 'Ulang Semua' : 'Berurutan'),
      action: MediaAction.setRepeatMode,
    );
    final controls = [
      shuffleControl,
      MediaControl.skipToPrevious,
      if (_playing) MediaControl.pause else MediaControl.play,
      MediaControl.skipToNext,
      repeatControl,
    ];"""

        if old_broadcast in content:
            content = content.replace(old_broadcast, new_broadcast)
            print(f"[OK] Patched controls in {path}")

        old_compact = """      androidCompactActionIndices: List.generate(controls.length, (i) => i)
          .where((i) => controls[i].action != MediaAction.stop)
          .toList(),"""
        new_compact = """      androidCompactActionIndices: const [1, 2, 3],"""

        if old_compact in content:
            content = content.replace(old_compact, new_compact)
            print(f"[OK] Patched compact action indices in {path}")

        with open(path, "w", encoding="utf-8") as f:
            f.write(content)

if __name__ == "__main__":
    patch()
