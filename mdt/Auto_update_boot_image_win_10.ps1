#Script to Update Boot Image generate from MDT to WDS
#Tutorial on link
#https://youtu.be/Q7hCDFkYiXQ
#Import module 
$module_mdt_path = "C:\Program Files\Microsoft Deployment Toolkit\Bin\MicrosoftDeploymentToolkit.psd1"
import-module $module_mdt_path
#Map drive to DS
$deploymentshare = "Path Folder Deployment Share"
New-PSDrive -Name "MDT" -PSProvider MDTProvider -Root $deploymentshare
#MAJ Deployment Share boot image
Update-MDTDeploymentShare -Path "MDT:" -Verbose
Remove-PSDrive -Name "MDT"
#Recuperation from Xml - Image Name
[xml]$xml_boot_image_x64 = Get-content $($deploymentshare + "\Boot\LiteTouchPE_x64.xml")

#Maj image WDS
Get-WdsBootImage -Architecture X64 -ImageName $xml_boot_image_x64.Definition.WindowsPE.ImageName | Remove-WdsBootImage
$image_boot_path = $deploymentshare + "\Boot\LiteTouchPE_x64.wim"
Import-WdsBootImage -NewImageName $xml_boot_image_x64.Definition.WindowsPE.ImageName -Path $image_boot_path -SkipVerify