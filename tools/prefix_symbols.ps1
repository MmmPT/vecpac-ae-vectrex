# Prefix local symbols in one assembly source file.
#
# This lets the Jetpac and Killer Queen sources coexist in one assembly
# without symbol collisions. Vectrex BIOS symbols and explicitly excluded
# symbols are left untouched.

param(
    [Parameter(Mandatory=$true)][string]$Path,
    [Parameter(Mandatory=$true)][string]$Out,
    [string]$Prefix = "g_",
    [string]$Exclude = ""
)

$excluded = @{}
foreach ($line in Get-Content "src\vectrex.i") {
    if ($line -match '^([A-Za-z_][A-Za-z0-9_]*)\s+equ\s') {
        $excluded[$Matches[1]] = $true
    }
}
foreach ($name in ($Exclude -split ',')) {
    $name = $name.Trim()
    if ($name -ne '') { $excluded[$name] = $true }
}

$text = [System.IO.File]::ReadAllText((Resolve-Path $Path))
$names = New-Object System.Collections.Generic.HashSet[string]

foreach ($line in Get-Content $Path) {
    if ($line -match '^([A-Za-z_][A-Za-z0-9_]*):') {
        [void]$names.Add($Matches[1])
    }
    elseif ($line -match '^([A-Za-z_][A-Za-z0-9_]*)\s+equ\s') {
        [void]$names.Add($Matches[1])
    }
}

# Longest names first, so a short symbol cannot corrupt a longer one.
$targets = @(
    $names |
    Where-Object { -not $excluded.ContainsKey($_) } |
    Sort-Object { $_.Length } -Descending
)

foreach ($name in $targets) {
    $text = [regex]::Replace(
        $text,
        "\b$([regex]::Escape($name))\b",
        "$Prefix$name"
    )
}

[System.IO.File]::WriteAllText(
    (Join-Path (Get-Location) $Out),
    $text,
    (New-Object System.Text.UTF8Encoding($false))
)

Write-Host ("Prefixed {0} symbols; left {1} shared/excluded symbols unchanged." -f $targets.Count, $excluded.Count)
Write-Host ("Written to {0}" -f $Out)
