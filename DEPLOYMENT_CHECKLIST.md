# Deployment Checklist

Use this checklist to ensure a successful deployment of the Case Management System.

## 📋 Pre-Deployment

### Azure Setup
- [ ] Azure subscription active and accessible
- [ ] Azure CLI installed (`az --version`)
- [ ] Logged in to Azure CLI (`az login`)
- [ ] Correct subscription selected (`az account show`)

### GitHub Setup
- [ ] GitHub repository created
- [ ] Local repository initialized (`git init`)
- [ ] Remote repository added (`git remote add origin <url>`)
- [ ] Code committed to repository

### Local Development Environment
- [ ] Node.js 20+ installed (`node --version`)
- [ ] Python 3.11+ installed (`python --version`)
- [ ] Docker installed (optional, `docker --version`)

---

## 🔐 Step 1: Configure GitHub Actions

- [ ] Service principal created with Federated Credentials
- [ ] GitHub secrets configured:
  - [ ] `AZURE_CLIENT_ID`
  - [ ] `AZURE_TENANT_ID`
  - [ ] `AZURE_SUBSCRIPTION_ID`
  - [ ] `POSTGRES_ADMIN_PASSWORD`
- [ ] Service principal has Contributor role on resource group

**Reference:** See `GITHUB_ACTIONS_SETUP.md`

---

## 🏗️ Step 2: Deploy Infrastructure

- [ ] Push code to main branch OR trigger workflow manually
- [ ] Wait for "Deploy Infrastructure" workflow to complete
- [ ] Verify resources created in Azure Portal:
  - [ ] Resource Group: `rg-casemanagement-simple`
  - [ ] PostgreSQL Flexible Server
  - [ ] Azure Container Registry
  - [ ] Container Apps Environment
  - [ ] Container App (Backend)
  - [ ] Azure Communication Services
- [ ] Check workflow outputs for URLs and names

---

## 💾 Step 3: Initialize Database

- [ ] Get PostgreSQL server FQDN from Azure Portal
- [ ] Update firewall rule to allow your IP
- [ ] Connect to PostgreSQL using psql or Azure Data Studio
- [ ] Run `database/schema.sql` to create tables
- [ ] (Optional) Run `database/sample-data.sql` for test data
- [ ] Verify tables created: `\dt` in psql

**Commands:**
```bash
# Get server name
az postgres flexible-server list -g rg-casemanagement-simple --query "[0].fullyQualifiedDomainName" -o tsv

# Add your IP
az postgres flexible-server firewall-rule create \
  -g rg-casemanagement-simple \
  -n <server-name> \
  -r AllowMyIP \
  --start-ip-address <your-ip> \
  --end-ip-address <your-ip>

# Connect and run schema
psql "host=<server> port=5432 dbname=casemanagement user=caseadmin password=<password> sslmode=require" -f database/schema.sql
```

---

## 🐳 Step 4: Deploy Backend

- [ ] Trigger "Deploy Backend" workflow
- [ ] Wait for workflow to complete
- [ ] Docker image built and pushed to ACR
- [ ] Container App updated with new image
- [ ] Get Backend API URL from workflow output
- [ ] Test health endpoint: `curl https://<api-url>/health`
- [ ] Test API docs: Open `https://<api-url>/docs` in browser
- [ ] Verify database connection works

**Health Check Response:**
```json
{
  "status": "healthy",
  "database": "connected",
  "email_service": "configured"
}
```

---

## 🎨 Step 5: Deploy Frontend

- [ ] Trigger "Deploy Frontend" workflow
- [ ] Wait for workflow to complete
- [ ] Static Web App created/updated
- [ ] Frontend built with correct API URL
- [ ] Get Frontend URL from workflow output
- [ ] Open frontend in browser
- [ ] Verify Kanban board displays

---

## ✅ Step 6: Functional Testing

### Basic Functionality
- [ ] Frontend loads without errors
- [ ] Kanban board displays columns (New, In Progress, Resolved, Closed)
- [ ] Sample tickets visible (if sample data loaded)
- [ ] Click "+" button to open create ticket modal
- [ ] Create a new ticket
- [ ] New ticket appears in "New" column
- [ ] Click on a ticket to view details
- [ ] Edit ticket (change status, priority, etc.)
- [ ] Verify ticket moves to correct column
- [ ] Delete a ticket

### Email Functionality
- [ ] Azure Communication Services domain verified
- [ ] Get sender email address from ACS
- [ ] Create ticket with customer email
- [ ] Click "Send Response" (if implemented)
- [ ] Check ticket responses
- [ ] Verify email sent (check ACS logs if needed)

### Performance & Security
- [ ] Backend responds quickly (< 1 second)
- [ ] Frontend loads quickly
- [ ] HTTPS enabled on all endpoints
- [ ] CORS working (no browser errors)
- [ ] Managed Identity working (check Container App logs)
- [ ] No credential errors in logs

---

## 🔍 Step 7: Monitoring & Verification

### Azure Portal Checks
- [ ] Container App: Status = "Running"
- [ ] Container App: Replicas = 1 (at least)
- [ ] PostgreSQL: Status = "Available"
- [ ] ACR: Contains `api:latest` image
- [ ] Static Web App: Status = "Ready"

### Log Checks
```bash
# Check Container App logs
az containerapp logs show \
  -g rg-casemanagement-simple \
  -n ca-api-cm-dev \
  --tail 50

# Look for:
# - No errors
# - Successful database connections
# - Health check responses
```

### Cost Verification
- [ ] Review Azure Cost Analysis
- [ ] Verify services are in expected pricing tiers
- [ ] Set up budget alerts (recommended: $200/month)

---

## 🚨 Troubleshooting

If something doesn't work, check:

### Infrastructure Issues
- [ ] Check GitHub Actions logs for errors
- [ ] Verify all GitHub secrets are set correctly
- [ ] Verify service principal has correct permissions
- [ ] Check Azure Activity Log for deployment errors

### Backend Issues
- [ ] Check Container App logs for errors
- [ ] Verify DATABASE_URL is correct
- [ ] Verify ACS_ENDPOINT is correct
- [ ] Test database connection from Azure Cloud Shell
- [ ] Verify Managed Identity role assignments

### Frontend Issues
- [ ] Check browser console for errors
- [ ] Verify VITE_API_URL is set correctly
- [ ] Check CORS configuration in backend
- [ ] Verify Static Web App deployment logs

### Database Issues
- [ ] Verify firewall rules allow connections
- [ ] Check if database exists: `\l` in psql
- [ ] Verify tables exist: `\dt` in psql
- [ ] Check PostgreSQL server is running

---

## 📊 Post-Deployment

### Documentation
- [ ] Update README with actual URLs
- [ ] Document any customizations made
- [ ] Save Azure resource names for reference
- [ ] Document any manual steps taken

### Security
- [ ] Review firewall rules (remove "allow all" if used)
- [ ] Set up Azure Key Vault for secrets (future enhancement)
- [ ] Enable Application Insights (future enhancement)
- [ ] Review CORS configuration (restrict to actual domains)

### Backup & Disaster Recovery
- [ ] Enable PostgreSQL automated backups
- [ ] Document restore procedure
- [ ] Export initial data for safekeeping
- [ ] Set up alerts for service health

---

## 🎯 Success Criteria

Deployment is successful when:

✅ All GitHub Actions workflows complete without errors
✅ Backend health endpoint returns "healthy"
✅ Frontend loads and displays Kanban board
✅ Can create, view, update, and delete tickets
✅ Tickets move between columns correctly
✅ No errors in browser console
✅ No errors in Container App logs
✅ Database contains expected tables and data
✅ Email functionality works (if configured)
✅ All Azure resources show "Running" or "Available" status

---

## 📞 Need Help?

1. **Check Documentation:**
   - `README.md` - Main documentation
   - `GITHUB_ACTIONS_SETUP.md` - GitHub Actions setup
   - Azure service documentation links in README

2. **Check Logs:**
   - GitHub Actions workflow logs
   - Container App logs
   - Browser console (F12)
   - Azure Activity Log

3. **Common Issues:**
   - See Troubleshooting section in README.md
   - Check service-specific documentation
   - Review Azure service health status

---

**Last Updated:** 2025-11-04

**Status:** Ready for deployment ✅
