#Script to Change TFTP Block Size to 16384
#Speed Up PXE Boot
#Tutorial on link
#https://youtu.be/6C3tlIXfVpU
#Variables
#Role WDS must already been in place
$remoteinstall_path = (Get-SmbShare -Name Reminst).Path
$drive_path = Split-Path -Path $remoteinstall_path -Qualifier
$wds_boot_folder = $remoteinstall_path + "\Boot\"
$bckp_archive = $drive_path + "\Backup_Orig_bcd_files.zip"
$bckp_folder = $drive_path "\Backup"
$bckp_log = $bckp_folder + "\" + "log.txt"


#Creation Folder/Log Backup if not exist
if (!(Test-Path $bckp_archive))
    {
    if (!(test-path $bckp_folder)){write-host "Creation Folder : $bckp_folder"; New-Item -ItemType Directory -Path $bckp_folder | out-null}
    if (!(test-path $bckp_log)){write-host "Creation File : $bckp_log"; New-Item -ItemType File -Path $bckp_log | out-null;Add-Content -Path $bckp_log -value '"FileName","Source","Destination"'}
    }

#Stop Service WDS
while ((get-service -Name WDSServer).Status -ne 'Stopped')
    {
    Stop-Service -Name WDSServer
    Start-Sleep -Seconds 1
    if ((Get-Service -Name WDSServer).Status -eq 'Stopped'){Write-Host -Object "Service WDSServer Stopped"}
    }

#Find all files default.bcd
$bcd_files = Get-ChildItem -Path $wds_boot_folder -Recurse | where -Property Name -EQ "default.bcd"
foreach ($file in $bcd_files)
    {
    #Test if backup already exist
    if (!(test-path -Path $bckp_archive))
        {
        #Arch Type - parent folder name
        $arch_type = split-path $file.DirectoryName -leaf
        #Backup Files
        #Folder to backup
        $bckp_folder_arch = $bckp_folder + "\" + $arch_type
        if (!(test-path $bckp_folder_arch)){write-host "Creation Folder : $bckp_folder_arch"; New-Item -ItemType Directory -Path $bckp_folder_arch | out-null}
        #Copy Original file
        Copy-Item -Path $file.FullName -Destination $bckp_folder_arch -Force | Out-Null
        #Log Backup 
        Add-Content -Path $bckp_log -Value "$($file.Name),$($file.DirectoryName),$bckp_folder_arch"
        }
    #Change TFTP Block Size to 16384
    start-process "bcdedit" -ArgumentList "/store $($file.FullName) /set {68d9e51c-a129-4ee1-9725-2ab00a957daf} ramdisktftpblocksize 16384"
    }
Start-Sleep -Seconds 1
if (Test-Path -Path $bckp_folder)
    {
    #Compress Backup Folder to Archive
    Compress-Archive -Path $bckp_folder -DestinationPath $bckp_archive
    #Remove Backup Folder
    Remove-Item -Path $bckp_folder -Recurse -Force
    }

#Start Service WDS
while ((get-service -Name WDSServer).Status -ne 'Running')
    {
    Start-Service -Name WDSServer
    Start-Sleep -Seconds 1
    if ((Get-Service -Name WDSServer).Status -eq 'Running'){Write-Host -Object "Service WDSServer Start"}
    }
Start-Sleep -Seconds 1
#Signal WDS Server to rebuil boot files
Start-process "sc" -ArgumentList "control wdsserver 129"