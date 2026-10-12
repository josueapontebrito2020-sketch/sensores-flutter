# Sensores en Flutter: batería, luz y proximidad

App de ejemplo en **Flutter y Dart** que lee tres sensores del dispositivo y muestra sus valores en tiempo real: **batería**, **luz ambiental** y **proximidad**. Es el proyecto de la actividad grupal de **Programación móvil (SS603)**: video tutorial sobre funcionalidades nativas con Flutter.

## Qué hace la app

| Sensor | Qué muestra |
| --- | --- |
| Batería | Nivel (0 a 100 %) y estado: Cargando, Desconectado, Completa o Conectado (sin cargar) |
| Luz | Iluminancia en lux. Si baja de 20 lux, el fondo de la pantalla cambia a oscuro |
| Proximidad | "Objeto CERCA" o "Despejado", junto con el valor crudo que entrega el sensor |

Si el dispositivo no tiene un sensor, la app no falla: muestra el texto **"Sensor no disponible"** en esa tarjeta.

## Paquetes usados

| Paquete | Para qué se usa |
| --- | --- |
| [`battery_plus`](https://pub.dev/packages/battery_plus) | Nivel y estado de la batería |
| [`light`](https://pub.dev/packages/light) | Sensor de luz ambiental |
| [`proximity_sensor`](https://pub.dev/packages/proximity_sensor) | Sensor de proximidad |

Las versiones exactas están en `pubspec.yaml`.

## Permisos por plataforma

Ninguno de los tres sensores pide un permiso en ejecución en Android ni en iOS. Por eso no existe un diálogo para aceptar o negar un permiso. El caso equivalente es que el sensor no esté disponible, y la app lo maneja con el texto "Sensor no disponible".

| Sensor | Android | iOS | Web |
| --- | --- | --- | --- |
| Batería | Ninguno | Ninguno | Battery Status API: solo navegadores Chromium y con HTTPS |
| Luz | Ninguno | Sin API pública. SensorKit exige un entitlement aprobado por Apple | AmbientLightSensor: experimental, desactivada por defecto en Chrome, requiere HTTPS |
| Proximidad | Ninguno. `WAKE_LOCK` solo si la app apaga la pantalla | Ninguno. El sistema apaga la pantalla al activar el monitoreo | Sin soporte en los navegadores principales |

Dónde se configura cada plataforma:

- **Android:** `android/app/src/main/AndroidManifest.xml`. No hay ningún `uses-permission` para estos sensores. El permiso `HIGH_SAMPLING_RATE_SENSORS` (Android 12 o superior) solo hace falta para frecuencias de más de 200 Hz, y no se usa.
- **iOS:** `ios/Runner/Info.plist`. No hay ninguna clave de uso (`NS...UsageDescription`) para estos sensores.
- **Web:** `web/index.html`. No se declara nada: depende del navegador.

## Estructura del proyecto

```
sensores_demo/
├── lib/
│   └── main.dart        # Toda la lógica y la interfaz
├── android/             # Configuración de Android
├── ios/                 # Configuración de iOS
├── web/                 # Configuración de Web
└── pubspec.yaml         # Dependencias
```

## Cómo funciona el código (`lib/main.dart`)

1. **Estado:** `SensoresPage` es un `StatefulWidget`. Guarda el nivel y el estado de la batería, los lux, si hay luz disponible, si hay un objeto cerca y el valor crudo de proximidad.
2. **Suscripciones:** cada sensor entrega un `Stream`. Las suscripciones se guardan en la lista `_subs`.
3. **`_iniciar()`:** se llama en `initState` y conecta los tres sensores. Cada dato nuevo actualiza la pantalla con `setState`.
4. **Sensor no disponible:** la luz va dentro de un `try` y `catch`, y tiene `onError`. Si falla, `_luzDisponible` queda en `false`.
5. **`mounted`:** antes de cada `setState` se comprueba `if (!mounted) return;` para no actualizar una pantalla que ya se cerró.
6. **`dispose()`:** cancela todas las suscripciones para evitar fugas de memoria y consumo de batería.
7. **`_textoEstado()`:** traduce el estado de la batería al español.

## Requisitos

- **Flutter 3.44 o superior** (lo exige `proximity_sensor`). Comprueba la versión con `flutter --version`.
- Android Studio con el SDK de Android, o al menos las herramientas de línea de comandos.
- VS Code con las extensiones de Flutter y Dart (opcional).
- Un celular Android con **Depuración USB** activada. Los emuladores casi no simulan estos sensores, así que se recomienda un dispositivo real.
- En **Windows**, el **Modo de desarrollador** activado (Flutter lo necesita para enlazar los plugins).

Comprueba tu entorno con:

```bash
flutter doctor
```

## Cómo ejecutarla

1. Clona el repositorio y entra a la carpeta:

   ```bash
   git clone <URL-del-repositorio>
   cd sensores_demo
   ```

2. Descarga las dependencias:

   ```bash
   flutter pub get
   ```

3. Conecta el celular por USB con la depuración activada y comprueba que aparezca:

   ```bash
   flutter devices
   ```

4. Ejecuta la app en tu dispositivo:

   ```bash
   flutter run -d <id-del-dispositivo>
   ```

La primera compilación en Android es lenta, porque descarga Gradle, el NDK y el SDK. Las siguientes son mucho más rápidas.

## Cómo probarla

1. **Batería:** conecta y desconecta el cargador. El estado cambia entre "Cargando" y "Desconectado".
2. **Luz:** tapa la parte superior del celular con la mano. El valor baja casi a cero y el fondo se vuelve oscuro. Apunta una linterna al sensor y el valor sube.
3. **Proximidad:** acerca la mano a la parte superior de la pantalla. Cambia a "Objeto CERCA" y, al alejarla, vuelve a "Despejado".

## Solución de problemas

| Problema | Solución |
| --- | --- |
| `Building with plugins requires symlink support` | Activa el Modo de desarrollador de Windows: `start ms-settings:developers` |
| El celular no aparece en `flutter devices` | Activa la Depuración USB, usa un cable de datos y acepta el aviso en el celular |
| `INSTALL_FAILED_USER_RESTRICTED` (Xiaomi, Redmi, Poco) | Activa **Instalar vía USB** en Opciones de desarrollador y acepta rápido el aviso de instalación |
| Errores rojos en el editor al abrir el proyecto en otro computador | Ejecuta `flutter pub get` y reinicia el analizador (**Dart: Restart Analysis Server**) |
| Error de rutas de otro computador al compilar | Borra `build`, `.dart_tool` y `android/local.properties`, y vuelve a ejecutar `flutter pub get` |
| La luz muestra "Sensor no disponible" | El dispositivo no tiene el sensor o no lo entrega a la app (en iOS no está disponible) |
| La proximidad no cambia | Algunos celulares usan un sensor virtual poco sensible. Prueba acercando la palma a 1 o 2 cm del auricular |

## Limitaciones conocidas

- La luz ambiental funciona en **Android**. En iOS no hay una API pública sencilla para leerla.
- La proximidad depende del hardware: algunos modelos no tienen un sensor físico.
- En Web, la luz y la proximidad no tienen soporte en los navegadores principales.

## Equipo

- Alan Omar Amador de La Cruz
- Johsua Josue Aponte Brito

Programación móvil (SS603) · Grupo [número]