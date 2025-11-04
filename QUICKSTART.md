# Quick Start - Local Development

This guide helps you run the case management system locally for development.

## Prerequisites

- Python 3.11+
- Node.js 20+
- PostgreSQL (local or Azure)
- Git

---

## 1. Clone Repository

```bash
git clone https://github.com/YourUsername/case-management-simple.git
cd case-management-simple
```

---

## 2. Setup Backend

### Create Virtual Environment

**Windows (PowerShell):**
```powershell
cd backend
python -m venv venv
.\venv\Scripts\Activate.ps1
```

**macOS/Linux:**
```bash
cd backend
python -m venv venv
source venv/bin/activate
```

### Install Dependencies

```bash
pip install -r requirements.txt
```

### Configure Environment Variables

Create `.env` file in `backend/` directory:

```env
DATABASE_URL=postgresql://caseadmin:password@localhost:5432/casemanagement
ACS_ENDPOINT=https://your-acs.communication.azure.com
ACS_SENDER_EMAIL=DoNotReply@xxx.azurecomm.net
COMPANY_NAME=Wrangler Tax Services
AZURE_CLIENT_ID=system
```

**Note:** For local development without ACS, email sending will fail gracefully.

### Setup Local Database

**Option A: Use Azure PostgreSQL** (recommended)
```bash
# Use your deployed Azure PostgreSQL
# Connection string from Azure Portal
```

**Option B: Local PostgreSQL**
```bash
# Install PostgreSQL locally
# Create database
createdb casemanagement

# Run schema
psql -d casemanagement -f ../database/schema.sql

# Load sample data
psql -d casemanagement -f ../database/sample-data.sql
```

### Run Backend

```bash
uvicorn app.main:app --reload
```

Backend will be available at:
- API: http://localhost:8000
- API Docs: http://localhost:8000/docs
- Health: http://localhost:8000/health

---

## 3. Setup Frontend

Open a new terminal window.

### Install Dependencies

```bash
cd frontend
npm install
```

### Configure Environment

Create `.env.local` file in `frontend/` directory:

```env
VITE_API_URL=http://localhost:8000/api
```

### Run Frontend

```bash
npm run dev
```

Frontend will be available at: http://localhost:5173

---

## 4. Verify Everything Works

1. **Open Browser**: http://localhost:5173
2. **Check Kanban Board**: Should see columns (New, In Progress, Resolved, Closed)
3. **View Sample Tickets**: If you loaded sample data, tickets should appear
4. **Create Ticket**: Click "+" button
5. **Test API**: Open http://localhost:8000/docs

---

## 5. Development Workflow

### Make Backend Changes

1. Edit files in `backend/app/`
2. Save - Uvicorn auto-reloads
3. Test in API docs: http://localhost:8000/docs

### Make Frontend Changes

1. Edit files in `frontend/src/`
2. Save - Vite auto-refreshes
3. Check browser: http://localhost:5173

### Database Changes

1. Edit `database/schema.sql`
2. Run migration:
   ```bash
   psql -d casemanagement -f database/schema.sql
   ```

---

## 6. Testing

### Test Backend Endpoints

Using the API docs (http://localhost:8000/docs):

1. **GET /api/tickets/** - List all tickets
2. **POST /api/tickets/** - Create ticket
3. **GET /api/tickets/{id}** - Get specific ticket
4. **PUT /api/tickets/{id}** - Update ticket
5. **DELETE /api/tickets/{id}** - Delete ticket

### Test with cURL

```bash
# Get all tickets
curl http://localhost:8000/api/tickets/

# Create ticket
curl -X POST http://localhost:8000/api/tickets/ \
  -H "Content-Type: application/json" \
  -d '{
    "title": "Test Ticket",
    "description": "Testing API",
    "category": "general",
    "priority": "medium",
    "customer_name": "Test User",
    "customer_email": "test@example.com"
  }'
```

---

## 7. Common Issues

### Backend won't start

**Error: `ModuleNotFoundError`**
```bash
# Make sure virtual environment is activated
# Re-install dependencies
pip install -r requirements.txt
```

**Error: `Can't connect to database`**
```bash
# Check DATABASE_URL in .env
# Verify PostgreSQL is running
# Check credentials
```

### Frontend won't start

**Error: `Cannot find module`**
```bash
# Delete node_modules and reinstall
rm -rf node_modules
npm install
```

**Error: `API requests fail (CORS)`**
```bash
# Make sure backend is running on port 8000
# Check VITE_API_URL in .env.local
# Verify CORS settings in backend/app/main.py
```

### Database connection fails

**Check connection string format:**
```
postgresql://username:password@host:port/database?sslmode=require
```

**For Azure PostgreSQL:**
```
postgresql://caseadmin@servername:password@servername.postgres.database.azure.com:5432/casemanagement?sslmode=require
```

---

## 8. Hot Tips

### Auto-format Python Code

```bash
pip install black
black backend/app/
```

### Auto-format JavaScript Code

```bash
npx prettier --write frontend/src/
```

### Watch Backend Logs

```bash
# Backend logs appear in terminal automatically with --reload
```

### Debug React in Browser

1. Open DevTools (F12)
2. Check Console tab for errors
3. Check Network tab for API requests

### Test Email Locally (without ACS)

Email sending will fail gracefully in local development. To test:
1. Deploy to Azure (ACS configured)
2. Or use a local email testing tool like Mailhog

---

## 9. Environment Variables Reference

### Backend (.env)

| Variable | Required | Description | Example |
|----------|----------|-------------|---------|
| `DATABASE_URL` | Yes | PostgreSQL connection string | `postgresql://user:pass@host:5432/db` |
| `ACS_ENDPOINT` | Yes* | Azure Communication Services endpoint | `https://xxx.communication.azure.com` |
| `ACS_SENDER_EMAIL` | Yes* | Sender email address | `DoNotReply@xxx.azurecomm.net` |
| `COMPANY_NAME` | No | Company branding | `Wrangler Tax Services` |
| `AZURE_CLIENT_ID` | No | For Managed Identity | `system` |

*Required for email functionality

### Frontend (.env.local)

| Variable | Required | Description | Example |
|----------|----------|-------------|---------|
| `VITE_API_URL` | Yes | Backend API URL | `http://localhost:8000/api` |

---

## 10. Next Steps

✅ Local development environment setup
✅ Backend and frontend running
✅ Database connected

Now you can:
1. Start developing features
2. Test changes locally
3. Push to GitHub for automatic deployment
4. Use the deployment checklist to deploy to Azure

---

## 📚 Additional Resources

- **FastAPI Docs**: https://fastapi.tiangolo.com/
- **React Docs**: https://react.dev/
- **Vite Docs**: https://vitejs.dev/
- **SQLAlchemy Docs**: https://docs.sqlalchemy.org/
- **PostgreSQL Docs**: https://www.postgresql.org/docs/

---

**Happy Coding! 🚀**
