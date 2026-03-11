$originalDir = Get-Location

Write-Host "🔧 Настройка Git-хука commitlint" -ForegroundColor Cyan

$installDeps = Read-Host "Установить зависимости commitlint? (y/n, по умолчанию n)"
if ($installDeps -eq 'y') {
    $targetPath = Read-Host "Введите путь к папке для установки (Enter = текущая папка)"

    if ([string]::IsNullOrWhiteSpace($targetPath)) {
        $targetPath = "."
    }

    $targetDir = Resolve-Path -Path $targetPath -ErrorAction SilentlyContinue
    if (-not $targetDir) {
        Write-Host "❌ Папка '$targetPath' не существует. Создать её? (y/n)" -ForegroundColor Yellow
        $create = Read-Host
        if ($create -eq 'y') {
            New-Item -ItemType Directory -Force -Path $targetPath | Out-Null
            $targetDir = Resolve-Path $targetPath
        } else {
            Write-Host "❌ Установка отменена." -ForegroundColor Red
            exit 1
        }
    }

    Set-Location -Path $targetDir
    Write-Host "📦 Устанавливаем commitlint в $(Get-Location)" -ForegroundColor Green

    npm install --save-dev @commitlint/cli @commitlint/config-conventional
    if ($LASTEXITCODE -ne 0) {
        Write-Host "❌ Ошибка при установке пакетов." -ForegroundColor Red
        Set-Location $originalDir
        exit 1
    }

    Set-Content -Path commitlint.config.js -Value "export default { extends: ['@commitlint/config-conventional'] };" -Encoding ASCII
    Write-Host "✅ Конфиг создан." -ForegroundColor Green

    Set-Location $originalDir

} else {
    Write-Host "⏩ Пропускаем установку зависимостей." -ForegroundColor Yellow
}

New-Item -ItemType Directory -Force -Path .git/hooks | Out-Null

@'
#!/bin/sh

GIT_ROOT=$(git rev-parse --show-toplevel)
find_commitlint_dir() {
    for d in "$GIT_ROOT"/*/; do
        if [ -f "${d}node_modules/.bin/commitlint" ]; then
            echo "$d"
            return 0
        fi
    done
    if [ -f "$GIT_ROOT/node_modules/.bin/commitlint" ]; then
        echo "$GIT_ROOT"
        return 0
    fi
    return 1
}

COMMITLINT_DIR=$(find_commitlint_dir)
if [ -z "$COMMITLINT_DIR" ]; then
    echo "ERROR: commitlint is not found in anywhere"
    exit 1
fi

cd "$COMMITLINT_DIR"

npx --no -- commitlint --edit "$GIT_ROOT/.git/COMMIT_EDITMSG"
'@ | Out-File -FilePath .git/hooks/commit-msg -Encoding ASCII

git add -f .git/hooks/commit-msg
git update-index --chmod=+x .git/hooks/commit-msg

Write-Host "✅ Настройка завершена! Хук будет искать commitlint в подпапках (например, app)." -ForegroundColor Green