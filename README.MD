# Persist Data to Cosmos DB from Azure VM Using User Managed Identity

Developers at Mystique Unicorn are using priveleged identity to persist data to Cosmos DB. They would like to use User Managed Identity to persist data to Cosmos DB. Can you help them?


## 🎯 Solution

Azure offers user managed identity to be used with azure and non azure(aka on prem) resources. In this article, we will explore how to use user managed identity to persist data to Cosmos DB from Azure VM.

![Miztiik Automaton: Persist Data to Cosmos DB from Azure VM Using User Managed Identity](images/miztiik_automation_persist_data_to_cosmos_db_from_azure_vm_architecture_001.png)

1. ## 🧰 Prerequisites

   This demo, instructions, scripts and bicep template is designed to be run in `westeurope`. With few or no modifications you can try it out in other regions as well(_Not covered here_).

   - 🛠 Azure CLI Installed & Configured - [Get help here](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli)
   - 🛠 Bicep Installed & Configured - [Get help here](https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/install)
   - 🛠 VS Code & Bicep Extenstions - [Get help here](https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/install#vs-code-and-bicep-extension)

1. ## ⚙️ Setting up the environment

   - Get the application code

     ```bash
     https://github.com/miztiik/azure-vm-to-cosmos-db
     cd azure-vm-to-cosmos-db
     ```

1. ## 🚀 Prepare the environment

   Let check you have Azure Cli working with 

    ```bash
      # You should have azure cli preinstalled
      az account show
    ```

    You should see an output like this,

   ```json
    {
      "environmentName": "AzureCloud",
      "homeTenantId": "16b30820b6d3",
      "id": "1ac6fdbff37cd9e3",
      "isDefault": true,
      "managedByTenants": [],
      "name": "YOUR-SUBS-NAME",
      "state": "Enabled",
      "tenantId": "16b30820b6d3",
      "user": {
        "name": "miztiik@",
        "type": "user"
      }
    }
   ```

1. ## 🚀 Deploying the application

   - **Stack: Main Bicep**
     The params required for the modules are in `params.json`. Do modify them to suit your need.(_Especially the `adminPassword.secureString` for the VM. You are strongly encouraged to Just-In-Time access<sup>[10]</sup> or use SSH key instead of password based authentication_). The helper deployment script `deploy.sh` will deploy the `main.bicep` file. This will create the following resoureces
     - Resource Group(RG)
     - VNet, Subnet & Virtual Machine
     - Virtual Machine(Ubuntu)
        - Bootstrapped with custom libs using `userData` script.
     - User Managed Identity
        - Monitoring Metrics Publisher role assigned to the 
        - Permission to read and write data to Cosmos DB
        - Identity attached to the VM
       
     **Note** - I hacked the template from another repo of mine, so you will see some unused resources(log analytics workspace/queues etc.,). _You can safely ignore them, But do remember to clean up your Resource Group to avoid unnecessary costs._

      ```bash
      sh deploy.sh
      ```

     After successfully deploying the stack, Check the `Resource Groups/Deployments` section for the resources.


1. ## 🔬 Testing the solution

   - **Connect to the VM**

      The Ubuntu vm _should_ be bootstrapped using `userData` to install python3, git and also Azure Idenity initialized.
      - Connect to the using using Just In Time Access<sup>[10]</sup>.
            - The bootstrap code should have clone this repo to `/var/azure-vm-to-cosmos-db`, If not clone the repo.
      - The `az_producer_for_cosmosdb.py` script expects the following environment variable. _In production, you probabaly want to store these in App configuration_
         - `COSMOS_DB_ACCOUNT` - Name of the cosmos DB Account
         - `COSMOS_DB_NAME` - Name of the cosmos DB
         - `COSMOS_DB_CONTAINER_NAME` - Name of the cosmos DB Container


    - **Initiate Event Generation & Ingestion**

      ```bash
      # ssh miztiik@publicIP
      # cd /var/
      # git clone https://github.com/miztiik/azure-vm-to-cosmos-db
      # cd azure-vm-to-cosmos-db

      # If pre-reqs have not been installed, run the bootstrap script manually
      # bash /var/azure-vm-to-cosmos-db/modules/vm/bootstrap_scripts/deploy_app.sh
      
      export COSMOS_DB_ACCOUNT="store-backend-db-account-002"
      export COSMOS_DB_NAME="store-backend-db-002"
      export COSMOS_DB_CONTAINER_NAME="store-backend-container-002"
      python3 /var/azure-vm-to-cosmos-db/app/az_producer_for_cosmosdb.py &
      ```

        If everything goes all right, you should see messages like below. You can also check the logs at `/var/log/miztiik-store-events-2023-04-17.json`

        ```bash
        INFO:root:{
            "request_id": "80745806-7378-439e-9707-12d485236d54",
            "store_id": 6,
            "store_fqdn": "m-web-srv-011.internal.cloudapp.net",
            "store_ip": "10.0.0.4",
            "cust_id": 103,
            "category": "Furniture",
            "sku": 95894,
            "price": 43.43,
            "qty": 32,
            "discount": 4.1,
            "gift_wrap": false,
            "variant": "black",
            "priority_shipping": true,
            "ts": "2023-04-17T12:56:35.868661",
            "contact_me": "github.com/miztiik",
            "is_return": true
        }
        INFO:root:Message added to store-events-q-011 successfully
        ```

        Upon successful execution, You should receive `200` response code from the endpoint. If you navigate to the portal, You should see the metrics in the dashboard..

      ![Miztiik Automaton: Custom Metrics To Azure Monitor](images/miztiik_automation_custom_metrics_to_azure_monitor_architecture_002.png)
  
     
1. ## 📒 Conclusion

    Here we have demonstrated how to push custom metrics to the REST API using User Managed Identity.
  

1. ## 🧹 CleanUp

If you want to destroy all the resources created by the stack, Execute the below command to delete the stack, or _you can delete the stack from console as well_

- Resources created during [Deploying The Application](#-deploying-the-application)
- _Any other custom resources, you have created for this demo_

```bash
# Delete from resource group
az group delete --name Miztiik_Enterprises_xxx --yes
# Follow any on-screen prompt
```

This is not an exhaustive list, please carry out other necessary steps as maybe applicable to your needs.

## 📌 Who is using this

This repository aims to show how to Bicep to new developers, Solution Architects & Ops Engineers in Azure.

### 💡 Help/Suggestions or 🐛 Bugs

Thank you for your interest in contributing to our project. Whether it is a bug report, new feature, correction, or additional documentation or solutions, we greatly value feedback and contributions from our community. [Start here](/issues)

### 👋 Buy me a coffee

[![ko-fi](https://www.ko-fi.com/img/githubbutton_sm.svg)](https://ko-fi.com/Q5Q41QDGK) Buy me a [coffee ☕][900].

### 📚 References


1. [Azure Docs: Azure Custom Metrics][1]
1. [Miztiik Blog: Custom Metrics to Azure Monitor - REST API Endpoint][2]
1. [Miztiik Blog: Send custom metrics from Vm to Azure Monitor using AMA][3]
1. [Azure Docs: Register App to get Auth Tokens from AAD][3]
1. [Azure Docs: Custom Metrics AuthN - Managed Identity & Service Principal][4]
1. [Azure Docs: Get Access Token From VM using Managed Identity][5]
1. [Azure Docs: Sample Custom Metric][6]
1. [Azure Docs: Custom Metric Definition][7]
1. [Azure Docs: Platform and custom metrics Retention][8]
1. [Azure Docs: BuiltIn Roles - Monitoring Metrics Publisher][8]
1. [Azure Docs: Just In Time Access][10]

### 🏷️ Metadata

![miztiik-success-green](https://img.shields.io/badge/Miztiik:Automation:Level-100-green)

**Level**: 100

[1]: https://learn.microsoft.com/en-us/azure/azure-monitor/essentials/metrics-custom-overview
[2]: https://github.com/miztiik/azure-vm-to-cosmos-db
[3]: https://github.com/miztiik/send-vm-logs-to-azure-monitor
[4]: https://learn.microsoft.com/en-us/azure/azure-monitor/essentials/metrics-custom-overview#authentication
[5]: https://learn.microsoft.com/en-us/azure/active-directory/managed-identities-azure-resources/how-to-use-vm-token#get-a-token-using-curl
[6]: https://learn.microsoft.com/en-us/azure/azure-monitor/essentials/metrics-custom-overview#sample-custom-metric-publication
[7]: https://learn.microsoft.com/en-us/azure/azure-monitor/essentials/metrics-custom-overview#how-to-send-custom-metrics
[8]: https://learn.microsoft.com/en-us/azure/azure-monitor/essentials/data-platform-metrics#platform-and-custom-metrics
[9]: https://learn.microsoft.com/en-us/azure/role-based-access-control/built-in-roles#monitoring-metrics-publisher


[10]: https://learn.microsoft.com/en-us/azure/defender-for-cloud/just-in-time-access-usage

[100]: https://www.udemy.com/course/aws-cloud-security/?referralCode=B7F1B6C78B45ADAF77A9
[101]: https://www.udemy.com/course/aws-cloud-security-proactive-way/?referralCode=71DC542AD4481309A441
[102]: https://www.udemy.com/course/aws-cloud-development-kit-from-beginner-to-professional/?referralCode=E15D7FB64E417C547579
[103]: https://www.udemy.com/course/aws-cloudformation-basics?referralCode=93AD3B1530BC871093D6
[899]: https://www.udemy.com/user/n-kumar/
[900]: https://ko-fi.com/miztiik
[901]: https://ko-fi.com/Q5Q41QDGK