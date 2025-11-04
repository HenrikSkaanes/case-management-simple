# Simple Case Management System - Original Requirements

**Status:** ✅ **IMPLEMENTED**

This document contains the original requirements. The system has been fully implemented with the following improvements:

## ✨ What's Been Built

✅ **PostgreSQL Standard Tier** (2 vCores, 8GB RAM) - No auto-shutdown issues
✅ **Managed Identities** everywhere - ACR pull, ACS email, no credentials stored
✅ **GitHub Actions CI/CD** - Separate workflows for infrastructure, backend, frontend
✅ **FastAPI Backend** - REST API with SQLAlchemy, email integration, health checks
✅ **React Frontend** - Kanban board UI with create, update, delete functionality
✅ **Complete Documentation** - README, deployment checklist, quick start guide

## 📁 Key Files Created

- `README.md` - Main documentation
- `DEPLOYMENT_CHECKLIST.md` - Step-by-step deployment guide
- `GITHUB_ACTIONS_SETUP.md` - GitHub Actions configuration
- `QUICKSTART.md` - Local development setup
- `PROJECT_STRUCTURE.md` - Architecture overview
- `.github/workflows/` - Three GitHub Actions workflows
- `backend/` - Complete FastAPI application
- `frontend/` - Complete React application
- `infra/` - Bicep templates with managed identities
- `database/` - SQL schema and sample data

## 🚀 Deployment Instructions

Follow these steps to deploy:

1. **Read** `GITHUB_ACTIONS_SETUP.md` to configure GitHub Actions
2. **Follow** `DEPLOYMENT_CHECKLIST.md` for step-by-step deployment
3. **Refer to** `README.md` for complete documentation

## 💡 Key Improvements Over Original Design

| Aspect | Original | Implemented |
|--------|----------|-------------|
| PostgreSQL | Burstable B1ms | **Standard D2s_v3** (no auto-shutdown) |
| Authentication | Connection strings | **Managed Identity** (no credentials) |
| Deployment | Manual commands | **GitHub Actions** (automated CI/CD) |
| Documentation | Single file | **5 comprehensive guides** |
| Frontend | Not specified | **Beautiful Kanban board** with React |

---

# Simple Case Management System - Deployment Guide (Original)

## 🎯 Overview

A minimal, working case management system with:
- **Frontend**: Azure Static Web Apps (React + Vite)
- **Backend**: Azure Container Apps (FastAPI + Python)
- **Database**: Azure PostgreSQL Flexible Server
- **Email**: Azure Communication Services (with Managed Identity)

**No VNets, no APIM, no complexity** - just the essentials that work.

---

## 🏗️ Architecture

```
Internet
   │
   ├─→ Azure Static Web App (Frontend)
   │      └─→ React Dashboard with Kanban Board
   │
   └─→ Azure Container App (Backend API)
          └─→ FastAPI REST API
              └─→ PostgreSQL Database (Public Access + Firewall)
              └─→ Azure Communication Services (Managed Identity)
```

**Key Simplifications:**
- ✅ PostgreSQL with **public access enabled** + firewall rules
- ✅ Container Apps in **default consumption environment** (no VNet)
- ✅ **No** NAT Gateway, NSGs, Private DNS, or VNet complexity
- ✅ **No** API Management, Front Door, WAF
- ✅ Managed Identity for ACR pull and ACS email
- ✅ Simple CORS configuration

---

## 📊 Database Structure

### **Tickets Table**

```sql
CREATE TABLE tickets (
    -- Primary Key
    id SERIAL PRIMARY KEY,
    
    -- Ticket Information
    ticket_number VARCHAR UNIQUE,              -- e.g., "TAX-2025-0001"
    title VARCHAR NOT NULL,
    description TEXT,
    category VARCHAR NOT NULL,                 -- e.g., "income_tax", "vat", "deductions"
    priority VARCHAR DEFAULT 'medium',         -- low, medium, high, critical
    status VARCHAR DEFAULT 'new',              -- new, in_progress, resolved, closed
    
    -- Customer Information
    customer_name VARCHAR,
    customer_email VARCHAR,
    customer_phone VARCHAR,
    customer_id VARCHAR,
    
    -- Assignment & Ownership
    assigned_to VARCHAR,                       -- Employee name/ID
    assigned_at TIMESTAMP WITH TIME ZONE,
    department VARCHAR,                        -- e.g., "returns", "compliance", "general"
    
    -- Timeline & SLA Tracking
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    first_response_at TIMESTAMP WITH TIME ZONE,
    resolved_at TIMESTAMP WITH TIME ZONE,
    closed_at TIMESTAMP WITH TIME ZONE,
    due_date TIMESTAMP WITH TIME ZONE,
    
    -- Calculated Metrics (in minutes)
    response_time_minutes INTEGER,
    resolution_time_minutes INTEGER,
    
    -- Analytics & Additional Data
    tags JSONB,                                -- Array of tags: ["urgent", "vip", "complex"]
    satisfaction_rating INTEGER,               -- 1-5 stars
    reopened_count INTEGER DEFAULT 0,
    escalated BOOLEAN DEFAULT FALSE,
    notes TEXT
);

-- Indexes for performance
CREATE INDEX idx_tickets_status ON tickets(status);
CREATE INDEX idx_tickets_priority ON tickets(priority);
CREATE INDEX idx_tickets_category ON tickets(category);
CREATE INDEX idx_tickets_created_at ON tickets(created_at DESC);
CREATE INDEX idx_tickets_customer_email ON tickets(customer_email);
CREATE INDEX idx_tickets_assigned_to ON tickets(assigned_to);
```

### **Ticket Responses Table** (Email tracking)

```sql
CREATE TABLE ticket_responses (
    id SERIAL PRIMARY KEY,
    ticket_id INTEGER NOT NULL REFERENCES tickets(id) ON DELETE CASCADE,
    
    -- Response Content
    response_text TEXT NOT NULL,
    sent_by VARCHAR,                           -- Employee who sent it
    
    -- Email Delivery Tracking
    email_status VARCHAR DEFAULT 'pending',    -- pending, sent, failed, delivered
    email_message_id VARCHAR,                  -- ACS message ID
    email_error_message TEXT,
    
    -- Timestamps
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    sent_at TIMESTAMP WITH TIME ZONE,
    delivered_at TIMESTAMP WITH TIME ZONE
);

-- Index for querying responses by ticket
CREATE INDEX idx_ticket_responses_ticket_id ON ticket_responses(ticket_id);
CREATE INDEX idx_ticket_responses_created_at ON ticket_responses(created_at DESC);
```

---

## 🚀 Deployment Steps

### **Prerequisites**

1. Azure subscription
2. Azure CLI installed
3. Docker installed (for building container image)
4. GitHub repository (for CI/CD)

### **Step 1: Create Resource Group**

```bash
# Create new resource group
az group create --name rg-casemanagement-simple --location norwayeast
```

### **Step 2: Deploy PostgreSQL**

```bash
# Create PostgreSQL Flexible Server with PUBLIC access
az postgres flexible-server create \
  --resource-group rg-casemanagement-simple \
  --name psql-casemanagement-simple \
  --location norwayeast \
  --admin-user caseadmin \
  --admin-password 'YourSecurePassword123!' \
  --sku-name Standard_B1ms \
  --tier Burstable \
  --storage-size 32 \
  --version 16 \
  --public-access 0.0.0.0-255.255.255.255 \
  --tags Environment=simple AutoStop=Disabled

# Create database
az postgres flexible-server db create \
  --resource-group rg-casemanagement-simple \
  --server-name psql-casemanagement-simple \
  --database-name casemanagement

# Add firewall rule for your IP
MY_IP=$(curl -s https://api.ipify.org)
az postgres flexible-server firewall-rule create \
  --resource-group rg-casemanagement-simple \
  --name psql-casemanagement-simple \
  --rule-name AllowMyIP \
  --start-ip-address $MY_IP \
  --end-ip-address $MY_IP

# Add firewall rule for Azure services
az postgres flexible-server firewall-rule create \
  --resource-group rg-casemanagement-simple \
  --name psql-casemanagement-simple \
  --rule-name AllowAzureServices \
  --start-ip-address 0.0.0.0 \
  --end-ip-address 0.0.0.0
```

### **Step 3: Create Database Schema**

Connect to PostgreSQL and run:

```sql
-- Create tables (see Database Structure section above)
-- Copy and paste the CREATE TABLE statements
```

### **Step 4: Deploy Azure Container Registry**

```bash
# Create ACR
az acr create \
  --resource-group rg-casemanagement-simple \
  --name acrcasemanagementsimple \
  --sku Basic \
  --location norwayeast \
  --admin-enabled false
```

### **Step 5: Deploy Azure Communication Services**

```bash
# Create Email Communication Service
az communication email create \
  --resource-group rg-casemanagement-simple \
  --name email-casemanagement-simple \
  --data-location Europe

# Create domain (Azure Managed)
az communication email domain create \
  --resource-group rg-casemanagement-simple \
  --email-service-name email-casemanagement-simple \
  --domain-name AzureManagedDomain \
  --domain-management AzureManaged

# Create Communication Service
az communication create \
  --resource-group rg-casemanagement-simple \
  --name acs-casemanagement-simple \
  --data-location Europe

# Get the endpoint URL
ACS_ENDPOINT=$(az communication show \
  --resource-group rg-casemanagement-simple \
  --name acs-casemanagement-simple \
  --query hostName -o tsv)

echo "ACS Endpoint: https://$ACS_ENDPOINT"
```

### **Step 6: Build and Push Backend Image**

```bash
# Login to ACR
az acr login --name acrcasemanagementsimple

# Build and push from backend directory
cd backend
docker build -t acrcasemanagementsimple.azurecr.io/api:v1 .
docker push acrcasemanagementsimple.azurecr.io/api:v1
```

### **Step 7: Deploy Container Apps Environment**

```bash
# Create Container Apps Environment (consumption plan, no VNet)
az containerapp env create \
  --resource-group rg-casemanagement-simple \
  --name cae-casemanagement-simple \
  --location norwayeast
```

### **Step 8: Deploy Container App**

```bash
# Create Container App with System-Assigned Managed Identity
az containerapp create \
  --resource-group rg-casemanagement-simple \
  --name ca-api-simple \
  --environment cae-casemanagement-simple \
  --image acrcasemanagementsimple.azurecr.io/api:v1 \
  --target-port 8000 \
  --ingress external \
  --min-replicas 1 \
  --max-replicas 3 \
  --cpu 0.5 \
  --memory 1.0Gi \
  --registry-server acrcasemanagementsimple.azurecr.io \
  --registry-identity system \
  --system-assigned \
  --env-vars \
    DATABASE_URL=postgresql://caseadmin:YourSecurePassword123!@psql-casemanagement-simple.postgres.database.azure.com:5432/casemanagement?sslmode=require \
    ACS_ENDPOINT=https://$ACS_ENDPOINT \
    ACS_SENDER_EMAIL=DoNotReply@xxxxxxx.azurecomm.net \
    COMPANY_NAME="Wrangler Tax Services"

# Get the Container App URL
API_URL=$(az containerapp show \
  --resource-group rg-casemanagement-simple \
  --name ca-api-simple \
  --query properties.configuration.ingress.fqdn -o tsv)

echo "API URL: https://$API_URL"
```

### **Step 9: Grant Managed Identity Permissions**

```bash
# Get Container App Managed Identity Principal ID
PRINCIPAL_ID=$(az containerapp show \
  --resource-group rg-casemanagement-simple \
  --name ca-api-simple \
  --query identity.principalId -o tsv)

# Grant AcrPull role for Container Registry
ACR_ID=$(az acr show \
  --resource-group rg-casemanagement-simple \
  --name acrcasemanagementsimple \
  --query id -o tsv)

az role assignment create \
  --assignee $PRINCIPAL_ID \
  --role AcrPull \
  --scope $ACR_ID

# Grant Contributor role for ACS (to send emails)
ACS_ID=$(az communication show \
  --resource-group rg-casemanagement-simple \
  --name acs-casemanagement-simple \
  --query id -o tsv)

az role assignment create \
  --assignee $PRINCIPAL_ID \
  --role Contributor \
  --scope $ACS_ID
```

### **Step 10: Deploy Static Web App**

```bash
# Create Static Web App
az staticwebapp create \
  --resource-group rg-casemanagement-simple \
  --name stapp-casemanagement-simple \
  --location westeurope \
  --sku Free \
  --source https://github.com/YourUsername/case-management-system \
  --branch main \
  --app-location "/frontend" \
  --output-location "dist"

# Get Static Web App hostname
SWA_HOSTNAME=$(az staticwebapp show \
  --resource-group rg-casemanagement-simple \
  --name stapp-casemanagement-simple \
  --query defaultHostname -o tsv)

echo "Frontend URL: https://$SWA_HOSTNAME"

# Set API URL environment variable
az staticwebapp appsettings set \
  --resource-group rg-casemanagement-simple \
  --name stapp-casemanagement-simple \
  --setting-names VITE_API_URL=https://$API_URL/api
```

### **Step 11: Update CORS in Backend**

Update `backend/app/main.py` to include the Static Web App URL:

```python
allow_origins=[
    "http://localhost:5173",
    "https://YOUR-STATIC-WEB-APP.azurestaticapps.net",  # Add your SWA hostname
],
```

Rebuild and push the image, then restart the Container App.

---

## 🔧 Backend Configuration

### **Environment Variables**

| Variable | Description | Example |
|----------|-------------|---------|
| `DATABASE_URL` | PostgreSQL connection string | `postgresql://user:pass@host:5432/db?sslmode=require` |
| `ACS_ENDPOINT` | Azure Communication Services endpoint | `https://xxx.communication.azure.com` |
| `ACS_SENDER_EMAIL` | Sender email address | `DoNotReply@xxx.azurecomm.net` |
| `COMPANY_NAME` | Company branding | `Wrangler Tax Services` |

### **Dependencies** (`requirements.txt`)

```
fastapi==0.104.1
uvicorn[standard]==0.24.0
sqlalchemy==2.0.23
psycopg2-binary==2.9.9
pydantic-settings==2.1.0
python-multipart==0.0.6
azure-communication-email==1.0.0
azure-identity==1.15.0
pytest==7.4.3
pytest-asyncio==0.21.1
httpx==0.25.2
requests==2.31.0
```

---

## 🎨 Frontend Configuration

### **Environment Variables** (Static Web App settings)

| Variable | Description |
|----------|-------------|
| `VITE_API_URL` | Backend API base URL (e.g., `https://xxx.norwayeast.azurecontainerapps.io/api`) |

### **Build Configuration**

- **Framework**: React 18 with Vite
- **Build Command**: `npm run build`
- **Output Directory**: `dist`
- **App Location**: `/frontend`

---

## 📝 API Endpoints

### **Tickets**

| Method | Endpoint | Description |
|--------|----------|-------------|
| `GET` | `/api/tickets/` | Get all tickets |
| `POST` | `/api/tickets/` | Create new ticket |
| `GET` | `/api/tickets/{id}` | Get ticket by ID |
| `PUT` | `/api/tickets/{id}` | Update ticket |
| `DELETE` | `/api/tickets/{id}` | Delete ticket |
| `POST` | `/api/tickets/{id}/respond` | Send email response to customer |
| `GET` | `/api/tickets/{id}/responses` | Get all responses for ticket |

### **Health Check**

| Method | Endpoint | Description |
|--------|----------|-------------|
| `GET` | `/health` | Health check endpoint |
| `GET` | `/` | API info and version |

---

## 🔒 Security Features

- ✅ **Managed Identity** for ACR pull (no passwords)
- ✅ **Managed Identity** for ACS email (no connection strings)
- ✅ **HTTPS** everywhere (enforced by Azure)
- ✅ **CORS** properly configured
- ✅ **PostgreSQL SSL** required
- ✅ **Firewall rules** on PostgreSQL
- ✅ **Tags** to prevent auto-shutdown

---

## 💰 Cost Estimate (Monthly)

| Service | SKU | Estimated Cost |
|---------|-----|----------------|
| Static Web App | Free | $0 |
| Container Apps | Consumption (0.5 vCPU, 1 GB RAM, always-on) | ~$15-25 |
| Container Registry | Basic | ~$5 |
| PostgreSQL | Burstable B1ms (1 vCPU, 2 GB RAM) | ~$25 |
| Azure Communication Services | Pay-per-email | ~$0.25 per 1000 emails |
| **Total** | | **~$45-55/month** |

---

## 🚨 Common Issues & Solutions

### **Issue: API returns 500 Internal Server Error**

**Solution**: Check Container App logs:
```bash
az containerapp logs show \
  --resource-group rg-casemanagement-simple \
  --name ca-api-simple \
  --tail 100
```

### **Issue: CORS errors in browser**

**Solution**: 
1. Verify Static Web App URL is in `allow_origins` list in `main.py`
2. Rebuild and redeploy backend image
3. Restart Container App

### **Issue: Can't connect to PostgreSQL from local machine**

**Solution**: Add your IP to firewall rules:
```bash
MY_IP=$(curl -s https://api.ipify.org)
az postgres flexible-server firewall-rule create \
  --resource-group rg-casemanagement-simple \
  --name psql-casemanagement-simple \
  --rule-name AllowMyNewIP \
  --start-ip-address $MY_IP \
  --end-ip-address $MY_IP
```

### **Issue: Email sending fails**

**Solution**: 
1. Verify Managed Identity has Contributor role on ACS
2. Check ACS_ENDPOINT and ACS_SENDER_EMAIL are correct
3. Check Container App logs for authentication errors

### **Issue: PostgreSQL keeps shutting down**

**Solution**: Already handled with `AutoStop=Disabled` tag in deployment

---

## 📚 Sample Data (Optional)

```sql
-- Insert sample tickets for testing
INSERT INTO tickets (title, description, category, priority, status, customer_name, customer_email)
VALUES 
    ('Tax Deduction Question', 'Can I deduct home office expenses?', 'deductions', 'medium', 'new', 'John Doe', 'john@example.com'),
    ('VAT Return Issue', 'Need help with Q3 VAT return', 'vat', 'high', 'in_progress', 'Jane Smith', 'jane@example.com'),
    ('Income Tax Filing', 'Deadline approaching for income tax', 'income_tax', 'critical', 'new', 'Bob Johnson', 'bob@example.com');
```

---

## 🔄 GitHub Actions CI/CD (Optional)

Create `.github/workflows/deploy-simple.yml`:

```yaml
name: Deploy Simple Architecture

on:
  push:
    branches: [main]
    paths:
      - 'backend/**'
      - 'frontend/**'

jobs:
  build-backend:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Login to Azure
        uses: azure/login@v1
        with:
          creds: ${{ secrets.AZURE_CREDENTIALS }}
      
      - name: Build and push backend
        run: |
          az acr build \
            --resource-group rg-casemanagement-simple \
            --registry acrcasemanagementsimple \
            --image api:${{ github.sha }} \
            --image api:latest \
            ./backend
      
      - name: Update Container App
        run: |
          az containerapp update \
            --resource-group rg-casemanagement-simple \
            --name ca-api-simple \
            --image acrcasemanagementsimple.azurecr.io/api:${{ github.sha }}
```

---

## ✅ Verification Checklist

After deployment, verify:

- [ ] PostgreSQL is accessible and has tables created
- [ ] Container App is running (check health endpoint: `https://YOUR-API-URL/health`)
- [ ] API returns data (check tickets endpoint: `https://YOUR-API-URL/api/tickets/`)
- [ ] Static Web App loads
- [ ] Frontend can fetch tickets from API (no CORS errors)
- [ ] Email sending works (test via API docs: `https://YOUR-API-URL/docs`)
- [ ] Managed Identity authentication works (check logs for no password errors)

---

## 📞 Support Resources

- **Azure Container Apps**: https://learn.microsoft.com/azure/container-apps/
- **Azure Static Web Apps**: https://learn.microsoft.com/azure/static-web-apps/
- **Azure PostgreSQL**: https://learn.microsoft.com/azure/postgresql/
- **Azure Communication Services**: https://learn.microsoft.com/azure/communication-services/

---

## 🎯 Next Steps (Optional Enhancements)

Once the simple version is working, you can add:

1. **VNet Integration** for private networking
2. **API Management** for rate limiting and API gateway
3. **Azure Front Door** for global CDN and WAF
4. **Application Insights** for monitoring and telemetry
5. **Key Vault** for secrets management
6. **Entra ID Authentication** for user login

But start simple and add complexity only when needed!
