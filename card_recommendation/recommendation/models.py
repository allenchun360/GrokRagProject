from uuid import uuid4

from django.db import models


class Issuer(models.Model):
    """(e.g., Bank of America)"""
    id = models.UUIDField(primary_key=True, default=uuid4, editable=False)
    name = models.CharField(max_length=100)

    def __str__(self):
        return self.name


class Card(models.Model):
    """(e.g., Chase Sapphire Preferred)"""
    id = models.UUIDField(primary_key=True, default=uuid4, editable=False)
    issuer = models.ForeignKey(Issuer, on_delete=models.CASCADE)
    name = models.CharField(max_length=100)
    base_point_value = models.DecimalField(max_digits=4, decimal_places=2, null=True, blank=True)

    def __str__(self):
        return self.name


class MerchantCategory(models.Model):
    """(e.g., Gas, Online Shopping, Dining, etc.)"""
    id = models.UUIDField(primary_key=True, default=uuid4, editable=False)
    name = models.CharField(max_length=100)

    def __str__(self):
        return self.name


class MerchantCategoryCode(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid4, editable=False)
    code = models.CharField(max_length=4, unique=True)
    description = models.TextField()

    def __str__(self):
        return f"{self.code}: {self.description}"


class RewardCategory(models.Model):
    """Card & Merchant Category mapping"""
    id = models.UUIDField(primary_key=True, default=uuid4, editable=False)
    card = models.ForeignKey(Card, on_delete=models.CASCADE)
    merchant_category = models.ForeignKey(MerchantCategory, on_delete=models.CASCADE)
    merchant_category_codes = models.ManyToManyField(MerchantCategoryCode, blank=True)

    def __str__(self):
        return f"{self.card.name}: {self.merchant_category.name})"


class RewardRate(models.Model):
    """Card Benefits (e.g. cashback percentage, credit card points)"""
    id = models.UUIDField(primary_key=True, default=uuid4, editable=False)
    reward_category = models.OneToOneField(RewardCategory, on_delete=models.CASCADE)
    cashback_percentage = models.DecimalField(max_digits=4, decimal_places=2, null=True, blank=True)
    points = models.IntegerField(null=True, blank=True)
    reset_period = models.CharField(max_length=50, blank=True)
    limit = models.DecimalField(max_digits=10, decimal_places=2, null=True, blank=True)

    def __str__(self):
        rewards = []
        if self.cashback_percentage:
            rewards.append(f"{self.cashback_percentage}%")
        if self.points:
            rewards.append(f"{self.points} points")
        
        if rewards:
            return "Rate: " + " / ".join(rewards)
        return "No rewards specified"

