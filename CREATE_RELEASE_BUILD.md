# 🚀 دليل إنشاء نسخة الإصدار (Release Build)

## الخطوة 1️⃣: إنشاء مفتاح التوقيع (Signing Key)

افتح PowerShell في مجلد المشروع وشغل:

```powershell
# إنشاء مجلد android في المجلد الرئيسي (إذا لم يكن موجود)
cd android

# إنشاء keystore جديد
keytool -genkey -v -keystore upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload

# سيطلب منك:
# Enter keystore password: [اختر كلمة سر قوية واحفظها]
# Re-enter new password: [أعد كتابة الكلمة]
# What is your first and last name?: [اسمك أو اسم الشركة]
# What is the name of your organizational unit?: [اسم القسم أو اتركها فارغة]
# What is the name of your organization?: [اسم المؤسسة أو اتركها فارغة]
# What is the name of your City or Locality?: [المدينة]
# What is the name of your State or Province?: [المنطقة]
# What is the two-letter country code?: [SA]
# Is CN=..., correct? [yes]
```

## الخطوة 2️⃣: إنشاء ملف key.properties

أنشئ ملف جديد في `android/key.properties`:

```properties
storePassword=YOUR_KEYSTORE_PASSWORD
keyPassword=YOUR_KEY_PASSWORD
keyAlias=upload
storeFile=upload-keystore.jks
```

**⚠️ مهم جداً:**
- استبدل `YOUR_KEYSTORE_PASSWORD` بكلمة السر اللي اخترتها
- استبدل `YOUR_KEY_PASSWORD` بنفس كلمة السر (أو اختر كلمة مختلفة إذا طلب منك)
- **احفظ هذه المعلومات في مكان آمن!** إذا ضاعت، ما تقدر تحدّث التطبيق!

## الخطوة 3️⃣: تحديث build.gradle.kts

الملف موجود في: `android/app/build.gradle.kts`

### أضف في الأعلى (بعد السطر `id("dev.flutter.flutter-gradle-plugin")`):

```kotlin
// قراءة بيانات التوقيع
val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = java.util.Properties()
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(java.io.FileInputStream(keystorePropertiesFile))
}
```

### أضف في android { ... } قبل buildTypes:

```kotlin
    signingConfigs {
        create("release") {
            storeFile = file(keystoreProperties["storeFile"] ?: "upload-keystore.jks")
            storePassword = keystoreProperties["storePassword"] as String?
            keyAlias = keystoreProperties["keyAlias"] as String?
            keyPassword = keystoreProperties["keyPassword"] as String?
        }
    }
```

### عدّل buildTypes:

```kotlin
    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
            // تفعيل التصغير والتشويش (اختياري)
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
        }
    }
```

## الخطوة 4️⃣: بناء App Bundle

```powershell
# تأكد إنك في مجلد المشروع الرئيسي
cd "C:\Users\Sultan\Desktop\Athar App"

# بناء app bundle
flutter build appbundle --release

# الملف سيكون في:
# build/app/outputs/bundle/release/app-release.aab
```

## الخطوة 5️⃣: رفع على Google Play Console

1. اذهب لـ Google Play Console
2. اختر التطبيق
3. اذهب لـ "الإصدار" → "الاختبار الداخلي"
4. اضغط "إنشاء إصدار جديد"
5. ارفع ملف `app-release.aab`
6. املأ "ملاحظات الإصدار"
7. احفظ وراجع
8. اضغط "إصدار"

---

## ⚠️ ملاحظات مهمة:

### 🔐 احفظ هذه الملفات في مكان آمن:
- `android/upload-keystore.jks`
- `android/key.properties`

**إذا فقدتها، لن تستطيع تحديث التطبيق أبداً!**

### 📝 أضف للـ .gitignore:
```gitignore
# Keystore files
*.jks
*.keystore
key.properties
```

### 🔄 للتحديثات المستقبلية:
فقط غيّر رقم الإصدار في `pubspec.yaml`:
```yaml
version: 1.0.1+2  # رقم الإصدار + رقم البناء
```

ثم أعد بناء:
```powershell
flutter build appbundle --release
```

---

## ✅ التحقق من النجاح:

بعد البناء، تأكد من:
- ✅ حجم الملف معقول (حوالي 20-50 MB)
- ✅ لا أخطاء في عملية البناء
- ✅ الملف موجود في `build/app/outputs/bundle/release/app-release.aab`

---

## 🎯 الخطوات السريعة (بعد إعداد الـ keystore):

```powershell
# 1. نظف البناء السابق
flutter clean

# 2. احصل على الـ dependencies
flutter pub get

# 3. ابني الـ bundle
flutter build appbundle --release

# 4. الملف جاهز للرفع!
```

---

## 📱 اختبار النسخة قبل الرفع:

```powershell
# بناء APK للاختبار
flutter build apk --release

# تثبيت على جهاز متصل
flutter install --release
```

---

**تم التحديث:** ديسمبر 2025
**اسم التطبيق:** أثر (Athar)
**Package:** com.atharmaps.app
