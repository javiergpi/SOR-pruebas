###########################################################
#    Termina todas las instancias 
#  Autor: Javier González Pisano 
#  Fecha: 29/10/2022
###########################################################


  aws ec2 describe-instances | \
    jq -r .Reservations[].Instances[].InstanceId | \
      xargs -L 1 -I {} aws ec2 modify-instance-attribute \
        --no-disable-api-termination \
        --instance-id {}
  aws ec2 describe-instances  | \
    jq -r .Reservations[].Instances[].InstanceId | \
      xargs -L 1 -I {} aws ec2 terminate-instances \
       \
        --instance-id {}
done