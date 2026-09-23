# علوم نهم – استاد ویسی

## آپلود فایل‌ها: Cloudinary به‌جای Firebase Storage
چون Firebase Storage به پلن Blaze (کارت بانکی) نیاز دارد، آپلود عکس‌ها و فایل‌ها
(عکس پروفایل استاد، تصاویر فصل‌ها، PDF کتاب) از طریق **Cloudinary** (رایگان، بدون کارت) انجام می‌شود.

تنظیمات فعلی در `lib/services/cloudinary_service.dart`:
- Cloud name: `nhqclamj`
- Upload preset (Unsigned): `Olom haftom veysi`

⚠️ اگر بعداً preset یا cloud name را عوض کردید، فقط همین دو خط را در آن فایل ویرایش کنید.

## وضعیت فعلی پروژه
این نسخه شامل موارد زیر است:
- ساختار پایه پروژه Flutter
- `pubspec.yaml` با تمام پکیج‌های مورد نیاز پروژه
- تم روشن/تاریک با رنگ‌های آبی/نارنجی
- `main.dart` با راه‌اندازی Firebase و Hive و RTL کامل
- صفحه اصلی با ۱۵ فصل کتاب علوم نهم
- صفحه پروفایل استاد با آپلود/برش عکس (از طریق Cloudinary)
- نمایشگر PDF کتاب، جزئیات فصل با گالری تصاویر
- آزمون چهارگزینه‌ای، داشبورد دبیر، آزمایشگاه مجازی، دستیار AI

## مراحل بعدی
۲. ماژول PDF + استخراج خودکار تصاویر
۳. بخش آموزش با گالری تصاویر هر فصل
۴. داشبورد نظارتی دبیر (۶ تب)
۵. آزمون‌ساز + بانک سؤال تصویری
۶. آزمایشگاه مجازی + دستیار AI
۷. بازی‌وارسازی + گزارش‌گیری
۸. تست نهایی

## نحوه اجرا روی سیستم خودتان
1. Flutter SDK را نصب کنید: https://docs.flutter.dev/get-started/install
2. یک پروژه در Firebase Console بسازید و Auth / Firestore / FCM را فعال کنید (Storage لازم نیست، از Cloudinary استفاده می‌شود).
3. فایل `google-services.json` را در `android/app/` قرار دهید.
4. دستورات زیر را اجرا کنید:
   ```
   flutter pub get
   flutter run
   flutter build apk --release
   ```
