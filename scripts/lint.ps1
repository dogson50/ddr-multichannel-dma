param(
    [string]$UiFdmaPath = (Join-Path $PSScriptRoot '..\vendor\uiFDMA.v')
)

$ErrorActionPreference = 'Stop'
$repo = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$rtl = Join-Path $repo 'rtl'
$ui = [IO.Path]::GetFullPath($UiFdmaPath)

if (-not (Get-Command iverilog -ErrorAction SilentlyContinue)) {
    throw 'iverilog was not found in PATH.'
}
if (-not (Test-Path -LiteralPath $ui -PathType Leaf)) {
    throw "Missing external uiFDMA implementation: $ui"
}

$files = @(
    (Join-Path $rtl 'dma_stream_packer.v'),
    (Join-Path $rtl 'sfifo.v'),
    (Join-Path $rtl 'WFIFO_VIDEO.v'),
    (Join-Path $rtl 'WFIFOdma_v1.v'),
    (Join-Path $rtl 'RFIFO_VIDEO.v'),
    (Join-Path $rtl 'RFIFOdma_v1.v'),
    $ui,
    (Join-Path $rtl 'DMA4DDR_ctrl_v1.v')
)

& iverilog -g2012 -Wall -tnull -s DMA4DDR_ctrl_v1 @files
if ($LASTEXITCODE -ne 0) { throw "iverilog failed with exit code $LASTEXITCODE" }
Write-Host 'Lint passed.' -ForegroundColor Green
