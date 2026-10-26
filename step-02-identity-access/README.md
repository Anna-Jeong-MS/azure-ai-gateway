# 02. Identity and access

English | [Korean](../kr/step-02-identity-access/README.md)

[Previous: preparation and resources](../step-01-prepare-resources/README.md) | [Contents](../README.md) | [Next: backends and pools](../step-03-backend-pools/README.md)

## 2-A. Enable the APIM system-assigned identity

### Objective and prerequisites

Allow APIM to authenticate to model accounts with Microsoft Entra tokens instead of model keys. APIM must be Online, and the operator must have permission to modify it.

### 2-A-1. Enable the identity in the portal

1. Open the APIM instance.
2. Select **Security > Managed identities**, or the **Managed identities** menu.
3. Open **System assigned**.
4. Set **Status > On > Save**. If already enabled, do not disable or recreate it.
5. Copy the displayed **Object (principal) ID** into local working notes.
6. Confirm the APIM name, resource ID, and principal ID all refer to the intended instance.

The system-assigned service principal follows the APIM resource lifecycle. Disabling and re-enabling it, or recreating APIM, can change the identity; do not assume existing assignments still apply.

### Optional: inspect or enable using CLI

Use a PowerShell session with `$ResourceGroup` and `$ApimName` set as described in step 01.

```powershell
az apim show --resource-group $ResourceGroup --name $ApimName `
  --query identity --output json
```

Use the following only when the instance has no identity. **If user-assigned identities are already attached, do not simply replace `identity.type` with this command. Add the system-assigned identity in the portal while preserving existing identities.**

```powershell
az apim update --resource-group $ResourceGroup --name $ApimName `
  --set identity.type=SystemAssigned

$ApimPrincipalId = az apim show --resource-group $ResourceGroup --name $ApimName `
  --query identity.principalId --output tsv
if ([string]::IsNullOrWhiteSpace($ApimPrincipalId)) {
    throw "APIM principalId is empty. Check the managed identity configuration."
}
```

### 2-A-2. Understand the authentication boundaries

| Connection | Credential |
| --- | --- |
| Client to APIM | APIM subscription key created in step 04 |
| APIM to Azure OpenAI | Entra token obtained with the APIM managed identity |

Enabling the identity does not grant access to model accounts. Assign a role on **each AI account** next. Obtaining a token does not bypass network restrictions.

### Completion criteria

- [ ] System-assigned identity is On.
- [ ] Record a nonempty principal ID.
- [ ] Do not confuse it with another APIM identity or the operator's object ID.
- [ ] Preserve any existing user-assigned identities.

### Troubleshooting

- **Cannot edit identity:** Check APIM management permission and PIM activation.
- **No principal ID displayed:** Save and refresh the resource. Do not substitute another identity.

### Official documentation

- [Create and use APIM managed identities](https://learn.microsoft.com/en-us/azure/api-management/api-management-howto-use-managed-service-identity)
- [Managed identity authentication policy](https://learn.microsoft.com/en-us/azure/api-management/authentication-managed-identity-policy)

---

## 2-B. Assign access to each AI account

### Objective and prerequisites

Assign `Cognitive Services OpenAI User` to the APIM identity at the **individual account scope** for Text A/B and Image A/B.

Use the APIM principal ID from section 2-A and the four AI account resource IDs from step 01. The operator needs `Microsoft.Authorization/roleAssignments/write` at the applicable scope.

### 2-B-1. Choose the role and scope

| Setting | Value |
| --- | --- |
| Principal receiving access | APIM system-assigned managed identity |
| Role | Cognitive Services OpenAI User |
| Scope | Each individual Text A/B and Image A/B account resource |
| Built-in role ID | `5e0bd9bd-7b93-4f28-af87-19fc36ad61bd` |

This role allows Entra-based inference and some resource/deployment reads. It does not allow model deployment creation/modification or account key access, making it suitable for this calling scenario. Broader subscription or resource-group assignments are technically possible but are not used here.

### 2-B-2. Repeat in the portal for each account

1. Open the **AI account**, not the APIM IAM page.
2. Select **Access control (IAM) > Add > Add role assignment**.
3. Under **Role**, select `Cognitive Services OpenAI User`.
4. Under **Members > Assign access to**, select **Managed identity**.
5. In **Select members**, choose the APIM subscription and **API Management service**.
6. Select the intended APIM service and verify the principal matches section 2-A.
7. Select **Review + assign**.
8. Check the role, principal, and scope under **Role assignments**.
9. Repeat for the remaining three accounts.

If the same principal/role/scope assignment already exists, do not create a duplicate. Assigning the role to the operator instead of APIM does not complete this task.

### Optional: assign one account using CLI

Replace the inputs and repeat for each account. If accounts use different resource groups or subscriptions, use each account's full actual resource ID.

```powershell
$ApimPrincipalId = "<apim-principal-id>"
$AiAccountResourceId = "<full-ai-account-resource-id>"
$OpenAiUserRoleId = "5e0bd9bd-7b93-4f28-af87-19fc36ad61bd"

az role assignment create `
  --assignee-object-id $ApimPrincipalId `
  --assignee-principal-type ServicePrincipal `
  --role $OpenAiUserRoleId `
  --scope $AiAccountResourceId
```

Inspect the assignments:

```powershell
az role assignment list --scope $AiAccountResourceId `
  --query "[?principalId=='$ApimPrincipalId'].{role:roleDefinitionName,scope:scope,principal:principalId}" `
  --output table
```

### 2-B-3. Record verification

| AI account | Role | APIM principal matches | Account scope matches |
| --- | --- | --- | --- |
| Text A | OpenAI User | Verified | Verified |
| Text B | OpenAI User | Verified | Verified |
| Image A | OpenAI User | Verified | Verified |
| Image B | OpenAI User | Verified | Verified |

RBAC propagation can take time. If an immediate call fails, verify the assignment and allow for documented propagation behavior. Do not promise success after a fixed number of minutes.

### Completion criteria

- [ ] Verify the APIM identity's role on each of the four accounts.
- [ ] Avoid unnecessary subscription-wide or resource-group-wide grants.
- [ ] Distinguish operator permissions from APIM inference permissions.

### Troubleshooting

- **Add role assignment disabled:** Check whether the operator has only Contributor; request the role-assignment owner.
- **401/403 from calls:** Check principal, scope, token audience, and network restrictions. A 403 does not always mean RBAC.
- **Failure after identity recreation:** Compare the current principal ID with the assignment's principal.

### Official documentation

- [Azure OpenAI role permissions](https://learn.microsoft.com/en-us/azure/foundry-classic/openai/how-to/role-based-access-control)
- [Role assignment procedure and operator permissions](https://learn.microsoft.com/en-us/azure/role-based-access-control/role-assignments-portal)
