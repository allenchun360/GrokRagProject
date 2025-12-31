from rest_framework import status
from rest_framework.response import Response
from rest_framework.generics import CreateAPIView, UpdateAPIView
from rest_framework.serializers import ModelSerializer, BooleanField
from users.models import User, PhoneAuthentication
from users.serializers import UserSerializer

from django.utils.translation import gettext_lazy as _
from django.db import IntegrityError, transaction
from django.shortcuts import get_object_or_404

from twilio_config import twilio_client, twilio_phone_number
from twilio.base.exceptions import TwilioException


class SendPhoneCodeSerializer(ModelSerializer):
    is_register = BooleanField()

    class Meta:
        model = PhoneAuthentication
        fields = (
          'phone_number',
          'is_register'
        )

class SendPhoneCode(CreateAPIView):
    serializer_class = SendPhoneCodeSerializer

    def create(self, request, *args, **kwargs):
        code_request = self.serializer_class(data=request.data)
        code_request.is_valid(raise_exception=True)

        phone_number = code_request.data.get('phone_number')
        is_register = code_request.data.get("is_register")

        PhoneAuthentication.objects.filter(phone_number=phone_number).delete()

        if phone_number is None or is_register is None:
            return Response("Missing information", status=400)
        
        customer = User.objects.filter(username=phone_number)

        if is_register and customer.exists():
            return Response({"error": "User already exists"}, status=400)
        elif not is_register and not customer.exists():
            return Response({"error": "User does not exist"}, status=400)
        
        phone_auth = PhoneAuthentication.objects.create(
            phone_number=phone_number,
        )
        
        try:
            twilio_client.messages.create(
                body=f"Your code for AIO is {phone_auth.code}",
                from_=twilio_phone_number,
                to=str(phone_number),
            )
        except TwilioException as e:
            return Response({'error': 'Failed to send message'}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


        return Response(
            code_request.data,
            status.HTTP_201_CREATED,
        )


class RegisterVerifyPhoneCodeSerializer(ModelSerializer):

    class Meta:
        model = PhoneAuthentication
        fields = (
          'phone_number',
          'code',
          'proxy_uuid',
        )

class RegisterVerifyPhoneCode(UpdateAPIView):
    serializer_class = RegisterVerifyPhoneCodeSerializer

    def update(self, request, *args, **kwargs):
        verify_request = self.serializer_class(data=request.data)
        verify_request.is_valid(raise_exception=True)

        phone_number = verify_request.data.get('phone_number')
        code = verify_request.data.get('code')
        
        phone_auths = PhoneAuthentication.objects.filter(
            phone_number=phone_number,
            code=code,
        )
        
        if not phone_auths.exists():
            return Response(
                {
                    'error': 'Code does not match',
                },
                status.HTTP_400_BAD_REQUEST,                
            )
        
        phone_auths.update(is_verified=True)
        PhoneAuthentication.objects.filter(phone_number=phone_number).delete()

        # REGISTRATION
        phone_number = verify_request.data.get("phone_number")

        try:
            user = User.objects.create_user(
                username=phone_number, 
                phone_number=phone_number,
            )
        except IntegrityError:
            return Response(
                {
                    'detail': 'Phone number already registered',
                },
                status=status.HTTP_400_BAD_REQUEST,
            )
        user_serializer = UserSerializer(user)

        return Response(
            {
                'detail': 'User registered successfully',
                'user': user_serializer.data,
            },
            status=status.HTTP_201_CREATED,
        )

class LoginVerifyPhoneCodeSerializer(ModelSerializer):
    class Meta:
        model = PhoneAuthentication
        fields = (
          'phone_number',
          'code',
        )

class LoginVerifyPhoneCode(UpdateAPIView):
    serializer_class = LoginVerifyPhoneCodeSerializer

    def update(self, request, *args, **kwargs):
        verify_request = self.serializer_class(data=request.data)
        verify_request.is_valid(raise_exception=True)

        phone_number = verify_request.data.get('phone_number')
        code = verify_request.data.get('code')

        customer = get_object_or_404(User, username=phone_number)

        phone_auths = PhoneAuthentication.objects.filter(
            phone_number=phone_number,
            code=code,
        )

        if not phone_auths.exists():
            return Response(
                {
                    'error': 'Code does not match',
                },
                status=status.HTTP_400_BAD_REQUEST,
            )

        try:
            with transaction.atomic():
                phone_auths.update(is_verified=True)
                PhoneAuthentication.objects.filter(phone_number=phone_number).delete()
        except IntegrityError:
            return Response(
                {
                    'message': 'Error verifying phone code.',
                },
                status=status.HTTP_500_INTERNAL_SERVER_ERROR,
            )

        user_serializer = UserSerializer(customer)
        return Response(
            {
                'message': 'Login successful.',
                'user': user_serializer.data,
            },
            status=status.HTTP_200_OK,
        )
