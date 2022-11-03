###########################################################
#       Creación de una VPC, subred pública, 
#       internet gateway, tabla de rutas, 
#       grupo de seguridad y dos instancias EC2 Windows 2022 (SERVIDOR Y CLIENTE)
#      en AWS con AWS CLI

#  Autor: Javier González Pisano (basado en Javier Terán González)
#  Fecha: 02/11/2022
###########################################################

#SECCION DE VARIABLES: A CUSTOMIZAR POR EL ALUMNO

# VARIABLES AWS

#CIDR de la VPC
AWS_VPC_CIDR_BLOCK=192.168.66.0/24

#CIDR de la subred pública (deber ser subconjunto de la anterior)
AWS_Subred_CIDR_BLOCK=192.168.66.0/24

#Dirección privada del PDC en la subred pública
AWS_IP_Servidor=192.168.66.100

#Dirección privada del cliente en la subred pública
AWS_IP_Cliente=192.168.66.200

# Nombre de la clave usada para generar contraseñas
AWS_Nombre_Clave="javier" 

# VARIABLES PDC (NECESARIAS PARA CONFIGURACION PDC)

#Nombre del PDC
Nombre_Servidor="SERVIDOR-PROFE"

#Usuario administrador en el PDC
Admin_Servidor="javier"

#Password del administrador en el PDC (sacar a partir de la clave .pem) [INSERGURO]
Password_Servidor="Naranco.22"

#Nombre DNS del dominio
DNS_Dominio="dominioprofe.local"

#Nombre NETBIOS del dominio. Pondremos el DNS sin el sufijo y en mayúsculas, por covnención
NETBIOS_DOMINIO="DOMINIOPROFE"

#URL Repositorio (no tocar)
URL_REPOSITORIO="https://github.com/javiergpi/SOR.git"

#Script para promocion PDC (no tocar)
SCRIPT_PDC="PromocionaPDC.ps1"

## Crear una VPC (Virtual Private Cloud) con su etiqueta
## La VPC tendrá un bloque IPv4 proporcionado por el usuario y uno IPv6 de AWS

echo "1. Creando VPC..."

AWS_ID_VPC=$(aws ec2 create-vpc \
  --cidr-block $AWS_VPC_CIDR_BLOCK \
  --amazon-provided-ipv6-cidr-block \
  --tag-specifications 'ResourceType=vpc,Tags=[{Key=Name,Value=SOR-vpc}]' \
  --query 'Vpc.{VpcId:VpcId}' \
  --output text)

## Habilitar los nombres DNS para la VPC
aws ec2 modify-vpc-attribute \
  --vpc-id $AWS_ID_VPC \
  --enable-dns-hostnames "{\"Value\":true}"


echo "2. Creando subred pública..."
## Crear una subred publica con su etiqueta
AWS_ID_SubredPublica=$(aws ec2 create-subnet \
  --vpc-id $AWS_ID_VPC --cidr-block $AWS_Subred_CIDR_BLOCK \
  --availability-zone us-east-1a \
  --tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value=SOR-subred-publica}]' \
  --query 'Subnet.{SubnetId:SubnetId}' \
  --output text)

## Habilitar la asignación automática de IPs públicas en la subred pública
aws ec2 modify-subnet-attribute \
  --subnet-id $AWS_ID_SubredPublica \
  --map-public-ip-on-launch

echo "3. Creando y asignando Internet Gateway..."
## Crear un Internet Gateway (Puerta de enlace) con su etiqueta
AWS_ID_InternetGateway=$(aws ec2 create-internet-gateway \
  --tag-specifications 'ResourceType=internet-gateway,Tags=[{Key=Name,Value=SOR-igw}]' \
  --query 'InternetGateway.{InternetGatewayId:InternetGatewayId}' \
  --output text)

## Asignar el Internet gateway a la VPC
aws ec2 attach-internet-gateway \
--vpc-id $AWS_ID_VPC \
--internet-gateway-id $AWS_ID_InternetGateway


echo "4. Creando y asignando tabla de rutas..."
## Crear una tabla de rutas
AWS_ID_TablaRutas=$(aws ec2 create-route-table \
--vpc-id $AWS_ID_VPC \
--query 'RouteTable.{RouteTableId:RouteTableId}' \
--output text )

## Crear la ruta por defecto a la puerta de enlace (Internet Gateway)
aws ec2 create-route \
  --route-table-id $AWS_ID_TablaRutas \
  --destination-cidr-block 0.0.0.0/0 \
  --gateway-id $AWS_ID_InternetGateway

## Asociar la subred pública con la tabla de rutas
AWS_ROUTE_TABLE_ASSOID=$(aws ec2 associate-route-table  \
  --subnet-id $AWS_ID_SubredPublica \
  --route-table-id $AWS_ID_TablaRutas \
  --output text)

## Añadir etiqueta a la ruta por defecto
AWS_DEFAULT_ROUTE_TABLE_ID=$(aws ec2 describe-route-tables \
  --filters "Name=vpc-id,Values=$AWS_ID_VPC" \
  --query 'RouteTables[?Associations[0].Main != `flase`].RouteTableId' \
  --output text) &&
aws ec2 create-tags \
--resources $AWS_DEFAULT_ROUTE_TABLE_ID \
--tags "Key=Name,Value=SOR ruta por defecto"

## Añadir etiquetas a la tabla de rutas
aws ec2 create-tags \
--resources $AWS_ID_TablaRutas \
--tags "Key=Name,Value=SOR-rtb-public"

echo "5. Creando un conjunto de opciones DHCP..."
## Crear un conjunto de opciones DHCP
AWS_DHCP_OPTIONS_ID=$(aws ec2 create-dhcp-options \
    --dhcp-configuration \
        "Key=domain-name-servers,Values=$AWS_IP_Servidor,8.8.8.8" \
        "Key=domain-name,Values=$DNS_Dominio" \
        "Key=netbios-node-type,Values=2" \
    --tag-specifications 'ResourceType=dhcp-options,Tags=[{Key=Name,Value=SOR-DHCP-opciones}]' \
    --query 'DhcpOptions.{DhcpOptionsId:DhcpOptionsId}' \
  --output text)

## Asgignar el conjunto de opciones DHCP al VPC
aws ec2 associate-dhcp-options --dhcp-options-id $AWS_DHCP_OPTIONS_ID --vpc-id $AWS_ID_VPC


###################################

echo "Creando grupo de seguridad..."
## Crear un grupo de seguridad
aws ec2 create-security-group \
  --vpc-id $AWS_ID_VPC \
  --group-name SOR-Windows-SG \
  --description 'SOR-Windows-SG'


AWS_CUSTOM_SECURITY_GROUP_ID=$(aws ec2 describe-security-groups \
  --filters "Name=vpc-id,Values=$AWS_ID_VPC" \
  --query 'SecurityGroups[?GroupName == `SOR-Windows-SG`].GroupId' \
  --output text)

## Abrir los puertos de acceso a la instancia
aws ec2 authorize-security-group-ingress \
  --group-id $AWS_CUSTOM_SECURITY_GROUP_ID \
  --ip-permissions '[{"IpProtocol": "tcp", "FromPort": 3389, "ToPort": 3389, "IpRanges": [{"CidrIp": "0.0.0.0/0", "Description": "Allow RDP"}]}]'


## Añadirle etiqueta al grupo de seguridad
aws ec2 create-tags \
--resources $AWS_CUSTOM_SECURITY_GROUP_ID \
--tags "Key=Name,Value=SOR-Windows-SG" 



## Crear una instancia EC2  (con una imagen Windows Server 2022 Base )

BASEDIR=$(cd $(dirname $0) && pwd)


sed -i "1 i\$SCRIPT_PDC=\"${SCRIPT_PDC}\" \n" "${BASEDIR}/UserDataServidor.txt"
sed -i "1 i\$URL_REPOSITORIO=\"${URL_REPOSITORIO}\" \n" "${BASEDIR}/UserDataServidor.txt"
sed -i "1 i\$NETBIOS_DOMINIO=\"${NETBIOS_DOMINIO}\" \n" "${BASEDIR}/UserDataServidor.txt"
sed -i "1 i\$DNS_DOMINIO=\"${DNS_Dominio}\" \n" "${BASEDIR}/UserDataServidor.txt"
sed -i "1 i\$ADMIN_SERVIDOR=\"${Admin_Servidor}\" \n" "${BASEDIR}/UserDataServidor.txt"
sed -i "1 i\$PASSWORD_SERVIDOR=\"${Password_Servidor}\" \n" "${BASEDIR}/UserDataServidor.txt"
sed -i '1s/^/<powershell> \n /' "${BASEDIR}/UserDataServidor.txt"
sed -i "$ a </powershell> \n"  "${BASEDIR}/UserDataServidor.txt"

echo "Creando instancia SERVIDOR..."
AWS_AMI_ID=ami-07a53499a088e4a8c 
AWS_EC2_INSTANCE_ID=$(aws ec2 run-instances \
  --image-id $AWS_AMI_ID \
  --instance-type t2.medium \
  --key-name $AWS_Nombre_Clave \
  --user-data file://${BASEDIR}/UserDataServidor.txt \
  --monitoring "Enabled=false" \
  --security-group-ids $AWS_CUSTOM_SECURITY_GROUP_ID \
  --subnet-id $AWS_ID_SubredPublica \
  --private-ip-address $AWS_IP_Servidor \
  --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=SOR-SERVIDOR}]' \
  --query 'Instances[0].InstanceId' \
  --output text)

## Mostrar la ip publica de la instancia
 AWS_EC2_INSTANCE_PUBLIC_IP=$(aws ec2 describe-instances \
 --filters "Name=instance-id,Values="$AWS_EC2_INSTANCE_ID \
 --query "Reservations[*].Instances[*].PublicIpAddress" \
 --output=text) &&
 echo "Creada instancia servidor con IP " $AWS_EC2_INSTANCE_PUBLIC_IP

echo "Creando instancia CLIENTE..."
AWS_AMI_ID=ami-07a53499a088e4a8c
AWS_EC2_INSTANCE_ID2=$(aws ec2 run-instances \
  --image-id $AWS_AMI_ID \
  --instance-type t2.small \
  --key-name "$AWS_Nombre_Clave" \
  --monitoring "Enabled=false" \
  --security-group-ids $AWS_CUSTOM_SECURITY_GROUP_ID \
  --subnet-id $AWS_ID_SubredPublica \
  --private-ip-address $AWS_IP_Cliente \
  --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=SOR-CLIENTE}]' \
  --query 'Instances[0].InstanceId' \
  --output text)

## Mostrar la ip publica de la instancia
 AWS_EC2_INSTANCE_PUBLIC_IP=$(aws ec2 describe-instances \
 --filters "Name=instance-id,Values="$AWS_EC2_INSTANCE_ID2 \
 --query "Reservations[*].Instances[*].PublicIpAddress" \
 --output=text) &&
 echo "Creada instancia cliente con IP " $AWS_EC2_INSTANCE_PUBLIC_IP


