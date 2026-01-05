# 🔐 Configuración de Google Sign-In - Huellas SHA

## ⚠️ IMPORTANTE: Configuración por PC/Entorno

**Esta configuración es desde el PC del TRABAJO.**

⚠️ **Las huellas SHA son ÚNICAS por cada PC/keystore.** Esto significa que:

- ✅ **PC del TRABAJO:** Tiene sus propias huellas SHA (las que están documentadas aquí)
- ✅ **PC de CASA:** Tendrá DIFERENTES huellas SHA
- ✅ **Cada PC debe tener sus huellas SHA agregadas en Google Cloud Console**

## 📍 Ubicación de Keystores

### PC del TRABAJO (Actual)

**Keystore de DEBUG:**
- Ubicación: `C:\Users\USUARIO\.android\debug.keystore`
- Este keystore es específico de este PC y genera huellas SHA únicas

### PC de CASA

**Keystore de DEBUG:**
- Ubicación: `C:\Users\TU_USUARIO_CASA\.android\debug.keystore`
- ⚠️ Este keystore será DIFERENTE y tendrá DIFERENTES huellas SHA

## 🔑 Huellas SHA del PC del TRABAJO

⚠️ **Las huellas SHA del PC del TRABAJO están en el archivo `TUS_HUELLAS_SHA.txt` (no incluido en el repositorio).**

Para obtener tus propias huellas SHA, consulta `OBTENER_SHA.md`.

## 🔑 Huellas SHA del PC de CASA

⚠️ **PENDIENTE:** Necesitas obtenerlas cuando trabajes desde casa.

### Cómo obtener las huellas SHA en casa:

```powershell
# En PowerShell, desde el directorio raíz del proyecto:
keytool -list -v -keystore "$env:USERPROFILE\.android\debug.keystore" -alias androiddebugkey -storepass android -keypass android
```

Busca las líneas:
- `SHA1: ...`
- `SHA256: ...`

## 📝 Solución: Agregar AMBAS huellas en Google Cloud Console

Para que Google Sign-In funcione tanto en el PC del trabajo como en casa, debes agregar **AMBAS** huellas SHA en Google Cloud Console:

1. Ve a: https://console.cloud.google.com/apis/credentials
2. Busca tu OAuth 2.0 Client ID para Android:
   - Package name: `com.betstrading.betrader`
   - Client ID: `1020559524014-ge0t5b3bhkpdpg8h958b4rf8o716l12r`
3. Edita el cliente OAuth 2.0
4. En "Huellas digitales del certificado SHA", agrega:
   - ✅ SHA-1 y SHA-256 del **PC del TRABAJO** (ya agregadas)
   - ✅ SHA-1 y SHA-256 del **PC de CASA** (agregar cuando las obtengas)
5. Guarda los cambios

**Nota:** Puedes agregar MÚLTIPLES huellas SHA en el mismo cliente OAuth. Esto permite que la app funcione desde diferentes PCs.

## 🔄 Workflow Recomendado

### Primera vez en casa:
1. Ejecuta el comando keytool para obtener las huellas SHA del PC de casa
2. Agrega esas huellas SHA en Google Cloud Console
3. Espera 2-5 minutos para que se propaguen los cambios
4. Prueba el login con Google

### Si cambias de PC:
- Cada PC nuevo necesitará tener sus huellas SHA agregadas en Google Cloud Console
- El proceso es el mismo: obtener huellas → agregar en Google Cloud Console

## 💡 Alternativa: Usar un Keystore Compartido

Si quieres usar las MISMAS huellas SHA en ambos PCs, puedes:

1. **Copiar el keystore de debug:**
   - Copiar `C:\Users\USUARIO\.android\debug.keystore` (del trabajo)
   - Pegarlo en `C:\Users\TU_USUARIO_CASA\.android\debug.keystore` (en casa)
   
   ⚠️ **ADVERTENCIA:** Esto solo funciona si ambos PCs usan el mismo usuario de Windows o configuras los permisos correctamente.

2. **Usar un keystore de release compartido:**
   - Crear un keystore de release
   - Guardarlo en un lugar seguro (ej: encriptado en la nube)
   - Usar ese mismo keystore en ambos PCs
   - Esto requiere configurar `key.properties` en ambos PCs

## 📋 Checklist

- [x] Huellas SHA del PC del TRABAJO obtenidas
- [x] Huellas SHA del PC del TRABAJO agregadas en Google Cloud Console
- [ ] Huellas SHA del PC de CASA obtenidas (pendiente)
- [ ] Huellas SHA del PC de CASA agregadas en Google Cloud Console
- [ ] Google Sign-In probado desde PC del TRABAJO
- [ ] Google Sign-In probado desde PC de CASA

## 🔗 Archivos Relacionados

- `TUS_HUELLAS_SHA.txt` - Huellas SHA actuales (PC del TRABAJO) - ⚠️ **NO incluido en repositorio**
- `OBTENER_SHA.md` - Guía para obtener huellas SHA
- `UBICACION_KEYSTORES.md` - Información sobre ubicación de keystores

## 📞 Notas Adicionales

- El keystore de debug se genera automáticamente la primera vez que ejecutas una app Android
- Cada PC tiene su propio keystore de debug con huellas SHA únicas
- Google Cloud Console permite agregar múltiples huellas SHA al mismo cliente OAuth
- Los cambios en Google Cloud Console pueden tardar hasta 5 minutos en propagarse

