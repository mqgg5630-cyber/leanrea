#Requires -Version 5.1
<#
.SYNOPSIS
    Can this host run a local model (no API key) for real-time chat analysis?
    Read-only. ASCII only.
#>
$ErrorActionPreference = 'Continue'
$ProgressPreference    = 'SilentlyContinue'

function Line([string]$k, [string]$v) { Write-Output ('{0}={1}' -f $k, $v) }

Line 'COMPUTER' $env:COMPUTERNAME
$cs = Get-CimInstance Win32_ComputerSystem
$cpu = Get-CimInstance Win32_Processor | Select-Object -First 1
Line 'CPU' ($cpu.Name.Trim() + ' cores=' + $cpu.NumberOfCores + ' threads=' + $cpu.NumberOfLogicalProcessors)
Line 'RAM_GB' ([math]::Round($cs.TotalPhysicalMemory / 1GB, 1))

# ---- GPUs -------------------------------------------------------------------
try {
    $gpus = Get-CimInstance Win32_VideoController | ForEach-Object {
        '{0} :: {1} MB driver {2}' -f $_.Name, [int]($_.AdapterRAM / 1MB), $_.DriverVersion
    }
    Line 'GPU' (($gpus -join ' || ') -replace '^$', 'none')
} catch { Line 'GPU' 'unknown' }

$nv = Get-Command nvidia-smi.exe -ErrorAction SilentlyContinue
if (-not $nv -and (Test-Path 'C:\Windows\System32\nvidia-smi.exe')) { $nv = 'C:\Windows\System32\nvidia-smi.exe' }
if ($nv) {
    $q = & $nv --query-gpu=name,memory.total,driver_version --format=csv,noheader 2>&1
    Line 'NVIDIA' (($q -join ' || ') -replace '\s+', ' ')
} else {
    Line 'NVIDIA' 'no nvidia-smi'
}

# ---- existing local model runtimes ------------------------------------------
foreach ($cmd in @('ollama.exe', 'llama-server.exe', 'lm-studio.exe', 'python.exe')) {
    $c = Get-Command $cmd -ErrorAction SilentlyContinue
    if ($c) { Line ('CMD ' + $cmd) $c.Source }
}
$ollamaDirs = @("$env:LOCALAPPDATA\Programs\Ollama", "$env:LOCALAPPDATA\Ollama", 'C:\Program Files\Ollama', 'E:\Ollama', 'D:\Ollama')
foreach ($d in $ollamaDirs) { if (Test-Path -LiteralPath $d) { Line ('DIR ' + $d) 'yes' } }
if (Test-Path -LiteralPath "$env:USERPROFILE\.ollama\models") {
    Line 'OLLAMA_MODELS' ((Get-ChildItem "$env:USERPROFILE\.ollama\models\manifests" -Recurse -File -ErrorAction SilentlyContinue |
        ForEach-Object { $_.FullName.Replace("$env:USERPROFILE\.ollama\models\manifests\", '') }) -join ', ')
} else { Line 'OLLAMA_MODELS' 'missing' }

try {
    $r = Invoke-WebRequest -Uri 'http://127.0.0.1:11434/api/tags' -UseBasicParsing -TimeoutSec 4
    Line 'OLLAMA_RUNNING' ('yes ' + $r.Content.Substring(0, [Math]::Min(200, $r.Content.Length)))
} catch { Line 'OLLAMA_RUNNING' 'no' }

# ---- what the chat stack already has ---------------------------------------
$VPy = 'E:\0apps\jev-chat-windows\venv\Scripts\python.exe'
if (Test-Path -LiteralPath $VPy) {
    $m = & $VPy -c "import importlib;print(','.join(m for m in ['httpx','requests','openai','numpy'] if importlib.util.find_spec(m)))" 2>&1
    Line 'VENV_MODULES' ($m -join ' ')
}
Line 'FREE_C_GB' ([math]::Round((Get-PSDrive C).Free / 1GB, 1))
Line 'FREE_D_GB' ([math]::Round((Get-PSDrive D).Free / 1GB, 1))
Line 'FREE_E_GB' ([math]::Round((Get-PSDrive E).Free / 1GB, 1))
Line 'PROBE_LLM_DONE' 'True'
