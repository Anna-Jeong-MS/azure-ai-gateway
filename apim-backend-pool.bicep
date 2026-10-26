targetScope = 'resourceGroup'

@description('Existing API Management service name.')
param apimName string

@description('Primary Language Model API backend URL, including the deployment path.')
param primaryBackendUrl string

@description('Secondary Azure OpenAI backend URL, including the deployment path.')
param secondaryBackendUrl string

param primaryLocation string = 'uaenorth'
param secondaryLocation string = 'eastus2'

resource apim 'Microsoft.ApiManagement/service@2024-05-01' existing = {
  name: apimName
}

resource primaryBackend 'Microsoft.ApiManagement/service/backends@2025-09-01-preview' = {
  parent: apim
  name: 'gpt-terra-llm-openai-endpoint'
  properties: {
    title: 'GPT 5.6 Terra - UAE North (Language Model API)'
    description: 'Language Model API backend reused as priority 1.'
    type: 'Single'
    protocol: 'http'
    azureRegion: primaryLocation
    url: primaryBackendUrl
    circuitBreaker: {
      rules: [
        {
          name: 'openai-429'
          acceptRetryAfter: true
          tripDuration: 'PT1M'
          failureCondition: {
            count: 1
            interval: 'PT1M'
            statusCodeRanges: [
              {
                min: 429
                max: 429
              }
            ]
          }
        }
      ]
    }
  }
}

resource secondaryBackend 'Microsoft.ApiManagement/service/backends@2025-09-01-preview' = {
  parent: apim
  name: 'gpt-terra-eastus2'
  properties: {
    title: 'GPT 5.6 Terra - East US 2'
    description: 'Priority 2 Azure OpenAI spillover backend.'
    type: 'Single'
    protocol: 'http'
    azureRegion: secondaryLocation
    url: secondaryBackendUrl
    circuitBreaker: {
      rules: [
        {
          name: 'openai-429'
          acceptRetryAfter: true
          tripDuration: 'PT1M'
          failureCondition: {
            count: 1
            interval: 'PT1M'
            statusCodeRanges: [
              {
                min: 429
                max: 429
              }
            ]
          }
        }
      ]
    }
  }
}

resource backendPool 'Microsoft.ApiManagement/service/backends@2025-09-01-preview' = {
  parent: apim
  name: 'gpt-terra-pool'
  properties: {
    title: 'GPT 5.6 Terra priority pool'
    description: 'UAE North primary with East US 2 spillover.'
    type: 'Pool'
    pool: {
      failureResponse: {
        statusCode: 503
      }
      services: [
        {
          id: primaryBackend.id
          priority: 1
          weight: 100
        }
        {
          id: secondaryBackend.id
          priority: 2
          weight: 100
        }
      ]
    }
  }
}

output backendPoolId string = backendPool.id
output backendPoolName string = backendPool.name
