from flask import Flask, render_template, request, redirect, url_for, jsonify, send_file, flash, session, Response
import os
import json
from datetime import datetime
import csv
import io
from io import StringIO, BytesIO
import google.generativeai as genai
from google.api_core import retry
from typing import List, Dict, Any
import qrcode
import time
from random import uniform
from collections import deque
from threading import Lock
from supabase import create_client, Client
from dotenv import load_dotenv
from functools import wraps

# Load environment variables
load_dotenv()

app = Flask(__name__)
app.secret_key = 'your-super-secret-key-12345'  # Replace this with a secure random key in production
app.config['SESSION_TYPE'] = 'filesystem'

# Add datetime filter
@app.template_filter('datetime')
def format_datetime(value):
    if not value:
        return ''
    try:
        if isinstance(value, str):
            value = datetime.fromisoformat(value.replace('Z', '+00:00'))
        return value.strftime('%Y-%m-%d %H:%M:%S')
    except Exception as e:
        print(f"Error formatting datetime: {str(e)}")
        return str(value)

# Initialize Supabase client
supabase: Client = create_client(
    os.getenv('SUPABASE_URL'),
    os.getenv('SUPABASE_KEY')
)

# Configure Gemini API with proper error handling
try:
    genai.configure(api_key=os.getenv('GOOGLE_API_KEY'))
    
    # Configure the model with recommended settings from documentation
    generation_config = {
        "temperature": 0.7,
        "top_p": 0.8,
        "top_k": 40,
        "max_output_tokens": 2048,
        "candidate_count": 1
    }

    # Create the model - using gemini-pro for better compatibility
    model = genai.GenerativeModel('gemini-pro')
    print("Gemini model initialized successfully")
except Exception as e:
    print(f"Error initializing Gemini model: {str(e)}")
    model = None

def login_required(f):
    @wraps(f)
    def decorated_function(*args, **kwargs):
        if 'user' not in session:
            return redirect(url_for('login'))
        return f(*args, **kwargs)
    return decorated_function

@app.route('/login', methods=['GET', 'POST'])
def login():
    if request.method == 'POST':
        email = request.form.get('email')
        password = request.form.get('password')
        try:
            # Sign in with Supabase
            auth_response = supabase.auth.sign_in_with_password({
                "email": email,
                "password": password
            })
            
            if not auth_response.user:
                return render_template('login.html', error="Invalid credentials")
            
            # Store user data in session
            session['user'] = {
                'id': auth_response.user.id,
                'email': auth_response.user.email,
                'access_token': auth_response.session.access_token,
                'refresh_token': auth_response.session.refresh_token
            }
            
            # Set Supabase auth header for future requests
            supabase.postgrest.auth(auth_response.session.access_token)
            
            flash('Successfully logged in!', 'success')
            return redirect(url_for('dashboard'))
            
        except Exception as e:
            print(f"Login error: {str(e)}")
            error_msg = str(e)
            if "Invalid login credentials" in error_msg:
                error_msg = "Invalid email or password"
            return render_template('login.html', error=error_msg)
            
    return render_template('login.html')

@app.route('/signup', methods=['GET', 'POST'])
def signup():
    if request.method == 'POST':
        email = request.form.get('email')
        password = request.form.get('password')
        try:
            # Sign up with Supabase
            auth_response = supabase.auth.sign_up({
                "email": email,
                "password": password
            })
            
            if not auth_response.user:
                return render_template('signup.html', error="Failed to create account")
            
            # Store user data in session
            session['user'] = {
                'id': auth_response.user.id,
                'email': auth_response.user.email,
                'access_token': auth_response.session.access_token if auth_response.session else None,
                'refresh_token': auth_response.session.refresh_token if auth_response.session else None
            }
            
            # Set Supabase auth header for future requests
            if auth_response.session:
                supabase.postgrest.auth(auth_response.session.access_token)
            
            flash('Successfully registered!', 'success')
            return redirect(url_for('dashboard'))
            
        except Exception as e:
            print(f"Signup error: {str(e)}")
            error_msg = str(e)
            if "User already registered" in error_msg:
                error_msg = "This email is already registered. Please login instead."
            return render_template('signup.html', error=error_msg)
            
    return render_template('signup.html')

@app.route('/logout')
def logout():
    try:
        # Sign out from Supabase
        if 'user' in session and session['user'].get('access_token'):
            supabase.auth.sign_out()
    except Exception as e:
        print(f"Logout error: {str(e)}")
    
    # Clear session
    session.clear()
    return redirect(url_for('login'))

@app.before_request
def check_session():
    if 'user' in session:
        try:
            # Refresh token if needed
            user = session['user']
            if user.get('access_token'):
                supabase.postgrest.auth(user['access_token'])
        except Exception as e:
            print(f"Session check error: {str(e)}")
            session.clear()
            return redirect(url_for('login'))

@app.route('/')
def home():
    if 'user' not in session:
        return render_template('landing.html')
    return redirect(url_for('dashboard'))

@app.route('/dashboard')
@login_required
def dashboard():
    try:
        # Get user data from session
        user_id = session.get('user', {}).get('id')
        access_token = session.get('user', {}).get('access_token')
        
        if not user_id or not access_token:
            print("No user_id or access_token found in session")
            session.clear()
            return redirect(url_for('login'))
        
        print(f"Fetching forms for user: {user_id}")
        
        # Create a new Supabase client with the user's access token
        client = create_client(
            os.getenv('SUPABASE_URL'),
            os.getenv('SUPABASE_KEY')
        )
        client.postgrest.auth(access_token)
        
        # Fetch forms for the current user
        forms_response = client.table('forms').select('*').eq('user_id', user_id).order('created_at', desc=True).execute()
        print(f"Forms response: {forms_response}")
        
        if not forms_response.data:
            print("No forms found")
            return render_template('home.html', forms=[])
            
        forms = forms_response.data
        print(f"Found {len(forms)} forms")
        
        return render_template('home.html', forms=forms)
    except Exception as e:
        print(f"Error fetching forms: {str(e)}")
        print(f"Error type: {type(e)}")
        if hasattr(e, '__dict__'):
            print(f"Error details: {e.__dict__}")
        import traceback
        traceback.print_exc()
        flash('Error fetching forms. Please try again.', 'error')
        return render_template('home.html', forms=[])

@app.route('/create-form', methods=['GET', 'POST'])
@login_required
def create_form():
    return render_template('form_builder.html', form=None)

@app.route('/forms/<int:form_id>/edit', methods=['GET'])
@login_required
def edit_form(form_id):
    try:
        # Get form data from Supabase
        response = supabase.table('forms').select('*').eq('id', form_id).execute()
        if not response.data:
            flash('Form not found', 'error')
            return redirect(url_for('dashboard'))
        
        form = response.data[0]
        
        # Check if user owns this form
        if str(form['user_id']) != session['user']['id']:
            flash('You do not have permission to edit this form', 'error')
            return redirect(url_for('dashboard'))
        
        return render_template('form_builder.html', form=form)
    except Exception as e:
        print(f"Error editing form: {str(e)}")
        flash('An error occurred while loading the form', 'error')
        return redirect(url_for('dashboard'))

@app.route('/forms/<int:form_id>/preview', methods=['GET'])
@login_required
def preview_form(form_id):
    try:
        # Get form data from Supabase
        response = supabase.table('forms').select('*').eq('id', form_id).execute()
        if not response.data:
            flash('Form not found', 'error')
            return redirect(url_for('dashboard'))
        
        form = response.data[0]
        
        # Check if user owns this form
        if str(form['user_id']) != session['user']['id']:
            flash('You do not have permission to preview this form', 'error')
            return redirect(url_for('dashboard'))
        
        return render_template('form_view.html', form=form, preview=True)
    except Exception as e:
        print(f"Error previewing form: {str(e)}")
        flash('An error occurred while loading the form preview', 'error')
        return redirect(url_for('dashboard'))

@app.route('/forms', methods=['POST'])
@login_required
def save_form():
    try:
        data = request.json
        if not data:
            print("No JSON data received")
            return jsonify({'error': 'No data provided'}), 400
            
        user_id = session.get('user', {}).get('id')
        access_token = session.get('user', {}).get('access_token')
        
        if not user_id or not access_token:
            print("No user_id or access_token found in session")
            return jsonify({'error': 'User not authenticated'}), 401
        
        print(f"Received form data: {json.dumps(data, indent=2)}")
        print(f"User ID: {user_id}")
        
        if not data.get('title'):
            return jsonify({'error': 'Form title is required'}), 400
            
        if not data.get('fields'):
            return jsonify({'error': 'At least one form field is required'}), 400
            
        # Validate that all fields have labels
        for field in data['fields']:
            if not field.get('label', '').strip():
                return jsonify({'error': 'All fields must have labels'}), 400

        current_time = datetime.now().isoformat()
        
        # Create a new Supabase client with the user's access token
        client = create_client(
            os.getenv('SUPABASE_URL'),
            os.getenv('SUPABASE_KEY')
        )
        client.postgrest.auth(access_token)
        
        # Check for duplicate title for this user
        base_title = data['title']
        title = base_title
        counter = 1
        
        while True:
            try:
                title_check = client.table('forms').select('id').eq('title', title).eq('user_id', user_id)
                if 'id' in data:
                    title_check = title_check.neq('id', data['id'])
                
                response = title_check.execute()
                print(f"Title check response: {response}")
                
                if not response.data:
                    break
                    
                title = f"{base_title} ({counter})"
                counter += 1
            except Exception as e:
                print(f"Error checking title: {str(e)}")
                return jsonify({'error': 'Error checking form title'}), 500
        
        form_data = {
            'title': title,
            'description': data.get('description', ''),
            'fields': data['fields'],
            'theme': data.get('theme', 'default'),
            'updated_at': current_time,
            'user_id': user_id
        }
        
        print(f"Preparing to save form data: {json.dumps(form_data, indent=2)}")
        
        try:
            if 'id' in data:
                # Verify ownership before updating
                existing_form = client.table('forms').select('user_id').eq('id', data['id']).single().execute()
                print(f"Existing form check: {existing_form}")
                
                if not existing_form.data or existing_form.data['user_id'] != user_id:
                    return jsonify({'error': 'Unauthorized to modify this form'}), 403
                    
                # Update existing form
                print(f"Updating form {data['id']}")
                response = client.table('forms').update(form_data).eq('id', data['id']).execute()
                form_id = data['id']
            else:
                # Create new form
                print("Creating new form")
                form_data['created_at'] = current_time
                response = client.table('forms').insert(form_data).execute()
                print(f"Insert response: {response}")
                form_id = response.data[0]['id']
            
            return jsonify({
                'id': form_id,
                'title': title,
                'message': 'Form saved successfully'
            })
        except Exception as e:
            print(f"Database operation error: {str(e)}")
            print(f"Error type: {type(e)}")
            if hasattr(e, '__dict__'):
                print(f"Error details: {e.__dict__}")
            return jsonify({'error': f'Database error: {str(e)}'}), 500
            
    except Exception as e:
        print(f"Unexpected error in save_form: {str(e)}")
        print(f"Error type: {type(e)}")
        if hasattr(e, '__dict__'):
            print(f"Error details: {e.__dict__}")
        import traceback
        traceback.print_exc()
        return jsonify({'error': f'An unexpected error occurred: {str(e)}'}), 500

@app.route('/forms/<int:form_id>/view', methods=['GET'])
@login_required
def view_form(form_id):
    try:
        print(f"Attempting to view form {form_id}")
        user_id = session.get('user', {}).get('id')
        if not user_id:
            print("No user_id found in session")
            return render_template('error.html', error="User not authenticated"), 401
            
        # Fetch form and verify ownership
        print(f"Fetching form for user {user_id}")
        response = supabase.table('forms').select('*').eq('id', form_id).single().execute()
        print(f"Form fetch response: {response}")
        
        if not response.data:
            print("Form not found")
            return render_template('error.html', error="Form not found"), 404
            
        form = response.data
        print(f"Retrieved form: {json.dumps(form, indent=2)}")
        
        # Check if preview mode
        preview = request.args.get('preview', 'false').lower() == 'true'
        print(f"Preview mode: {preview}")
        
        return render_template('form_view.html', form=form, preview=preview)
        
    except Exception as e:
        print(f"Error viewing form: {str(e)}")
        print(f"Error type: {type(e)}")
        if hasattr(e, '__dict__'):
            print(f"Error details: {e.__dict__}")
        import traceback
        traceback.print_exc()
        return render_template('error.html', error=f"Error viewing form: {str(e)}")

@app.route('/submit-response/<form_id>', methods=['POST'])
def submit_response(form_id):
    try:
        print(f"Attempting to submit response for form {form_id}")
        print(f"Request form data: {request.form}")
        
        # Get form data from database
        form_response = supabase.table('forms').select('*').eq('id', form_id).execute()
        print(f"Form query response: {form_response}")
        
        if not form_response.data:
            print(f"Form {form_id} not found")
            return jsonify({'error': 'Form not found'}), 404
        
        form = form_response.data[0]
        print(f"Found form: {form}")
        
        # Collect response data
        response_data = {}
        for i, field in enumerate(form['fields'], 1):
            field_name = f'field_{i}'
            if field['type'] == 'checkbox':
                values = request.form.getlist(f'{field_name}[]')
                response_data[field_name] = values if values else []
            else:
                value = request.form.get(field_name)
                response_data[field_name] = value if value is not None else ''

            if field.get('required') and not response_data[field_name]:
                error_msg = f'Field "{field["label"]}" is required'
                print(f"Validation error: {error_msg}")
                return jsonify({'error': error_msg}), 400

        # Prepare response data
        current_time = datetime.utcnow().isoformat()
        response_data_to_insert = {
            'form_id': int(form_id),  # Keep as integer since we created table with bigint
            'response_data': response_data,
            'created_at': current_time
        }
        
        print(f"Attempting to save response: {response_data_to_insert}")
        
        # Try to insert the response directly
        try:
            print("Attempting to insert response...")
            result = supabase.table('form_responses').insert(response_data_to_insert).execute()
            print(f"Insert result: {result}")
            
            if not result.data:
                print("No data returned from insert")
                return jsonify({'error': 'Failed to save response'}), 500
                
            response_id = result.data[0].get('id')
            if not response_id:
                print("No response ID in result data")
                return jsonify({'error': 'Failed to get response ID'}), 500
                
            print(f"Successfully saved response with ID: {response_id}")
            return jsonify({
                'message': 'Response submitted successfully',
                'response_id': response_id
            }), 200
            
        except Exception as insert_error:
            error_msg = str(insert_error)
            print(f"Insert error: {error_msg}")
            print(f"Insert error type: {type(insert_error)}")
            if hasattr(insert_error, '__dict__'):
                print(f"Insert error details: {insert_error.__dict__}")
            
            if 'relation "form_responses" does not exist' in error_msg:
                return jsonify({'error': 'The form responses table is not set up in the database. Please run the setup SQL first.'}), 500
            elif 'violates foreign key constraint' in error_msg:
                return jsonify({'error': 'Invalid form ID'}), 400
            else:
                return jsonify({'error': f'Failed to save response: {error_msg}'}), 500
            
    except Exception as e:
        print(f"Unexpected error: {str(e)}")
        print(f"Error type: {type(e)}")
        if hasattr(e, '__dict__'):
            print(f"Error details: {e.__dict__}")
        import traceback
        traceback.print_exc()
        return jsonify({'error': f'An unexpected error occurred: {str(e)}'}), 500

@app.route('/forms/<int:form_id>/delete', methods=['POST'])
@login_required
def delete_form(form_id):
    try:
        user_id = session['user']['id']
        # Verify ownership before deleting
        form = supabase.table('forms').select('user_id').eq('id', form_id).single().execute()
        
        if not form.data or form.data['user_id'] != user_id:
            return jsonify({'error': 'Unauthorized to delete this form'}), 403
        
        # Delete form and its responses
        supabase.table('form_responses').delete().eq('form_id', form_id).execute()
        supabase.table('forms').delete().eq('id', form_id).execute()
        
        return jsonify({'message': 'Form deleted successfully'})
    except Exception as e:
        print(f"Error deleting form: {str(e)}")
        return jsonify({'error': str(e)}), 500

@app.route('/forms/<int:form_id>/responses')
@login_required
def view_responses(form_id):
    try:
        # Get form details
        form = supabase.table('forms').select('*').eq('id', form_id).single().execute()
        if not form.data:
            return render_template('error.html', error="Form not found"), 404

        # Get responses
        responses = supabase.table('form_responses').select('*').eq('form_id', form_id).execute()
        
        return render_template('responses.html', 
            form=form.data, 
            responses=responses.data)
    except Exception as e:
        print(f"Error viewing responses: {str(e)}")
        return render_template('error.html', error="Failed to fetch responses")

@app.route('/forms/<int:form_id>/responses/export')
@login_required
def export_responses(form_id):
    try:
        # Get form details
        form = supabase.table('forms').select('*').eq('id', form_id).single().execute()
        if not form.data:
            return jsonify({'error': 'Form not found'}), 404

        # Get responses
        responses = supabase.table('form_responses').select('*').eq('form_id', form_id).execute()
        
        # Create CSV data
        output = io.StringIO()
        writer = csv.writer(output)
        
        # Write headers
        headers = ['Response ID', 'Submission Date']
        for field in form.data['fields']:
            headers.append(field['label'])
        writer.writerow(headers)
        
        # Write response data
        for response in responses.data:
            row = [response['id'], response['created_at']]
            response_data = response['response_data']
            for i, _ in enumerate(form.data['fields'], 1):
                field_key = f'field_{i}'
                row.append(response_data.get(field_key, ''))
            writer.writerow(row)
        
        # Prepare response
        output.seek(0)
        return Response(
            output.getvalue(),
            mimetype='text/csv',
            headers={
                'Content-Disposition': f'attachment; filename=form_{form_id}_responses.csv'
            }
        )
    except Exception as e:
        print(f"Error exporting responses: {str(e)}")
        return jsonify({'error': str(e)}), 500

# Rate limiter for AI generation
class RateLimiter:
    def __init__(self, max_requests=60, time_window=60):  # 60 requests per minute by default
        self.max_requests = max_requests
        self.time_window = time_window
        self.requests = deque()
        self.lock = Lock()
        
    def can_make_request(self):
        with self.lock:
            now = time.time()
            
            # Remove old requests
            while self.requests and self.requests[0] < now - self.time_window:
                self.requests.popleft()
            
            # Check if we can make a new request
            if len(self.requests) < self.max_requests:
                self.requests.append(now)
                return True
                
            return False
            
    def get_wait_time(self):
        with self.lock:
            if not self.requests:
                return 0
                
            now = time.time()
            oldest_request = self.requests[0]
            time_passed = now - oldest_request
            
            if time_passed >= self.time_window:
                return 0
                
            return self.time_window - time_passed

@retry.Retry()
def generate_with_backoff(prompt, max_retries=3, initial_delay=1):
    try:
        response = model.generate_content(prompt)
        return response.text
    except Exception as e:
        if max_retries > 0:
            delay = initial_delay * (1 + uniform(-0.1, 0.1))  # Add some jitter
            time.sleep(delay)
            return generate_with_backoff(prompt, max_retries - 1, initial_delay * 2)
        else:
            raise e

@app.route('/generate-form', methods=['POST'])
def generate_form():
    try:
        data = request.json
        description = data.get('description', '')
        
        if not description:
            return jsonify({'error': 'Description is required'}), 400
            
        # Generate form structure using AI
        prompt = f"""Create a form structure based on this description: {description}
        
        Return ONLY a JSON array of form fields, with each field having these properties:
        - id: string (unique identifier like 'field_1', 'field_2', etc.)
        - label: string (display text)
        - type: string (one of: text, number, email, tel, textarea, select, radio, checkbox)
        - required: boolean
        - options: array of strings (only for select, radio, checkbox types)

        Example response format:
        [
            {{"id": "field_1", "label": "Full Name", "type": "text", "required": true}},
            {{"id": "field_2", "label": "Email Address", "type": "email", "required": true}},
            {{"id": "field_3", "label": "Options", "type": "select", "required": false, "options": ["Option 1", "Option 2"]}}
        ]

        Important:
        1. Return ONLY the JSON array, no other text
        2. Make sure all fields have unique IDs
        3. Include options array only for select, radio, and checkbox types
        4. Keep the response focused and relevant to: {description}"""
        
        response = generate_with_backoff(prompt)
        
        try:
            # Clean the response to ensure it's valid JSON
            response_text = response.strip()
            # Remove any markdown code block indicators if present
            response_text = response_text.replace('```json', '').replace('```', '').strip()
            
            # Parse the JSON
            fields = json.loads(response_text)
            
            # Validate the response structure
            if not isinstance(fields, list):
                raise ValueError("Response must be a JSON array")
            
            # Validate each field
            for field in fields:
                required_keys = {'id', 'label', 'type', 'required'}
                if not all(key in field for key in required_keys):
                    raise ValueError(f"Field missing required keys: {required_keys}")
                
                # Ensure options are present for certain field types
                if field['type'] in {'select', 'radio', 'checkbox'}:
                    if 'options' not in field or not isinstance(field['options'], list):
                        field['options'] = ['Option 1', 'Option 2', 'Option 3']
                
                # Ensure proper boolean value for required
                field['required'] = bool(field['required'])
                
                # Ensure unique ID
                if not field['id']:
                    field['id'] = f"field_{fields.index(field) + 1}"
            
            return jsonify({'fields': fields})
        except json.JSONDecodeError as e:
            print(f"JSON decode error: {str(e)}\nResponse was: {response_text}")
            return jsonify({'error': 'Invalid AI response format'}), 500
        except ValueError as e:
            print(f"Validation error: {str(e)}\nResponse was: {response_text}")
            return jsonify({'error': str(e)}), 500
            
    except Exception as e:
        print(f"Error generating form: {str(e)}")
        return jsonify({'error': str(e)}), 500

@app.route('/forms/<int:form_id>/share')
def share_form(form_id):
    try:
        # Get form details from Supabase
        response = supabase.table('forms').select('title').eq('id', form_id).single().execute()
        form = response.data
        
        if not form:
            return "Form not found", 404
            
        share_url = request.host_url + f'forms/{form_id}'
        return render_template('share.html', form=form, share_url=share_url)
    except Exception as e:
        print(f"Error sharing form: {str(e)}")
        return "Error sharing form", 500

@app.route('/forms/<int:form_id>/qr')
def generate_qr(form_id):
    try:
        share_url = request.host_url + f'forms/{form_id}'
        
        # Generate QR code
        qr = qrcode.QRCode(version=1, box_size=10, border=5)
        qr.add_data(share_url)
        qr.make(fit=True)
        
        img = qr.make_image(fill_color="black", back_color="white")
        
        # Save to BytesIO
        img_io = BytesIO()
        img.save(img_io, 'PNG')
        img_io.seek(0)
        
        return send_file(img_io, mimetype='image/png')
    except Exception as e:
        print(f"Error generating QR code: {str(e)}")
        return "Error generating QR code", 500

if __name__ == '__main__':
    app.run(debug=True)