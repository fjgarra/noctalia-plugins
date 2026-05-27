# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Naturaleza del repo

Workspace de plugins QML para noctalia-shell (Quickshell). Cada subdirectorio de primer nivel es un plugin independiente. El único entorno de ejecución es la máquina local (niri + noctalia corriendo).

## Crear y desplegar un plugin

**Scaffold:**
```bash
bash new-plugin.sh <plugin-id> "<Plugin Name>"
```

**Desplegar, reiniciar y verificar:**
```bash
bash .claude/skills/run-noctalia-plugins/driver.sh <plugin-id>
```

El driver copia el plugin a `~/.config/noctalia/plugins/`, lo habilita en `plugins.json`, reinicia noctalia, espera 5 s y verifica `"Plugin loaded: <plugin-id>"` en `/tmp/noctalia-restart.log`. Luego toma screenshot con `niri msg action screenshot-screen` → `~/Imágenes/Screenshots/`.

## Reglas críticas

- **No hay hot-reload.** Cualquier cambio en `.qml` o en el manifest requiere reinicio completo de noctalia. `plugins.json` y `settings.json` sí se recargan en vivo, pero el escaneo de plugins solo ocurre al arrancar.
- **`BarPill` para texto en barra** (`qs.Modules.Bar.Extras`). `NIconButton` no muestra texto.
- **`screen` es `required property`** en `BarPill` — no omitirlo.
- **`Logger.i/d/w/e`** para logging; no `console.log`.
- El `id` en `manifest.json` debe coincidir exactamente con el nombre del directorio.

## Añadir widget a la barra

Editar `~/.config/noctalia/settings.json`, insertar en `bar.widgets.left` o `.right`:
```json
{ "id": "plugin:<plugin-id>" }
```
Requiere reinicio para que surta efecto.

## Referencia QML/API

`AGENTS.md` (raíz del repo) contiene las guidelines completas: API de pluginApi, servicios disponibles (Keyboard, Compositor, UI), patrones de settings, convenciones de manifest. Leerlo antes de escribir código de plugin.
