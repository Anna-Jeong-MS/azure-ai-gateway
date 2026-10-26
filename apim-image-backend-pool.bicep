targetScope = 'resourceGroup'

@description('Existing API Management service name.')
param apimName string

@description('Primary image backend URL, including the future deployment path.')
param primaryBackendUrl string

@description('Secondary image backend URL, including the future deployment path.')
param secondaryBackendUrl string

resource apim 'Microsoft.ApiManagement/service@2024-05-01' existing = {
  name: apimName
}

resource primaryBackend 'Microsoft.ApiManagement/service/backends@2025-09-01-preview' = {
  parent: apim
  name: 'gpt-image-primary'
  properties: {
    title: 'GPT Image 2.5 Flare - Primary placeholder'
    description: 'Priority 1 image backend. Replace the placeholder URL after model deployment.'
    type: 'Single'
    protocol: 'http'
    url: primaryBackendUrl
    circuitBreaker: {
      rules: [
        {
          name: 'image-429'
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
  name: 'gpt-image-secondary'
  properties: {
    title: 'GPT Image 2.5 Flare - Secondary placeholder'
    description: 'Priority 2 image backend. Replace the placeholder URL after model deployment.'
    type: 'Single'
    protocol: 'http'
    url: secondaryBackendUrl
    circuitBreaker: {
      rules: [
        {
          name: 'image-429'
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

resource imageBackendPool 'Microsoft.ApiManagement/service/backends@2025-09-01-preview' = {
  parent: apim
  name: 'gpt-image-pool'
  properties: {
    title: 'GPT Image 2.5 Flare priority pool'
    description: 'Configuration-only image backend pool with primary and secondary placeholders.'
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

output backendPoolId string = imageBackendPool.id
output backendPoolName string = imageBackendPool.name
