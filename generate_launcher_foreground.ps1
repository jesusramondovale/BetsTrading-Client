# Script para generar los iconos ic_launcher_foreground.png usando directamente new_icon.png
# Uso: .\generate_launcher_foreground.ps1 [ruta_imagen]
# Ejemplo: .\generate_launcher_foreground.ps1 assets/new_icon.png
# Si no se proporciona ruta, usa assets/new_icon.png por defecto

param(
    [Parameter(Position=0)]
    [string]$ImagePath = "assets/app_icon.png"
)

Write-Host "Generando iconos ic_launcher_foreground.png..." -ForegroundColor Green
Write-Host "Imagen fuente: $ImagePath" -ForegroundColor Cyan
Write-Host ""

# Verificar que la imagen existe
if (-not (Test-Path $ImagePath)) {
    Write-Host "ERROR: No se encuentra la imagen en: $ImagePath" -ForegroundColor Red
    exit 1
}

# Función para redimensionar imagen usando .NET System.Drawing
function Resize-Image {
    param(
        [string]$SourcePath,
        [string]$DestinationPath,
        [int]$Width,
        [int]$Height
    )
    
    try {
        Add-Type -AssemblyName System.Drawing
        
        $sourceImage = [System.Drawing.Image]::FromFile((Resolve-Path $SourcePath).Path)
        
        # Crear una nueva imagen con las dimensiones especificadas y formato ARGB (canal alpha para transparencia)
        $bitmap = New-Object System.Drawing.Bitmap($Width, $Height, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
        $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
        
        # Configurar alta calidad de redimensionamiento
        $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
        $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
        $graphics.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
        $graphics.CompositingQuality = [System.Drawing.Drawing2D.CompositingQuality]::HighQuality
        
        # Limpiar el área de dibujo (asegura fondo transparente)
        $graphics.Clear([System.Drawing.Color]::Transparent)
        
        # Dibujar la imagen redimensionada directamente (sin fondo, preservando transparencia)
        $graphics.DrawImage($sourceImage, 0, 0, $Width, $Height)
        
        # Guardar como PNG
        $resolvedPath = try { (Resolve-Path $DestinationPath).Path } catch { $DestinationPath }
        $bitmap.Save($resolvedPath, [System.Drawing.Imaging.ImageFormat]::Png)
        
        # Liberar recursos
        $graphics.Dispose()
        $bitmap.Dispose()
        $sourceImage.Dispose()
        
        return $true
    } catch {
        Write-Host "  [ERROR] $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

# Nombre del archivo destino
$destFileName = "ic_launcher_foreground.png"

# Dimensiones para cada densidad según especificaciones de Android adaptive icons
$drawableFolders = @{
    "android/app/src/main/res/drawable-mdpi" = @{ Size = 108 }
    "android/app/src/main/res/drawable-hdpi" = @{ Size = 162 }
    "android/app/src/main/res/drawable-xhdpi" = @{ Size = 216 }
    "android/app/src/main/res/drawable-xxhdpi" = @{ Size = 324 }
    "android/app/src/main/res/drawable-xxxhdpi" = @{ Size = 432 }
}

Write-Host "Redimensionando y copiando imagen a las carpetas de recursos..." -ForegroundColor Yellow
Write-Host ""

$successCount = 0
$failCount = 0

foreach ($folder in $drawableFolders.Keys) {
    if (Test-Path $folder) {
        $size = $drawableFolders[$folder].Size
        $destPath = Join-Path $folder $destFileName
        
        Write-Host "  Procesando $folder" -ForegroundColor Cyan
        Write-Host "    Dimensiones: ${size}x${size} px" -ForegroundColor Gray
        
        if (Resize-Image -SourcePath $ImagePath -DestinationPath $destPath -Width $size -Height $size) {
            Write-Host "    [OK] Generado: $destPath" -ForegroundColor Green
            $successCount++
        } else {
            Write-Host "    [ERROR] No se pudo generar $destPath" -ForegroundColor Red
            $failCount++
        }
    } else {
        Write-Host "  [SKIP] Carpeta no existe: $folder" -ForegroundColor Yellow
    }
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
if ($successCount -gt 0) {
    Write-Host "Iconos generados exitosamente!" -ForegroundColor Green
    Write-Host "Iconos creados: $successCount" -ForegroundColor Cyan
}
if ($failCount -gt 0) {
    Write-Host "Iconos con errores: $failCount" -ForegroundColor Red
}
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Los archivos ic_launcher_foreground.png han sido actualizados en todas las densidades." -ForegroundColor Cyan
Write-Host "El adaptive icon en ic_launcher.xml ya está configurado para usar estos archivos." -ForegroundColor Cyan
