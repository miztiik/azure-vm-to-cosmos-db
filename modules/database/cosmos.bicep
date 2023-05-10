
param deploymentParams object
param tags object

param cosmosDbParams object

param appConfigName string



// Create CosmosDB Account
resource r_cosmosDbAccount 'Microsoft.DocumentDB/databaseAccounts@2022-08-15' = {
  name: '${cosmosDbParams.cosmosDbNamePrefix}-db-account-${deploymentParams.global_uniqueness}'
  location: deploymentParams.location
  kind: 'GlobalDocumentDB'
  tags: tags
  properties: {
    publicNetworkAccess: 'Enabled'
    databaseAccountOfferType: 'Standard'
    enableAutomaticFailover: true
    consistencyPolicy: {
      defaultConsistencyLevel: 'Session'
    }
    locations: [
      {
        locationName: deploymentParams.location
        isZoneRedundant: false
      }
    ]
    
    backupPolicy: {
      type: 'Continuous'
    }
    capabilities: [
      {
        name: 'EnableServerless'
      }
    ]
  }
}

// Create CosmosDB Database
var databaseName = '${cosmosDbParams.cosmosDbNamePrefix}-db-${deploymentParams.global_uniqueness}'

resource r_cosmosDb 'Microsoft.DocumentDB/databaseAccounts/sqlDatabases@2021-06-15' = {
  parent: r_cosmosDbAccount
  name: databaseName
  properties: {
    resource: {
      id: databaseName
    }
  }
}

var containerName = '${cosmosDbParams.cosmosDbNamePrefix}-container-${deploymentParams.global_uniqueness}'

// Create CosmosDB Container
resource r_cosmosDbContainer 'Microsoft.DocumentDB/databaseAccounts/sqlDatabases/containers@2022-08-15' = {
  name: containerName
  parent: r_cosmosDb
  properties: {
    resource: {
      id: containerName
      partitionKey: {
        paths: [
          '/id'
        ]
        kind: 'Hash'
      }
      indexingPolicy: {
        indexingMode: 'consistent'
        includedPaths: [
          {
            path: '/*'
          }
        ]
        excludedPaths: [
          {
            path: '/_etag/?'
          }
        ] 
      }
      conflictResolutionPolicy: {
        mode: 'LastWriterWins'
        conflictResolutionPath: '/_ts'
      }
    }
  }
}


// Store the storage account name and primary endpoint in the App Config
resource r_appConfig 'Microsoft.AppConfiguration/configurationStores@2023-03-01' existing = {
  name: appConfigName
}

resource r_db_accnt_Kv 'Microsoft.AppConfiguration/configurationStores/keyValues@2023-03-01' = {
  parent: r_appConfig
  name: 'COSMOS_DB_ACCOUNT'
  properties: {
    value: r_cosmosDbAccount.name
    contentType: 'text/plain'
    tags: tags
  }
}

resource r_db_name_Kv 'Microsoft.AppConfiguration/configurationStores/keyValues@2023-03-01' = {
  parent: r_appConfig
  name: 'COSMOS_DB_NAME'
  properties: {
    value: r_cosmosDb.name
    contentType: 'text/plain'
    tags: tags
  }
}

resource r_db_container_name_Kv 'Microsoft.AppConfiguration/configurationStores/keyValues@2023-03-01' = {
  parent: r_appConfig
  name: 'COSMOS_DB_CONTAINER_NAME'
  properties: {
    value: r_cosmosDbContainer.name
    contentType: 'text/plain'
    tags: tags
  }
}


// Outputs
output cosmosDbAccountName string = r_cosmosDbAccount.name
output cosmosDbName string = r_cosmosDb.name
output cosmosDbContainerName string = r_cosmosDbContainer.name

