from rest_framework_simplejwt.tokens import RefreshToken
from rest_framework.serializers import ModelSerializer, SerializerMethodField
from users.models import User, UserCard
from recommendation.serializers import CardSerializer

# Add serializers
class UserSerializer(ModelSerializer):
    token = SerializerMethodField()

    def get_token(self, user):
        refresh = RefreshToken.for_user(user)

        return {
            'refresh': str(refresh),
            'access': str(refresh.access_token),
        }
    
    class Meta:
        model = User
        fields = ['id', 'first_name', 'last_name', 'email', 'username', 'token', 'phone_number']

class UserCardSerializer(ModelSerializer):
    card_model = CardSerializer(read_only=True)

    class Meta:
        model = UserCard
        fields = ['id', 'name', 'card_number', 'expiration_date', 'cvv', 'card_model']
