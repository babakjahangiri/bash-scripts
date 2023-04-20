#!/bin/bash

###############################################################################
# The bash file, get all certificates from the given account aws names in the 
# given regions and save them as CSV file in the given S3 bucket
# by Babak Jahangiri (babak.jahangiri@morrisonsplc.co.uk)
###############################################################################

accfile='awsacc.txt'
regionfile='awsregions.txt'
csvfile='certsreport.csv'
s3bucket='mori-nonprod-reports'

#this account was used to save the file into the bucket 
distacc="nonprod-infra"

    
    echo " "
    echo "**************************************************"
    echo "*                                                *"
    echo "*              Listing certificates              *"
    echo "*                                                *"
    echo "**************************************************"
    
    #make the file header
    echo '{ "header":["aws account","region","ARN", "domian name", "Issuer", "Issued At", "Not Before", "Not After", "Status"]}' | jq -r '.header | @csv' > $csvfile
    
    #read account file
    while read acc;
    do     


    if [ -z "$acc" ];then
      echo "can not read an empty account"
    else

        current_aws_access_key=$(aws --profile pp secretsmanager get-secret-value --secret-id "$acc" | jq --raw-output '.SecretString' | jq -r .terraform_access_key)
        current_aws_secret_key=$(aws --profile pp secretsmanager get-secret-value --secret-id "$acc" | jq --raw-output '.SecretString' | jq -r .terraform_secret_key)
        
        #current_aws_default_region="$region"

        ## Set AWS pofile On the fly
        #aws configure set aws_access_key_id $current_aws_access_key; aws configure set aws_secret_access_key $current_aws_secret_key; aws configure set default.region $current_aws_default_region
        aws configure set aws_access_key_id $current_aws_access_key; aws configure set aws_secret_access_key $current_aws_secret_key;

        echo " "
        echo "- - - - - - - - - - - - - - - - - - - -"   
        echo "fetching certificates in $acc ... "
        echo " "   

        #Change The Region
        while read region;
        do
            aws configure set default.region $region

            echo " "
            echo "> $region :"


            #now I comment this part maybe we want to check each certificate by getting the ARN
            ARNs=$(aws acm list-certificates | jq -c -r '(.CertificateSummaryList[].CertificateArn)')
            echo $ARNs

            #Go trough each ARN and get each certificate info with describe-certificate
            for arn in ${ARNs[@]}
            do : 
          
            certdata=$(aws acm describe-certificate --certificate-arn $arn | jq -r '.[] |  ["'$acc'"] + ["'$region'"] + ["'$arn'"] + [.DomainName, .Issuer, .IssuedAt, .NotBefore, .NotAfter, .Status] | @csv')

            echo "saved to csvfile .."
            echo $certdata >> $csvfile

            done

        done < $regionfile 
    fi
  
    done < $accfile


    echo "Saving the CSV file to the s3://$s3bucket ..."


   current_aws_access_key=$(aws --profile pp secretsmanager get-secret-value --secret-id "$distacc" | jq --raw-output '.SecretString' | jq -r .terraform_access_key)
   current_aws_secret_key=$(aws --profile pp secretsmanager get-secret-value --secret-id "$distacc" | jq --raw-output '.SecretString' | jq -r .terraform_secret_key)
   aws configure set aws_access_key_id $current_aws_access_key; aws configure set aws_secret_access_key $current_aws_secret_key;
   
   aws s3 cp $csvfile s3://$s3bucket/certificates-list.csv

