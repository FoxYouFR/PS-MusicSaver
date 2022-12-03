$userprofile = $env:USERPROFILE
Set-Location C:\Users\admin\Desktop\adb

function transfertBusybox{
    #La recherche est lancée un fois dans le vide afin d'activer ADB. Si cela n'est pas fait, une erreur peut être engendrée!
    .\adb.exe devices -l
    $devices = .\adb.exe devices -l
    #Le String "device product" apparait seulement si il y un device connecté
    if($devices -match "device product"){
        .\adb.exe push C:\Users\admin\Desktop\busybox\busybox /data/local #fonctionne si /data/local existe
    }
}

if(!(Test-Path -Path "$userprofile\Desktop\busybox")){
    mkdir $userprofile\Desktop\busybox
    $source = "benno.id.au/android/busybox"
    $destination = "$userprofile\Desktop\busybox\busybox"
    Write-Host "Téléchargement en cours..."
    Invoke-WebRequest $source -OutFile $destination
    Write-Host "Téléchargement terminé!"
    transfertBusybox
}

#utiliser busybox avec : busybox stat $file