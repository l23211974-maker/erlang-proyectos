$f = '_build/default/lib/prometheus/src/prometheus_misc.erl'
if (Test-Path $f) {
    $c = Get-Content $f -Raw
    if ($c -notmatch 'nowarn_deprecated_catch') {
        # Try the atom form: nowarn_deprecated_catch
        $c = $c -replace '-module\(prometheus_misc\)\.', "-module(prometheus_misc).`r`n`r`n-compile(nowarn_deprecated_catch)."
        [IO.File]::WriteAllText($f, $c, (New-Object System.Text.UTF8Encoding($false)))
        Write-Host "Patched $f with atom form"
    } else {
        Write-Host "Already patched"
    }
} else {
    Write-Host "File not found: $f"
}