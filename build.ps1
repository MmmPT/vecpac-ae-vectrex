# Build the complete VECPAC A.E. cartridge image.
#
# Requirements:
#   tools\asm6809-2.17-w64\asm6809.exe
#
# Optional for -Play:
#   tools\mame\mame.exe
#   roms\vectrex.zip
#
# Usage:
#   .\build.ps1
#   .\build.ps1 -Play
#
# The Vectrex BIOS and MAME are not distributed with this repository.

param([switch]$Play)

$ErrorActionPreference = 'Stop'
$root = $PSScriptRoot
$build = Join-Path $root 'build'
$asm = Join-Path $root 'tools\asm6809-2.17-w64\asm6809.exe'
$mame = Join-Path $root 'tools\mame\mame.exe'
$roms = Join-Path $root 'roms'

if (-not (Test-Path $asm)) {
    throw "asm6809 was not found at: $asm"
}

New-Item -ItemType Directory -Force -Path $build | Out-Null

# 1. Prefix Killer Queen local symbols.
& (Join-Path $root 'tools\prefix_symbols.ps1') `
    -Path 'src\gx.asm' `
    -Out 'build\gx_pref.asm' `
    -Prefix 'g_' `
    -Exclude 'CART,gx_enter' | Out-Null

# 2. Remove include/org/end directives, each game's CART equ 0,
#    and the standalone cartridge headers.
function Get-Body($file) {
    $lines = [System.IO.File]::ReadAllLines((Resolve-Path $file))
    $out = New-Object System.Collections.ArrayList
    $inHeader = $false

    foreach ($line in $lines) {
        if ($line -match '^\s+include\s') { continue }
        if ($line -match '^\s+org\s') { continue }
        if ($line -match '^\s+end\s') { continue }
        if ($line -match '^CART\s+equ\s') { continue }

        if ($line -match '^\s+fcc\s+"g GCE') {
            $inHeader = $true
            continue
        }
        if ($inHeader) {
            if ($line -match '^\s+fcb\s+\$00\s*$') {
                $inHeader = $false
            }
            continue
        }

        [void]$out.Add($line)
    }
    return $out
}

$jp = Get-Body 'src\jetpac.asm'
$gx = Get-Body 'build\gx_pref.asm'

$jp = $jp | ForEach-Object { $_ -replace '^main:', 'jp_main:' }
$gx = $gx | ForEach-Object { $_ -replace '^g_main:', 'gx_main:' }

# Jetpac clears its standalone high-score table at startup.
# In the combined cartridge the supervisor owns the table, so remove
# that exact initialization block.
$jpText = ($jp -join "`r`n")
$pattern = "(?m)^\s+ldx\s+#hi_table[^\r\n]*\r?\n\s+ldb\s+#HI_COUNT\*3[^\r\n]*\r?\n^mi_hi:[^\r\n]*\r?\n\s+clr\s+,x\+[^\r\n]*\r?\n\s+decb[^\r\n]*\r?\n\s+bne\s+mi_hi[^\r\n]*"
if ($jpText -match $pattern) {
    $jpText = [regex]::Replace($jpText, $pattern, "")
}
else {
    throw "Could not locate the Jetpac standalone high-score initialization block."
}
$jp = $jpText -split "`r`n"

# 3. Generate src\cart.asm.
$supervisor = [System.IO.File]::ReadAllLines((Resolve-Path 'src\supervisor.asm'))
$all = New-Object System.Collections.ArrayList

foreach ($line in $supervisor) { [void]$all.Add($line) }
[void]$all.Add("")
[void]$all.Add("; =====================================================================")
[void]$all.Add("; JETPAC")
[void]$all.Add("; =====================================================================")
foreach ($line in $jp) { [void]$all.Add($line) }
[void]$all.Add("")
[void]$all.Add("; =====================================================================")
[void]$all.Add("; KILLER QUEEN")
[void]$all.Add("; =====================================================================")
foreach ($line in $gx) { [void]$all.Add($line) }
[void]$all.Add("")
[void]$all.Add("        end     main")

$cart = Join-Path $root 'src\cart.asm'
[System.IO.File]::WriteAllLines(
    $cart,
    $all,
    (New-Object System.Text.UTF8Encoding($false))
)

# 4. Assemble.
Push-Location (Join-Path $root 'src')
try {
    & $asm -B `
        -o (Join-Path $build 'VecpacAE.vec') `
        -l (Join-Path $build 'VecpacAE.lst') `
        'cart.asm'
    if ($LASTEXITCODE -ne 0) {
        throw "asm6809 failed with exit code $LASTEXITCODE"
    }
}
finally {
    Pop-Location
}

$size = (Get-Item (Join-Path $build 'VecpacAE.vec')).Length
Write-Host ("VecpacAE.vec: {0} bytes ({1:P1} of a 32K cartridge)" -f $size, ($size / 32768))

if ($Play) {
    if (-not (Test-Path $mame)) { throw "MAME was not found at: $mame" }
    if (-not (Test-Path (Join-Path $roms 'vectrex.zip'))) {
        throw "Vectrex BIOS archive was not found at: $(Join-Path $roms 'vectrex.zip')"
    }

    & $mame vectrex `
        -rompath $roms `
        -cart (Join-Path $build 'VecpacAE.vec') `
        -skip_gameinfo `
        -window `
        -nomaximize `
        -resolution 512x640
}
