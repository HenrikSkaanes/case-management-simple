# GitHub Actions Setup Guide

This guide walks you through setting up GitHub Actions for automated deployments.

## Prerequisites

- Azure subscription
- GitHub repository
- Azure CLI installed

---

## Step 1: Create Azure Service Principal

We'll use **Federated Identity Credentials** (recommended) for GitHub Actions authentication.

### Option A: Federated Credentials (Recommended)

```bash
# Set your variables
SUBSCRIPTION_ID="<your-subscription-id>"
RESOURCE_GROUP="rg-casemanagement-simple"
APP_NAME="github-actions-cm-simple"
GITHUB_ORG="<your-github-username>"
GITHUB_REPO="case-management-simple"

# Login to Azure
az login

# Set subscription
az account set --subscription $SUBSCRIPTION_ID

# Create resource group (if not exists)
az group create --name $RESOURCE_GROUP --location norwayeast

# Create service principal
SP_OUTPUT=$(az ad sp create-for-rbac --name $APP_NAME \
  --role contributor \
  --scopes /subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RESOURCE_GROUP \
  --sdk-auth)

echo "$SP_OUTPUT"

# Extract IDs (save these for GitHub secrets)
CLIENT_ID=$(echo $SP_OUTPUT | jq -r '.clientId')
TENANT_ID=$(echo $SP_OUTPUT | jq -r '.tenantId')

echo "Client ID: $CLIENT_ID"
echo "Tenant ID: $TENANT_ID"
echo "Subscription ID: $SUBSCRIPTION_ID"

# Create federated credential for main branch
az ad app federated-credential create \
  --id $CLIENT_ID \
  --parameters "{
    \"name\": \"github-actions-main\",
    \"issuer\": \"https://token.actions.githubusercontent.com\",
    \"subject\": \"repo:$GITHUB_ORG/$GITHUB_REPO:ref:refs/heads/main\",
    \"audiences\": [\"api://AzureADTokenExchange\"]
  }"

echo "✅ Federated credential created for main branch"
```

### Option B: Client Secret (Alternative)

If you prefer using a client secret:

```bash
# Create service principal with secret
az ad sp create-for-rbac --name $APP_NAME \
  --role contributor \
  --scopes /subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RESOURCE_GROUP \
  --sdk-auth

# Save the entire JSON output - you'll need it for GitHub
```

---

## Step 2: Configure GitHub Secrets

Go to your GitHub repository:
1. Click **Settings**
2. Go to **Secrets and variables** → **Actions**
3. Click **New repository secret**

Add these secrets:

| Secret Name | Value | Where to find |
|------------|-------|---------------|
| `AZURE_CLIENT_ID` | Your client ID | From Step 1 output |
| `AZURE_TENANT_ID` | Your tenant ID | From Step 1 output |
| `AZURE_SUBSCRIPTION_ID` | Your subscription ID | `az account show --query id -o tsv` |
| `POSTGRES_ADMIN_PASSWORD` | Strong password for PostgreSQL | Create a secure password |

**Example:**
- Name: `AZURE_CLIENT_ID`
- Secret: `abcd1234-5678-90ef-ghij-klmnopqrstuv`

### Password Requirements

`POSTGRES_ADMIN_PASSWORD` must be:
- 8-128 characters long
- Contains uppercase letters
- Contains lowercase letters
- Contains numbers
- Example: `MySecure@Password123!`

---

## Step 3: Verify Permissions

Ensure the service principal has correct permissions:

```bash
# Check role assignments
az role assignment list \
  --assignee $CLIENT_ID \
  --resource-group $RESOURCE_GROUP \
  --output table

# Should show 'Contributor' role
```

---

## Step 4: Test Deployment

### Test Infrastructure Deployment

1. Go to **Actions** tab in GitHub
2. Select **Deploy Infrastructure** workflow
3. Click **Run workflow** → **Run workflow**
4. Watch the deployment progress

Expected output:
- Resource group created
- PostgreSQL server deployed
- Container registry created
- Container app environment created
- Role assignments completed

### Test Backend Deployment

After infrastructure is ready:

1. Go to **Actions** → **Deploy Backend**
2. Click **Run workflow**
3. Watch the build and deployment

Expected output:
- Docker image built
- Image pushed to ACR
- Container app updated

### Test Frontend Deployment

1. Go to **Actions** → **Deploy Frontend**
2. Click **Run workflow**
3. Watch the build and deployment

Expected output:
- Node dependencies installed
- Frontend built
- Static Web App deployed

---

## Step 5: Verify Deployment

### Check Backend

```bash
# Get API URL
API_URL=$(az containerapp show \
  --resource-group rg-casemanagement-simple \
  --name ca-api-cm-dev \
  --query properties.configuration.ingress.fqdn -o tsv)

# Test health endpoint
curl https://$API_URL/health

# Should return: {"status":"healthy",...}
```

### Check Frontend

```bash
# Get Static Web App URL
SWA_URL=$(az staticwebapp show \
  --resource-group rg-casemanagement-simple \
  --name stapp-cm-simple-* \
  --query defaultHostname -o tsv)

echo "Frontend URL: https://$SWA_URL"
```

Visit the URL in your browser - you should see the Kanban board.

---

## Workflow Triggers

Workflows are automatically triggered on push to `main` branch:

| Workflow | Triggered by |
|----------|-------------|
| **Deploy Infrastructure** | Changes to `infra/**` |
| **Deploy Backend** | Changes to `backend/**` |
| **Deploy Frontend** | Changes to `frontend/**` |

You can also trigger manually from the Actions tab.

---

## Troubleshooting

### Issue: "Error: The client has permission to perform action on the resource"

**Solution:** Add more specific role:

```bash
az role assignment create \
  --assignee $CLIENT_ID \
  --role "Contributor" \
  --scope /subscriptions/$SUBSCRIPTION_ID
```

### Issue: "Error: No subscription found"

**Solution:** Set default subscription:

```bash
az account set --subscription $SUBSCRIPTION_ID
```

### Issue: Federated credential not working

**Solution:** Verify subject format:

```bash
# Should be exactly:
# repo:YourOrg/YourRepo:ref:refs/heads/main

az ad app federated-credential list --id $CLIENT_ID
```

### Issue: PostgreSQL deployment fails

**Solution:** Check password meets requirements:
- 8-128 characters
- Mix of upper, lower, numbers
- Special characters allowed

---

## Security Best Practices

1. **Use Federated Credentials** - No secrets stored in GitHub
2. **Limit Scope** - Service principal only has access to one resource group
3. **Rotate Secrets** - If using client secrets, rotate regularly
4. **Monitor Activity** - Check Azure Activity Log for deployment actions

---

## Clean Up (Optional)

To remove everything:

```bash
# Delete resource group (removes all resources)
az group delete --name rg-casemanagement-simple --yes --no-wait

# Delete service principal
az ad sp delete --id $CLIENT_ID

# Delete GitHub secrets manually in GitHub UI
```

---

## Next Steps

✅ GitHub Actions configured
✅ Automated deployments working
✅ Infrastructure, backend, and frontend deployed

Now you can:
1. Make changes to code
2. Push to `main` branch
3. GitHub Actions automatically deploys
4. Monitor deployments in Actions tab

**Happy deploying! 🚀**
