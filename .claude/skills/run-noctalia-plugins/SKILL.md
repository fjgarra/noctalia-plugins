---
name: run-noctalia-plugins
description: deploy, run, test, screenshot noctalia plugins; build and reload QML bar widgets for noctalia-shell
---

Workspace de plugins QML para noctalia-shell (Quickshell). Cada subdirectorio es un plugin independiente. El driver despliega un plugin a `~/.config/noctalia/plugins/`, reinicia noctalia-shell, verifica que cargó y toma un screenshot.

Paths relativos a `~/ia/noctalia-plugins/`.

## Crear un plugin nuevo

```bash
bash new-plugin.sh <plugin-id> "<Plugin Name>"
```

Genera `<plugin-id>/` con `manifest.json`, `BarWidget.qml` (Item+BarPill mínimo) e `i18n/en.json`. Edita los `TODO` y despliega con el driver.

## Estructura de un plugin

```
<plugin-id>/
  manifest.json       ← id, name, version, entryPoints, metadata.defaultSettings
  BarWidget.qml       ← widget de barra (si entryPoints.barWidget existe)
  i18n/en.json        ← traducciones (al menos "menu.settings" si hay contextMenu)
  Panel.qml           ← panel opcional
  Settings.qml        ← settings UI opcional
```

## Prerequisitos

noctalia-shell corriendo (`pgrep -f "qs -c noctalia-shell"`), niri activo, `$WAYLAND_DISPLAY` set (`wayland-1`). No hace falta nada más — QML no compila.

## Run (agent path)

```bash
cd ~/ia/noctalia-plugins
bash .claude/skills/run-noctalia-plugins/driver.sh <plugin-id>
```

El driver:
1. Copia `<plugin-id>/` a `~/.config/noctalia/plugins/`
2. Habilita el plugin en `~/.config/noctalia/plugins.json`
3. Mata noctalia y lo relanza (`setsid qs -c noctalia-shell >/tmp/noctalia-restart.log 2>&1`)
4. Espera 5 s y comprueba `"Plugin loaded: <plugin-id>"` en los logs
5. Toma screenshot con `niri msg action screenshot-screen` → `~/Imágenes/Screenshots/`

Salida de éxito:
```
==> OK: plugin loaded
==> Screenshot: /home/garra/Imágenes/Screenshots/Screenshot-….png
```

Logs completos: `/tmp/noctalia-restart.log`

## Verificar QML en vivo (sin reiniciar)

`plugins.json` y `settings.json` tienen `watchChanges: true` — noctalia recarga esos archivos en vivo. Pero el **escaneo de plugins solo ocurre al arrancar**: crear un plugin nuevo o editar `BarWidget.qml` siempre requiere reinicio.

```bash
# Reinicio rápido sin driver (si el plugin ya está instalado)
pkill -f "qs -c noctalia-shell"; sleep 1
setsid qs -c noctalia-shell >/tmp/noctalia-restart.log 2>&1 </dev/null &
sleep 5 && grep "Plugin loaded" /tmp/noctalia-restart.log
```

## Screenshot manual

```bash
niri msg action screenshot-screen
ls -t ~/Imágenes/Screenshots/*.png | head -1
```

## Añadir widget a la barra

Editar `~/.config/noctalia/settings.json`, insertar en `bar.widgets.left` o `bar.widgets.right`:

```json
{ "id": "plugin:<plugin-id>" }
```

noctalia normaliza la entrada (añade defaults) la próxima vez que se reinicia.

## Reglas del sistema de plugins (de AGENTS.md oficial)

- Root del `BarWidget.qml`: usar `Item` (para text/pill) o `NIconButton` (para botón-icono).
- Para mostrar texto en la barra: usar `BarPill` de `qs.Modules.Bar.Extras` (icon + text + hover + click).
- Servicios útiles: `qs.Services.Keyboard` (KeyboardLayoutService), `qs.Services.Compositor` (cycleKeyboardLayout), `qs.Services.UI` (PanelService, BarService, Style, Color).
- Logging: `Logger.i/d/w/e` — no `console.log`.
- Strings de usuario: `pluginApi?.tr("key")` con `i18n/en.json`.
- Settings: patrón `cfg → defaults → fallback`: `cfg.foo ?? defaults.foo ?? "fallback"`.
- `manifest.json`: `id` debe coincidir con el nombre del directorio; `metadata.defaultSettings` debe incluir todos los settings que usa el plugin.

## Gotchas

- **El escaneo de plugins es solo al arrancar.** Editar un `.qml` no recarga nada hasta reiniciar noctalia. No hay hot-reload.
- **noctalia reescribe `settings.json` al salir** normalizando entradas (añade props por defecto). El `id` del widget se conserva; los settings del plugin también.
- **`plugins.json` migra a v2 en el primer arranque** (añade `sourceUrl`). Es inofensivo — lo hace el PluginRegistry automáticamente.
- **QML syntax errors silenciosos en logs.** Si el plugin no aparece como "loaded" pero sí como "registered", hay un error de QML en tiempo de instanciación. Buscar `Error` en `/tmp/noctalia-restart.log`.
- **`BarPill` requiere `screen` como `required property`** — no omitirlo aunque el plugin no lo use activamente.
- **`NIconButton` no muestra texto**, solo icono. Para texto en barra usar `BarPill` con `forceOpen: true` o un `Item` + `Rectangle` + `Text` (patrón del plugin oficial `not-just-text`).

## Troubleshooting

| Síntoma | Fix |
|---|---|
| `"An instance of this configuration is already running"` | `pkill -f "qs -c noctalia-shell"` y volver a lanzar |
| Plugin no aparece en barra | Verificar que `{ "id": "plugin:<id>" }` está en `settings.json` y que `plugins.json` tiene `"enabled": true` |
| `Plugin loaded` no aparece en logs | Error de manifest: comprobar que `id` coincide con nombre de carpeta y que `manifest.json` es JSON válido |
| Error de QML en logs | Syntax error en `.qml`; buscar línea `Error` en `/tmp/noctalia-restart.log` |
