from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List
from datetime import datetime
from .. import models, schemas
from ..database import get_db
from ..email_service import email_service

router = APIRouter(prefix="/tickets", tags=["tickets"])

def generate_ticket_number(db: Session, category: str) -> str:
    """Generate unique ticket number like TAX-2025-0001"""
    year = datetime.now().year
    prefix = category.upper()[:3]
    
    # Get the latest ticket for this year
    latest = db.query(models.Ticket).filter(
        models.Ticket.ticket_number.like(f"{prefix}-{year}-%")
    ).order_by(models.Ticket.id.desc()).first()
    
    if latest and latest.ticket_number:
        # Extract number and increment
        try:
            last_num = int(latest.ticket_number.split('-')[-1])
            new_num = last_num + 1
        except:
            new_num = 1
    else:
        new_num = 1
    
    return f"{prefix}-{year}-{new_num:04d}"

@router.get("/", response_model=List[schemas.Ticket])
def get_tickets(
    skip: int = 0,
    limit: int = 100,
    status: str = None,
    category: str = None,
    priority: str = None,
    db: Session = Depends(get_db)
):
    """Get all tickets with optional filters"""
    query = db.query(models.Ticket)
    
    if status:
        query = query.filter(models.Ticket.status == status)
    if category:
        query = query.filter(models.Ticket.category == category)
    if priority:
        query = query.filter(models.Ticket.priority == priority)
    
    tickets = query.order_by(models.Ticket.created_at.desc()).offset(skip).limit(limit).all()
    return tickets

@router.get("/{ticket_id}", response_model=schemas.Ticket)
def get_ticket(ticket_id: int, db: Session = Depends(get_db)):
    """Get a specific ticket by ID"""
    ticket = db.query(models.Ticket).filter(models.Ticket.id == ticket_id).first()
    if not ticket:
        raise HTTPException(status_code=404, detail="Ticket not found")
    return ticket

@router.post("/", response_model=schemas.Ticket, status_code=status.HTTP_201_CREATED)
def create_ticket(ticket: schemas.TicketCreate, db: Session = Depends(get_db)):
    """Create a new ticket"""
    # Generate ticket number
    ticket_number = generate_ticket_number(db, ticket.category)
    
    # Create ticket
    db_ticket = models.Ticket(
        **ticket.model_dump(),
        ticket_number=ticket_number
    )
    db.add(db_ticket)
    db.commit()
    db.refresh(db_ticket)
    return db_ticket

@router.put("/{ticket_id}", response_model=schemas.Ticket)
def update_ticket(
    ticket_id: int,
    ticket_update: schemas.TicketUpdate,
    db: Session = Depends(get_db)
):
    """Update a ticket"""
    db_ticket = db.query(models.Ticket).filter(models.Ticket.id == ticket_id).first()
    if not db_ticket:
        raise HTTPException(status_code=404, detail="Ticket not found")
    
    # Update only provided fields
    update_data = ticket_update.model_dump(exclude_unset=True)
    for field, value in update_data.items():
        setattr(db_ticket, field, value)
    
    # Update timestamps based on status changes
    if "status" in update_data:
        if update_data["status"] == "in_progress" and not db_ticket.first_response_at:
            db_ticket.first_response_at = datetime.utcnow()
        elif update_data["status"] == "resolved" and not db_ticket.resolved_at:
            db_ticket.resolved_at = datetime.utcnow()
        elif update_data["status"] == "closed" and not db_ticket.closed_at:
            db_ticket.closed_at = datetime.utcnow()
    
    db.commit()
    db.refresh(db_ticket)
    return db_ticket

@router.delete("/{ticket_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_ticket(ticket_id: int, db: Session = Depends(get_db)):
    """Delete a ticket"""
    db_ticket = db.query(models.Ticket).filter(models.Ticket.id == ticket_id).first()
    if not db_ticket:
        raise HTTPException(status_code=404, detail="Ticket not found")
    
    db.delete(db_ticket)
    db.commit()
    return None

@router.post("/{ticket_id}/respond", response_model=schemas.TicketResponse)
async def send_ticket_response(
    ticket_id: int,
    email_request: schemas.EmailRequest,
    db: Session = Depends(get_db)
):
    """Send an email response to the customer"""
    # Get ticket
    ticket = db.query(models.Ticket).filter(models.Ticket.id == ticket_id).first()
    if not ticket:
        raise HTTPException(status_code=404, detail="Ticket not found")
    
    if not ticket.customer_email:
        raise HTTPException(status_code=400, detail="Ticket has no customer email")
    
    # Create response record
    db_response = models.TicketResponse(
        ticket_id=ticket_id,
        response_text=email_request.response_text,
        sent_by=email_request.sent_by,
        email_status='pending'
    )
    db.add(db_response)
    db.commit()
    db.refresh(db_response)
    
    # Send email
    success, message_id, error = await email_service.send_ticket_response(
        recipient_email=ticket.customer_email,
        recipient_name=ticket.customer_name or "Customer",
        ticket_number=ticket.ticket_number,
        response_text=email_request.response_text,
        sent_by=email_request.sent_by
    )
    
    # Update response record
    if success:
        db_response.email_status = 'sent'
        db_response.email_message_id = message_id
        db_response.sent_at = datetime.utcnow()
        
        # Update ticket first_response_at if not set
        if not ticket.first_response_at:
            ticket.first_response_at = datetime.utcnow()
    else:
        db_response.email_status = 'failed'
        db_response.email_error_message = error
    
    db.commit()
    db.refresh(db_response)
    
    if not success:
        raise HTTPException(status_code=500, detail=f"Failed to send email: {error}")
    
    return db_response

@router.get("/{ticket_id}/responses", response_model=List[schemas.TicketResponse])
def get_ticket_responses(ticket_id: int, db: Session = Depends(get_db)):
    """Get all responses for a ticket"""
    ticket = db.query(models.Ticket).filter(models.Ticket.id == ticket_id).first()
    if not ticket:
        raise HTTPException(status_code=404, detail="Ticket not found")
    
    responses = db.query(models.TicketResponse).filter(
        models.TicketResponse.ticket_id == ticket_id
    ).order_by(models.TicketResponse.created_at.desc()).all()
    
    return responses
