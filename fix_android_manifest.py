with open('android/app/src/main/AndroidManifest.xml', 'r', encoding='utf-8') as f:
    manifest = f.read()

# Flutter apps don't have internet permission by default in release builds!
if '<uses-permission android:name="android.permission.INTERNET"/>' not in manifest:
    manifest = manifest.replace(
        '<application', 
        '<uses-permission android:name="android.permission.INTERNET"/>\n    <application'
    )
    with open('android/app/src/main/AndroidManifest.xml', 'w', encoding='utf-8') as f:
        f.write(manifest)
    print("Added INTERNET permission.")
else:
    print("INTERNET permission already exists.")
