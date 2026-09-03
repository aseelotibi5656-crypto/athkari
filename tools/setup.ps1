# إعداد مشروع "أذكاري" لأول مرة.
#
# الاستخدام (من مجلد المشروع):
#   powershell -ExecutionPolicy Bypass -File tools\setup.ps1
#
# ما يفعله:
#   1) يتأكد من وجود Flutter.
#   2) ينزّل الحزم (flutter pub get).
#   3) يشغّل التحليل والاختبارات.
#
# مجلد أندرويد جاهز في المشروع ولا يحتاج توليدًا.
#
# لتوليد مجلد iOS لاحقًا (بناؤه يحتاج جهاز macOS):
#   powershell -ExecutionPolicy Bypass -File tools\setup.ps1 -WithIos

param(
    [switch]$WithIos
)

$ErrorActionPreference = "Stop"
$projectRoot = Split-Path -Parent $PSScriptRoot
Set-Location $projectRoot

Write-Host "==> التحقق من Flutter..." -ForegroundColor Cyan
$flutter = Get-Command flutter -ErrorAction SilentlyContinue
if (-not $flutter) {
    Write-Host "Flutter غير مثبّت أو غير مضاف إلى PATH." -ForegroundColor Red
    Write-Host "ثبّته من: https://docs.flutter.dev/get-started/install/windows"
    exit 1
}
flutter --version

Write-Host "`n==> تنزيل الحزم..." -ForegroundColor Cyan
flutter pub get
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

if ($WithIos -and -not (Test-Path "ios")) {
    Write-Host "`n==> توليد مجلد iOS..." -ForegroundColor Cyan

    # نحمي الكود والإعدادات من أي استبدال يقوم به flutter create.
    $backup = Join-Path $env:TEMP ("athkari_backup_" + [Guid]::NewGuid().ToString("N"))
    New-Item -ItemType Directory -Path $backup -Force | Out-Null
    Copy-Item -Path "lib" -Destination $backup -Recurse -Force
    Copy-Item -Path "pubspec.yaml" -Destination $backup -Force
    if (Test-Path "android") { Copy-Item -Path "android" -Destination $backup -Recurse -Force }

    flutter create --platforms=ios --org com.aseelotibi --project-name athkari .

    # استرجاع الملفات الأصلية.
    Remove-Item -Path "lib" -Recurse -Force
    Copy-Item -Path (Join-Path $backup "lib") -Destination $projectRoot -Recurse -Force
    Copy-Item -Path (Join-Path $backup "pubspec.yaml") -Destination $projectRoot -Force
    if (Test-Path (Join-Path $backup "android")) {
        Remove-Item -Path "android" -Recurse -Force
        Copy-Item -Path (Join-Path $backup "android") -Destination $projectRoot -Recurse -Force
    }
    Remove-Item -Path $backup -Recurse -Force

    & (Join-Path $PSScriptRoot "patch_ios.ps1")
} elseif ($WithIos) {
    Write-Host "`n==> مجلد iOS موجود مسبقًا، تم تخطّي التوليد." -ForegroundColor Yellow
}

Write-Host "`n==> تحليل الكود..." -ForegroundColor Cyan
flutter analyze

Write-Host "`n==> تشغيل الاختبارات..." -ForegroundColor Cyan
flutter test

Write-Host "`nتم الإعداد. شغّل التطبيق بـ: flutter run" -ForegroundColor Green
