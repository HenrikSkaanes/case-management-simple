-- Case Management System Database Schema
-- PostgreSQL 16 compatible

-- ============================================
-- Table: tickets
-- ============================================
CREATE TABLE IF NOT EXISTS tickets (
    -- Primary Key
    id SERIAL PRIMARY KEY,
    
    -- Ticket Information
    ticket_number VARCHAR UNIQUE NOT NULL,
    title VARCHAR NOT NULL,
    description TEXT,
    category VARCHAR NOT NULL,
    priority VARCHAR DEFAULT 'medium',
    status VARCHAR DEFAULT 'new',
    
    -- Customer Information
    customer_name VARCHAR,
    customer_email VARCHAR,
    customer_phone VARCHAR,
    customer_id VARCHAR,
    
    -- Assignment & Ownership
    assigned_to VARCHAR,
    assigned_at TIMESTAMP WITH TIME ZONE,
    department VARCHAR,
    
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
    tags JSONB,
    satisfaction_rating INTEGER CHECK (satisfaction_rating >= 1 AND satisfaction_rating <= 5),
    reopened_count INTEGER DEFAULT 0,
    escalated BOOLEAN DEFAULT FALSE,
    notes TEXT
);

-- ============================================
-- Table: ticket_responses
-- ============================================
CREATE TABLE IF NOT EXISTS ticket_responses (
    id SERIAL PRIMARY KEY,
    ticket_id INTEGER NOT NULL REFERENCES tickets(id) ON DELETE CASCADE,
    
    -- Response Content
    response_text TEXT NOT NULL,
    sent_by VARCHAR,
    
    -- Email Delivery Tracking
    email_status VARCHAR DEFAULT 'pending',
    email_message_id VARCHAR,
    email_error_message TEXT,
    
    -- Timestamps
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    sent_at TIMESTAMP WITH TIME ZONE,
    delivered_at TIMESTAMP WITH TIME ZONE
);

-- ============================================
-- Indexes for Performance
-- ============================================

-- Tickets table indexes
CREATE INDEX IF NOT EXISTS idx_tickets_status ON tickets(status);
CREATE INDEX IF NOT EXISTS idx_tickets_priority ON tickets(priority);
CREATE INDEX IF NOT EXISTS idx_tickets_category ON tickets(category);
CREATE INDEX IF NOT EXISTS idx_tickets_created_at ON tickets(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_tickets_customer_email ON tickets(customer_email);
CREATE INDEX IF NOT EXISTS idx_tickets_assigned_to ON tickets(assigned_to);
CREATE INDEX IF NOT EXISTS idx_tickets_ticket_number ON tickets(ticket_number);

-- Ticket responses table indexes
CREATE INDEX IF NOT EXISTS idx_ticket_responses_ticket_id ON ticket_responses(ticket_id);
CREATE INDEX IF NOT EXISTS idx_ticket_responses_created_at ON ticket_responses(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_ticket_responses_email_status ON ticket_responses(email_status);

-- ============================================
-- Function: Update updated_at timestamp
-- ============================================
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Trigger for tickets table
DROP TRIGGER IF EXISTS update_tickets_updated_at ON tickets;
CREATE TRIGGER update_tickets_updated_at
    BEFORE UPDATE ON tickets
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- ============================================
-- Sample Data (Optional)
-- ============================================
-- Uncomment to insert sample tickets for testing

/*
INSERT INTO tickets (ticket_number, title, description, category, priority, status, customer_name, customer_email)
VALUES 
    ('TAX-2025-0001', 'Tax Deduction Question', 'Can I deduct home office expenses?', 'deductions', 'medium', 'new', 'John Doe', 'john@example.com'),
    ('VAT-2025-0001', 'VAT Return Issue', 'Need help with Q3 VAT return', 'vat', 'high', 'in_progress', 'Jane Smith', 'jane@example.com'),
    ('INC-2025-0001', 'Income Tax Filing', 'Deadline approaching for income tax', 'income_tax', 'critical', 'new', 'Bob Johnson', 'bob@example.com'),
    ('GEN-2025-0001', 'General Inquiry', 'What documents do I need for tax filing?', 'general', 'low', 'resolved', 'Alice Williams', 'alice@example.com'),
    ('DED-2025-0001', 'Business Expense Deduction', 'Questions about business travel expenses', 'deductions', 'medium', 'in_progress', 'Charlie Brown', 'charlie@example.com');
*/

-- ============================================
-- Verification Query
-- ============================================
-- Run this to verify the schema was created successfully

DO $$
BEGIN
    RAISE NOTICE 'Database schema created successfully!';
    RAISE NOTICE 'Tables: tickets, ticket_responses';
    RAISE NOTICE 'Indexes: Created for optimal query performance';
    RAISE NOTICE 'Triggers: auto-update timestamps enabled';
END $$;
