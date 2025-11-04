from azure.communication.email import EmailClient
from azure.identity import DefaultAzureCredential, ManagedIdentityCredential
from .config import settings
import logging

logger = logging.getLogger(__name__)

class EmailService:
    def __init__(self):
        # Use Managed Identity for authentication
        try:
            if settings.azure_client_id == "system":
                # System-assigned managed identity
                credential = ManagedIdentityCredential()
            else:
                # User-assigned managed identity
                credential = ManagedIdentityCredential(client_id=settings.azure_client_id)
            
            self.email_client = EmailClient(settings.acs_endpoint, credential)
            logger.info("Email client initialized with Managed Identity")
        except Exception as e:
            logger.error(f"Failed to initialize email client: {str(e)}")
            # Fallback to DefaultAzureCredential
            credential = DefaultAzureCredential()
            self.email_client = EmailClient(settings.acs_endpoint, credential)
            logger.info("Email client initialized with DefaultAzureCredential")
    
    async def send_ticket_response(
        self,
        recipient_email: str,
        recipient_name: str,
        ticket_number: str,
        response_text: str,
        sent_by: str = None
    ) -> tuple[bool, str, str]:
        """
        Send email response to customer
        Returns: (success: bool, message_id: str, error: str)
        """
        try:
            sender = settings.acs_sender_email
            
            # Create email message
            message = {
                "senderAddress": sender,
                "recipients": {
                    "to": [{"address": recipient_email, "displayName": recipient_name}]
                },
                "content": {
                    "subject": f"Response to Ticket {ticket_number} - {settings.company_name}",
                    "plainText": f"""
Dear {recipient_name},

Thank you for contacting {settings.company_name}.

{response_text}

---
Ticket Reference: {ticket_number}
{f'Handled by: {sent_by}' if sent_by else ''}

If you have any further questions, please reply to this email or contact us directly.

Best regards,
{settings.company_name}
                    """,
                    "html": f"""
<!DOCTYPE html>
<html>
<head>
    <style>
        body {{ font-family: Arial, sans-serif; line-height: 1.6; color: #333; }}
        .container {{ max-width: 600px; margin: 0 auto; padding: 20px; }}
        .header {{ background-color: #0066cc; color: white; padding: 20px; text-align: center; }}
        .content {{ padding: 20px; background-color: #f9f9f9; }}
        .footer {{ padding: 15px; text-align: center; font-size: 12px; color: #666; }}
        .ticket-ref {{ background-color: #e8f4f8; padding: 10px; margin: 15px 0; border-left: 4px solid #0066cc; }}
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h2>{settings.company_name}</h2>
        </div>
        <div class="content">
            <p>Dear {recipient_name},</p>
            <p>Thank you for contacting {settings.company_name}.</p>
            <p>{response_text}</p>
            <div class="ticket-ref">
                <strong>Ticket Reference:</strong> {ticket_number}<br>
                {f'<strong>Handled by:</strong> {sent_by}' if sent_by else ''}
            </div>
            <p>If you have any further questions, please reply to this email or contact us directly.</p>
            <p>Best regards,<br>{settings.company_name}</p>
        </div>
        <div class="footer">
            <p>This is an automated message from {settings.company_name}</p>
        </div>
    </div>
</body>
</html>
                    """
                }
            }
            
            # Send email
            poller = self.email_client.begin_send(message)
            result = poller.result()
            
            logger.info(f"Email sent successfully. Message ID: {result['id']}")
            return True, result['id'], ""
            
        except Exception as e:
            error_msg = str(e)
            logger.error(f"Failed to send email: {error_msg}")
            return False, "", error_msg

# Singleton instance
email_service = EmailService()
