# Script para generar el splash screen nativo copiando la imagen a las carpetas de recursos
# Uso: .\generate_splash.ps1 [ruta_imagen]
# Ejemplo: .\generate_splash.ps1 assets/android12splash-es.png
# Si no se proporciona ruta, usa assets/android12splash-clean.png por defecto

param(
    [Parameter(Position=0)]
    [string]$ImagePath = "assets/android12splash-clean.png"
)

Write-Host "Generando splash screen nativo..." -ForegroundColor Green
Write-Host "Imagen fuente: $ImagePath" -ForegroundColor Cyan
Write-Host ""

# Verificar que la imagen existe
if (-not (Test-Path $ImagePath)) {
    Write-Host "ERROR: No se encuentra la imagen en: $ImagePath" -ForegroundColor Red
    exit 1
}

# Nombre del archivo destino (android12splash_en.png)
$destFileName = "android12splash_en.png"

# Carpetas drawable donde copiar la imagen
$drawableFolders = @(
    "android/app/src/main/res/drawable",
    "android/app/src/main/res/drawable-v21",
    "android/app/src/main/res/drawable-hdpi",
    "android/app/src/main/res/drawable-mdpi",
    "android/app/src/main/res/drawable-xhdpi",
    "android/app/src/main/res/drawable-xxhdpi",
    "android/app/src/main/res/drawable-xxxhdpi"
)

Write-Host "Copiando imagen a las carpetas de recursos..." -ForegroundColor Yellow

$copiedCount = 0
foreach ($folder in $drawableFolders) {
    if (Test-Path $folder) {
        $destPath = Join-Path $folder $destFileName
        try {
            Copy-Item -Path $ImagePath -Destination $destPath -Force
            Write-Host "  [OK] $destPath" -ForegroundColor Green
            $copiedCount++
        } catch {
            Write-Host "  [ERROR] No se pudo copiar a $destPath" -ForegroundColor Red
        }
    } else {
        Write-Host "  [SKIP] Carpeta no existe: $folder" -ForegroundColor Yellow
    }
}

Write-Host ""
Write-Host "Splash screen generado exitosamente!" -ForegroundColor Green
Write-Host "Imagenes copiadas: $copiedCount de $($drawableFolders.Count)" -ForegroundColor Cyan
Write-Host ""
Write-Host "La imagen se ha copiado como '$destFileName' en las carpetas drawable." -ForegroundColor Cyan
Write-Host "Los archivos XML ya estan configurados para usar esta imagen." -ForegroundColor Cyan
Write-Host ""
Write-Host "Nota: Si cambias la imagen, ejecuta este script nuevamente." -ForegroundColor Yellow

