# VARIABLES
    # Credentials variables
    $terraform_azure_arm_client_id            = $env:terraform_creds_azure_arm_client_id
    $terraform_azure_arm_client_secret        = $env:terraform_creds_azure_arm_client_secret
    $terraform_azure_arm_tenant_id            = $env:terraform_creds_azure_arm_tenant_id
    $terraform_azure_arm_uat_subscription_id  = $env:terraform_creds_azure_arm_uat_subscription_id
    $terraform_azure_arm_prod_subscription_id = $env:terraform_creds_azure_arm_prod_subscription_id

    # Backend variables
    $terraform_azure_access_key               = $env:terraform_backend_azure_access_key
    $terraform_azure_container_name           = $env:terraform_backend_azure_container_name
    $terraform_azure_key                      = $env:terraform_backend_azure_key
    $terraform_azure_resource_group_name      = $env:terraform_backend_azure_resource_group_name
    $terraform_azure_storage_account_name     = $env:terraform_backend_azure_storage_account_name

# Stage 1 - Report Terraform version & declare vars
    write-host "Stage 1 - Report Terraform version & declare vars"
    & $psscriptroot\terraform.exe version

# Stage 2 - Create terraform backend file
    write-host "Stage 2 - Create terraform backend file"

    $content_location = "$psscriptroot/live/uat/backend.tf"
    New-Item -ItemType File $content_location -verbose
    Add-Content -Path $content_location ""
    Add-Content -Path $content_location "terraform {"
    Add-Content -Path $content_location "  backend `"azure`" {"
    Add-Content -Path $content_location "    access_key           = `"$terraform_azure_access_key`""
    Add-Content -Path $content_location "    container_name       = `"$terraform_azure_container_name`""
    Add-Content -Path $content_location "    key                  = `"$terraform_azure_key`""
    Add-Content -Path $content_location "    resource_group_name  = `"$terraform_azure_resource_group_name`""
    Add-Content -Path $content_location "    storage_account_name = `"$terraform_azure_storage_account_name`""
    Add-Content -Path $content_location "  }"
    Add-Content -Path $content_location "}"
    write-host "Created backend.tf file"
    #Get-Content $content_location 

# Stage 3 - Create credentials file
    write-host "Stage 3 - Create credentials file"

    $content_location = "$psscriptroot/credentials.tfvars"
    New-Item -ItemType File $content_location -verbose
    Add-Content -Path $content_location "azure-subscription_id-prod  = `"$terraform_azure_arm_prod_subscription_id`""
    Add-Content -Path $content_location "azure-subscription_id-uat   = `"$terraform_azure_arm_uat_subscription_id`""
    Add-Content -Path $content_location "azure-client_id             = `"$terraform_azure_arm_client_id`""
    Add-Content -Path $content_location "azure-client_secret         = `"$terraform_azure_arm_client_secret`""
    Add-Content -Path $content_location "azure-tenant_id             = `"$terraform_azure_arm_tenant_id`""
    write-host "Created credentials.tfvars file"
    #Get-Content $content_location

    ls $psscriptroot ; ls "$psscriptroot/live/uat"

    cd "./live/uat" # -verbose

# Stage 4 - Perform your first terraform plan
    write-host "Stage 4 - Perform your first terraform plan"

    $get  = & $psscriptroot\terraform.exe get
    $init = & $psscriptroot\terraform.exe init

    & $psscriptroot\terraform.exe plan -var-file="../../credentials.tfvars"
    $plan = & $psscriptroot\terraform.exe plan -var-file="../../credentials.tfvars"

    $ErrorActionPreference= 'Continue'
    $output = $plan | select -Last 1

        # If condition
        if ($output -match "doesn't need to do anything"){ $return = 0 }
        elseif ($output -match "to change")              { $return = 2 }
        else                                             { $return = 1 }
        # Second If condition based on return code 
        if ($return -eq "0"){
            write-host "No changes to state - Exiting 0"
            write-host $output
            $exit_code = 0
        }
        elseif ($return -eq "1"){
            write-host "exiting 1 - failed"
            write-host $plan
            $exit_code = 1 
        }
        else {
            write-host "Changes to be made to state - Exiting 2"
            write-host $output
            $exit_code = 0
        }

# Stage 4 - Cleanup of plan files
    write-host "Stage 4 - Cleanup of plan files"

    remove-item backend.tf -verbose
    cd ../../ -verbose
    remove-item credentials.tfvars -verbose

    exit $exit_code