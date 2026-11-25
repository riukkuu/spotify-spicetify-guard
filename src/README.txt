Spotify Spicetify Guard (portable)
=================================

Что это
-------
Не ставит BlockTheSpot. Рекламу блокирует расширение adblockify из
Spicetify Marketplace (то, что было включено у вас в Marketplace).

Маленькая заглушка вместо Spotify.exe при каждом запуске Spotify:
1) проверяет/восстанавливает саму заглушку;
2) если Spicetify уже стоит — сохраняет и восстанавливает его тему,
   Extensions, CustomApps и Marketplace-расширения;
3) если Spicetify не стоит — ставит его из архива и дальше тоже сохраняет;
4) накладывает тему/расширения заново (`spicetify backup apply`);
5) запускает настоящий Spotify и выходит.

Фонового процесса между запусками нет. Обновления Spotify остаются включены.

Требования
----------
- Windows x64, standalone Spotify (не Microsoft Store).
- Права администратора НЕ нужны.
- Интернет нужен только для того, чтобы Marketplace подгрузил JS adblockify
  с GitHub (как сейчас). Сам Spicetify и все файлы уже лежат в архиве.

Установка
---------
1. Сначала обычным образом установить Spotify с официального сайта.
   НЕ Microsoft Store! Если Spotify скачан из Store — удали его и поставь
   десктопную версию с https://www.spotify.com/download/windows/
   Как понять, что у тебя Store-версия: в диспетчере задач ПКМ по Spotify ->
   "Открыть расположение файла". Если путь начинается с
   C:\Program Files\WindowsApps\SpotifyAB... — это Store, удали её.
   Для обычной версии путь будет C:\Users\<твое_имя>\AppData\Roaming\Spotify
2. ОБЯЗАТЕЛЬНО запустить Spotify один раз после установки, чтобы создалась
   папка %APPDATA%\Spotify. Можно просто открыть окно входа и закрыть его.
3. Распаковать архив в любую папку.
4. Двойным кликом запустить Install.cmd.
   Это важно: обычный ПКМ -> "Запустить с помощью PowerShell" не работает,
   потому что политика выполнения PowerShell по умолчанию запрещает скрипты.
   Install.cmd сам запускает install.ps1 с нужным параметром и оставляет окно
   открытым, чтобы было видно результат.
5. Дождаться появившегося окна "Done. Just start Spotify normally" и
   нажать в нём OK, потом запустить Spotify как обычно.

Если окно закрылось раньше надписи "Done. Just start Spotify normally" —
открой файл:
  %LOCALAPPDATA%\SpotifyAdBlock\install-progress.log
Там по шагам записано, что именно выполнил installer. Если в конце есть
"Done" и файл install-complete.txt — установка завершилась полностью,
даже если консоль закрылась раньше.

Что проверять
-------------
В Spotify: Marketplace -> Расширения -> adblockify должен быть "Установлено".
Файл лога: %LOCALAPPDATA%\SpotifyAdBlock\watch.log
В `%APPDATA%\Spotify\Apps\xpui\spicetify-config.json` должно быть theme_name = marketplace.

Ярлыки
------
- Автозагрузка: "Spotify Spicetify Guard (Logon)" — разовая проверка при входе.
- Рабочий стол: "Spotify Spicetify Guard" — ручная починка.

Удаление
--------
Папку с распакованным архивом можно удалить после завершения. Если Windows
пишет, что папка «используется программой» — нажми любую клавишу в окне
Install.cmd/Uninstall.cmd, чтобы закрыть его. CMD и PowerShell перед паузой
переходят в %TEMP%, поэтому папка архива больше не блокируется.

Двойной клик по Uninstall.cmd из распакованной папки, либо команда:

  powershell -ExecutionPolicy Bypass -File "%LOCALAPPDATA%\SpotifyAdBlock\uninstall.ps1"

Возвращает оригинальный Spotify.exe, убирает заглушку и ярлыки.
Spicetify, тема и расширения НЕ удаляются.

Оговорки
--------
- Процесс в Dispatcher/Task Manager может называться Spotify-real.exe — нормально.
- Модификация клиента может нарушать условия использования Spotify.
