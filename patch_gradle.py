import re

with open('android/app/build.gradle', 'r') as f:
    content = f.read()

# Replace the buildTypes block and add signingConfigs right above it
old_build_types = """    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig signingConfigs.debug
        }
    }"""

new_build_types = """    signingConfigs {
        release {
            storeFile file("release.jks")
            storePassword "unraid123"
            keyAlias "unraidapp"
            keyPassword "unraid123"
        }
    }

    buildTypes {
        release {
            signingConfig signingConfigs.release
        }
    }"""

content = content.replace(old_build_types, new_build_types)

with open('android/app/build.gradle', 'w') as f:
    f.write(content)
