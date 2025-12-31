from django.contrib import admin
from .models import Issuer, Card, MerchantCategory, MerchantCategoryCode, RewardCategory, RewardRate

# Register your models here.
@admin.register(Issuer)
class IssuerAdmin(admin.ModelAdmin):
    list_display = ("id", "name")
    search_fields = ("name",)


@admin.register(Card)
class CardAdmin(admin.ModelAdmin):
    list_display = ("id", "name", "issuer", "base_point_value")
    list_filter = ("issuer",)
    search_fields = ("name", "issuer__name")


@admin.register(MerchantCategory)
class MerchantCategoryAdmin(admin.ModelAdmin):
    list_display = ("id", "name")
    search_fields = ("name",)


@admin.register(MerchantCategoryCode)
class MerchantCategoryCodeAdmin(admin.ModelAdmin):
    list_display = ("id", "code", "description")
    search_fields = ("code", "description")


class RewardRateInline(admin.StackedInline):
    model = RewardRate
    extra = 0


@admin.register(RewardCategory)
class RewardCategoryAdmin(admin.ModelAdmin):
    list_display = ("id", "card", "merchant_category")
    list_filter = ("card__issuer", "merchant_category")
    search_fields = ("card__name", "merchant_category__name")
    filter_horizontal = ("merchant_category_codes",)

    inlines = [RewardRateInline]

@admin.register(RewardRate)
class RewardRateAdmin(admin.ModelAdmin):
    list_display = ("id", "reward_category", "cashback_percentage", "points", "limit", "reset_period")
    list_filter = ("reset_period",)
    search_fields = ("reward_category__card__name", "reward_category__merchant_category__name")
