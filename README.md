# Simple Case Management System

A minimal, production-ready case management system for Wrangler Tax Services with:
- **Frontend**: Azure Static Web Apps (React + Vite)
- **Backend**: Azure Container Apps (FastAPI + Python)
- **Database**: Azure PostgreSQL Flexible Server (Standard tier - no auto-shutdown)
- **Email**: Azure Communication Services with Managed Identity

**✨ Key Features:**
- 📋 Kanban board interface for ticket management
- 📧 Email responses to customers via Azure Communication Services
- 🔐 Managed identities throughout (no passwords or connection strings)
- 🚀 GitHub Actions CI/CD for infrastructure, backend, and frontend
- 💾 PostgreSQL Standard tier (no auto-shutdown issues)

---

## 🏗️ Architecture

```
Internet
   │
   ├─→ Azure Static Web App (Frontend)
   │      └─→ React Dashboard with Kanban Board
   │
   └─→ Azure Container App (Backend API)
          ├─→ FastAPI REST API
          ├─→ PostgreSQL Database (Standard tier)
          └─→ Azure Communication Services (Managed Identity)
```

**Key Benefits:**
- ✅ PostgreSQL **Standard tier** (General Purpose) - no auto-shutdown
- ✅ **Managed Identity** for ACR pull, ACS email, no passwords
- ✅ **GitHub Actions** for automated deployments
- ✅ Simple architecture, easy to maintain
- ✅ Production-ready with proper scaling

---

## 📋 Prerequisites

1. **Azure Subscription**
2. **GitHub Repository** for your code
3. **Azure CLI** installed locally (for initial setup)
4. **Node.js 20+** (for local frontend development)
5. **Python 3.11+** (for local backend development)
6. **Docker** (optional, for local backend testing)

---

## 🚀 Quick Start (Deployment)

### Step 1: Configure Azure Service Principal for GitHub Actions

Create a service principal with Federated Credentials for GitHub Actions:

```bash
# Set variables
SUBSCRIPTION_ID="your-subscription-id"
RESOURCE_GROUP="rg-casemanagement-simple"
APP_NAME="github-actions-cm-simple"
GITHUB_ORG="YourGitHubUsername"
GITHUB_REPO="case-management-simple"

# Create service principal
az ad sp create-for-rbac --name $APP_NAME --role contributor \
  --scopes /subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RESOURCE_GROUP \
  --sdk-auth

# Note: Save the output, you'll need client-id, tenant-id, and subscription-id

# Get the Application (client) ID
APP_ID=$(az ad sp list --display-name $APP_NAME --query "[0].appId" -o tsv)

# Create federated credential for GitHub Actions
az ad app federated-credential create \
  --id $APP_ID \
  --parameters '{
    "name": "github-actions-main",
    "issuer": "https://token.actions.githubusercontent.com",
    "subject": "repo:'$GITHUB_ORG'/'$GITHUB_REPO':ref:refs/heads/main",
    "audiences": ["api://AzureADTokenExchange"]
  }'
```

### Step 2: Configure GitHub Secrets

Add these secrets to your GitHub repository (Settings → Secrets and variables → Actions):

| Secret Name | Description | Example |
|------------|-------------|---------|
| `AZURE_CLIENT_ID` | Service principal client ID | `abcd1234-...` |
| `AZURE_TENANT_ID` | Azure tenant ID | `efgh5678-...` |
| `AZURE_SUBSCRIPTION_ID` | Azure subscription ID | `ijkl9012-...` |
| `POSTGRES_ADMIN_PASSWORD` | PostgreSQL admin password | `YourSecurePassword123!` |

**Note:** Password must be 8-128 characters with uppercase, lowercase, and numbers.

### Step 3: Deploy Infrastructure

Push your code to the `main` branch or manually trigger the workflow:

```bash
git add .
git commit -m "Initial commit"
git push origin main
```

Or trigger manually in GitHub:
1. Go to **Actions** tab
2. Select **Deploy Infrastructure**
3. Click **Run workflow**

This will create:
- Resource Group
- PostgreSQL Flexible Server (Standard tier)
- Container Registry
- Container Apps Environment
- Container App (Backend API)
- Azure Communication Services
- Role assignments for Managed Identity

### Step 4: Initialize Database

After infrastructure is deployed, connect to PostgreSQL and run the schema:

```bash
# Get PostgreSQL server name from Azure Portal or:
POSTGRES_SERVER=$(az postgres flexible-server list \
  --resource-group rg-casemanagement-simple \
  --query "[0].fullyQualifiedDomainName" -o tsv)

# Connect and run schema
psql "host=$POSTGRES_SERVER port=5432 dbname=casemanagement user=caseadmin password=YourSecurePassword123! sslmode=require" \
  -f database/schema.sql

# (Optional) Load sample data
psql "host=$POSTGRES_SERVER port=5432 dbname=casemanagement user=caseadmin password=YourSecurePassword123! sslmode=require" \
  -f database/sample-data.sql
```

### Step 5: Deploy Backend

The backend will be automatically deployed when you push changes to `backend/` folder, or trigger manually:

1. Go to **Actions** → **Deploy Backend**
2. Click **Run workflow**

### Step 6: Deploy Frontend

The frontend will be automatically deployed when you push changes to `frontend/` folder, or trigger manually:

1. Go to **Actions** → **Deploy Frontend**
2. Click **Run workflow**

---

## 🔧 Local Development

### Backend Development

```bash
cd backend

# Create virtual environment
python -m venv venv
venv\Scripts\activate  # Windows
# source venv/bin/activate  # macOS/Linux

# Install dependencies
pip install -r requirements.txt

# Set environment variables
$env:DATABASE_URL="postgresql://caseadmin:password@localhost:5432/casemanagement"
$env:ACS_ENDPOINT="https://your-acs.communication.azure.com"
$env:ACS_SENDER_EMAIL="DoNotReply@xxx.azurecomm.net"
$env:COMPANY_NAME="Wrangler Tax Services"

# Run backend
uvicorn app.main:app --reload
```

Backend will be available at: `http://localhost:8000`
- API Docs: `http://localhost:8000/docs`
- Health Check: `http://localhost:8000/health`

### Frontend Development

```bash
cd frontend

# Install dependencies
npm install

# Set API URL
$env:VITE_API_URL="http://localhost:8000/api"

# Run frontend
npm run dev
```

Frontend will be available at: `http://localhost:5173`

---

## 📊 Database Schema

### Tickets Table

| Column | Type | Description |
|--------|------|-------------|
| `id` | Serial | Primary key |
| `ticket_number` | VARCHAR | Unique ticket ID (e.g., TAX-2025-0001) |
| `title` | VARCHAR | Ticket title |
| `description` | TEXT | Detailed description |
| `category` | VARCHAR | Category (income_tax, vat, deductions, etc.) |
| `priority` | VARCHAR | Priority level (low, medium, high, critical) |
| `status` | VARCHAR | Status (new, in_progress, resolved, closed) |
| `customer_name` | VARCHAR | Customer name |
| `customer_email` | VARCHAR | Customer email |
| `assigned_to` | VARCHAR | Assigned employee |
| `created_at` | TIMESTAMP | Creation timestamp |
| `updated_at` | TIMESTAMP | Last update timestamp |

### Ticket Responses Table

| Column | Type | Description |
|--------|------|-------------|
| `id` | Serial | Primary key |
| `ticket_id` | Integer | Foreign key to tickets |
| `response_text` | TEXT | Response content |
| `sent_by` | VARCHAR | Employee who sent response |
| `email_status` | VARCHAR | Email delivery status |
| `created_at` | TIMESTAMP | Creation timestamp |

---

## 🔐 Security Features

1. **Managed Identities**
   - Container App uses system-assigned managed identity
   - No passwords for ACR pull
   - No connection strings for ACS email

2. **HTTPS Everywhere**
   - All endpoints use HTTPS
   - SSL required for PostgreSQL connections

3. **CORS Configuration**
   - Properly configured CORS for frontend-backend communication

4. **PostgreSQL Security**
   - Firewall rules in place
   - SSL required for connections
   - Azure services access enabled

---

## 📝 API Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| `GET` | `/api/tickets/` | Get all tickets (with optional filters) |
| `POST` | `/api/tickets/` | Create new ticket |
| `GET` | `/api/tickets/{id}` | Get ticket by ID |
| `PUT` | `/api/tickets/{id}` | Update ticket |
| `DELETE` | `/api/tickets/{id}` | Delete ticket |
| `POST` | `/api/tickets/{id}/respond` | Send email response |
| `GET` | `/api/tickets/{id}/responses` | Get all responses |
| `GET` | `/health` | Health check |
| `GET` | `/` | API info |

---

## 💰 Cost Estimate (Monthly)

| Service | SKU | Estimated Cost |
|---------|-----|----------------|
| Static Web App | Free | $0 |
| Container Apps | Consumption (0.5 vCPU, 1 GB) | $15-25 |
| Container Registry | Basic | $5 |
| PostgreSQL | Standard D2s_v3 (2 vCores, 8 GB) | $140-160 |
| Azure Communication Services | Pay-per-email | $0.25 per 1000 emails |
| **Total** | | **~$160-190/month** |

**Note:** PostgreSQL Standard tier ensures no auto-shutdown and better performance.

---

## 🚨 Troubleshooting

### Backend returns 500 errors

Check Container App logs:
```bash
az containerapp logs show \
  --resource-group rg-casemanagement-simple \
  --name ca-api-cm-dev \
  --tail 100
```

### CORS errors in browser

1. Verify Static Web App URL is in CORS configuration
2. Rebuild and redeploy backend
3. Check Container App environment variables

### Can't connect to PostgreSQL

Add your IP to firewall:
```bash
MY_IP=$(curl -s https://api.ipify.org)
az postgres flexible-server firewall-rule create \
  --resource-group rg-casemanagement-simple \
  --name psql-cm-dev-xxxxx \
  --rule-name AllowMyIP \
  --start-ip-address $MY_IP \
  --end-ip-address $MY_IP
```

### Email sending fails

1. Verify Managed Identity has Contributor role on ACS
2. Check ACS sender email domain is verified
3. Review Container App logs for authentication errors

---

## 📚 Additional Resources

- [Azure Container Apps Documentation](https://learn.microsoft.com/azure/container-apps/)
- [Azure Static Web Apps Documentation](https://learn.microsoft.com/azure/static-web-apps/)
- [Azure PostgreSQL Documentation](https://learn.microsoft.com/azure/postgresql/)
- [Azure Communication Services Documentation](https://learn.microsoft.com/azure/communication-services/)
- [GitHub Actions for Azure](https://github.com/Azure/actions)

---

## 🎯 Next Steps

Once deployed and working:

1. **Add Authentication** - Integrate Entra ID for user login
2. **Add Monitoring** - Set up Application Insights
3. **Add VNet Integration** - For enhanced security
4. **Add API Management** - For rate limiting and API gateway
5. **Add Backup Strategy** - Automated database backups
6. **Add Custom Domain** - Use your own domain name

---

## 📞 Support

For issues or questions:
1. Check the troubleshooting section
2. Review Azure Portal logs
3. Check GitHub Actions workflow logs

---

## ✅ Verification Checklist

After deployment:

- [ ] Infrastructure deployed successfully
- [ ] PostgreSQL is accessible and schema created
- [ ] Container App is running (check `/health` endpoint)
- [ ] Backend API returns data (check `/api/tickets/`)
- [ ] Frontend loads and displays tickets
- [ ] Can create new tickets
- [ ] Can update ticket status (drag and drop on Kanban board)
- [ ] Email sending works (test via ticket response)
- [ ] Managed Identity authentication works (no credential errors in logs)

---

**Built with ❤️ for Wrangler Tax Services**
