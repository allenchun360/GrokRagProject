from django.contrib import admin

from users.models import User, UserCard, PhoneAuthentication

# Register your models here.
admin.site.register(User)
admin.site.register(UserCard)
admin.site.register(PhoneAuthentication)
