###########################################################
#    Termina todas las instancias 
#  Autor: Javier González Pisano 
#  Fecha: 29/10/2022
###########################################################


# Borra todas las instancias
  aws ec2 describe-instances --filters "Name=instance-state-name, Values=running" | \
    jq -r .Reservations[].Instances[].InstanceId | \
      xargs -L 1 -I {} aws ec2 modify-instance-attribute \
        --no-disable-api-termination \
        --instance-id {}
  aws ec2 describe-instances  | \
    jq -r .Reservations[].Instances[].InstanceId | \
      xargs -L 1 -I {} aws ec2 terminate-instances \
        --instance-id {}



#  # get default vpc
#   vpc=$( aws ec2  describe-vpcs  --output text --query 'Vpcs[0].VpcId' )
#   if [ "${vpc}" = "None" ]; then
#     echo "${INDENT}No default vpc found"
#     continue
#   fi
#   echo "${INDENT}Found default vpc ${vpc}"

#   # get internet gateway
#   igw=$(aws ec2 describe-internet-gateways --filter Name=attachment.vpc-id,Values=${vpc}  --output text --query 'InternetGateways[0].InternetGatewayId' )
#   if [ "${igw}" != "None" ]; then
#     echo "${INDENT}Detaching and deleting internet gateway ${igw}"
#     aws ec2 detach-internet-gateway --internet-gateway-id ${igw} --vpc-id ${vpc}
#     aws ec2 delete-internet-gateway --internet-gateway-id ${igw}
#   fi

#   # get subnets
#   subnets=$(aws ec2 describe-subnets --filters Name=vpc-id,Values=${vpc} --output text --query 'Subnets[].SubnetId' )
#   if [ "${subnets}" != "None" ]; then
#     for subnet in ${subnets}; do
#       echo "${INDENT}Deleting subnet ${subnet}"
#       aws ec2 delete-subnet --subnet-id ${subnet}
#     done
#   fi

#   # https://docs.aws.amazon.com/cli/latest/reference/ec2/delete-vpc.html
#   # - You can't delete the main route table
#   # - You can't delete the default network acl
#   # - You can't delete the default security group

#   # delete default vpc
#   echo "${INDENT}Deleting vpc ${vpc}"
#   aws ec2 delete-vpc --vpc-id ${vpc}
