#Fonction pour trouver et transférer les vidéos
function transfertVideos{
    if(!(Test-Path -Path "$userprofile\Desktop\médias")){
        mkdir $userprofile\Desktop\médias
    }
    if(!(Test-Path -Path "$userprofile\Desktop\médias\vidéos")){
        mkdir $userprofile\Desktop\médias\vidéos
    }
    findMaxSize
    foreach ($file in .\adb.exe shell find | Where-Object {$_ -match "\.mp4" -or $_ -match "\.3gp" -or $_ -match "\.webm" -or $_ -match "\.ts"})
    {
        [string]$infoFichier = .\adb.exe shell "busybox stat -t $file"
        $infoTaille = $infoFichier.Substring($file.length).Split(' ')[1]
        #if($Global:maxSize -ne 0){
            #if([int]$infoTaille -lt $Global:maxSize){
                Write-Host $file
                write-host $infoFichier
                write-host $Global:maxSize
                #.\adb.exe pull $file $userprofile\Desktop\médias\vidéos
            #}
        #}else{
         #   .\adb.exe pull $file $userprofile\Desktop\médias\vidéos
        #}

    }
}
transfertVideos