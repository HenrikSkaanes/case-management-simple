from sqlalchemy import Column, Integer, String, Text, Boolean, TIMESTAMP, ForeignKey, Index
from sqlalchemy.dialects.postgresql import JSONB
from sqlalchemy.sql import func
from sqlalchemy.orm import relationship
from .database import Base

class Ticket(Base):
    __tablename__ = "tickets"
    
    # Primary Key
    id = Column(Integer, primary_key=True, index=True)
    
    # Ticket Information
    ticket_number = Column(String, unique=True, index=True)
    title = Column(String, nullable=False)
    description = Column(Text)
    category = Column(String, nullable=False, index=True)
    priority = Column(String, default='medium', index=True)
    status = Column(String, default='new', index=True)
    
    # Customer Information
    customer_name = Column(String)
    customer_email = Column(String, index=True)
    customer_phone = Column(String)
    customer_id = Column(String)
    
    # Assignment & Ownership
    assigned_to = Column(String, index=True)
    assigned_at = Column(TIMESTAMP(timezone=True))
    department = Column(String)
    
    # Timeline & SLA Tracking
    created_at = Column(TIMESTAMP(timezone=True), server_default=func.now(), index=True)
    updated_at = Column(TIMESTAMP(timezone=True), server_default=func.now(), onupdate=func.now())
    first_response_at = Column(TIMESTAMP(timezone=True))
    resolved_at = Column(TIMESTAMP(timezone=True))
    closed_at = Column(TIMESTAMP(timezone=True))
    due_date = Column(TIMESTAMP(timezone=True))
    
    # Calculated Metrics (in minutes)
    response_time_minutes = Column(Integer)
    resolution_time_minutes = Column(Integer)
    
    # Analytics & Additional Data
    tags = Column(JSONB)
    satisfaction_rating = Column(Integer)
    reopened_count = Column(Integer, default=0)
    escalated = Column(Boolean, default=False)
    notes = Column(Text)
    
    # Relationship
    responses = relationship("TicketResponse", back_populates="ticket", cascade="all, delete-orphan")

class TicketResponse(Base):
    __tablename__ = "ticket_responses"
    
    id = Column(Integer, primary_key=True, index=True)
    ticket_id = Column(Integer, ForeignKey("tickets.id", ondelete="CASCADE"), nullable=False, index=True)
    
    # Response Content
    response_text = Column(Text, nullable=False)
    sent_by = Column(String)
    
    # Email Delivery Tracking
    email_status = Column(String, default='pending')
    email_message_id = Column(String)
    email_error_message = Column(Text)
    
    # Timestamps
    created_at = Column(TIMESTAMP(timezone=True), server_default=func.now(), index=True)
    sent_at = Column(TIMESTAMP(timezone=True))
    delivered_at = Column(TIMESTAMP(timezone=True))
    
    # Relationship
    ticket = relationship("Ticket", back_populates="responses")
