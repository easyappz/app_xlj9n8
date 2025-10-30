# Django API Boilerplate - LLM Modification Guide

## Project Overview

This project uses Python 3.12.

This is a minimal Django REST API boilerplate using:
- **Django**: Web framework
- **Django REST Framework (DRF)**: API functionality
- **drf-spectacular**: OpenAPI 3.0 schema generation

There are also optional dependencies suggested by DRF installed that you can use:
- django-filter
- django-guardian

Always consider used libraries versions from requirements.txt to use for gathering actual docs if needed.
Please note that there are always docs in docs/ directory for django, django-filter, django-guardian, djangorestframework, drf-spectacular for exact used versions of these libraries, you can try to gather info from there when addressing a complex task or a bug.

Please note that you must not add any additional libraries to the project. You can only use libraries listed in requirements.txt.

**Important**: This project generates static OpenAPI spec files (`openapi.yml`) for frontend generation. No web-based documentation UI is exposed.

## Project Structure

**Key directories and files:**
- `config/` - Django project configuration folder
  - `settings.py` - Main settings (INSTALLED_APPS, REST_FRAMEWORK config)
  - `urls.py` - Root URL configuration
- `api/` - Main API application folder
  - `models.py` - Database models
  - `serializers.py` - DRF serializers (data validation/transformation)
  - `views.py` - API views/endpoints
  - `urls.py` - API URL routing
- `manage.py` - Django management commands
- `openapi.yml` - Generated API specification (regenerate after changes)
- `requirements.txt` - Dependencies

## Core Patterns Used

### 1. API Views Pattern

Uses `APIView` with `@extend_schema` decorator for documentation:

```python
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status
from drf_spectacular.utils import extend_schema
from .serializers import YourSerializer

class YourView(APIView):
    @extend_schema(
        request=YourSerializer,  # For POST/PUT/PATCH
        responses={200: YourSerializer},  # Success response
        description="Describe what this endpoint does"
    )
    def get(self, request):
        # Implementation
        return Response(data)
```

### 2. Serializer Pattern

Serializers define data structure and validation:

```python
from rest_framework import serializers

class YourSerializer(serializers.Serializer):
    field_name = serializers.CharField(max_length=200)
    number_field = serializers.IntegerField()
    optional_field = serializers.CharField(required=False)
```

### 3. URL Pattern

Register views in `api/urls.py`:

```python
from django.urls import path
from .views import YourView

urlpatterns = [
    path('endpoint/', YourView.as_view(), name='endpoint-name'),
]
```

## Step-by-Step Modification Instructions

### Adding a New API Endpoint

**Step 1: Create Serializer** (`api/serializers.py`)

```python
class NewEndpointSerializer(serializers.Serializer):
    # Define your data structure
    name = serializers.CharField(max_length=100)
    email = serializers.EmailField()
    age = serializers.IntegerField(min_value=0, required=False)
```

**Step 2: Create View** (`api/views.py`)

```python
from drf_spectacular.utils import extend_schema
from .serializers import NewEndpointSerializer

class NewEndpointView(APIView):
    """
    Brief description of this endpoint.
    """

    @extend_schema(
        responses={200: NewEndpointSerializer},
        description="GET method description"
    )
    def get(self, request):
        # Your logic here
        data = {'name': 'John', 'email': 'john@example.com', 'age': 30}
        serializer = NewEndpointSerializer(data)
        return Response(serializer.data)

    @extend_schema(
        request=NewEndpointSerializer,
        responses={201: NewEndpointSerializer},
        description="POST method description"
    )
    def post(self, request):
        serializer = NewEndpointSerializer(data=request.data)
        if serializer.is_valid():
            # Process validated data
            # serializer.validated_data contains clean data
            return Response(serializer.data, status=status.HTTP_201_CREATED)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
```

**Step 3: Register URL** (`api/urls.py`)

```python
from .views import NewEndpointView

urlpatterns = [
    # ... existing patterns ...
    path('new-endpoint/', NewEndpointView.as_view(), name='new-endpoint'),
]
```

**Step 4: Regenerate Schema**

```bash
python manage.py spectacular --file openapi.yml
```

### Adding Database Models

**Step 1: Define Model** (`api/models.py`)

```python
from django.db import models

class YourModel(models.Model):
    name = models.CharField(max_length=200)
    email = models.EmailField(unique=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ['-created_at']

    def __str__(self):
        return self.name
```

**Step 2: Create Model Serializer** (`api/serializers.py`)

```python
from rest_framework import serializers
from .models import YourModel

class YourModelSerializer(serializers.ModelSerializer):
    class Meta:
        model = YourModel
        fields = ['id', 'name', 'email', 'created_at', 'updated_at']
        read_only_fields = ['id', 'created_at', 'updated_at']
```

**Step 3: Create CRUD Views** (`api/views.py`)

```python
from rest_framework.generics import ListCreateAPIView, RetrieveUpdateDestroyAPIView
from .models import YourModel
from .serializers import YourModelSerializer

class YourModelListView(ListCreateAPIView):
    """
    GET: List all items
    POST: Create new item
    """
    queryset = YourModel.objects.all()
    serializer_class = YourModelSerializer

class YourModelDetailView(RetrieveUpdateDestroyAPIView):
    """
    GET: Retrieve single item
    PUT/PATCH: Update item
    DELETE: Delete item
    """
    queryset = YourModel.objects.all()
    serializer_class = YourModelSerializer
```

**Step 4: Register URLs** (`api/urls.py`)

```python
urlpatterns = [
    # ... existing patterns ...
    path('items/', YourModelListView.as_view(), name='item-list'),
    path('items/<int:pk>/', YourModelDetailView.as_view(), name='item-detail'),
]
```

**Step 5: Create and Run Migrations**

```bash
python manage.py makemigrations
python manage.py migrate
```

**Step 6: Regenerate Schema**

```bash
python manage.py spectacular --file openapi.yml
```

## Common Serializer Field Types

```python
# Text fields
field = serializers.CharField(max_length=200)
field = serializers.EmailField()
field = serializers.URLField()
field = serializers.SlugField()
field = serializers.UUIDField()

# Numeric fields
field = serializers.IntegerField(min_value=0, max_value=100)
field = serializers.FloatField()
field = serializers.DecimalField(max_digits=10, decimal_places=2)

# Boolean and choice fields
field = serializers.BooleanField()
field = serializers.ChoiceField(choices=['option1', 'option2', 'option3'])

# Date/time fields
field = serializers.DateTimeField()
field = serializers.DateField()
field = serializers.TimeField()

# Complex fields
field = serializers.ListField(child=serializers.CharField())
field = serializers.DictField()
field = serializers.JSONField()

# Relations (for models)
field = serializers.PrimaryKeyRelatedField(queryset=Model.objects.all())
field = serializers.StringRelatedField()

# Common parameters
field = serializers.CharField(
    required=False,        # Optional field
    allow_null=True,       # Allow null values
    allow_blank=True,      # Allow empty strings
    default='value',       # Default value
    read_only=True,        # Not writable
    write_only=True,       # Not readable (e.g., passwords)
)
```

## Common HTTP Status Codes

```python
from rest_framework import status

# Success responses
status.HTTP_200_OK              # GET, PUT, PATCH success
status.HTTP_201_CREATED         # POST success
status.HTTP_204_NO_CONTENT      # DELETE success

# Client error responses
status.HTTP_400_BAD_REQUEST     # Validation error
status.HTTP_401_UNAUTHORIZED    # Authentication required
status.HTTP_403_FORBIDDEN       # Permission denied
status.HTTP_404_NOT_FOUND       # Resource not found

# Server error
status.HTTP_500_INTERNAL_SERVER_ERROR
```

## View Response Patterns

### Simple Response

```python
return Response({'message': 'Success'})
```

### Response with Status Code

```python
return Response(data, status=status.HTTP_201_CREATED)
```

### Error Response

```python
return Response(
    {'error': 'Something went wrong'},
    status=status.HTTP_400_BAD_REQUEST
)
```

### Validation Error Response

```python
serializer = YourSerializer(data=request.data)
if serializer.is_valid():
    # Process data
    return Response(serializer.data, status=status.HTTP_201_CREATED)
return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
```

## Query Parameters

```python
def get(self, request):
    # Get query parameter: /api/endpoint/?search=value
    search = request.query_params.get('search', '')

    # Get with default
    page = request.query_params.get('page', 1)

    # Get multiple values: /api/endpoint/?tag=python&tag=django
    tags = request.query_params.getlist('tag')
```

## Path Parameters

```python
# In urls.py
path('items/<int:pk>/', YourView.as_view())
path('items/<str:slug>/', YourView.as_view())
path('items/<uuid:id>/', YourView.as_view())

# In view
def get(self, request, pk):
    # Use pk parameter
    pass
```

## Advanced @extend_schema Examples

### Multiple Response Codes

```python
@extend_schema(
    request=InputSerializer,
    responses={
        200: OutputSerializer,
        400: {'description': 'Validation error'},
        404: {'description': 'Not found'},
    },
    description="Detailed description"
)
```

### Query Parameters Documentation

```python
from drf_spectacular.utils import extend_schema, OpenApiParameter
from drf_spectacular.types import OpenApiTypes

@extend_schema(
    parameters=[
        OpenApiParameter(
            name='search',
            type=OpenApiTypes.STR,
            location=OpenApiParameter.QUERY,
            description='Search term',
            required=False
        ),
        OpenApiParameter(
            name='page',
            type=OpenApiTypes.INT,
            location=OpenApiParameter.QUERY,
            description='Page number',
            required=False
        ),
    ],
    responses={200: YourSerializer(many=True)}
)
def get(self, request):
    pass
```

### List Response (many=True)

```python
@extend_schema(
    responses={200: YourSerializer(many=True)},
    description="Returns a list of items"
)
def get(self, request):
    items = YourModel.objects.all()
    serializer = YourSerializer(items, many=True)
    return Response(serializer.data)
```

## Testing the API

```bash
# GET request
curl http://localhost:8000/api/endpoint/

# POST request
curl -X POST http://localhost:8000/api/endpoint/ \
  -H "Content-Type: application/json" \
  -d '{"field": "value"}'

# PUT request
curl -X PUT http://localhost:8000/api/endpoint/1/ \
  -H "Content-Type: application/json" \
  -d '{"field": "updated value"}'

# DELETE request
curl -X DELETE http://localhost:8000/api/endpoint/1/
```

## Essential Commands

```bash
# Run development server
python manage.py runserver

# Create migrations after model changes
python manage.py makemigrations

# Apply migrations
python manage.py migrate

# Regenerate API schema (DO THIS AFTER ANY API CHANGES)
python manage.py spectacular --file openapi.yml
```

## Checklist for Adding New Features

When adding a new endpoint:

- Create/update serializer in `api/serializers.py`
- Create/update view in `api/views.py`
- Add `@extend_schema` decorator to all HTTP methods
- Register URL in `api/urls.py`
- If using models: create migration and run migrate
- **Regenerate schema**: `python manage.py spectacular --file openapi.yml`
- Test endpoint with curl or HTTP client
- Verify schema has no errors: check for "Errors: 0" in output

General routine after any change:

- Check that server starts and returns no errors via `DJANGO_DEBUG=1 python manage.py runserver`.
- `python manage.py makemigrations` is idempotent so we can run it explicity for any change, just to be sure.
- Run `ruff format` before commit to maintain the code well-formatted.

## Configuration Files to Modify

### Adding Dependencies

Adding new dependencies is not allowed.

### Changing API Metadata

Edit `config/settings.py`:

```python
SPECTACULAR_SETTINGS = {
    'TITLE': 'Easyapp API',
    'DESCRIPTION': 'API documentation for easyapp',
    'VERSION': '1.0.0',
    'SERVE_INCLUDE_SCHEMA': False,
    # Add more settings if needed
}
```

## Common Issues and Solutions

### Error: "unable to guess serializer"

**Solution**: Add `@extend_schema` decorator with `request` and `responses` parameters.

### Schema not updating

**Solution**: Run `python manage.py spectacular --file openapi.yml` after any API changes.

### Migration errors

**Solution**:

```bash
python manage.py makemigrations
python manage.py migrate
```

### Import errors

**Solution**: Ensure all new models/serializers/views are imported correctly in their respective files.

## Example: Complete Feature Addition

Here's a complete example of adding a "Task" management endpoint:

**File: `api/models.py`**

```python
class Task(models.Model):
    title = models.CharField(max_length=200)
    description = models.TextField(blank=True)
    completed = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return self.title
```

**File: `api/serializers.py`**

```python
class TaskSerializer(serializers.ModelSerializer):
    class Meta:
        model = Task
        fields = ['id', 'title', 'description', 'completed', 'created_at']
        read_only_fields = ['id', 'created_at']
```

**File: `api/views.py`**

```python
from rest_framework.generics import ListCreateAPIView, RetrieveUpdateDestroyAPIView
from .models import Task
from .serializers import TaskSerializer

class TaskListView(ListCreateAPIView):
    """
    GET: List all tasks
    POST: Create a new task
    """
    queryset = Task.objects.all()
    serializer_class = TaskSerializer

class TaskDetailView(RetrieveUpdateDestroyAPIView):
    """
    GET: Retrieve a task
    PUT/PATCH: Update a task
    DELETE: Delete a task
    """
    queryset = Task.objects.all()
    serializer_class = TaskSerializer
```

**File: `api/urls.py`**

```python
from .views import TaskListView, TaskDetailView

urlpatterns = [
    path('hello/', HelloWorldView.as_view(), name='hello-world'),
    path('tasks/', TaskListView.as_view(), name='task-list'),
    path('tasks/<int:pk>/', TaskDetailView.as_view(), name='task-detail'),
]
```

**Run commands:**

```bash
python manage.py makemigrations
python manage.py migrate
python manage.py spectacular --file openapi.yml
```

## End of Guide

This boilerplate is designed for:

1. Building REST APIs quickly
2. Generating OpenAPI specs for frontend generation
3. Maintaining clean, documented code

Always regenerate `openapi.yml` after modifications so the frontend generation process has the latest API definition.
