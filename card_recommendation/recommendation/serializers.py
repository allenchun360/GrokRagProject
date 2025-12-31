from rest_framework import serializers
from .models import RewardRate, Card, Issuer

class IssuerSerializer(serializers.ModelSerializer):
    class Meta:
        model = Issuer
        fields = ['id', 'name']

class CardSerializer(serializers.ModelSerializer):
    issuer = IssuerSerializer(read_only=True)

    class Meta:
        model = Card
        fields = ['id', 'name', 'issuer', 'base_point_value']

class RewardRateSerializer(serializers.ModelSerializer):
    card = serializers.SerializerMethodField()

    class Meta:
        model = RewardRate
        fields = ['card', 'cashback_percentage', 'points', 'reset_period', 'limit']

    def get_card(self, obj):
        return CardSerializer(obj.reward_category.card).data
