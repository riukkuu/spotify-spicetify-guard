# Spotify Spicetify Guard

[English version](README.md)

Небольшой портативный набор, который сохраняет **обычный Spotify** с
**Spicetify + Marketplace + `adblockify`** после обновлений Spotify.

Рекламу блокирует расширение Marketplace **`adblockify`**.
Проект **не использует BlockTheSpot** и не патчит загрузчик Spotify.

## Возможности

- Обновления Spotify остаются **включёнными**.
- Не нужны права администратора, планировщик заданий, WMI-триггеры,
  правка реестра, фоновый watcher и опрос процессов.
- Восстановление запускается **только при старте Spotify**, после чего
  заглушка передаёт управление настоящему клиенту и выходит.
- Уже установленный Spicetify сохраняется и никогда не перезаписывается.
- Если Spicetify отсутствует — он ставится из portable-копии в архиве.
- Ярлыки на рабочем столе и в автозагрузке просто запускают ту же разовую
  проверку.

## Требования

- Windows x64.
- **Обычный Spotify с сайта** https://www.spotify.com/download/windows/
  (`%APPDATA%\Spotify\Spotify.exe`).
- **Версия из Microsoft Store не поддерживается**
  (`C:\Program Files\WindowsApps\SpotifyAB...`).
- Перед установкой запусти Spotify один раз, чтобы появилась папка
  `%APPDATA%\Spotify`.
- Права администратора не нужны.

## Установка

1. Установи обычный Spotify с официального сайта и запусти его один раз.
2. Скачай ZIP со страницы **Releases** и распакуй куда удобно.
3. Запусти **`Install.cmd`** двойным кликом.
   Не используй ПКМ → «Запустить с помощью PowerShell»: политика выполнения
   PowerShell по умолчанию блокирует скрипты. `Install.cmd` сам передаёт
   `-ExecutionPolicy Bypass`.
4. Дождись окна `Done. Just start Spotify normally.` и нажми **OK**.
5. Запускай Spotify как обычно.

Папку распаковки можно удалить. ZIP оставь на случай переустановки.

## Как это работает

| Файл | Роль |
|---|---|
| `Spotify.exe` | Небольшая C#-заглушка: выполняет проверку, затем запускает настоящий клиент. |
| `Spotify-real.exe` | Оригинальный подписанный `Spotify.exe`, переименованный установщиком. |
| `Spotify-real.dll` | Жёсткая ссылка на `Spotify.dll`, чтобы переименованный клиент загружался. |
| `%LOCALAPPDATA%\SpotifyAdBlock\` | Рабочие скрипты, portable Spicetify, снимок профиля и логи. |
| `repair.ps1` / `watch.ps1` | Разовое восстановление: заглушка, hardlink, Spicetify, тема, расширения и состояние Marketplace. |
| `spicetify backup apply` | Повторно применяет тему и расширения, если обновление сняло патч. |

При обычном запуске, когда ничего не изменилось, проверка ничего не делает:
патч не накладывается, новые строки в лог не пишутся.

## Ограничения

- Marketplace загружает `adblockify` с `cdn.jsdelivr.net` / `cdn.jsdelivr.xyz`
  при старте клиента. Без интернета или при заблокированном CDN реклама может
  не блокироваться. `assets/adblockify.js` в репозитории — контрольная копия
  того же скрипта; сборка намеренно использует доставку через Marketplace,
  чтобы adblockify обновлялся без пересборки пакета.
- Если обновление Spotify перезаписало `Spotify.exe` оригинальным клиентом
  до того, как сработал лаунчер, этот один запуск будет без патча. Лаунчер
  восстановится при следующем входе в Windows (ярлык в автозагрузке), через
  ярлык проверки на рабочем столе либо повторным запуском `Install.cmd`.
- Spicetify CLI в комплекте зафиксирован на версии 2.46.7. Будущее обновление
  Spotify, изменившее структуру `xpui`, может потребовать новую версию CLI.

## Проверка

- В Spotify: **Marketplace → Extensions → adblockify** должен быть установлен.
- `%APPDATA%\Spotify\Apps\xpui\spicetify-config.json` должен существовать с
  `theme_name = marketplace`.
- Логи:
  - `%LOCALAPPDATA%\SpotifyAdBlock\install-progress.log`
  - `%LOCALAPPDATA%\SpotifyAdBlock\watch.log`

## Удаление

Запусти `Uninstall.cmd` двойным кликом из распакованной папки либо выполни:

```powershell
powershell -ExecutionPolicy Bypass -File "%LOCALAPPDATA%\SpotifyAdBlock\uninstall.ps1"
```

Это вернёт оригинальный `Spotify.exe`, уберёт заглушку и ярлыки.
Spicetify, тема и расширения **не удаляются**.

## Сборка

В репозитории лежат только скрипты и небольшие ресурсы. Готовый ZIP
публикуется как GitHub Release. Чтобы собрать его локально, нужна папка
portable Spicetify CLI (для опубликованной сборки использовалась версия
2.46.7):

```powershell
.\build.ps1 -CliPath 'C:\path\to\spicetify-cli'
```

Скрипт компилирует `src/launcher.cs` через C#-компилятор .NET Framework и
создаёт `dist\Spotify-AdBlock-Portable.zip`, где все файлы лежат в корне
архива.

## Лицензия

Проект распространяется по лицензии **GNU General Public License v3.0 или
более поздней версии**. См. [LICENSE](LICENSE) и [COPYRIGHT](COPYRIGHT).

Сторонние компоненты сохраняют свои лицензии:
[THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md).

## Юридическое и благодарности

Модификация клиента может нарушать условия использования Spotify.
Используй на свой страх и риск. Проект не связан со Spotify AB и не
поддерживается ею.
