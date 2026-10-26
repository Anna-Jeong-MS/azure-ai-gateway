targetScope = 'resourceGroup'

@description('Globally unique API Management service name.')
param apimName string

@description('Globally unique Azure OpenAI account name in UAE North.')
param primaryOpenAIName string

@description('Globally unique Azure OpenAI account name in East US 2.')
param secondaryOpenAIName string

@description('API Management publisher email.')
param publisherEmail string

param publisherName string = 'Azure AI Gateway'
param apimLocation string = 'eastus2'
param primaryLocation string = 'uaenorth'
param secondaryLocation string = 'eastus2'
param modelName string = 'gpt-5.6-terra'
param modelVersion string = '2026-07-09'
param deploymentName string = 'gpt-5-6-terra'
param modelCapacity int = 1
param imagePrimaryBackendUrl string = 'https://replace-with-image-primary.example.com/openai/deployments/gpt-image-2-5-flare'
param imageSecondaryBackendUrl string = 'https://replace-with-image-secondary.example.com/openai/deployments/gpt-image-2-5-flare'

var openAIUserRoleDefinitionId = subscriptionResourceId(
  'Microsoft.Authorization/roleDefinitions',
  '5e0bd9bd-7b93-4f28-af87-19fc36ad61bd'
)

resource primaryOpenAI 'Microsoft.CognitiveServices/accounts@2025-06-01' = {
  name: primaryOpenAIName
  location: primaryLocation
  kind: 'OpenAI'
  sku: {
    name: 'S0'
  }
  properties: {
    customSubDomainName: primaryOpenAIName
    disableLocalAuth: true
    publicNetworkAccess: 'Enabled'
  }
}

resource secondaryOpenAI 'Microsoft.CognitiveServices/accounts@2025-06-01' = {
  name: secondaryOpenAIName
  location: secondaryLocation
  kind: 'OpenAI'
  sku: {
    name: 'S0'
  }
  properties: {
    customSubDomainName: secondaryOpenAIName
    disableLocalAuth: true
    publicNetworkAccess: 'Enabled'
  }
}

resource primaryModel 'Microsoft.CognitiveServices/accounts/deployments@2025-06-01' = {
  parent: primaryOpenAI
  name: deploymentName
  sku: {
    name: 'GlobalStandard'
    capacity: modelCapacity
  }
  properties: {
    model: {
      format: 'OpenAI'
      name: modelName
      version: modelVersion
    }
    versionUpgradeOption: 'NoAutoUpgrade'
  }
}

resource secondaryModel 'Microsoft.CognitiveServices/accounts/deployments@2025-06-01' = {
  parent: secondaryOpenAI
  name: deploymentName
  sku: {
    name: 'GlobalStandard'
    capacity: modelCapacity
  }
  properties: {
    model: {
      format: 'OpenAI'
      name: modelName
      version: modelVersion
    }
    versionUpgradeOption: 'NoAutoUpgrade'
  }
}

resource apim 'Microsoft.ApiManagement/service@2024-05-01' = {
  name: apimName
  location: apimLocation
  sku: {
    name: 'StandardV2'
    capacity: 1
  }
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    publisherEmail: publisherEmail
    publisherName: publisherName
    publicNetworkAccess: 'Enabled'
    virtualNetworkType: 'None'
  }
}

resource primaryOpenAIRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(primaryOpenAI.id, apim.id, openAIUserRoleDefinitionId)
  scope: primaryOpenAI
  properties: {
    principalId: apim.identity.principalId
    principalType: 'ServicePrincipal'
    roleDefinitionId: openAIUserRoleDefinitionId
  }
}

resource secondaryOpenAIRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(secondaryOpenAI.id, apim.id, openAIUserRoleDefinitionId)
  scope: secondaryOpenAI
  properties: {
    principalId: apim.identity.principalId
    principalType: 'ServicePrincipal'
    roleDefinitionId: openAIUserRoleDefinitionId
  }
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
    url: '${primaryOpenAI.properties.endpoint}openai/deployments/${deploymentName}'
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
    url: '${secondaryOpenAI.properties.endpoint}openai/deployments/${deploymentName}'
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

resource languageModelApi 'Microsoft.ApiManagement/service/apis@2024-05-01' = {
  parent: apim
  name: 'gpt-terra-llm'
  properties: {
    displayName: 'GPT 5.6 Terra Language Model API'
    description: 'OpenAI-compatible multi-region GPT 5.6 Terra AI Gateway.'
    path: 'ai'
    protocols: [
      'https'
    ]
    subscriptionRequired: true
    termsOfServiceUrl: 'https://openai.com/policies/terms-of-use'
  }
}

resource chatCompletions 'Microsoft.ApiManagement/service/apis/operations@2024-05-01' = {
  parent: languageModelApi
  name: 'createChatCompletion'
  properties: {
    displayName: 'Creates a model response for the given chat conversation'
    method: 'POST'
    urlTemplate: '/chat/completions'
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

resource languageModelApiPolicy 'Microsoft.ApiManagement/service/apis/policies@2024-05-01' = {
  parent: languageModelApi
  name: 'policy'
  properties: {
    format: 'rawxml'
    value: loadTextContent('apim-policy.xml')
  }
  dependsOn: [
    backendPool
    primaryOpenAIRole
    secondaryOpenAIRole
    primaryModel
    secondaryModel
    chatCompletions
  ]
}

resource imagePrimaryBackend 'Microsoft.ApiManagement/service/backends@2025-09-01-preview' = {
  parent: apim
  name: 'gpt-image-primary'
  properties: {
    title: 'GPT Image 2.5 Flare - Primary placeholder'
    description: 'Priority 1 image backend. Replace the placeholder URL after model deployment.'
    type: 'Single'
    protocol: 'http'
    url: imagePrimaryBackendUrl
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

resource imageSecondaryBackend 'Microsoft.ApiManagement/service/backends@2025-09-01-preview' = {
  parent: apim
  name: 'gpt-image-secondary'
  properties: {
    title: 'GPT Image 2.5 Flare - Secondary placeholder'
    description: 'Priority 2 image backend. Replace the placeholder URL after model deployment.'
    type: 'Single'
    protocol: 'http'
    url: imageSecondaryBackendUrl
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
          id: imagePrimaryBackend.id
          priority: 1
          weight: 100
        }
        {
          id: imageSecondaryBackend.id
          priority: 2
          weight: 100
        }
      ]
    }
  }
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
    imageBackendPool
    imageGenerations
  ]
}

output apimGatewayUrl string = apim.properties.gatewayUrl
output languageModelApiBaseUrl string = '${apim.properties.gatewayUrl}/ai'
output chatCompletionsPath string = '/chat/completions'
output imageApiBaseUrl string = '${apim.properties.gatewayUrl}/images'
output imageGenerationsPath string = '/generations'
output primaryOpenAIEndpoint string = primaryOpenAI.properties.endpoint
output secondaryOpenAIEndpoint string = secondaryOpenAI.properties.endpoint
