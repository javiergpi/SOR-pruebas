
# Script de unión a dominio. 
# Debería incluir las variables:
#   - DNS_DOMINIO

$Credenciales = $Host.UI.PromptForCredential("Credenciales", "Escribe credenciales para unirte al dominio", "", $DNS_DOMINIO)
Add-Computer -DomainName $DNS_DOMINIO -cred $Credenciales