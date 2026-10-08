#!/usr/bin/env python3
"""
آماده‌سازی پوشه‌ی android بعد از `flutter create`:
  1) کپی google-services.json از ریشه‌ی پروژه به android/app
  2) فعال کردن پلاگین google-services
  3) minSdk = 21
  4) مجوز INTERNET + UCropActivity (برای برش عکس) + queries (برای url_launcher)
اگر هر مرحله پیدا نشد، با پیام خطا متوقف می‌شود تا در لاگ Codemagic معلوم باشد.
"""
import os
import re
import shutil
import sys


def fail(msg):
    print("ERROR:", msg)
    sys.exit(1)


def read(p):
    with open(p, encoding="utf-8") as f:
        return f.read()


def write(p, s):
    with open(p, "w", encoding="utf-8") as f:
        f.write(s)


# 1) google-services.json
if not os.path.exists("google-services.json"):
    fail("google-services.json در ریشه‌ی پروژه پیدا نشد.")
shutil.copy("google-services.json", "android/app/google-services.json")
print("google-services.json copied")

# 2) پلاگین google-services
settings_p = "android/settings.gradle"
app_p = "android/app/build.gradle"
settings = read(settings_p) if os.path.exists(settings_p) else ""
app = read(app_p)

if 'id "dev.flutter.flutter-plugin-loader"' in settings:
    # قالب جدید Flutter (plugins block)
    if "com.google.gms.google-services" not in settings:
        settings, n = re.subn(
            r'(id "org\.jetbrains\.kotlin\.android"[^\n]*\n)',
            r'\1    id "com.google.gms.google-services" version "4.3.15" apply false\n',
            settings, count=1)
        if n == 0:
            fail("محل افزودن پلاگین در settings.gradle پیدا نشد.")
        write(settings_p, settings)
    if "com.google.gms.google-services" not in app:
        app, n = re.subn(
            r'(id "dev\.flutter\.flutter-gradle-plugin"[^\n]*\n)',
            r'\1    id "com.google.gms.google-services"\n',
            app, count=1)
        if n == 0:
            fail("محل افزودن پلاگین در app/build.gradle پیدا نشد.")
    print("google-services plugin added (new template)")
else:
    # قالب قدیمی (apply plugin)
    bg_p = "android/build.gradle"
    bg = read(bg_p)
    if "com.google.gms:google-services" not in bg:
        bg, n = re.subn(
            r'(classpath [\'"]com\.android\.tools\.build:gradle:[^\n]*\n)',
            r"\1        classpath 'com.google.gms:google-services:4.3.15'\n",
            bg, count=1)
        if n == 0:
            fail("classpath در android/build.gradle پیدا نشد.")
        write(bg_p, bg)
    if "com.google.gms.google-services" not in app:
        app += "\napply plugin: 'com.google.gms.google-services'\n"
    print("google-services plugin added (old template)")

# 3) minSdk
app, n = re.subn(r"minSdk(Version)?\s+flutter\.minSdkVersion", "minSdkVersion 21", app)
if n == 0 and "minSdkVersion 21" not in app:
    fail("minSdkVersion در app/build.gradle پیدا نشد.")
write(app_p, app)
print("minSdk set to 21")

# 4) AndroidManifest
man_p = "android/app/src/main/AndroidManifest.xml"
man = read(man_p)
if "android.permission.INTERNET" not in man:
    man = man.replace(
        "<application",
        '<uses-permission android:name="android.permission.INTERNET"/>\n    <application',
        1)
if "com.yalantis.ucrop.UCropActivity" not in man:
    man = man.replace(
        "</application>",
        '    <activity android:name="com.yalantis.ucrop.UCropActivity"\n'
        '        android:screenOrientation="portrait"\n'
        '        android:theme="@style/Theme.AppCompat.Light.NoActionBar"/>\n'
        "    </application>",
        1)
if "<queries>" not in man:
    man = man.replace(
        "</manifest>",
        "    <queries>\n"
        "        <intent>\n"
        '            <action android:name="android.intent.action.VIEW"/>\n'
        '            <data android:scheme="https"/>\n'
        "        </intent>\n"
        "    </queries>\n</manifest>",
        1)
write(man_p, man)
print("manifest patched")
