from pydantic import BaseModel, EmailStr
from typing import Optional, List, Any
from datetime import datetime

# Ticket Schemas
class TicketBase(BaseModel):
    title: str
    description: Optional[str] = None
    category: str
    priority: Optional[str] = "medium"
    status: Optional[str] = "new"
    customer_name: Optional[str] = None
    customer_email: Optional[str] = None
    customer_phone: Optional[str] = None
    customer_id: Optional[str] = None
    assigned_to: Optional[str] = None
    department: Optional[str] = None
    tags: Optional[Any] = None
    notes: Optional[str] = None

class TicketCreate(TicketBase):
    pass

class TicketUpdate(BaseModel):
    title: Optional[str] = None
    description: Optional[str] = None
    category: Optional[str] = None
    priority: Optional[str] = None
    status: Optional[str] = None
    customer_name: Optional[str] = None
    customer_email: Optional[str] = None
    customer_phone: Optional[str] = None
    customer_id: Optional[str] = None
    assigned_to: Optional[str] = None
    department: Optional[str] = None
    tags: Optional[Any] = None
    notes: Optional[str] = None

class Ticket(TicketBase):
    id: int
    ticket_number: Optional[str] = None
    assigned_at: Optional[datetime] = None
    created_at: datetime
    updated_at: datetime
    first_response_at: Optional[datetime] = None
    resolved_at: Optional[datetime] = None
    closed_at: Optional[datetime] = None
    due_date: Optional[datetime] = None
    response_time_minutes: Optional[int] = None
    resolution_time_minutes: Optional[int] = None
    satisfaction_rating: Optional[int] = None
    reopened_count: int = 0
    escalated: bool = False
    
    class Config:
        from_attributes = True

# Ticket Response Schemas
class TicketResponseBase(BaseModel):
    response_text: str
    sent_by: Optional[str] = None

class TicketResponseCreate(TicketResponseBase):
    pass

class TicketResponse(TicketResponseBase):
    id: int
    ticket_id: int
    email_status: str
    email_message_id: Optional[str] = None
    email_error_message: Optional[str] = None
    created_at: datetime
    sent_at: Optional[datetime] = None
    delivered_at: Optional[datetime] = None
    
    class Config:
        from_attributes = True

# Email Request Schema
class EmailRequest(BaseModel):
    response_text: str
    sent_by: Optional[str] = None
