"""card_recommendation URL Configuration

The `urlpatterns` list routes URLs to views. For more information please see:
    https://docs.djangoproject.com/en/4.1/topics/http/urls/
Examples:
Function views
    1. Add an import:  from my_app import views
    2. Add a URL to urlpatterns:  path('', views.home, name='home')
Class-based views
    1. Add an import:  from other_app.views import Home
    2. Add a URL to urlpatterns:  path('', Home.as_view(), name='home')
Including another URLconf
    1. Import the include() function: from django.urls import include, path
    2. Add a URL to urlpatterns:  path('blog/', include('blog.urls'))
"""
from django.contrib import admin
from django.urls import path, include
from users.views import UserViewSet, UserCardListView
from users.login_views import SendPhoneCode, RegisterVerifyPhoneCode, LoginVerifyPhoneCode
from users.views import get_user, update_user, delete_user, get_nearby_stores, create_user_cards, delete_user_card, get_online_stores

from recommendation.views import get_card_benefits_by_types, CardListView, analyze_cards_with_gpt, analyze_cards_with_gpt_streaming, get_card_details_streaming

from rest_framework.routers import DefaultRouter

from rest_framework_simplejwt.views import (
    TokenRefreshView,
)

router = DefaultRouter()
router.register(r'users', UserViewSet, basename='user')

urlpatterns = [
    path('api/token/refresh/', TokenRefreshView.as_view(), name='token_refresh'),
    path('api/', include(router.urls)),

    path('admin/', admin.site.urls),
    path('send-phone-code/', SendPhoneCode.as_view()),
    path('register-verify-phone-code/', RegisterVerifyPhoneCode.as_view()),
    path('login-verify-phone-code/', LoginVerifyPhoneCode.as_view()),

    path('get-user', get_user),
    path('update-user/', update_user),
    path('delete-user/', delete_user),
    path('user-cards/', UserCardListView.as_view(), name='user-card-list'),
    path('get-nearby-stores/', get_nearby_stores),
    path('get-online-stores/', get_online_stores),
    path('create-user-cards/', create_user_cards),
    path('delete-user-card/<uuid:pk>/', delete_user_card),

    path('cards/', CardListView.as_view(), name='card-list'),
    path('get-card-benefits-by-types/', get_card_benefits_by_types),
    path('analyze-cards-with-gpt/', analyze_cards_with_gpt),
    path('analyze-cards-with-gpt-streaming/', analyze_cards_with_gpt_streaming),
    path('card-details-streaming/<uuid:card_id>/', get_card_details_streaming),
]
