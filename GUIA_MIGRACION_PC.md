# 🚀 Guía de Migración del Proyecto a Otro PC

Esta guía te ayudará a migrar el proyecto BetsTrading-Client a un nuevo PC con Android Studio.

## ⚠️ Problemas Comunes y Soluciones

### 1. ✅ Archivo `local.properties` (Se regenera automáticamente)

**Problema:** El archivo contiene rutas absolutas específicas del PC anterior.

**Solución:**
- Android Studio normalmente regenera este archivo automáticamente
- Si no se regenera, créalo manualmente en `android/local.properties`:

```properties
sdk.dir=C:\\Users\\TU_NUEVO_USUARIO\\AppData\\Local\\Android\\sdk
flutter.sdk=C:\\ruta\\donde\\instalaste\\flutter
flutter.buildMode=debug
flutter.versionName=26.3.1
flutter.versionCode=260031
```

### 2. 🔑 Keystore de Debug y Google Sign-In

**Problema:** Cada PC tiene su propio keystore de debug con huellas SHA únicas.

**Solución A: Agregar nuevas huellas SHA en Google Cloud Console (Recomendado)**

1. Obtén las huellas SHA del nuevo PC:
```powershell
keytool -list -v -keystore "$env:USERPROFILE\.android\debug.keystore" -alias androiddebugkey -storepass android -keypass android
```

2. Busca las líneas `SHA1:` y `SHA256:`

3. Ve a [Google Cloud Console - Credentials](https://console.cloud.google.com/apis/credentials)

4. Busca el OAuth 2.0 Client ID para Android:
   - Package name: `com.betstrading.betrader`
   - Client ID: `1020559524014-ge0t5b3bhkpdpg8h958b4rf8o716l12r`

5. Edita el cliente y agrega las nuevas huellas SHA

6. Espera 2-5 minutos para que se propaguen los cambios

**Solución B: Copiar el keystore de debug (Alternativa)**

Si quieres usar las mismas huellas SHA:
1. Copia `C:\Users\USUARIO_ANTERIOR\.android\debug.keystore`
2. Pégalo en `C:\Users\TU_NUEVO_USUARIO\.android\debug.keystore`
3. ⚠️ Asegúrate de que los permisos sean correctos

### 3. 🔥 Archivo `google-services.json` (Firebase)

**Problema:** El archivo puede no estar en el repositorio (está en `.gitignore`).

**Solución:**
1. Ve a [Firebase Console](https://console.firebase.google.com/)
2. Selecciona el proyecto `betrader-v1`
3. Ve a Configuración del proyecto → Tus apps
4. Descarga el archivo `google-services.json` para Android
5. Colócalo en `android/app/google-services.json`

### 4. 📦 Dependencias de Flutter

**Problema:** Las dependencias no están descargadas.

**Solución:**
```bash
flutter pub get
flutter pub upgrade
```

### 5. 🛠️ Configuración de Gradle

**Problema:** Configuración de memoria puede no ser adecuada.

**Solución:**
- Revisa `android/gradle.properties` y ajusta `-Xmx8G` si tu PC tiene menos RAM
- Verifica que el NDK version `27.0.12077973` esté instalado en Android Studio

### 6. 🔐 Archivo `key.properties` y Keystores (⚠️ CRÍTICO - Transferencia Manual Requerida)

**Problema:** Los archivos `.jks`, `.keystore` y `key.properties` **NO están en el repositorio** por seguridad. Debes transferirlos manualmente de forma privada.

**⚠️ IMPORTANTE:** Estos archivos contienen credenciales sensibles y **NUNCA** deben subirse a Git.

**Solución - Transferencia Segura:**

#### Opción A: Transferencia Directa (USB, Disco Externo, etc.)

1. **En el PC anterior:**
   - Localiza tu archivo `.jks` o `.keystore` (puede estar en `android/app/` o en otra ubicación segura)
   - Localiza el archivo `android/key.properties` (si existe)
   - Copia ambos archivos a un USB/disco externo encriptado o transferencia segura

2. **En el nuevo PC:**
   - Copia el archivo `.jks` o `.keystore` a una ubicación segura (ej: `C:\keystores\betrader-release.jks`)
   - Crea `android/key.properties` con las rutas actualizadas:

```properties
storePassword=tu-store-password
keyPassword=tu-key-password
keyAlias=tu-alias
storeFile=C:\\keystores\\betrader-release.jks
```

#### Opción B: Almacenamiento en la Nube Encriptado

1. Comprime el archivo `.jks` con contraseña
2. Sube el archivo comprimido a un servicio seguro (ej: Google Drive con encriptación, OneDrive, etc.)
3. Descárgalo en el nuevo PC y descomprímelo
4. Elimina el archivo de la nube después de transferirlo

#### Opción C: Si NO tienes keystore de release

Si nunca creaste un keystore de release, puedes trabajar solo con el keystore de debug:
- El keystore de debug se genera automáticamente en cada PC
- Solo necesitarás agregar las nuevas huellas SHA en Google Cloud Console (ver sección 2)

**⚠️ ADVERTENCIA DE SEGURIDAD:**
- ❌ **NUNCA** subas archivos `.jks`, `.keystore` o `key.properties` al repositorio Git
- ✅ Usa transferencias seguras (USB, disco encriptado, nube encriptada)
- ✅ Mantén backups encriptados en ubicaciones seguras
- ✅ Si pierdes el keystore de release, **NO podrás actualizar tu app en Google Play Store**

### 7. 🎯 Configuración de Android Studio

**Verificaciones:**
- ✅ Flutter SDK instalado y configurado
- ✅ Android SDK instalado (mínimo API 24, compileSdk 36)
- ✅ NDK version 27.0.12077973 instalado
- ✅ Java 17+ configurado (Gradle lo detecta automáticamente)
- ✅ Plugins de Flutter y Dart instalados en Android Studio

## 📋 Checklist de Migración

### Antes de migrar:
- [ ] Verificar que el proyecto esté en un repositorio Git
- [ ] Hacer commit de todos los cambios pendientes
- [ ] **Localizar y copiar archivos sensibles que NO están en Git:**
  - [ ] Archivo `.jks` o `.keystore` de release (si existe)
  - [ ] Archivo `android/key.properties` (si existe)
  - [ ] Archivo `android/app/google-services.json` (si no está en Git)
- [ ] Preparar método de transferencia segura (USB, disco externo, nube encriptada)

### En el nuevo PC:
- [ ] Instalar Android Studio
- [ ] Instalar Flutter SDK
- [ ] Clonar el repositorio
- [ ] Abrir el proyecto en Android Studio
- [ ] Verificar que `local.properties` se haya generado correctamente
- [ ] Ejecutar `flutter pub get`
- [ ] Verificar que `google-services.json` esté presente
- [ ] Obtener huellas SHA del nuevo PC
- [ ] Agregar huellas SHA en Google Cloud Console (si usas Google Sign-In)
- [ ] Probar compilación: `flutter build apk --debug`
- [ ] Probar ejecución en emulador/dispositivo

### Si tienes keystore de release (⚠️ Transferencia Manual Requerida):
- [ ] **Transferir archivo `.jks` o `.keystore` desde el PC anterior** (USB, disco, nube encriptada)
- [ ] Colocar el keystore en una ubicación segura en el nuevo PC
- [ ] Crear `android/key.properties` con las rutas correctas del nuevo PC
- [ ] Verificar que `key.properties` tenga las rutas correctas (Windows usa `\\` o `/`)
- [ ] Probar compilación release: `flutter build apk --release`
- [ ] ⚠️ Verificar que `key.properties` y `.jks` NO se suban a Git (están en `.gitignore`)

## 🔍 Verificación Final

Ejecuta estos comandos para verificar que todo está correcto:

```bash
# Verificar Flutter
flutter doctor

# Verificar dependencias
flutter pub get

# Limpiar build anterior
flutter clean

# Probar compilación
flutter build apk --debug
```

## 📞 Archivos de Referencia

- `CONFIGURACION_GOOGLE_SIGNIN.md` - Configuración de Google Sign-In
- `OBTENER_SHA.md` - Cómo obtener huellas SHA
- `UBICACION_KEYSTORES.md` - Información sobre keystores

## ⚠️ Problemas Comunes

### Error: "SDK location not found"
- Verifica que `local.properties` tenga la ruta correcta del Android SDK
- Asegúrate de que Android Studio esté instalado correctamente

### Error: "Flutter SDK not found"
- Verifica que `local.properties` tenga la ruta correcta del Flutter SDK
- Ejecuta `flutter doctor` para verificar la instalación

### Error: "Google Sign-In failed"
- Verifica que las huellas SHA estén agregadas en Google Cloud Console
- Espera 2-5 minutos después de agregar las huellas
- Verifica que el package name sea `com.betstrading.betrader`

### Error: "google-services.json not found"
- Descarga el archivo desde Firebase Console
- Colócalo en `android/app/google-services.json`

## 💡 Tips

1. **Usa Git:** Asegúrate de que todos los archivos importantes estén versionados
2. **Documenta configuraciones locales:** Crea archivos `.example` para configuraciones que no se suben a Git
3. **Mantén backups seguros:** Guarda copias de seguridad encriptadas de keystores en ubicaciones seguras (nube encriptada, disco externo, etc.)
4. **Sincroniza huellas SHA:** Agrega las huellas SHA de todos los PCs donde trabajes en Google Cloud Console
5. **Verifica .gitignore:** Asegúrate de que `.jks`, `.keystore` y `key.properties` estén en `.gitignore` antes de hacer commit
6. **Usa un gestor de contraseñas:** Guarda las contraseñas de los keystores en un gestor de contraseñas seguro

## 🔒 Archivos que NO están en Git (Debes transferirlos manualmente)

Estos archivos están excluidos del repositorio por seguridad y debes transferirlos manualmente:

- ❌ `android/app/*.jks` - Keystore de release
- ❌ `android/app/*.keystore` - Keystore de release (formato alternativo)
- ❌ `android/key.properties` - Configuración del keystore
- ❌ `android/app/google-services.json` - Configuración de Firebase (puede estar o no en Git)
- ❌ `android/local.properties` - Se regenera automáticamente en cada PC

**Métodos seguros de transferencia:**
- USB o disco externo
- Servicio de nube encriptado (Google Drive, OneDrive, Dropbox con encriptación)
- Transferencia directa por red local (cable, WiFi seguro)
- Email encriptado (solo si es absolutamente necesario)

