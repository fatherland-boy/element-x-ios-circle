# Подготовка проекта Element X iOS на Windows для разработки (без сборки)

## Цель

Необходимо подготовить рабочее окружение на **Windows 10/11**, чтобы можно было:

* клонировать Element X iOS;
* открыть проект в VS Code;
* писать код;
* использовать AI-агента;
* делать commit/push;
* автоматически проверять, что проект собирается через GitHub Actions на macOS.

⚠️ **НЕ пытайся собирать приложение локально.**

На Windows это невозможно.

Работа заканчивается после успешного пуша проекта в GitHub.

---

# Этап 1. Установка необходимого ПО

## 1. Git

Проверить:

```bash
git --version
```

Если Git отсутствует:

https://git-scm.com/downloads

---

## 2. VS Code

Установить:

https://code.visualstudio.com/

---

## 3. Расширения VS Code

Установить:

* GitHub Pull Requests
* GitLens
* Swift
* Even Better TOML
* YAML
* EditorConfig

При использовании Claude Code / GLM установить соответствующее расширение.

---

## 4. GitHub CLI

Проверить:

```bash
gh --version
```

Если отсутствует:

https://cli.github.com/

---

## 5. Авторизация

```bash
gh auth login
```

Выбрать:

```
GitHub.com

HTTPS

Login with browser
```

Проверить:

```bash
gh auth status
```

---

# Этап 2. Создание собственного форка

НЕ работать напрямую с репозиторием Element.

Открыть:

https://github.com/element-hq/element-x-ios

Нажать:

```
Fork
```

Получить:

```
https://github.com/<USERNAME>/element-x-ios
```

---

# Этап 3. Клонирование

Создать рабочую папку.

Например

```
D:\Projects
```

или

```
C:\Projects
```

Выполнить:

```bash
cd D:\Projects

git clone https://github.com/<USERNAME>/element-x-ios.git

cd element-x-ios
```

---

# Этап 4. Проверка git

Проверить:

```bash
git remote -v
```

Должно быть примерно:

```
origin
https://github.com/<USERNAME>/element-x-ios.git
```

Добавить оригинальный репозиторий:

```bash
git remote add upstream https://github.com/element-hq/element-x-ios.git
```

Проверить:

```bash
git remote -v
```

Должно быть:

```
origin
upstream
```

---

# Этап 5. Создание рабочей ветки

Никогда не работать в main.

Создать:

```bash
git checkout -b feature/video-notes
```

---

# Этап 6. Открытие проекта

Открыть папку:

```
element-x-ios
```

в VS Code.

НЕ открывать отдельные файлы.

---

# Этап 7. Изучение структуры

AI должен изучить структуру проекта.

Не изменять код.

Найти:

```
Sources

Modules

Room

Composer

Timeline

Media

Services
```

Понять:

* где располагается Composer;
* где отправляются сообщения;
* где отображаются видеосообщения;
* где находится Media Upload;
* где находится Timeline;
* где находятся SwiftUI View.

---

# Этап 8. Создание рабочей документации

Создать папку

```
docs
```

Создать файл

```
docs/video-note-research.md
```

Описать:

* найденные классы;
* найденные View;
* цепочку отправки сообщений;
* цепочку отображения сообщений;
* архитектуру.

Без изменения проекта.

---

# Этап 9. Анализ проекта

AI должен найти:

* MediaPicker
* ComposerToolbar
* MessageComposer
* Timeline
* TimelineItem
* VideoMessage
* UploadService
* RoomProxy
* ClientProxy

Если каких-либо классов нет,
найти современные аналоги.

Нельзя придумывать.

---

# Этап 10. Создание архитектуры новой функции

Создать документ

```
docs/video-note-design.md
```

Описать:

```
VideoNoteRecorder

↓

VideoProcessor

↓

ThumbnailGenerator

↓

VideoUploader

↓

Timeline Renderer
```

Также описать:

* точки интеграции;
* зависимости;
* новые Swift файлы.

Не писать код.

---

# Этап 11. Подготовка GitHub Actions

Создать папку

```
.github/workflows
```

Создать файл

```
ios-build.yml
```

Использовать официальный macOS runner GitHub Actions.

Workflow должен:

* запускаться при push;
* запускаться при pull_request;
* устанавливать зависимости проекта;
* выполнять проверку сборки через xcodebuild;
* не публиковать IPA;
* не выполнять подпись приложения;
* завершаться ошибкой при любой ошибке компиляции.

Использовать только официальные GitHub Actions и актуальные версии.

---

# Этап 12. Проверка структуры

Проверить наличие:

```
docs/

.github/

.github/workflows/

ios-build.yml
```

---

# Этап 13. Первый commit

```bash
git add .

git commit -m "Initial project setup"
```

---

# Этап 14. Первый push

```bash
git push origin feature/video-notes
```

---

# Этап 15. Проверка GitHub Actions

После push:

Открыть GitHub.

Перейти:

```
Actions
```

Убедиться:

* Workflow появился.
* macOS Runner стартовал.
* Выполняется подготовка проекта.
* Началась проверка сборки.

Если workflow завершился ошибкой, необходимо исправить workflow, а не менять исходный код проекта.

---

# Что запрещено делать

До следующего этапа категорически запрещается:

* изменять Swift код проекта;
* изменять архитектуру;
* менять существующие View;
* менять Matrix SDK;
* менять Rust SDK;
* менять сетевой слой;
* менять API;
* добавлять FFmpeg;
* добавлять сторонние библиотеки;
* создавать новые функции.

Сейчас задача исключительно подготовительная.

---

# Ожидаемый результат

После выполнения инструкции должно быть получено:

* собственный форк проекта;
* локальный git-репозиторий;
* рабочая ветка `feature/video-notes`;
* проект открыт в VS Code;
* создана документация по архитектуре;
* настроен GitHub Actions с macOS Runner для проверки сборки;
* изменения закоммичены и отправлены в GitHub.

На этом этапе работа считается завершённой. Следующий этап — реализация функциональности видеосообщений ("кружочков"), но он **не входит** в данную инструкцию.
