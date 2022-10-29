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
 done



#  vpc=$(aws ec2 --region ${region} \
#     describe-vpcs --filter Name=isDefault,Values=true \
#     | jq -r .Vpcs[0].VpcId)
#   if [ "${vpc}" = "null" ]; then
#     echo "No default vpc found"
#     continue
#   fi
#   echo "Found default vpc ${vpc}"