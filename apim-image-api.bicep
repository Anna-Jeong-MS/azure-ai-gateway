targetScope = 'resourceGroup'

@description('Existing API Management service name.')
param apimName string

@description('Primary image backend URL, including the future deployment path.')
param primaryBackendUrl string

@description('Secondary image backend URL, including the future deployment path.')
param secondaryBackendUrl string

module imageBackends './apim-image-backend-pool.bicep' = {
  name: 'image-backend-pool'
  params: {
    apimName: apimName
    primaryBackendUrl: primaryBackendUrl
    secondaryBackendUrl: secondaryBackendUrl
  }
}

resource apim 'Microsoft.ApiManagement/service@2024-05-01' existing = {
  name: apimName
}

resource imageApi 'Microsoft.ApiManagement/service/apis@2024-05-01' = {
  parent: apim
  name: 'gpt-image-proxy'
  properties: {
    displayName: 'GPT Image 2.5 Flare Proxy API'
    description: 'Image generation proxy configuration. The image model deployment is intentionally omitted.'
    path: 'images'
    protocols: [
      'https'
    ]
    subscriptionRequired: true
  }
}

resource imageGenerations 'Microsoft.ApiManagement/service/apis/operations@2024-05-01' = {
  parent: imageApi
  name: 'create-image'
  properties: {
    displayName: 'Create image'
    description: 'Generate an image from a text prompt.'
    method: 'POST'
    urlTemplate: '/generations'
    templateParameters: []
    responses: [
      {
        statusCode: 200
      }
      {
        statusCode: 429
      }
      {
        statusCode: 503
      }
    ]
  }
}

resource imageApiPolicy 'Microsoft.ApiManagement/service/apis/policies@2024-05-01' = {
  parent: imageApi
  name: 'policy'
  properties: {
    format: 'rawxml'
    value: loadTextContent('apim-image-policy.xml')
  }
  dependsOn: [
    imageBackends
    imageGenerations
  ]
}

output imageApiUrl string = '${apim.properties.gatewayUrl}/images'
output imageOperationPath string = '/generations'
output imageBackendPoolName string = imageBackends.outputs.backendPoolName
