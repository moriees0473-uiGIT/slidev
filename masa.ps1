# 保存先フォルダの作成
$dictDir = "public/dict"
if (!(Test-Path $dictDir)) { New-Item -ItemType Directory -Path $dictDir }

# 確実に存在するURLリスト（失敗した3ファイルを含め、正しいパスを網羅）
$files = @(
    "base.dat.gz", "cc.dat.gz", "check.dat.gz", "tid.dat.gz", 
    "unk.dat.gz", "unk_char.dat.gz", "unk_compat.dat.gz", "unk_map.dat.gz",
    "char.dat.gz", "dat.dat.gz", "connection.dat.gz"
)

# jsdelivrの特定のパスから順番にダウンロード
foreach ($file in $files) {
    $url = "https://cdn.jsdelivr.net/npm/kuromoji@0.1.2/dict/$file"
    $outputPath = Join-Path $dictDir $file
    Write-Host "Downloading $file ..." -ForegroundColor Cyan
    try {
        Invoke-WebRequest -Uri $url -OutFile $outputPath -ErrorAction Stop
        Write-Host "Successfully downloaded $file" -ForegroundColor Green
    } catch {
        Write-Host "Failed to download $file. Checking alternative URL..." -ForegroundColor Yellow
        # 失敗した場合の予備URL（GitHub Raw）
        $altUrl = "https://raw.githubusercontent.com/takuyaa/kuromoji.js/master/dict/$file"
        try {
            Invoke-WebRequest -Uri $altUrl -OutFile $outputPath
            Write-Host "Successfully downloaded $file from GitHub" -ForegroundColor Green
        } catch {
            Write-Host "Error: Could not download $file" -ForegroundColor Red
        }
    }
}

# 最終確認
Write-Host "`n--- Final Check ---" -ForegroundColor White
Get-ChildItem $dictDir | Select-Object Name