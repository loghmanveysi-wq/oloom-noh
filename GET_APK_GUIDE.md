# راهنمای گرفتن فایل APK نصب‌شدنی (بدون نصب Flutter روی کامپیوتر)

## روش کار
ساخت APK با **Codemagic** (سرویس ابری ساخت اپلیکیشن) انجام می‌شود. کافی است پروژه در گیت‌هاب باشد.

---

## مرحله ۱: ساخت پروژه Firebase
1. به https://console.firebase.google.com بروید و با جیمیل وارد شوید.
2. «Add project» ← نام پروژه مثلاً `oloom-noh-veisi`.
3. **Authentication** ← Get started ← روش «ایمیل/رمز عبور» را فعال کنید.
4. **Firestore Database** ← Create database ← حالت Production ← منطقه را انتخاب کنید.
5. قوانین فایل `firestore.rules` را در بخش Rules همین Firestore پیست کنید.
6. (Storage لازم نیست؛ آپلود فایل‌ها با Cloudinary انجام می‌شود.)
7. در صفحه اصلی پروژه آیکن اندروید را بزنید:
   - Package name: `com.veisi.oloomnoh`
   - فایل `google-services.json` دانلود می‌شود و باید در `android/app/` ریپو قرار بگیرد.

## مرحله ۲: پروژه در گیت‌هاب
پروژه در ریپوی `oloom-noh` است. پوشه `android/` و فایل `google-services.json` هنوز باید اضافه شوند.

## مرحله ۳: ساخت APK با Codemagic
1. به https://codemagic.io بروید و با حساب گیت‌هاب وارد شوید.
2. «Add application» ← ریپوی `oloom-noh` را انتخاب کنید.
3. نوع پروژه را «Flutter App» بگذارید.
4. Build for platform: **Android** و Build format: **APK**.
5. **Start new build** را بزنید.
6. بعد از چند دقیقه، APK در بخش Artifacts آماده دانلود است.

## مرحله ۴: نصب روی گوشی
1. فایل APK را روی گوشی دانلود کنید.
2. رویش بزنید و اجازه «نصب از منابع ناشناس» را بدهید.

---

## فونت Vazirmatn
فعلاً فونت در `pubspec.yaml` فعال نیست. برای فعال‌سازی، فایل‌های فونت را در `assets/fonts/` قرار دهید و بخش `fonts` را به `pubspec.yaml` برگردانید.

## کلید OpenAI
کلید API را هرگز مستقیم در کد یا گیت‌هاب قرار ندهید. از Environment variables امن در Codemagic و `--dart-define` استفاده کنید.
