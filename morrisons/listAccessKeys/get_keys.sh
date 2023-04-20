#!/bin/bash

###############################################################################
# The script get all access keys for all sndicsovery users across all 
# aws accounts and save the list CSV file in the given S3 bucket
# by Babak Jahangiri (babak.jahangiri@morrisonsplc.co.uk)
#################################################################################

accfile='awsacc.txt'
csvfile='sndicsovery_keys.csv'
s3bucket='mori-nonprod-reports'

#region='eu-west-1'
#this account was used to save the file into the bucket
distacc='nonprod-infra'

    echo '**************************************************'                                             
    echo ' Listing All sndicsovery users accesss keys       '         
    echo '**************************************************'

    #make the file header & clear file
    #echo '{ "header":[ "AWS account", "Access Key1", "Access Key2", "InstanceId", "InstanceType", "ImageId", "Private IP", "Private DNS", "Public IP", "Public DNS", "Subnet Id", "VPC Id", "Name", "Status"]}' | jq -r ' .header | @csv' > $csvfile 
    echo '{ "header":[ "AWS account", "User Name", "Access Key1", "Access Key2]}' | jq -r ' .header | @csv' > $csvfile 
 
     # go to all given aws accounts
     while read acc;
     do

        if [ -z "$acc" ];then
            echo "can not read an empty account"
        else
          
            current_aws_access_key=$(aws --profile pp secretsmanager get-secret-value --secret-id "$acc" | jq --raw-output '.SecretString' | jq -r .terraform_access_key)
            current_aws_secret_key=$(aws --profile pp secretsmanager get-secret-value --secret-id "$acc" | jq --raw-output '.SecretString' | jq -r .terraform_secret_key)
            echo " "
            echo "Logging into : " $acc

            ## Set AWS pofile On the fly
            aws configure set aws_access_key_id $current_aws_access_key; aws configure set aws_secret_access_key $current_aws_secret_key;
                
            #no region settings is needed
            #aws configure set default.region $region
            
            user=$(aws iam get-user --user-name sndiscovery)
            echo user
            # accesskeyslist=$(aws iam list-access-keys --user-name sndiscovery)

           # echo $accesskeyslist
                    # accesskeyslist=$(aws ec2 describe-instances --query "Reservations[*].Instances[*].{InstanceId:InstanceId,
                    # InstanceType:InstanceType,ImageId:ImageId,PublicIPAddress:PublicIpAddress,PublicDnsName:PublicDnsName,
                    # PrivateIpAddress:PrivateIpAddress,PrivateDnsName:PrivateDnsName,SubnetId:SubnetId,VpcId:VpcId,
                    # Name:Tags[?Key=='Name']|[0].Value,Status:State.Name}")

                    # l=$(jq ' . | length' <<< $instanceslist)

                    # echo "found $l instance(s) in $region"

                        #  for ((i=0 ; i<=$(($l - 1)) ; i++)); do
                        #  echo $instanceslist | jq -r '.['$i'] | .[] | ["'$acc'" , "'$region'"] + [.InstanceId, .InstanceType, .ImageId, .PublicIPAddress, .PublicDnsName, .PrivateIpAddress, .PrivateDnsName, .SubnetId, .VpcId, .Name, .Status] | @csv ' >> $csvfile
                        #  done
          fi 

     done < $accfile

    # echo "Saving the Ec2 Reports CSV file to the S3 ..."
  
    # dId=$(date +%Y-%m-%d_%H-%M)

    # current_aws_access_key=$(aws --profile pp secretsmanager get-secret-value --secret-id "$distacc" | jq --raw-output '.SecretString' | jq -r .terraform_access_key)
    # current_aws_secret_key=$(aws --profile pp secretsmanager get-secret-value --secret-id "$distacc" | jq --raw-output '.SecretString' | jq -r .terraform_secret_key)
    # aws configure set aws_access_key_id $current_aws_access_key; aws configure set aws_secret_access_key $current_aws_secret_key;
   
     #aws s3 cp $csvfile s3://$s3bucket/ec2-reports-$dId.csv

     #echo "all data saved to ec2-reports-$dId.csv in the $s3bucket bucket in $distacc account."