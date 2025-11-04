from pydantic_settings import BaseSettings

class Settings(BaseSettings):
    # Database
    database_url: str
    
    # Azure Communication Services
    acs_endpoint: str
    acs_sender_email: str
    
    # Application
    company_name: str = "Wrangler Tax Services"
    
    # Azure Managed Identity
    azure_client_id: str = "system"
    
    class Config:
        env_file = ".env"
        case_sensitive = False

settings = Settings()
