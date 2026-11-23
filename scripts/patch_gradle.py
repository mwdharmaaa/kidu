import glob
import os

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

    # 2. Patch on_audio_query_android in pub-cache
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

    # 3. Upgrade any other plugins in pub-cache with JavaVersion.VERSION_1_8 to 17
    for path in glob.glob(f"{pub_cache}/hosted/pub.dev/*/android/build.gradle"):
        with open(path, "r", encoding="utf-8") as f:
            content = f.read()
        if "JavaVersion.VERSION_1_8" in content:
            content = content.replace("JavaVersion.VERSION_1_8", "JavaVersion.VERSION_17")
            with open(path, "w", encoding="utf-8") as f:
                f.write(content)
            print(f"[OK] Upgraded Java version to 17 in {path}")

if __name__ == "__main__":
    patch()
