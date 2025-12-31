import random
from uuid import uuid4

from django.contrib.auth.models import AbstractUser
from django.contrib.auth import get_user_model
from django.db import models
from django.utils.translation import gettext_lazy as _
from django.utils import timezone
from django.core.validators import RegexValidator
from recommendation.models import Card

def random_code():
    return "".join([str(random.randint(0, 9)) for _ in range(6)])

class User(AbstractUser):
    id = models.UUIDField(primary_key=True, default=uuid4, editable=False)
    phone_regex = RegexValidator(
        regex=r'^\+?1?\d{9,15}$',
        message=_("Phone number must be entered in the format: '+999999999'. Up to 15 digits allowed.")
    )
    phone_number = models.CharField(validators=[phone_regex], max_length=17, unique=True)

class UserCard(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid4, editable=False)
    user = models.ForeignKey(get_user_model(), on_delete=models.CASCADE, related_name="cards", null=True, blank=True)
    card_model = models.ForeignKey(Card, on_delete=models.CASCADE, null=True, blank=True)
    name = models.CharField(
        max_length=100,
        help_text="Name on card",
        blank=True
    )
    card_number = models.CharField(
        max_length=19,  # To accommodate 16 digits plus possible spaces/hyphens
        help_text="Card number",
        blank=True
    )
    expiration_date = models.CharField(
        max_length=5,  # MM/YY format
        validators=[
            RegexValidator(
                regex=r'^(0[1-9]|1[0-2])/([0-9]{2})$',
                message="Enter date in MM/YY format (e.g., 12/25)"
            )
        ],
        help_text="Card expiration date in MM/YY format",
        blank=True
    )
    cvv = models.CharField(
        max_length=4,  # Some cards have 4-digit CVV
        help_text="Card security code",
        blank=True
    )
    created_at = models.DateTimeField(auto_now_add=True)
    
    def save(self, *args, **kwargs):
        # Remove any spaces or hyphens from card number before saving
        self.card_number = ''.join(filter(str.isdigit, self.card_number))
        super().save(*args, **kwargs)

class PhoneAuthentication(models.Model):
    phone_regex = RegexValidator(
        regex=r'^\+?1?\d{9,15}$',
        message=_("Phone number must be entered in the format: '+999999999'. Up to 15 digits allowed.")
    )
    phone_number = models.CharField(validators=[phone_regex], max_length=17)
    code = models.CharField(max_length=6, default=random_code)
    is_verified = models.BooleanField(default=False)
    proxy_uuid = models.UUIDField(default=uuid4)
