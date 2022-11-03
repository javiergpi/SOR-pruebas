$DNS_DOMINIO=$args[0];
$NETBIOS_DOMINIO=$args[1];



#Eliminamos el registro de la tarea programada
 $exists = Get-ScheduledTask | Where-Object {$_.TaskName -like 'ConfiguraAD'}
 if($exists){
    Unregister-ScheduledTask -TaskName 'ConfiguraAD' -Confirm:$false
 }


#
# Configuramos AD
#

Import-Module ADDSDeployment
Install-ADDSForest `
-CreateDnsDelegation:$false `
-DatabasePath "C:\Windows\NTDS" `
-DomainMode "WinThreshold" `
-DomainName $DNS_DOMINIO `
-DomainNetbiosName $NETBIOS_DOMINIO `
-SafeModeAdministratorPassword (ConvertTo-SecureString -AsPlainText "Naranco.22" -Force) `
-ForestMode "WinThreshold" `
-InstallDns:$true `
-LogPath "C:\Windows\NTDS" `
-NoRebootOnCompletion:$false `
-SysvolPath "C:\Windows\SYSVOL" `
-Force:$true