
<powershell>
#Renombramos el servidor
Rename-Computer -ComputerName  -NewName "SERVIDOR-NN" 

#Abrimos las reglas del Firewall para permitir PING
New-NetFirewallRule -DisplayName "Allow inbound ICMPv4" -Direction Inbound -Protocol ICMPv4 -IcmpType 8 -RemoteAddress <localsubnet> -Action Allow
New-NetFirewallRule -DisplayName "Allow inbound ICMPv6" -Direction Inbound -Protocol ICMPv6 -IcmpType 8 -RemoteAddress <localsubnet> -Action Allow
New-NetFirewallRule -DisplayName "Allow outbound ICMPv4" -Direction Outbound -Protocol ICMPv4 -IcmpType 8 -RemoteAddress <localsubnet> -Action Allow
New-NetFirewallRule -DisplayName "Allow outbound ICMPv6" -Direction Outbound -Protocol ICMPv6 -IcmpType 8 -RemoteAddress <localsubnet> -Action Allow



#Instalamos rol AD
Install-windowsfeature -name AD-Domain-Services -IncludeManagementTools


#
# Configuramos AD
#

Import-Module ADDSDeployment
Install-ADDSForest `
-CreateDnsDelegation:$false `
-DatabasePath "C:\Windows\NTDS" `
-DomainMode "WinThreshold" `
-DomainName "dominioPROFE.local" `
-DomainNetbiosName "DOMINIOPROFE" `
-ForestMode "WinThreshold" `
-InstallDns:$true `
-LogPath "C:\Windows\NTDS" `
-NoRebootOnCompletion:$false `
-SysvolPath "C:\Windows\SYSVOL" `
-Force:$true


</powershell>
