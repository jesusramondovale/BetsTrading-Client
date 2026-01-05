# Cómo obtener las huellas SHA para Google Sign-In

## ⚠️ IMPORTANTE: Huellas SHA por PC

**Las huellas SHA son ÚNICAS por cada PC/keystore.**

- Cada PC tiene su propio keystore de debug con huellas SHA diferentes
- Si trabajas desde múltiples PCs (trabajo/casa), necesitarás agregar las huellas SHA de CADA PC en Google Cloud Console
- Google Cloud Console permite agregar MÚLTIPLES huellas SHA al mismo cliente OAuth

## Error 10 (DEVELOPER_ERROR)

Este error ocurre cuando las huellas digitales SHA-1/SHA-256 no coinciden con las configuradas en Google Cloud Console.

## Pasos para obtener las huellas SHA

### Método 1: Usando Gradle (Recomendado)

Si Gradle no funciona por problemas de Java, primero configura Java 11 en `android/gradle.properties`:
```
org.gradle.java.home=C:\\Program Files\\Microsoft\\jdk-11.0.16.101-hotspot
```

Luego, desde el directorio raíz del proyecto, ejecuta:

```bash
cd android
.\gradlew.bat signingReport
```

Busca en la salida las líneas que contengan:
- `SHA1:`
- `SHA256:`

Copiarás algo como:
```
SHA1: A1:B2:C3:D4:E5:F6:...
SHA256: 12:34:56:78:90:AB:CD:EF:...
```

### Método 2: Usando keytool directamente (MÁS RÁPIDO ⚡)

Si Gradle no funciona o quieres un método más rápido, usa keytool directamente:

**Para debug (keystore por defecto de Android):**

En PowerShell:
```powershell
keytool -list -v -keystore "$env:USERPROFILE\.android\debug.keystore" -alias androiddebugkey -storepass android -keypass android
```

En CMD:
```cmd
keytool -list -v -keystore "%USERPROFILE%\.android\debug.keystore" -alias androiddebugkey -storepass android -keypass android
```

**Para release (si tienes un keystore personalizado):**
```bash
keytool -list -v -keystore ruta\a\tu\keystore.jks -alias tu_alias
```

Busca las líneas en la salida:
- `SHA1: A1:B2:C3:...`
- `SHA256: 12:34:56:...`

**NOTA:** El keystore de debug usa contraseñas por defecto (`android` para storepass y keypass).

### 2. Actualizar en Google Cloud Console

1. Ve a: https://console.cloud.google.com/apis/credentials
2. Busca tu OAuth 2.0 Client ID para Android
   - Package name debe ser: `com.betstrading.betrader`
   - Client ID debe coincidir con: `1020559524014-ge0t5b3bhkpdpg8h958b4rf8o716l12r`
3. Edita el cliente OAuth 2.0
4. En la sección "Huellas digitales del certificado SHA", agrega:
   - SHA-1: (la que obtuviste del paso 1)
   - SHA-256: (la que obtuviste del paso 1)
5. Guarda los cambios

### 3. Notas importantes

**Múltiples PCs:**
Si trabajas desde diferentes PCs (trabajo/casa), cada uno tiene su propio keystore de debug con huellas SHA diferentes. Debes agregar las huellas SHA de CADA PC en Google Cloud Console.

**Debug vs Release:**
Si estás usando diferentes variantes de build (debug/release), necesitarás agregar AMBAS huellas:
- La huella SHA del keystore de debug (usada durante desarrollo)
- La huella SHA del keystore de release (usada para producción)

**Múltiples huellas SHA:**
Google Cloud Console permite agregar múltiples huellas SHA al mismo cliente OAuth. Esto es necesario si:
- Trabajas desde múltiples PCs (cada uno con su keystore de debug)
- Usas builds de debug y release
- Tienes diferentes entornos de desarrollo

### 4. Verificar configuración

Asegúrate de que en `lib/config/config.dart` el `SERVER_CLIENT_ID` sea:
```
1020559524014-ge0t5b3bhkpdpg8h958b4rf8o716l12r.apps.googleusercontent.com
```

### 5. Reconstruir la app

Después de actualizar las huellas:
```bash
flutter clean
flutter pub get
flutter run
```

