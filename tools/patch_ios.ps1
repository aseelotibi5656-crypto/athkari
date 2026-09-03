# تعديل إعدادات iOS المطلوبة لتطبيق "أذكاري" بعد توليد مجلد ios/.
#
# يضيف إلى Info.plist:
#   • اسم العرض العربي "أذكاري"
#   • دعم اللغة العربية واتجاه RTL
#   • أوضاع الخلفية اللازمة للإشعارات المحلية
#
# يُستدعى تلقائيًا من tools\setup.ps1، ويمكن تشغيله يدويًا في أي وقت.

$ErrorActionPreference = "Stop"
$projectRoot = Split-Path -Parent $PSScriptRoot
$plistPath = Join-Path $projectRoot "ios\Runner\Info.plist"

if (-not (Test-Path $plistPath)) {
    Write-Host "لم يُعثر على $plistPath — ولّد مجلد iOS أولًا." -ForegroundColor Red
    exit 1
}

[xml]$plist = Get-Content $plistPath -Encoding UTF8
$dict = $plist.plist.dict

function Set-PlistString([xml]$doc, $dict, [string]$key, [string]$value) {
    $keys = @($dict.key)
    $index = [Array]::IndexOf($keys, $key)
    if ($index -ge 0) {
        # المفتاح موجود: نستبدل قيمته النصيّة.
        $node = $dict.SelectNodes("key")[$index].NextSibling
        $node.InnerText = $value
    } else {
        $k = $doc.CreateElement("key"); $k.InnerText = $key
        $v = $doc.CreateElement("string"); $v.InnerText = $value
        $dict.AppendChild($k) | Out-Null
        $dict.AppendChild($v) | Out-Null
    }
}

Set-PlistString $plist $dict "CFBundleDisplayName" "أذكاري"
Set-PlistString $plist $dict "CFBundleName" "athkari"
Set-PlistString $plist $dict "CFBundleDevelopmentRegion" "ar"

# اللغات المدعومة: العربية.
if (-not ($dict.key -contains "CFBundleLocalizations")) {
    $k = $plist.CreateElement("key"); $k.InnerText = "CFBundleLocalizations"
    $arr = $plist.CreateElement("array")
    $s = $plist.CreateElement("string"); $s.InnerText = "ar"
    $arr.AppendChild($s) | Out-Null
    $dict.AppendChild($k) | Out-Null
    $dict.AppendChild($arr) | Out-Null
}

# أوضاع الخلفية: الإشعارات البعيدة (اختيارية مع FCM) والجلب.
if (-not ($dict.key -contains "UIBackgroundModes")) {
    $k = $plist.CreateElement("key"); $k.InnerText = "UIBackgroundModes"
    $arr = $plist.CreateElement("array")
    foreach ($mode in @("fetch", "remote-notification")) {
        $s = $plist.CreateElement("string"); $s.InnerText = $mode
        $arr.AppendChild($s) | Out-Null
    }
    $dict.AppendChild($k) | Out-Null
    $dict.AppendChild($arr) | Out-Null
}

$plist.Save($plistPath)
Write-Host "تم تعديل Info.plist بنجاح." -ForegroundColor Green

# ---------------------------------------------------------------------------
# رفع الحد الأدنى لنظام iOS إلى 13.0
#
# مكتبات Firebase الحديثة (firebase_core 3.x وما فوق) لا تدعم أقل من iOS 13،
# وبدون هذا التعديل يفشل `pod install` أثناء البناء برسالة غامضة.
# ---------------------------------------------------------------------------

$podfilePath = Join-Path $projectRoot "ios\Podfile"
if (Test-Path $podfilePath) {
    $podfile = Get-Content $podfilePath -Raw -Encoding UTF8
    if ($podfile -match "(?m)^\s*#?\s*platform :ios") {
        $podfile = $podfile -replace "(?m)^\s*#?\s*platform :ios.*$", "platform :ios, '13.0'"
    } else {
        $podfile = "platform :ios, '13.0'`r`n" + $podfile
    }
    Set-Content -Path $podfilePath -Value $podfile -Encoding UTF8 -NoNewline
    Write-Host "تم ضبط الحد الأدنى لنظام iOS على 13.0 في Podfile." -ForegroundColor Green
}

$pbxprojPath = Join-Path $projectRoot "ios\Runner.xcodeproj\project.pbxproj"
if (Test-Path $pbxprojPath) {
    $pbxproj = Get-Content $pbxprojPath -Raw -Encoding UTF8
    $pbxproj = $pbxproj -replace "IPHONEOS_DEPLOYMENT_TARGET = [\d.]+;", "IPHONEOS_DEPLOYMENT_TARGET = 13.0;"
    Set-Content -Path $pbxprojPath -Value $pbxproj -Encoding UTF8 -NoNewline
    Write-Host "تم ضبط الحد الأدنى لنظام iOS على 13.0 في مشروع Xcode." -ForegroundColor Green
}

Write-Host "`nملاحظة: بناء iOS يحتاج جهاز macOS — استخدمي GitHub Actions للبناء سحابيًا." -ForegroundColor Yellow
