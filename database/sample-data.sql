-- Sample data for testing the Case Management System

-- Insert sample tickets
INSERT INTO tickets (ticket_number, title, description, category, priority, status, customer_name, customer_email, customer_phone, assigned_to, department)
VALUES 
    ('TAX-2025-0001', 'Tax Deduction Question', 'Customer wants to know if home office expenses are deductible for 2024.', 'deductions', 'medium', 'new', 'John Doe', 'john.doe@example.com', '+47 123 45 678', NULL, 'returns'),
    
    ('VAT-2025-0001', 'VAT Return Issue', 'Need assistance with Q3 2024 VAT return submission. Numbers don''t match.', 'vat', 'high', 'in_progress', 'Jane Smith', 'jane.smith@example.com', '+47 234 56 789', 'Erik Hansen', 'compliance'),
    
    ('INC-2025-0001', 'Income Tax Filing Deadline', 'Approaching deadline for income tax filing. Need urgent assistance.', 'income_tax', 'critical', 'new', 'Bob Johnson', 'bob.johnson@example.com', '+47 345 67 890', NULL, 'returns'),
    
    ('GEN-2025-0001', 'Required Documents', 'What documents are needed for annual tax filing?', 'general', 'low', 'resolved', 'Alice Williams', 'alice.williams@example.com', NULL, 'Siri Olsen', 'general'),
    
    ('DED-2025-0002', 'Business Travel Expenses', 'Questions about deducting business travel and meal expenses.', 'deductions', 'medium', 'in_progress', 'Charlie Brown', 'charlie.brown@example.com', '+47 456 78 901', 'Per Larsen', 'returns'),
    
    ('COM-2025-0001', 'Compliance Audit Support', 'Need help preparing for upcoming tax audit.', 'compliance', 'high', 'new', 'David Miller', 'david.miller@example.com', '+47 567 89 012', NULL, 'compliance'),
    
    ('VAT-2025-0002', 'VAT Registration', 'New business needs help with VAT registration process.', 'vat', 'medium', 'resolved', 'Emma Davis', 'emma.davis@example.com', '+47 678 90 123', 'Kari Nordmann', 'compliance'),
    
    ('INC-2025-0002', 'Tax Credit Inquiry', 'How to claim research and development tax credits?', 'income_tax', 'low', 'closed', 'Frank Wilson', 'frank.wilson@example.com', NULL, 'Siri Olsen', 'returns');

-- Update some tickets with response times
UPDATE tickets 
SET 
    first_response_at = created_at + INTERVAL '2 hours',
    response_time_minutes = 120
WHERE status IN ('in_progress', 'resolved', 'closed');

UPDATE tickets 
SET 
    resolved_at = created_at + INTERVAL '1 day',
    resolution_time_minutes = 1440
WHERE status IN ('resolved', 'closed');

UPDATE tickets 
SET 
    closed_at = resolved_at + INTERVAL '2 hours'
WHERE status = 'closed';

-- Insert sample responses
INSERT INTO ticket_responses (ticket_id, response_text, sent_by, email_status, sent_at)
VALUES 
    (
        (SELECT id FROM tickets WHERE ticket_number = 'VAT-2025-0001'),
        'Thank you for contacting us. I have reviewed your Q3 VAT return and identified the discrepancy. The issue was in line 5 where input VAT was incorrectly calculated. I will send you a corrected version shortly.',
        'Erik Hansen',
        'sent',
        NOW() - INTERVAL '1 day'
    ),
    (
        (SELECT id FROM tickets WHERE ticket_number = 'GEN-2025-0001'),
        'For your annual tax filing, you will need: 1) Income statements (salary slips), 2) Bank statements, 3) Receipts for deductible expenses, 4) Previous year''s tax return. Please gather these documents and we can schedule a meeting.',
        'Siri Olsen',
        'sent',
        NOW() - INTERVAL '2 days'
    ),
    (
        (SELECT id FROM tickets WHERE ticket_number = 'DED-2025-0002'),
        'Business travel expenses are deductible. You can deduct: transportation costs, accommodation, and 50% of meal expenses. Keep all receipts and maintain a travel log with business purposes documented.',
        'Per Larsen',
        'sent',
        NOW() - INTERVAL '3 hours'
    );

-- Add some tags to tickets
UPDATE tickets SET tags = '["urgent", "vip"]'::jsonb WHERE priority = 'critical';
UPDATE tickets SET tags = '["follow-up-required"]'::jsonb WHERE status = 'in_progress';
UPDATE tickets SET tags = '["documentation", "new-customer"]'::jsonb WHERE category = 'general';

-- Set due dates for open tickets (7 days from creation)
UPDATE tickets 
SET due_date = created_at + INTERVAL '7 days'
WHERE status IN ('new', 'in_progress');

-- Display summary
SELECT 
    'Sample data loaded successfully!' as message,
    (SELECT COUNT(*) FROM tickets) as total_tickets,
    (SELECT COUNT(*) FROM ticket_responses) as total_responses;

-- Show tickets by status
SELECT 
    status,
    COUNT(*) as count
FROM tickets
GROUP BY status
ORDER BY 
    CASE status
        WHEN 'new' THEN 1
        WHEN 'in_progress' THEN 2
        WHEN 'resolved' THEN 3
        WHEN 'closed' THEN 4
    END;
