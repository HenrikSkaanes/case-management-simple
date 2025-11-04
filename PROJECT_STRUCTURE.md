# Project Structure

```
case-management-simple/
│
├── .github/
│   └── workflows/
│       ├── deploy-infrastructure.yml    # Deploys Azure infrastructure
│       ├── deploy-backend.yml           # Builds and deploys backend
│       └── deploy-frontend.yml          # Builds and deploys frontend
│
├── backend/
│   ├── app/
│   │   ├── routers/
│   │   │   ├── __init__.py
│   │   │   └── tickets.py              # Ticket API endpoints
│   │   ├── __init__.py
│   │   ├── config.py                    # Configuration settings
│   │   ├── database.py                  # Database connection and session
│   │   ├── email_service.py             # Azure Communication Services integration
│   │   ├── main.py                      # FastAPI application entry point
│   │   ├── models.py                    # SQLAlchemy models
│   │   └── schemas.py                   # Pydantic schemas
│   ├── Dockerfile                       # Backend container image
│   └── requirements.txt                 # Python dependencies
│
├── frontend/
│   ├── src/
│   │   ├── App.css                      # Application styles
│   │   ├── App.jsx                      # Main React component (Kanban board)
│   │   ├── api.js                       # API client (Axios)
│   │   └── main.jsx                     # React entry point
│   ├── .gitignore
│   ├── index.html                       # HTML template
│   ├── package.json                     # Node dependencies
│   └── vite.config.js                   # Vite configuration
│
├── infra/
│   ├── modules/
│   │   ├── acr.bicep                    # Azure Container Registry
│   │   ├── acs.bicep                    # Azure Communication Services
│   │   ├── container-app.bicep          # Backend Container App
│   │   ├── container-app-env.bicep      # Container Apps Environment
│   │   ├── postgres.bicep               # PostgreSQL Flexible Server
│   │   ├── role-assignment-acr.bicep    # ACR role assignment
│   │   └── role-assignment-acs.bicep    # ACS role assignment
│   ├── main.bicep                       # Main infrastructure template
│   └── main.bicepparam                  # Infrastructure parameters
│
├── database/
│   ├── schema.sql                       # Database schema creation
│   └── sample-data.sql                  # Sample data for testing
│
├── .gitignore                           # Git ignore rules
├── DEPLOYMENT_CHECKLIST.md              # Step-by-step deployment guide
├── GITHUB_ACTIONS_SETUP.md              # GitHub Actions configuration guide
├── instructions.md                      # Original requirements (your file)
└── README.md                            # Main documentation

```

## 📁 Directory Details

### `.github/workflows/`
GitHub Actions workflows for CI/CD:
- **deploy-infrastructure.yml**: Deploys all Azure resources using Bicep
- **deploy-backend.yml**: Builds Docker image and updates Container App
- **deploy-frontend.yml**: Builds React app and deploys to Static Web App

### `backend/`
FastAPI backend application:
- **app/main.py**: Application entry point with CORS and routing
- **app/models.py**: SQLAlchemy database models (Ticket, TicketResponse)
- **app/schemas.py**: Pydantic schemas for request/response validation
- **app/database.py**: Database connection and session management
- **app/email_service.py**: Email sending via ACS with Managed Identity
- **app/routers/tickets.py**: REST API endpoints for ticket operations
- **Dockerfile**: Container image definition
- **requirements.txt**: Python package dependencies

### `frontend/`
React frontend application:
- **src/App.jsx**: Main component with Kanban board UI
- **src/api.js**: Axios-based API client for backend communication
- **src/App.css**: Custom styling for Kanban board
- **vite.config.js**: Vite build configuration
- **package.json**: Node.js dependencies

### `infra/`
Infrastructure as Code (Bicep):
- **main.bicep**: Orchestrates all infrastructure modules
- **main.bicepparam**: Parameter file for deployment
- **modules/**: Individual Bicep modules for each Azure service
  - Uses **Standard tier PostgreSQL** (no auto-shutdown)
  - Implements **Managed Identities** throughout
  - Configures **role assignments** automatically

### `database/`
SQL scripts:
- **schema.sql**: Creates tables, indexes, and triggers
- **sample-data.sql**: Inserts test data for development

### Documentation
- **README.md**: Complete project documentation
- **GITHUB_ACTIONS_SETUP.md**: Guide for setting up GitHub Actions
- **DEPLOYMENT_CHECKLIST.md**: Step-by-step deployment verification
- **instructions.md**: Original project requirements

---

## 🔑 Key Features by Component

### Backend (FastAPI)
- ✅ RESTful API for ticket management
- ✅ PostgreSQL integration with SQLAlchemy
- ✅ Email sending via Azure Communication Services
- ✅ Managed Identity authentication (no credentials)
- ✅ CORS configured for frontend
- ✅ Health check endpoints
- ✅ Automatic ticket number generation
- ✅ Timestamp tracking for SLA metrics

### Frontend (React + Vite)
- ✅ Kanban board interface (4 columns: New, In Progress, Resolved, Closed)
- ✅ Create, read, update, delete tickets
- ✅ Modal dialogs for ticket details
- ✅ Priority badges (critical, high, medium, low)
- ✅ Real-time data refresh (30-second polling)
- ✅ Responsive design
- ✅ Beautiful gradient background
- ✅ Professional styling

### Infrastructure (Bicep)
- ✅ **PostgreSQL Standard tier** (2 vCores, 8GB RAM) - no auto-shutdown
- ✅ **Managed Identity** for Container App
- ✅ **Role assignments** for ACR pull and ACS email
- ✅ Container Apps with auto-scaling
- ✅ Azure Communication Services with managed domain
- ✅ Container Registry for Docker images
- ✅ Modular Bicep templates for maintainability

### CI/CD (GitHub Actions)
- ✅ **Federated credentials** (no secrets in GitHub)
- ✅ Separate workflows for infrastructure, backend, frontend
- ✅ Automatic builds on code changes
- ✅ Manual workflow triggers available
- ✅ ACR build integration (no Docker daemon needed)
- ✅ Output artifacts for verification

---

## 🔄 Deployment Flow

```
1. Push to GitHub (main branch)
   ↓
2. GitHub Actions triggered
   ↓
3a. Infrastructure Workflow         3b. Backend Workflow           3c. Frontend Workflow
    ├─ Deploy Bicep templates           ├─ Build Docker image          ├─ Install npm packages
    ├─ Create/update resources          ├─ Push to ACR                 ├─ Build with Vite
    ├─ Configure managed identity       └─ Update Container App        └─ Deploy to Static Web App
    └─ Assign roles
   ↓
4. Services running on Azure
   ↓
5. Access via public URLs
```

---

## 📊 Technology Stack

| Layer | Technology | Purpose |
|-------|-----------|---------|
| **Frontend** | React 18 | UI framework |
| | Vite | Build tool and dev server |
| | Axios | HTTP client |
| | TanStack Query | Data fetching and caching |
| **Backend** | FastAPI | Python web framework |
| | SQLAlchemy | ORM for database |
| | Uvicorn | ASGI server |
| | Azure SDK | ACS email integration |
| **Database** | PostgreSQL 16 | Relational database |
| **Infrastructure** | Azure Bicep | IaC templates |
| | Azure Container Apps | Backend hosting |
| | Azure Static Web Apps | Frontend hosting |
| | Azure Container Registry | Docker image storage |
| | Azure Communication Services | Email delivery |
| **CI/CD** | GitHub Actions | Automation platform |

---

## 🔐 Security Architecture

```
GitHub Actions
   │ (Federated Credential)
   ↓
Azure AD
   │ (Managed Identity)
   ↓
Container App ──→ ACR (pull images)
   │              ACS (send emails)
   │              PostgreSQL (query data)
   ↓
Static Web App
```

**No passwords or connection strings stored in:**
- GitHub repository
- Environment variables (except database URL)
- Container App configuration

All authentication uses **Managed Identity** where possible.

---

## 📈 Scaling Strategy

| Component | Current | Can Scale To |
|-----------|---------|--------------|
| Container App | 1-3 replicas | 1-30 replicas |
| PostgreSQL | Standard D2s_v3 | Up to 64 vCores |
| Static Web App | Free tier | Standard tier (custom domains, auth) |
| Container Registry | Basic | Premium (geo-replication) |

---

## 💡 Next Steps

1. **Deploy the system** using the deployment checklist
2. **Test functionality** with sample data
3. **Customize branding** (company name, colors, logo)
4. **Add features** (authentication, notifications, reporting)
5. **Monitor performance** with Application Insights
6. **Implement backups** for PostgreSQL

---

**Project Status:** ✅ Ready for deployment

**Last Updated:** 2025-11-04
