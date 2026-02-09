# أثر - Athar

<div dir="rtl">

## 🏕️ تطبيق أنيق لمشاركة أماكن الكشتات والمخيمات

تطبيق "أثر" هو تطبيق جوال أنيق يتيح للمستخدمين مشاركة واكتشاف أماكن الكشتات والمخيمات الجميلة. يمكن للمستخدمين إضافة صور لأماكنهم المفضلة مع الوصف والموقع، والتنقل إلى هذه الأماكن باستخدام خرائط Google.

### ✨ المميزات

- 🗺️ **خريطة تفاعلية**: عرض جميع أماكن الكشتات على خريطة تفاعلية
- 📸 **مشاركة الصور**: إضافة صور متعددة لكل مكان
- 📝 **الوصف التفصيلي**: كتابة وصف مفصل لكل مكان
- 🧭 **التنقل**: التوجيه المباشر إلى الموقع عبر Google Maps
- ❤️ **الإعجاب**: إمكانية الإعجاب بالأماكن المفضلة
- 🎨 **تصميم أنيق**: ألوان التراب والبيج الأنيقة

### 🛠️ التقنيات المستخدمة

- **Flutter**: إطار العمل الأساسي للتطبيق
- **Firebase**: 
  - Authentication للمصادقة
  - Firestore لقاعدة البيانات
  - Storage لتخزين الصور
- **Google Maps**: للخرائط التفاعلية
- **Provider**: لإدارة الحالة
- **Google Fonts**: خطوط Cairo الأنيقة

### 🎨 نظام الألوان

التطبيق يستخدم نظام ألوان أنيق جداً مكون من:
- **الأبيض النقي**: `#FFFFFF`
- **البيج الفاتح**: `#F5EFE7`
- **لون التراب الذهبي**: `#C4A27C`
- **التراب الداكن**: `#8B7355`

### 📱 المتطلبات

- Flutter SDK 3.0 أو أحدث
- حساب Firebase
- Google Maps API Key
- Xcode (لنظام iOS)
- Android Studio (لنظام Android)

### 🚀 التثبيت والإعداد

#### 1. تثبيت Flutter

إذا لم يكن لديك Flutter مثبت:

**Windows:**
```powershell
# قم بتحميل Flutter من الموقع الرسمي
# https://docs.flutter.dev/get-started/install/windows

# أو استخدم winget
winget install --id=Google.Flutter -e
```

**Mac/Linux:**
```bash
# قم بتحميل Flutter من الموقع الرسمي
# https://docs.flutter.dev/get-started/install
```

#### 2. التحقق من التثبيت

```bash
flutter doctor
```

#### 3. تثبيت المكتبات

```bash
flutter pub get
```

#### 4. إعداد Firebase

1. قم بإنشاء مشروع في [Firebase Console](https://console.firebase.google.com)
2. أضف تطبيق iOS وتطبيق Android
3. قم بتثبيت FlutterFire CLI:

```bash
dart pub global activate flutterfire_cli
```

4. قم بتكوين Firebase:

```bash
flutterfire configure
```

#### 5. إعداد Google Maps API

1. انتقل إلى [Google Cloud Console](https://console.cloud.google.com)
2. قم بإنشاء مشروع جديد أو اختر مشروع موجود
3. فعّل Google Maps SDK for Android و iOS
4. احصل على API Key

**لنظام Android:**
أضف API Key في `android/app/src/main/AndroidManifest.xml`:

```xml
<manifest ...>
    <application ...>
        <meta-data
            android:name="com.google.android.geo.API_KEY"
            android:value="YOUR_API_KEY_HERE"/>
    </application>
</manifest>
```

**لنظام iOS:**
أضف API Key في `ios/Runner/AppDelegate.swift`:

```swift
import GoogleMaps

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GMSServices.provideAPIKey("YOUR_API_KEY_HERE")
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
```

### 🏃‍♂️ تشغيل التطبيق

#### Android:
```bash
flutter run
```

#### iOS:
```bash
cd ios
pod install
cd ..
flutter run
```

### 📦 بناء التطبيق للنشر

#### Android (APK):
```bash
flutter build apk --release
```

#### Android (App Bundle - للنشر على Play Store):
```bash
flutter build appbundle --release
```

#### iOS:
```bash
flutter build ios --release
```

### 📁 هيكل المشروع

```
lib/
├── core/
│   └── theme/
│       ├── app_colors.dart      # نظام الألوان الأنيق
│       └── app_theme.dart       # تصميم التطبيق
├── models/
│   └── camping_spot.dart        # نموذج بيانات مكان الكشتة
├── providers/
│   ├── spots_provider.dart      # إدارة حالة الأماكن
│   └── auth_provider.dart       # إدارة حالة المصادقة
├── screens/
│   ├── home_screen.dart         # الشاشة الرئيسية مع الخريطة
│   ├── add_spot_screen.dart     # شاشة إضافة مكان جديد
│   └── spot_details_screen.dart # شاشة تفاصيل المكان
├── widgets/
│   ├── spot_card.dart           # بطاقة عرض المكان
│   └── elegant_app_bar.dart     # شريط التطبيق الأنيق
└── main.dart                    # نقطة البداية
```

### 🔧 التخصيص

#### تغيير الألوان:
عدّل ملف `lib/core/theme/app_colors.dart` لتخصيص نظام الألوان.

#### تخصيص الخطوط:
غيّر الخط في `lib/core/theme/app_theme.dart` من خط Cairo إلى أي خط آخر.

### 📝 قواعد Firestore

أضف هذه القواعد في Firebase Console:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /camping_spots/{spotId} {
      allow read: if true;
      allow create: if request.auth != null;
      allow update, delete: if request.auth.uid == resource.data.userId;
    }
  }
}
```

### 🔐 قواعد Firebase Storage

```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /camping_spots/{allPaths=**} {
      allow read: if true;
      allow write: if request.auth != null;
    }
  }
}
```

### 🌟 الميزات المستقبلية

- [ ] تسجيل دخول بالبريد الإلكتروني
- [ ] نظام التعليقات
- [ ] نظام التقييمات
- [ ] البحث والفلترة
- [ ] الأماكن المفضلة
- [ ] مشاركة الأماكن على وسائل التواصل
- [ ] الوضع الليلي
- [ ] دعم لغات متعددة

### 📄 الترخيص

هذا المشروع مفتوح المصدر ومتاح للاستخدام الشخصي والتجاري.

### 🤝 المساهمة

نرحب بالمساهمات! إذا كان لديك اقتراح أو تحسين، لا تتردد في فتح Issue أو Pull Request.

### 📞 التواصل

إذا كان لديك أي استفسار، يمكنك التواصل عبر:
- GitHub Issues
- Email: [بريدك الإلكتروني]

---

صُنع بـ ❤️ من أجل عشاق الكشتات والبر

</div>
