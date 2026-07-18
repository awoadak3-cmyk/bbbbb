# AuroraStream — iOS (Swift/SwiftUI)

هذا مشروع iOS **جديد ومنفصل بالكامل** عن نسخة أندرويد (مكتوب بلغة Swift/SwiftUI بدل Kotlin/Compose)،
يقرأ نفس بيانات مستودع GitHub (`data/index.json` + `data/<file>.json`) اللي يستخدمها إصدار أندرويد،
بنفس الألوان والتصميم وترتيب الأقسام.

## البنية

```
AuroraStreamiOS/
├── project.yml              ← مواصفة XcodeGen (يولّد .xcodeproj تلقائياً)
└── Sources/
    ├── AuroraStreamApp.swift
    ├── Info.plist
    ├── Models/               ← MediaItem, WatchHistoryEntry (نفس شكل بيانات أندرويد بالضبط)
    ├── Theme/                ← نفس لوحة الألوان بالضبط (BrandRed, DeepBlack...)
    ├── Networking/           ← GitHubDataService, LibraryRepository, HLSDownloader
    ├── Storage/              ← SettingsStore, WatchHistoryStore (UserDefaults بدل DataStore)
    └── Views/
        ├── Home, Details, Player, Search, Settings, Components, RootView
```

## طريقة الفتح على جهازك (Mac + Xcode مطلوبين)

1. ثبّت [XcodeGen](https://github.com/yonaskolb/XcodeGen) إذا ما عندك:
   ```bash
   brew install xcodegen
   ```
2. من داخل مجلد `AuroraStreamiOS`:
   ```bash
   xcodegen generate
   open AuroraStream.xcodeproj
   ```
3. بـ Xcode: اختر جهاز محاكي (Simulator) أو آيفون حقيقي، واضغط Run.
4. أول تشغيل: روح لتاب "الإعدادات" داخل التطبيق وحط `owner/repo` بتاع مستودع GitHub اللي فيه مجلد `data/`.

## ملف الـ CI (`.github/workflows/ios-build.yml`)

يبني التطبيق تلقائياً على كل push، لكن **بدون توقيع (code signing)** — يبني وينجح على iOS Simulator فقط،
عشان ما يحتاج حساب Apple Developer. هذا كافٍ للتأكد إن الكود يبني بدون أخطاء تلقائياً.

### ليش ما يقدر يبني ويرسل لجهازك مباشرة تلقائياً؟

تنزيل تطبيق iOS **على جهاز آيفون حقيقي** (خارج App Store) يتطلب توقيعاً رسمياً من Apple —
حتى لو كان الـ workflow يشتغل 100%، ما فيه "ملف تثبيت" زي APK بأندرويد تقدر تنزّله وتشغّله مباشرة.
تحتاج واحد من:
- **حساب Apple Developer** (99$/سنة) + شهادة توقيع + provisioning profile، ثم توزيع عبر
  TestFlight أو App Store.
- أو تشغيله محلياً على جهازك عبر Xcode مباشرة (مجاني، بس يحتاج حسابك الشخصي وربطه بالجهاز
  لمدة 7 أيام قبل ما يحتاج إعادة توقيع).

إذا تبي أضيف خطوات التوقيع والتوزيع عبر TestFlight بالـ workflow، أحتاج منك معلومات حساب
Apple Developer الخاص فيك (Team ID + شهادات) — هذي ما أقدر أجهزها لحالي لأنها مرتبطة بحسابك.

## ملاحظات صادقة عن الفروقات عن نسخة أندرويد

- **المشغّل**: يعرض صفحة الـ embed الرسمية مباشرة عبر `WKWebView` (نفس مبدأ أندرويد)،
  ويصطاد رابط m3u8 بصمت عن طريق حقن سكربت JS يراقب `fetch`/`XMLHttpRequest` — لأن iOS
  ما عنده معادل مباشر لـ `shouldInterceptRequest` بأندرويد.
- **التنزيل**: يستخدم `AVAssetExportSession` (تقنية Apple الأصلية لمعالجة HLS) بدل التجميع
  اليدوي للمقاطع، ويحفظ الملف بمجلد التطبيق بـ Files app.
- **التخزين**: `UserDefaults` + `Codable` بدل DataStore، بنفس المنطق (سجل مشاهدة، إعدادات).
- **"متابعة المشاهدة"**: نفس صدق الرسالة اللي بأندرويد — نعرف "أي حلقة" كنت عليها، مو
  الثانية بالضبط، لأن التشغيل يمر بواجهة موقع خارجي.
