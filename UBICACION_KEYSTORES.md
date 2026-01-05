# 📍 Ubicación de tus Keystores

## Situación Actual

**NO tienes keystore de RELEASE configurado actualmente.**

El archivo `android/key.properties` NO existe, lo que significa que:
- ✅ Estás usando el keystore de **DEBUG** por defecto (para desarrollo)
- ❌ NO tienes keystore de **RELEASE** configurado (para producción)

## 📂 Ubicaciones de Keystores

### 1. Keystore de DEBUG (el que estás usando ahora)

**Ubicación:**
```
C:\Users\TU_USUARIO\.android\debug.keystore
```

Este es el keystore que usaste para obtener las huellas SHA. Es el keystore por defecto de Android Studio.

**Contraseñas por defecto:**
- Store password: `android`
- Key password: `android`
- Alias: `androiddebugkey`

### 2. Keystore de RELEASE (NO configurado)

No tienes un keystore de release configurado. Si necesitas uno para publicar en Google Play Store, tienes dos opciones:

#### Opción A: Crear un nuevo keystore de release

```bash
keytool -genkey -v -keystore C:\ruta\donde\guardar\tu-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias tu-alias
```

Luego crea el archivo `android/key.properties` con este contenido:

```properties
storePassword=tu-store-password
keyPassword=tu-key-password
keyAlias=tu-alias
storeFile=C:\\ruta\\donde\\guardar\\tu-keystore.jks
```

#### Opción B: Si ya tienes un keystore de release

Busca en tu sistema archivos `.jks` o `.keystore`. Lugares comunes donde suelen estar:

- `C:\Users\TU_USUARIO\Documents\`
- `C:\Users\TU_USUARIO\Desktop\`
- `C:\dev\BetsTrading-Client\android\app\` (aunque está en .gitignore)
- Alguna carpeta de backups o documentos importantes

Para buscar en todo el sistema (PowerShell):
```powershell
Get-ChildItem -Path C:\ -Recurse -Include *.jks,*.keystore -ErrorAction SilentlyContinue | Select-Object FullName
```

⚠️ **ADVERTENCIA:** Este comando puede tardar mucho y requiere permisos administrativos.

## 🔍 Verificar si tienes keystores

Los archivos `.jks` y `.keystore` están en `.gitignore` por seguridad (no deben subirse a git), pero pueden estar en tu disco local.

### Buscar en ubicaciones comunes:

```powershell
# Buscar en tu directorio de usuario
Get-ChildItem -Path $env:USERPROFILE -Recurse -Include *.jks,*.keystore -ErrorAction SilentlyContinue

# Buscar en documentos
Get-ChildItem -Path "$env:USERPROFILE\Documents" -Recurse -Include *.jks,*.keystore -ErrorAction SilentlyContinue
```

## ⚠️ Importante

Si ya publicaste la app en Google Play Store antes, **DEBES usar el mismo keystore** o perderás la capacidad de actualizar la app. Google Play no permite cambiar el keystore de una app existente.

## 📝 Para Google Sign-In

**Para desarrollo (debug):** Ya tienes las huellas SHA configuradas ✅

**Para producción (release):** Si vas a publicar la app, necesitarás:
1. Crear/configurar tu keystore de release
2. Obtener las huellas SHA del keystore de release
3. Agregar esas huellas SHA también en Google Cloud Console

