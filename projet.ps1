# ---------------------------------------------------------------
# COMMANDE: saveYourDatas.ps1
# VERSION : 0.6
# AUTEUR  : Kolly Florian
# CREATION: 13.09.2016
# ARGUMENT: 
# MODIF.  :
# -
# - 
# Ce script permet de faire une sauvegarde des fichiers souhaités d'un téléphone sur un ordinateur
# ---------------------------------------------------------------

$nomScript = "Backup phone"
$userprofile = $env:USERPROFILE
$Global:maxSize
$trackBar = New-Object System.Windows.Forms.TrackBar

#installation automatique d'ADB
function installationADB{
    if(!(Test-Path -Path "$userprofile\Desktop\adb")){
        mkdir $userprofile\Desktop\adb
        $source = "http://adbshell.com/upload/adb.zip"
        $destination = "$userprofile\Desktop\adb\adb.zip"
        Write-Host "Téléchargement d'ADB en cours..."
        Invoke-WebRequest $source -OutFile $destination
        Write-Host "Téléchargement d'ADB terminé!"
        Write-Host "Installation d'ADB en cours..."
        $shell = new-object -com shell.application
        $zip = $shell.NameSpace(“$userprofile\Desktop\adb\adb.zip”)
        foreach($item in $zip.items())
        {
            $shell.Namespace(“$userprofile\Desktop\adb”).copyhere($item)
        }
    Write-Host "Installation d'ADB terminée!"
    Remove-Item $userprofile\Desktop\adb\adb.zip
    }
}

function transfertBusybox{
    #La recherche est lancée un fois dans le vide afin d'activer ADB. Si cela n'est pas fait, une erreur peut être engendrée!
    .\adb.exe devices -l
    $devices = .\adb.exe devices -l
    #Le String "device product" apparait seulement si il y un device connecté
    if($devices -match "device product"){
        .\adb.exe push C:\Users\admin\Desktop\busybox\busybox /data/local #fonctionne si /data/local existe
    }
}

function installationBusyBox{
    if(!(Test-Path -Path "$userprofile\Desktop\busybox")){
        mkdir $userprofile\Desktop\busybox
        $source = "benno.id.au/android/busybox"
        $destination = "$userprofile\Desktop\busybox\busybox"
        Write-Host "Téléchargement de busyBox en cours..."
        Invoke-WebRequest $source -OutFile $destination
        Write-Host "Téléchargement busyBox terminé!"
        transfertBusybox
    }
}

#Initialisation du programme
function chargementADB{
    #installation d'ADB
    installationADB

    #Chargement d'ADB
    $cheminPC = "$userprofile\Desktop\adb"
    Set-Location $cheminPC

    #Installation busyBox
    #installationBusyBox
}

#fonction pour trouver la taille max des fichiers à transférer (Bytes)
function findMaxSize{
    switch ($trackBar.Value){
        1 { $Global:maxSize = 1048576; break }
        2 { $Global:maxSize = 5242880; break }
        3 { $Global:maxSize = 10485760; break }
        4 { $Global:maxSize = 20971520; break }
        5 { $Global:maxSize = 0; break }
    }
}

#Fonction pour supprimer une tâche planifiée
function supprimerTachePlanifiee{
    Unregister-ScheduledTask -TaskName $nomScript -Confirm:$false
}

#Fonction pour gérer les processus
function gestionProcessus{
    Get-Process | where {$_.Name -eq "adb"} | Stop-Process
    foreach($processus in Get-Process | where {$_.Name -eq "powershell" -and $_.Id -ne $PID}){
        Stop-Process $processus
    }
}

#Fonction pour écrire un message dans le fichier texte
function ecrireResultat{
    if(!(Test-Path $userprofile\Desktop\log.txt)){
        New-Item $userprofile\Desktop\log.txt -ItemType File
    }

    $dateCourante = Get-Date -Format G

    "`n$dateCourante : Le transfert de $file a été fait" >> $userprofile\Desktop\log.txt
}

#Ecriture dans le log Windows
function ecrireWindowsLog([String]$origine){
    $logExiste = Get-EventLog -LogName Application | Where {$_.Source -eq $nomScript} 
    if (! $logExiste) {
        New-EventLog -LogName Application -Source $nomScript
    }

    #Le paramètre origine permet de mettre dans le log la nature de ce qui à été transféré
    Write-EventLog -LogName Application -Source $nomScript -EntryType Information -EventId 1 -Message "L'application a bien lancé la sauvegarde pour les $origine"
}

#Fonction pour trouver et transférer les musiques
function transfertMusics{
    if(!(Test-Path -Path "$userprofile\Desktop\médias")){
        mkdir $userprofile\Desktop\médias
    }
    if(!(Test-Path -Path "$userprofile\Desktop\médias\musiques")){
        mkdir $userprofile\Desktop\médias\musiques
    }
    findMaxSize
    foreach ($file in .\adb.exe shell find | Where-Object {$_ -match "\.mp3" -or $_ -match "\.flac" -or $_ -match "\.wav"})
    {
        if($Global:maxSize -ne 0){
            [string]$infoFichier = .\adb.exe shell "busybox stat -t '$file'"
            $infoTaille = $infoFichier.Substring($file.length).Split(' ')[1]
            if([int]$infoTaille -lt $Global:maxSize){
                Write-Host $file
                write-host $infoTaille
                write-host $Global:maxSize
                .\adb.exe pull $file "$userprofile\Desktop\médias\musiques"
             }
         }else{
            .\adb.exe pull $file "$userprofile\Desktop\médias\musiques"
         }

        ecrireResultat
    }
    ecrireWindowsLog -origine "musiques"
}

#Fonction pour trouver et transférer les images
function transfertImages{
    if(!(Test-Path -Path "$userprofile\Desktop\médias")){
        mkdir $userprofile\Desktop\médias
    }
    if(!(Test-Path -Path "$userprofile\Desktop\médias\images")){
        mkdir $userprofile\Desktop\médias\images
    }
    findMaxSize
    foreach ($file in .\adb.exe shell find | Where-Object {$_ -match "\.jpg" -or $_ -match "\.png" -or $_ -match "\.bmp" -or $_ -match "\.gif"})
    {
        if($Global:maxSize -ne 0){
            [string]$infoFichier = .\adb.exe shell "busybox stat -t $file"
            $infoTaille = $infoFichier.Substring($file.length).Split(' ')[1]
            if([int]$infoTaille -lt $Global:maxSize){
                Write-Host $file
                write-host $infoTaille
                write-host $Global:maxSize
                .\adb.exe pull $file $userprofile\Desktop\médias\images
            }
        }else{
            .\adb.exe pull $file $userprofile\Desktop\médias\images
        }

        ecrireResultat
    }
    ecrireWindowsLog -origine "images"
}


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
        if($Global:maxSize -ne 0){
        [string]$infoFichier = .\adb.exe shell "busybox stat -t $file"
        $infoTaille = $infoFichier.Substring($file.length).Split(' ')[1]
            if([int]$infoTaille -lt $Global:maxSize){
                Write-Host $file
                write-host $infoTaille
                write-host $Global:maxSize
                .\adb.exe pull $file $userprofile\Desktop\médias\vidéos
            }
        }else{
            .\adb.exe pull $file $userprofile\Desktop\médias\vidéos
        }

        ecrireResultat
    }
    ecrireWindowsLog -origine "vidéos"
}

#Interface générée par PrimalForms

#Generated Form Function
function GenerateForm {
########################################################################
# Code Generated By: SAPIEN Technologies PrimalForms (Community Edition) v1.0.10.0
# Generated On: 21.09.2016 20:06
# Generated By: admin
########################################################################

#region Import the Assemblies
[reflection.assembly]::loadwithpartialname("System.Drawing") | Out-Null
[reflection.assembly]::loadwithpartialname("System.Windows.Forms") | Out-Null
#endregion

#region Generated Form Objects
$FormSYD = New-Object System.Windows.Forms.Form
$btnAide = New-Object System.Windows.Forms.Button
$ChckImages = New-Object System.Windows.Forms.CheckBox
$ChckTaches = New-Object System.Windows.Forms.CheckBox
$txtHistorique = New-Object System.Windows.Forms.RichTextBox
$Titre = New-Object System.Windows.Forms.Label
$btnHistorique = New-Object System.Windows.Forms.Button
$btnTransfert = New-Object System.Windows.Forms.Button
$label1 = New-Object System.Windows.Forms.Label
$ChckMusics = New-Object System.Windows.Forms.CheckBox
$ChckVideos = New-Object System.Windows.Forms.CheckBox
$cmbBoxJours = New-Object System.Windows.Forms.ComboBox
$cmbBoxHeures = New-Object System.Windows.Forms.ComboBox
$txtHeures = New-Object System.Windows.Forms.Label
$panel1 = New-Object System.Windows.Forms.Panel
$progressBar = New-Object System.Windows.Forms.ProgressBar
$label1Mo = New-Object System.Windows.Forms.Label
$label5Mo = New-Object System.Windows.Forms.Label
$label10Mo = New-Object System.Windows.Forms.Label
$label20Mo = New-Object System.Windows.Forms.Label
$labelAll = New-Object System.Windows.Forms.Label
$InitialFormWindowState = New-Object System.Windows.Forms.FormWindowState
#endregion Generated Form Objects

#----------------------------------------------
#Generated Event Script Blocks
#----------------------------------------------
#Provide Custom Code for events specified in PrimalForms.

$handler_btnAide_Click= 
{
    [System.Windows.Forms.MessageBox]::Show("
    Pour que ce script fonctionne correctement, il faut que: 
    `r1) Les options pour développeurs soient activées sur votre téléphone
    `r2) Le débogage Android soit activé
    `r3) Le téléphone soit rooté
    `r4) L'accès soit au moins permis pour ADB
    `r5) Le type de connexion soit MTP (multimedia Transfert Protocol)
    `r6) Le débogage USB vers le PC soit autorisé sur le téléphone
    `r7) Le téléphone soit correctement être branché par USB au PC
    `r----------------------------------- Informations -----------------------------------
    `r1) Pour certaines fonctionnalités, le script doit être lancé en Adminsitrateur
    `r2) Nécessite une connexion Internet pour l'installation d'ADB
    `r3) ADB sera installé sur le bureau
    `r4) Un dossier médias contenant les fichiers transférés sera créé sur le bureau
    `r5) Si l'application crash, ne cliquez pas dessus et laissez l'application faire!
    `r------------------------------------- Contacts -------------------------------------
    `r - www.scriptosaurus.ch (disponible plus tard)
    `r - kollyf01@studentfr.ch
    ")
}

$handler_ChckTache_Click= 
{
    if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")){    
            [System.Windows.Forms.MessageBox]::Show("Pour utiliser cette fonctionnalité, veuillez lancer ce script en administrateur!")
            $ChckTaches.Checked = $false
    }else{
        if($ChckTaches.Checked.Equals($true)){
            $tache = New-ScheduledTaskAction -Execute $PSScriptRoot\projet.ps1
            switch ($cmbBoxJours.SelectedItem){
                Lundi { $jour = "Monday"; break }
                Mardi { $jour = "Thursday"; break }
                Mercredi { $jour = "Wednesday"; break }
                jeudi { $jour = "Tuesday"; break }
                Vendredi { $jour = "Friday"; break }
                Samedi { $jour = "Saturday"; break }
                Dimanche { $jour = "Sunday"; break }
            }
            if($cmbBoxJours.SelectedItem -ne $null -and $cmbBoxHeures.SelectedItem -ne $null){
                $dateLancement = New-ScheduledTaskTrigger -Weekly -DaysOfWeek $jour -At $cmbBoxHeures.SelectedItem
                $planificateur = Get-ScheduledTask | select TaskName | ? {$_.TaskName -eq $nomScript}

                #Si le planificateur n'existe pas
                if($planificateur -eq $null){
                    Write-Host $planificateur
                    Register-ScheduledTask -Action $tache -Trigger $dateLancement -TaskName $nomScript -Description "Sauvegarde automatique des médias du téléphone"
                }

            }else{
                [System.Windows.Forms.MessageBox]::Show("Veuillez sélectionner un jour et une heure!")
                $ChckTaches.Checked = $false
            }
        }

        if($ChckTaches.Checked.Equals($false)){
            $planificateur = Get-ScheduledTask | select TaskName | ? {$_.TaskName -eq $nomScript}
            if($planificateur -ne $null){
                supprimerTachePlanifiee
            }
        }
    }
}

$handler_saveYourDatas_Load= 
{
    #Enlève les processus qui existe déjà
    gestionProcessus
    #Permet d'automatiquement cocher la checkBox chckTaches s'il y a déjà la tâche
    if(Get-ScheduledTask | select TaskName | ? {$_.TaskName -eq $nomScript}){
        $ChckTaches.Checked = $True
    }
}

$handler_btnHistorique_Click= 
{
    $dateJMA = Get-Date -Format d
    #Code par Roman Kuzmin trouvé sur StackOverFlow
    if(!(Test-Path $userprofile\Desktop\log.txt)){
        New-Item $userprofile\Desktop\log.txt -ItemType File
    }
    $reader = [System.IO.File]::OpenText("$userprofile\Desktop\log.txt")
    try {
        for() {
            $line = $reader.ReadLine()
            if ($null -eq $line -and !($line -contains ($dateJMA))){
                break
            }
            # process the line
            $txtHistorique.AppendText($line)
            $txtHistorique.AppendText("`r")
        }
    }
        finally {
        $reader.Close()
    }
}

$handler_btnTransfert_Click= 
{
    if($ChckMusics.Checked.Equals($True) -or $ChckImages.Checked.Equals($True) -or $ChckVideos.Checked.Equals($True)){
        chargementADB
        #La recherche est lancée un fois dans le vide afin d'activer ADB. Si cela n'est pas fait, une erreur peut être engendrée!
        .\adb.exe devices -l
        $devices = .\adb.exe devices -l
        #Le String "device product" apparait seulement si il y un device connecté
        if($devices -match "device product"){
            $progressBar.Value = 1
            if(($ChckMusics.Checked.Equals($True) -and $ChckImages.Checked.Equals($True) -and $ChckVideos.Checked.Equals($false)) -or ($ChckMusics.Checked.Equals($True) -and $ChckVideos.Checked.Equals($True) -and $ChckImages.Checked.Equals($false)) -or ($ChckImages.Checked.Equals($True) -and $ChckVideos.Checked.Equals($True) -and $ChckMusics.Checked.Equals($false))){
                $progressBar.Step = 49.5
            }elseif(($ChckMusics.Checked.Equals($True) -and $ChckImages.Checked.Equals($false) -and $ChckVideos.Checked.Equals($false)) -or ($ChckMusics.Checked.Equals($false) -and $ChckVideos.Checked.Equals($True) -and $ChckImages.Checked.Equals($false)) -or ($ChckImages.Checked.Equals($True) -and $ChckVideos.Checked.Equals($false) -and $ChckMusics.Checked.Equals($false))){
                $progressBar.Step = 99
            }else{
                $progressBar.Step = 33
            }
            if($ChckMusics.Checked.Equals($True)){
                transfertMusics
                $progressBar.PerformStep()
            }
            if($ChckImages.Checked.Equals($True)){
                transfertImages
                $progressBar.PerformStep()
            }
            if($ChckVideos.Checked.Equals($True)){
                transfertVideos
                $progressBar.PerformStep()
            }
            [System.Windows.Forms.MessageBox]::Show("Les transferts souhaités ont été réalisés!")
            $progressBar.Value = 0
        }else{
            [System.Windows.Forms.MessageBox]::Show("Veuillez connecter un appareil. Si l'erreur persiste, consultez l'aide!")
        }
    }else{
        [System.Windows.Forms.MessageBox]::Show("Veuillez choisir une catégorie à transférer!")
    }
}

$OnLoadForm_StateCorrection=
{#Correct the initial state of the form to prevent the .Net maximized form issue
	$FormSYD.WindowState = $InitialFormWindowState
}

#----------------------------------------------
#region Generated Form Code
$FormSYD.BackColor = [System.Drawing.Color]::FromArgb(255,240,240,240)
$System_Drawing_Size = New-Object System.Drawing.Size
$System_Drawing_Size.Height = 414
$System_Drawing_Size.Width = 721
$FormSYD.ClientSize = $System_Drawing_Size
$FormSYD.DataBindings.DefaultDataSourceUpdateMode = 0
$FormSYD.FormBorderStyle = 2
$FormSYD.Name = "FormSYD"
$FormSYD.Text = "SaveYourDatas"
$FormSYD.add_Load($handler_saveYourDatas_Load)

$btnAide.AccessibleDescription = "Afficher l''aide"
$btnAide.AccessibleName = "Aide"

$btnAide.DataBindings.DefaultDataSourceUpdateMode = 0

$System_Drawing_Point = New-Object System.Drawing.Point
$System_Drawing_Point.X = 523
$System_Drawing_Point.Y = 143
$btnAide.Location = $System_Drawing_Point
$btnAide.Name = "btnAide"
$System_Drawing_Size = New-Object System.Drawing.Size
$System_Drawing_Size.Height = 25
$System_Drawing_Size.Width = 176
$btnAide.Size = $System_Drawing_Size
$btnAide.TabIndex = 11
$btnAide.Text = "Afficher l''aide"
$btnAide.UseVisualStyleBackColor = $True
$btnAide.add_Click($handler_btnAide_Click)

$FormSYD.Controls.Add($btnAide)

$ChckImages.AccessibleDescription = "Images"
$ChckImages.AccessibleName = "Images"

$ChckImages.DataBindings.DefaultDataSourceUpdateMode = 0

$System_Drawing_Point = New-Object System.Drawing.Point
$System_Drawing_Point.X = 89
$System_Drawing_Point.Y = 113
$ChckImages.Location = $System_Drawing_Point
$ChckImages.Name = "ChckImages"
$System_Drawing_Size = New-Object System.Drawing.Size
$System_Drawing_Size.Height = 25
$System_Drawing_Size.Width = 104
$ChckImages.Size = $System_Drawing_Size
$ChckImages.TabIndex = 0
$ChckImages.Tag = "Images"
$ChckImages.Text = "Image(s)"
$ChckImages.UseVisualStyleBackColor = $True

$FormSYD.Controls.Add($ChckImages)

$trackBar.DataBindings.DefaultDataSourceUpdateMode = 0

$System_Drawing_Point = New-Object System.Drawing.Point
$System_Drawing_Point.X = 200
$System_Drawing_Point.Y = 115
$trackBar.Location = $System_Drawing_Point
$trackBar.Maximum = 5
$trackBar.Minimum = 1
$trackBar.LargeChange = 1
$trackBar.Name = "trackBar"
$System_Drawing_Size = New-Object System.Drawing.Size
$System_Drawing_Size.Height = 1
$System_Drawing_Size.Width = 230
$trackBar.Size = $System_Drawing_Size
$trackBar.TabIndex = 1
$trackBar.Value = 1

$FormSYD.Controls.Add($trackBar)

$ChckTaches.AccessibleDescription = "Planificateur"
$ChckTaches.AccessibleName = "Planificateur"

$ChckTaches.DataBindings.DefaultDataSourceUpdateMode = 0

$System_Drawing_Point = New-Object System.Drawing.Point
$System_Drawing_Point.X = 425
$System_Drawing_Point.Y = 191
$ChckTaches.Location = $System_Drawing_Point
$ChckTaches.Name = "ChckTaches"
$System_Drawing_Size = New-Object System.Drawing.Size
$System_Drawing_Size.Height = 25
$System_Drawing_Size.Width = 100
$ChckTaches.Size = $System_Drawing_Size
$ChckTaches.TabIndex = 9
$ChckTaches.Tag = "Planificateur"
$ChckTaches.Text = "Lancer tout les "
$ChckTaches.UseVisualStyleBackColor = $True
$ChckTaches.add_Click($handler_ChckTache_Click)

$FormSYD.Controls.Add($ChckTaches)

$ProgressBar.DataBindings.DefaultDataSourceUpdateMode = 0

$System_Drawing_Point = New-Object System.Drawing.Point
$System_Drawing_Point.X = 12
$System_Drawing_Point.Y = 380
$ProgressBar.Location = $System_Drawing_Point
$ProgressBar.Name = "ProgressBar"
$System_Drawing_Size = New-Object System.Drawing.Size
$System_Drawing_Size.Height = 23
$System_Drawing_Size.Width = 400
$ProgressBar.Size = $System_Drawing_Size
$progressBar.Step = 33
$progressBar.Style = 'continuous'
$ProgressBar.TabIndex = 0

$FormSYD.Controls.Add($ProgressBar)

$label1Mo.DataBindings.DefaultDataSourceUpdateMode = 0

$System_Drawing_Point = New-Object System.Drawing.Point
$System_Drawing_Point.X = 198
$System_Drawing_Point.Y = 158
$label1Mo.Location = $System_Drawing_Point
$label1Mo.Name = "label1Mo"
$System_Drawing_Size = New-Object System.Drawing.Size
$System_Drawing_Size.Height = 23
$System_Drawing_Size.Width = 34
$label1Mo.Size = $System_Drawing_Size
$label1Mo.TabIndex = 2
$label1Mo.Text = "1 Mo"

$FormSYD.Controls.Add($label1Mo)

$label5Mo.DataBindings.DefaultDataSourceUpdateMode = 0

$System_Drawing_Point = New-Object System.Drawing.Point
$System_Drawing_Point.X = 250
$System_Drawing_Point.Y = 158
$label5Mo.Location = $System_Drawing_Point
$label5Mo.Name = "label5Mo"
$System_Drawing_Size = New-Object System.Drawing.Size
$System_Drawing_Size.Height = 23
$System_Drawing_Size.Width = 34
$label5Mo.Size = $System_Drawing_Size
$label5Mo.TabIndex = 2
$label5Mo.Text = "5 Mo"

$FormSYD.Controls.Add($label5Mo)

$label10Mo.DataBindings.DefaultDataSourceUpdateMode = 0

$System_Drawing_Point = New-Object System.Drawing.Point
$System_Drawing_Point.X = 297
$System_Drawing_Point.Y = 158
$label10Mo.Location = $System_Drawing_Point
$label10Mo.Name = "label10Mo"
$System_Drawing_Size = New-Object System.Drawing.Size
$System_Drawing_Size.Height = 23
$System_Drawing_Size.Width = 38
$label10Mo.Size = $System_Drawing_Size
$label10Mo.TabIndex = 2
$label10Mo.Text = "10 Mo"

$FormSYD.Controls.Add($label10Mo)

$label20Mo.DataBindings.DefaultDataSourceUpdateMode = 0

$System_Drawing_Point = New-Object System.Drawing.Point
$System_Drawing_Point.X = 348
$System_Drawing_Point.Y = 158
$label20Mo.Location = $System_Drawing_Point
$label20Mo.Name = "label20Mo"
$System_Drawing_Size = New-Object System.Drawing.Size
$System_Drawing_Size.Height = 23
$System_Drawing_Size.Width = 38
$label20Mo.Size = $System_Drawing_Size
$label20Mo.TabIndex = 2
$label20Mo.Text = "20 Mo"

$FormSYD.Controls.Add($label20Mo)

$labelAll.DataBindings.DefaultDataSourceUpdateMode = 0

$System_Drawing_Point = New-Object System.Drawing.Point
$System_Drawing_Point.X = 403
$System_Drawing_Point.Y = 158
$labelAll.Location = $System_Drawing_Point
$labelAll.Name = "labelAll"
$System_Drawing_Size = New-Object System.Drawing.Size
$System_Drawing_Size.Height = 23
$System_Drawing_Size.Width = 38
$labelAll.Size = $System_Drawing_Size
$labelAll.TabIndex = 2
$labelAll.Text = "Tout"

$FormSYD.Controls.Add($labelAll)

$txtHistorique.DataBindings.DefaultDataSourceUpdateMode = 0
$System_Drawing_Point = New-Object System.Drawing.Point
$txtHistorique.BackColor = [System.Drawing.Color]::FromArgb(255,255,255,255)
$System_Drawing_Point.X = 12
$System_Drawing_Point.Y = 239
$txtHistorique.Location = $System_Drawing_Point
$txtHistorique.Name = "txtHistorique"
$txtHistorique.ReadOnly = $True
$System_Drawing_Size = New-Object System.Drawing.Size
$System_Drawing_Size.Height = 96
$System_Drawing_Size.Width = 697
$txtHistorique.Size = $System_Drawing_Size
$txtHistorique.TabIndex = 8
$txtHistorique.Text = "Historique:"

$FormSYD.Controls.Add($txtHistorique)

$Titre.BackColor = [System.Drawing.Color]::FromArgb(255,185,209,234)
$Titre.DataBindings.DefaultDataSourceUpdateMode = 0
$Titre.Font = New-Object System.Drawing.Font("Sitka Banner",36,3,3,1)

$System_Drawing_Point = New-Object System.Drawing.Point
$System_Drawing_Point.X = 12
$System_Drawing_Point.Y = 9
$Titre.Location = $System_Drawing_Point
$Titre.Name = "Titre"
$System_Drawing_Size = New-Object System.Drawing.Size
$System_Drawing_Size.Height = 67
$System_Drawing_Size.Width = 346
$Titre.Size = $System_Drawing_Size
$Titre.TabIndex = 6
$Titre.Text = "SaveYourDatas"

$FormSYD.Controls.Add($Titre)

$btnHistorique.AccessibleDescription = "Afficher l''historique"
$btnHistorique.AccessibleName = "Historique"

$btnHistorique.DataBindings.DefaultDataSourceUpdateMode = 0

$System_Drawing_Point = New-Object System.Drawing.Point
$System_Drawing_Point.X = 12
$System_Drawing_Point.Y = 341
$btnHistorique.Location = $System_Drawing_Point
$btnHistorique.Name = "btnHistorique"
$System_Drawing_Size = New-Object System.Drawing.Size
$System_Drawing_Size.Height = 30
$System_Drawing_Size.Width = 147
$btnHistorique.Size = $System_Drawing_Size
$btnHistorique.TabIndex = 5
$btnHistorique.Tag = "Historique"
$btnHistorique.Text = "Afficher l''historique"
$btnHistorique.UseVisualStyleBackColor = $True
$btnHistorique.add_Click($handler_btnHistorique_Click)

$FormSYD.Controls.Add($btnHistorique)

$cmbBoxJours.AccessibleDescription = "Jours"
$cmbBoxJours.AccessibleName = "Jours"
$cmbBoxJours.AutoCompleteMode = 1

$cmbBoxJours.DataBindings.DefaultDataSourceUpdateMode = 0

$cmbBoxJours.FormattingEnabled = $True
$cmbBoxJours.Items.Add("Lundi")|Out-Null
$cmbBoxJours.Items.Add("Mardi")|Out-Null
$cmbBoxJours.Items.Add("Mercredi")|Out-Null
$cmbBoxJours.Items.Add("Jeudi")|Out-Null
$cmbBoxJours.Items.Add("Vendredi")|Out-Null
$cmbBoxJours.Items.Add("Samedi")|Out-Null
$cmbBoxJours.Items.Add("Dimanche")|Out-Null
$System_Drawing_Point = New-Object System.Drawing.Point
$System_Drawing_Point.X = 525
$System_Drawing_Point.Y = 191
$cmbBoxJours.Location = $System_Drawing_Point
$cmbBoxJours.Name = "cmbBoxJours"
$System_Drawing_Size = New-Object System.Drawing.Size
$System_Drawing_Size.Height = 25
$System_Drawing_Size.Width = 90
$cmbBoxJours.Size = $System_Drawing_Size
$cmbBoxJours.TabIndex = 0

$FormSYD.Controls.Add($cmbBoxJours)

$txtHeures.DataBindings.DefaultDataSourceUpdateMode = 0

$System_Drawing_Point = New-Object System.Drawing.Point
$System_Drawing_Point.X = 619
$System_Drawing_Point.Y = 194
$txtHeures.Location = $System_Drawing_Point
$txtHeures.Name = "txtHeures"
$System_Drawing_Size = New-Object System.Drawing.Size
$System_Drawing_Size.Height = 25
$System_Drawing_Size.Width = 15
$txtHeures.Size = $System_Drawing_Size
$txtHeures.TabIndex = 0
$txtHeures.Text = " à "

$FormSYD.Controls.Add($txtHeures)

$cmbBoxHeures.AccessibleDescription = "Heures"
$cmbBoxHeures.AccessibleName = "Heures"
$cmbBoxHeures.DataBindings.DefaultDataSourceUpdateMode = 0
$cmbBoxHeures.FormattingEnabled = $True
$cmbBoxHeures.Items.Add("1:00")|Out-Null
$cmbBoxHeures.Items.Add("2:00")|Out-Null
$cmbBoxHeures.Items.Add("3:00")|Out-Null
$cmbBoxHeures.Items.Add("4:00")|Out-Null
$cmbBoxHeures.Items.Add("5:00")|Out-Null
$cmbBoxHeures.Items.Add("6:00")|Out-Null
$cmbBoxHeures.Items.Add("7:00")|Out-Null
$cmbBoxHeures.Items.Add("8:00")|Out-Null
$cmbBoxHeures.Items.Add("9:00")|Out-Null
$cmbBoxHeures.Items.Add("10:00")|Out-Null
$cmbBoxHeures.Items.Add("11:00")|Out-Null
$cmbBoxHeures.Items.Add("12:00")|Out-Null
$cmbBoxHeures.Items.Add("13:00")|Out-Null
$cmbBoxHeures.Items.Add("14:00")|Out-Null
$cmbBoxHeures.Items.Add("15:00")|Out-Null
$cmbBoxHeures.Items.Add("16:00")|Out-Null
$cmbBoxHeures.Items.Add("17:00")|Out-Null
$cmbBoxHeures.Items.Add("18:00")|Out-Null
$cmbBoxHeures.Items.Add("19:00")|Out-Null
$cmbBoxHeures.Items.Add("20:00")|Out-Null
$cmbBoxHeures.Items.Add("21:00")|Out-Null
$cmbBoxHeures.Items.Add("22:00")|Out-Null
$cmbBoxHeures.Items.Add("23:00")|Out-Null
$cmbBoxHeures.Items.Add("24:00")|Out-Null
$System_Drawing_Point = New-Object System.Drawing.Point
$System_Drawing_Point.X = 640
$System_Drawing_Point.Y = 191
$cmbBoxHeures.Location = $System_Drawing_Point
$cmbBoxHeures.Name = "cmbBoxHeures"
$System_Drawing_Size = New-Object System.Drawing.Size
$System_Drawing_Size.Height = 25
$System_Drawing_Size.Width = 55
$cmbBoxHeures.Size = $System_Drawing_Size
$cmbBoxHeures.TabIndex = 0

$FormSYD.Controls.Add($cmbBoxHeures)

$btnTransfert.AccessibleDescription = "Lancer le transfert"
$btnTransfert.AccessibleName = "Transfert"

$btnTransfert.DataBindings.DefaultDataSourceUpdateMode = 0

$System_Drawing_Point = New-Object System.Drawing.Point
$System_Drawing_Point.X = 562
$System_Drawing_Point.Y = 363
$btnTransfert.Location = $System_Drawing_Point
$btnTransfert.Name = "btnTransfert"
$System_Drawing_Size = New-Object System.Drawing.Size
$System_Drawing_Size.Height = 39
$System_Drawing_Size.Width = 147
$btnTransfert.Size = $System_Drawing_Size
$btnTransfert.TabIndex = 4
$btnTransfert.Tag = "Transfert"
$btnTransfert.Text = "Lancer le transfert"
$btnTransfert.UseVisualStyleBackColor = $True
$btnTransfert.add_Click($handler_btnTransfert_Click)

$FormSYD.Controls.Add($btnTransfert)

$label1.DataBindings.DefaultDataSourceUpdateMode = 0

$System_Drawing_Point = New-Object System.Drawing.Point
$System_Drawing_Point.X = 58
$System_Drawing_Point.Y = 87
$label1.Location = $System_Drawing_Point
$label1.Name = "label1"
$System_Drawing_Size = New-Object System.Drawing.Size
$System_Drawing_Size.Height = 23
$System_Drawing_Size.Width = 241
$label1.Size = $System_Drawing_Size
$label1.TabIndex = 3
$label1.Text = "Cochez les fichiers à transférer:"

$FormSYD.Controls.Add($label1)

$ChckMusics.AccessibleDescription = "Musiques"
$ChckMusics.AccessibleName = "Musiques"

$ChckMusics.DataBindings.DefaultDataSourceUpdateMode = 0

$System_Drawing_Point = New-Object System.Drawing.Point
$System_Drawing_Point.X = 89
$System_Drawing_Point.Y = 174
$ChckMusics.Location = $System_Drawing_Point
$ChckMusics.Name = "ChckMusics"
$System_Drawing_Size = New-Object System.Drawing.Size
$System_Drawing_Size.Height = 25
$System_Drawing_Size.Width = 104
$ChckMusics.Size = $System_Drawing_Size
$ChckMusics.TabIndex = 2
$ChckMusics.Tag = "Musiques"
$ChckMusics.Text = "Musique(s)"
$ChckMusics.UseVisualStyleBackColor = $True

$FormSYD.Controls.Add($ChckMusics)

$ChckVideos.AccessibleDescription = "Vidéos"
$ChckVideos.AccessibleName = "Vidéos"

$ChckVideos.DataBindings.DefaultDataSourceUpdateMode = 0

$System_Drawing_Point = New-Object System.Drawing.Point
$System_Drawing_Point.X = 89
$System_Drawing_Point.Y = 143
$ChckVideos.Location = $System_Drawing_Point
$ChckVideos.Name = "ChckVideos"
$System_Drawing_Size = New-Object System.Drawing.Size
$System_Drawing_Size.Height = 25
$System_Drawing_Size.Width = 104
$ChckVideos.Size = $System_Drawing_Size
$ChckVideos.TabIndex = 1
$ChckVideos.Tag = "Videos"
$ChckVideos.Text = "Vidéo(s)"
$ChckVideos.UseVisualStyleBackColor = $True

$FormSYD.Controls.Add($ChckVideos)

$panel1.BackColor = [System.Drawing.Color]::FromArgb(255,185,209,234)

$panel1.DataBindings.DefaultDataSourceUpdateMode = 0
$System_Drawing_Point = New-Object System.Drawing.Point
$System_Drawing_Point.X = -1
$System_Drawing_Point.Y = -1
$panel1.Location = $System_Drawing_Point
$panel1.Name = "panel1"
$System_Drawing_Size = New-Object System.Drawing.Size
$System_Drawing_Size.Height = 85
$System_Drawing_Size.Width = 726
$panel1.Size = $System_Drawing_Size
$panel1.TabIndex = 10

$FormSYD.Controls.Add($panel1)

#endregion Generated Form Code

#Save the initial state of the form
$InitialFormWindowState = $FormSYD.WindowState
#Init the OnLoad event to correct the initial state of the form
$FormSYD.add_Load($OnLoadForm_StateCorrection)
#Show the Form
$FormSYD.ShowDialog()| Out-Null

} #End Function

#Call the Function
GenerateForm