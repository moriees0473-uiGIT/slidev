$dictDir = "public/dict"
if (!(Test-Path $dictDir)) { New-Item -ItemType Directory -Path $dictDir }

# 特に失敗しやすい3ファイルに集中攻撃
$stubbornFiles = @("char.dat.gz", "dat.dat.gz", "connection.dat.gz")

foreach ($file in $stubbornFiles) {
    $outputPath = Join-Path $dictDir $file
    # ソース1: GitHubの別ブランチ（確実に存在する場所）
    $url = "https://raw.githubusercontent.com/takuyaa/kuromoji.js/master/dict/$file"
    
    Write-Host "Trying to get $file ..." -ForegroundColor Cyan
    try {
        Invoke-WebRequest -Uri $url -OutFile $outputPath -ErrorAction Stop
        Write-Host "Successfully downloaded $file" -ForegroundColor Green
    } catch {
        Write-Host "Still failing $file. Trying uncompressed source..." -ForegroundColor Yellow
        # ソース2: 非圧縮版を落としてリネームする最終手段
        $noGzFile = $file.Replace(".gz", "")
        $altUrl = "https://raw.githubusercontent.com/takuyaa/kuromoji.js/master/dict/$noGzFile"
        try {
            Invoke-WebRequest -Uri $altUrl -OutFile $outputPath
            Write-Host "Success! Got $noGzFile and saved as $file" -ForegroundColor Green
        } catch {
            Write-Host "Critical Error: Could not find $file anywhere." -ForegroundColor Red
        }
    }
}

# 全体の確認
Write-Host "`n--- Current dict folder status ---" -ForegroundColor White
Get-ChildItem $dictDir | Select-Object Name