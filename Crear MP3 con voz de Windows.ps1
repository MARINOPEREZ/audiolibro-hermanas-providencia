param([string]$Archivo)
$ErrorActionPreference = 'Stop'
if (-not $Archivo -or -not (Test-Path $Archivo)) {
  Write-Host "USO: arrastra un archivo .txt sobre 'Crear MP3 con voz de Windows.bat'"
  Write-Host " - Un libro completo (.txt)  -> crea el MP3 del libro"
  Write-Host " - Un guion PPT (con marcas '### DIAPOSITIVA N ###') -> crea un MP3 por diapositiva"
  pause; exit
}
Add-Type -AssemblyName System.Speech
$s = New-Object System.Speech.Synthesis.SpeechSynthesizer
$voces = $s.GetInstalledVoices() | ForEach-Object { $_.VoiceInfo } | Where-Object { $_.Culture.Name -like 'es*' }
if ($voces) {
  $s.SelectVoice(($voces | Select-Object -First 1).Name)
} else {
  Write-Host "No hay voces de escritorio en espanol. Voces disponibles:"
  $s.GetInstalledVoices() | ForEach-Object { Write-Host (' - ' + $_.VoiceInfo.Name) }
  Write-Host "Instala espanol en: Configuracion > Hora e idioma > Voz"
  pause; exit
}
Write-Host ("Voz seleccionada: " + $s.Voice.Name)
$log = Join-Path (Split-Path $Archivo -Parent) 'registro voz.txt'
Add-Content -Path $log -Value ((Get-Date -Format 'yyyy-MM-dd HH:mm') + ' | voz: ' + $s.Voice.Name + ' | entrada: ' + $Archivo)
$s.Rate = 0

Add-Type -AssemblyName System.Runtime.WindowsRuntime
$null = [Windows.Media.Transcoding.MediaTranscoder,Windows.Media,ContentType=WindowsRuntime]
$null = [Windows.Media.MediaProperties.MediaEncodingProfile,Windows.Media,ContentType=WindowsRuntime]
$null = [Windows.Storage.StorageFile,Windows.Storage,ContentType=WindowsRuntime]
function Await($op, $tipo) {
  $asTask = ([System.WindowsRuntimeSystemExtensions].GetMethods() | Where-Object { $_.Name -eq 'AsTask' -and $_.GetParameters().Count -eq 1 -and $_.GetParameters()[0].ParameterType.Name -eq 'IAsyncOperation`1' })[0]
  $t = $asTask.MakeGenericMethod($tipo).Invoke($null, @($op))
  $t.Wait() | Out-Null
  $t.Result
}
function AwaitAccion($ac) {
  $asTask = ([System.WindowsRuntimeSystemExtensions].GetMethods() | Where-Object { $_.Name -eq 'AsTask' -and $_.GetParameters().Count -eq 1 -and $_.GetParameters()[0].ParameterType.Name -eq 'IAsyncActionWithProgress`1' })[0]
  $t = $asTask.MakeGenericMethod([double]).Invoke($null, @($ac))
  $t.Wait() | Out-Null
}
function ConvertirMp3([string]$wav, [string]$mp3) {
  $src = Await ([Windows.Storage.StorageFile]::GetFileFromPathAsync($wav)) ([Windows.Storage.StorageFile])
  $carpeta = Await ([Windows.Storage.StorageFolder]::GetFolderFromPathAsync((Split-Path $mp3 -Parent))) ([Windows.Storage.StorageFolder])
  $dst = Await ($carpeta.CreateFileAsync((Split-Path $mp3 -Leaf), [Windows.Storage.CreationCollisionOption]::ReplaceExisting)) ([Windows.Storage.StorageFile])
  $perfil = [Windows.Media.MediaProperties.MediaEncodingProfile]::CreateMp3([Windows.Media.MediaProperties.AudioEncodingQuality]::Medium)
  $tc = New-Object Windows.Media.Transcoding.MediaTranscoder
  $prep = Await ($tc.PrepareFileTranscodeAsync($src, $dst, $perfil)) ([Windows.Media.Transcoding.PrepareTranscodeResult])
  if (-not $prep.CanTranscode) { throw "transcodificador no disponible" }
  AwaitAccion ($prep.TranscodeAsync())
  Remove-Item $wav -Force
}

$texto = [IO.File]::ReadAllText($Archivo, [Text.Encoding]::UTF8)
$dir = Split-Path $Archivo -Parent
$libro = Split-Path $dir -Leaf
if ($libro -eq 'LIBROS') { $libro = [IO.Path]::GetFileNameWithoutExtension($Archivo) }

if ($texto -match '### DIAPOSITIVA') {
  # ===== MODO GUION PPT: un MP3 por diapositiva =====
  $outDir = Join-Path $dir 'audios PPT'
  if (-not (Test-Path $outDir)) { New-Item -ItemType Directory -Path $outDir | Out-Null }
  $partes = [regex]::Split($texto, '###\s*DIAPOSITIVA\s+\d+\s*###') | Where-Object { $_.Trim().Length -gt 0 }
  $n = 0
  foreach ($parte in $partes) {
    $n++
    $num = '{0:d2}' -f $n
    Write-Host ("[" + $n + "/" + $partes.Count + "] Diapositiva " + $n + " ...")
    $wav = Join-Path $outDir ("dia_" + $num + ".wav")
    $mp3 = Join-Path $outDir ("dia_" + $num + ".mp3")
    $s.SetOutputToWaveFile($wav)
    $t = $parte.Trim()
    if ($t -eq '(pagina sin texto)' -or $t.Length -lt 2) { $t = 'pagina ' + $n }
    $s.Speak($t)
    $s.SetOutputToNull()
    try { ConvertirMp3 $wav $mp3 } catch { Write-Host ("  (quedo como WAV: " + $_.Exception.Message + ")") }
  }
  $s.Dispose()
  Write-Host ""
  Write-Host ("LISTO: " + $partes.Count + " audios en la carpeta '" + $outDir + "'")
  Write-Host "En la pestana 'Imagenes -> PPT' del Audiolibro, carga esos audios y genera el PPT."
} else {
  # ===== MODO LIBRO: un MP3 con el nombre de la carpeta =====
  $wav = Join-Path $dir ($libro + '.wav')
  $mp3 = Join-Path $dir ($libro + '.mp3')
  Write-Host "[1/2] Sintetizando el libro ..."
  $s.SetOutputToWaveFile($wav)
  $s.Speak($texto)
  $s.SetOutputToDefaultAudioDevice()
  $s.Dispose()
  Write-Host "[2/2] Convirtiendo a MP3 ..."
  try {
    ConvertirMp3 $wav $mp3
    Write-Host ""
    Add-Content -Path $log -Value ('   -> MP3 creado: ' + $mp3)
    Write-Host ("LISTO: " + $mp3)
    Write-Host "El boton 'Descargar MP3' del Audiolibro entregara este archivo para este libro."
  } catch {
    Write-Host ("No pude convertir a MP3 aqui (" + $_.Exception.Message + ").")
    Add-Content -Path $log -Value ('   -> FALLO transcodificacion, quedo WAV: ' + $wav)
    Write-Host ("El audio quedo como WAV: " + $wav)
    Write-Host "Arrastra ese WAV sobre la ventana del Audiolibro y se convertira a MP3 automaticamente."
  }
}
pause
