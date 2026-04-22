# WeatherWay 🌦️🗺️

Aplicación móvil desarrollada en Flutter que recomienda planes y lugares cercanos en función de la ubicación del usuario y las condiciones meteorológicas en tiempo real.

Proyecto desarrollado como Trabajo de Fin de Grado (TFG).
---
## Problema

Las aplicaciones tradicionales de mapas muestran lugares cercanos sin tener en cuenta el clima, lo que puede generar recomendaciones poco útiles (por ejemplo, actividades al aire libre en días de lluvia o calor extremo).
--
## Solución

Desarrollo de una aplicación que combina geolocalización, datos meteorológicos y categorías de interés para ofrecer recomendaciones adaptadas al contexto real del usuario.
--
## Lógica de recomendación

Implementación de un sistema que ajusta dinámicamente los resultados en función de:

condiciones meteorológicas (lluvia, temperatura)
tipo de actividad (interior/exterior)
preferencias del usuario

Ejemplos:

🌧️ Lluvia → prioriza espacios cerrados (museos, centros comerciales)
☀️ Calor extremo → evita actividades prolongadas al aire libre
--
##  Funcionalidades principales

- Registro e inicio de sesión con **Firebase Auth** (email/contraseña y Google).
- Obtención de ubicación del usuario con **Geolocator**.
- Visualización de mapa interactivo con **Google Maps**.
- Recomendación de lugares según clima y categorías.
- Consulta de clima actual mediante **OpenWeatherMap**.
- Guardado de favoritos en **Cloud Firestore**.
- Pantallas de perfil, ajustes y gestión de favoritos.

---

## Tecnologías utilizadas

- **Flutter / Dart**
- **Firebase Core**
- **Firebase Auth**
- **Cloud Firestore**
- **Google Sign-In**
- **Google Maps Flutter**
- **Google Maps Web Services**
- **Geolocator**
- **HTTP**
- **Connectivity Plus**

---

## Estructura del repositorio

- `tfg/` → código fuente principal de la app Flutter.
- `Manual_de_usuario_WeatherWay.pdf` → manual de usuario del proyecto.
- `app-release.apk` → build APK de ejemplo.

---
La aplicación fue completamente funcional durante su desarrollo. Actualmente el backend (Firebase) no se encuentra activo.


## Documentación adicional

- Manual de usuario: `Manual_de_usuario_WeatherWay.pdf`

---

##  Autor

**Francisco Marín**

Proyecto académico (TFG).
