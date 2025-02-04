// Form builder functionality
document.addEventListener('DOMContentLoaded', function() {
    // Initialize form builder
    const formBuilder = {
        init: function() {
            this.bindEvents();
            this.setupFormIfEditing();
            this.setupFieldModal();
        },

        bindEvents: function() {
            // Preview button click
            document.getElementById('preview-btn')?.addEventListener('click', () => this.previewForm());
            
            // Save button click
            document.getElementById('save-btn')?.addEventListener('click', () => this.saveForm());
            
            // Add field button click
            document.getElementById('add-field-btn')?.addEventListener('click', () => this.showAddFieldModal());

            // AI Generate button click
            document.getElementById('generate-form-btn')?.addEventListener('click', () => this.generateFormWithAI());
        },

        setupFormIfEditing: function() {
            // If form data exists (editing mode), populate the form
            if (window.formData) {
                document.getElementById('form-title').value = formData.title || '';
                document.getElementById('form-description').value = formData.description || '';
                if (formData.fields && Array.isArray(formData.fields)) {
                    formData.fields.forEach(field => this.addFieldToUI(field));
                }
            }
        },

        async previewForm() {
            try {
                showLoading('Preparing preview...');
                const formData = this.collectFormData();
                if (!formData) {
                    hideLoading();
                    return;
                }

                const response = await fetch('/forms', {
                    method: 'POST',
                    headers: {
                        'Content-Type': 'application/json'
                    },
                    body: JSON.stringify(formData)
                });

                const data = await response.json();
                hideLoading();

                if (!response.ok) {
                    throw new Error(data.error || 'Failed to save form');
                }

                // Redirect to preview page
                window.location.href = `/forms/${data.id}/preview`;
            } catch (error) {
                hideLoading();
                showError(error.message || 'Error preparing preview. Please try again.');
            }
        },

        async saveForm() {
            try {
                const formData = this.collectFormData();
                if (!formData) {
                    return; // Validation failed
                }

                showLoading('Saving form...');

                const response = await fetch('/forms', {
                    method: 'POST',
                    headers: {
                        'Content-Type': 'application/json',
                        'Accept': 'application/json'
                    },
                    body: JSON.stringify(formData)
                });

                const data = await response.json();

                if (!response.ok) {
                    throw new Error(data.error || 'Failed to save form');
                }

                hideLoading();
                showSuccess('Form saved successfully!');

                // Redirect to home page after successful save
                setTimeout(() => {
                    window.location.href = '/';
                }, 1500);
            } catch (error) {
                console.error('Save error:', error);
                hideLoading();
                showError(error.message || 'Error saving form. Please try again.');
            }
        },

        collectFormData: function() {
            const title = document.getElementById('form-title').value.trim();
            const description = document.getElementById('form-description').value.trim();
            const theme = document.getElementById('form-theme').value;
            const fieldsContainer = document.getElementById('fields-container');
            const fieldElements = fieldsContainer.getElementsByClassName('field-item');
            
            if (!title) {
                showError('Please enter a form title');
                return null;
            }

            if (fieldElements.length === 0) {
                showError('Please add at least one field to the form');
                return null;
            }

            const fields = Array.from(fieldElements).map((fieldEl, index) => {
                const fieldData = {
                    id: `field_${index + 1}`,
                    label: fieldEl.querySelector('.field-label').textContent,
                    type: fieldEl.getAttribute('data-field-type'),
                    required: fieldEl.querySelector('.field-required').checked
                };

                if (['select', 'radio', 'checkbox'].includes(fieldData.type)) {
                    fieldData.options = Array.from(fieldEl.querySelectorAll('.field-option'))
                        .map(opt => opt.textContent.trim())
                        .filter(opt => opt); // Remove empty options
                }

                return fieldData;
            });

            const formData = {
                title,
                description,
                theme,
                fields
            };

            // If editing an existing form, include the ID
            const formId = document.getElementById('form-id')?.value;
            if (formId) {
                formData.id = parseInt(formId);
            }

            return formData;
        },

        setupFieldModal: function() {
            // Get modal elements
            const fieldTypeSelect = document.getElementById('field-type');
            const optionsContainer = document.getElementById('options-container');
            const addOptionBtn = document.getElementById('add-option-btn');
            const saveFieldBtn = document.getElementById('save-field-btn');
            const fieldOptionsDiv = document.getElementById('field-options');

            // Handle field type change
            fieldTypeSelect?.addEventListener('change', () => {
                const showOptions = ['select', 'radio', 'checkbox'].includes(fieldTypeSelect.value);
                optionsContainer.style.display = showOptions ? 'block' : 'none';
                
                // Clear existing options
                fieldOptionsDiv.innerHTML = '';
                if (showOptions) {
                    // Add initial options
                    this.addOptionInput();
                    this.addOptionInput();
                }
            });

            // Handle add option button
            addOptionBtn?.addEventListener('click', () => {
                this.addOptionInput();
            });

            // Handle save field button
            saveFieldBtn?.addEventListener('click', () => {
                this.saveField();
            });
        },

        addOptionInput: function() {
            const fieldOptionsDiv = document.getElementById('field-options');
            const optionDiv = document.createElement('div');
            optionDiv.className = 'input-group mb-2';
            optionDiv.innerHTML = `
                <input type="text" class="form-control option-input" placeholder="Enter option">
                <button type="button" class="btn btn-outline-secondary mic-button" title="Click to speak">
                    <i class="fas fa-microphone"></i>
                </button>
                <button type="button" class="btn btn-outline-danger" onclick="this.closest('.input-group').remove()">
                    <i class="fas fa-times"></i>
                </button>
            `;
            fieldOptionsDiv.appendChild(optionDiv);

            // Initialize speech recognition for the new option input
            const micButton = optionDiv.querySelector('.mic-button');
            if (micButton) {
                micButton.addEventListener('click', function() {
                    const event = new Event('click');
                    this.dispatchEvent(event);
                });
            }
        },

        showAddFieldModal: function() {
            // Reset modal form
            const modal = document.getElementById('field-modal');
            const form = modal.querySelector('form');
            if (form) form.reset();

            // Reset options container
            const optionsContainer = document.getElementById('options-container');
            optionsContainer.style.display = 'none';
            const fieldOptionsDiv = document.getElementById('field-options');
            fieldOptionsDiv.innerHTML = '';

            // Show modal
            const modalInstance = new bootstrap.Modal(modal);
            modalInstance.show();
        },

        saveField: function() {
            const fieldLabel = document.getElementById('field-label').value.trim();
            const fieldType = document.getElementById('field-type').value;
            const fieldRequired = document.getElementById('field-required').checked;

            if (!fieldLabel) {
                showError('Please enter a field label');
                return;
            }

            const fieldData = {
                label: fieldLabel,
                type: fieldType,
                required: fieldRequired
            };

            // Get options for select, radio, or checkbox fields
            if (['select', 'radio', 'checkbox'].includes(fieldType)) {
                const options = Array.from(document.querySelectorAll('.option-input'))
                    .map(input => input.value.trim())
                    .filter(value => value);

                if (options.length < 2) {
                    showError('Please add at least two options');
                    return;
                }

                fieldData.options = options;
            }

            // Add field to UI
            this.addFieldToUI(fieldData);

            // Close modal
            const modal = bootstrap.Modal.getInstance(document.getElementById('field-modal'));
            modal.hide();
        },

        addFieldToUI: function(fieldData) {
            const fieldsContainer = document.getElementById('fields-container');
            const fieldElement = document.createElement('div');
            fieldElement.className = 'field-item card mb-3';
            fieldElement.setAttribute('data-field-type', fieldData.type);

            let optionsHtml = '';
            if (['select', 'radio', 'checkbox'].includes(fieldData.type) && fieldData.options) {
                optionsHtml = `
                    <div class="field-options mt-2">
                        <small class="text-muted">Options:</small>
                        <ul class="list-unstyled mb-0">
                            ${fieldData.options.map(opt => `
                                <li class="field-option">${opt}</li>
                            `).join('')}
                        </ul>
                    </div>
                `;
            }

            fieldElement.innerHTML = `
                <div class="card-body">
                    <div class="d-flex justify-content-between align-items-start">
                        <div>
                            <h5 class="field-label mb-1">${fieldData.label}</h5>
                            <small class="text-muted">${fieldData.type}</small>
                            ${optionsHtml}
                        </div>
                        <div class="d-flex gap-2">
                            <div class="form-check">
                                <input type="checkbox" class="form-check-input field-required" 
                                       ${fieldData.required ? 'checked' : ''}>
                                <label class="form-check-label">Required</label>
                            </div>
                            <button type="button" class="btn btn-outline-danger btn-sm" 
                                    onclick="this.closest('.field-item').remove()">
                                <i class="fas fa-trash"></i>
                            </button>
                        </div>
                    </div>
                </div>
            `;

            fieldsContainer.appendChild(fieldElement);
        },

        async generateFormWithAI() {
            const description = document.getElementById('ai-description').value.trim();
            if (!description) {
                showError('Please enter a description for the form you want to generate');
                return;
            }

            try {
                showLoading('Generating form with AI...');
                const response = await fetch('/generate-form', {
                    method: 'POST',
                    headers: {
                        'Content-Type': 'application/json'
                    },
                    body: JSON.stringify({ description })
                });

                const data = await response.json();
                hideLoading();

                if (!response.ok) {
                    throw new Error(data.error || 'Failed to generate form');
                }

                // Clear existing fields
                document.getElementById('fields-container').innerHTML = '';

                // Add generated fields
                data.fields.forEach(field => {
                    this.addFieldToUI(field);
                });

                showSuccess('Form generated successfully!');
            } catch (error) {
                hideLoading();
                showError(error.message);
            }
        }
    };

    // Initialize form builder
    formBuilder.init();
});

// Helper functions for UI feedback
function showLoading(message = 'Loading...') {
    const loadingEl = document.createElement('div');
    loadingEl.className = 'loading-overlay';
    loadingEl.innerHTML = `
        <div class="spinner-border text-primary" role="status">
            <span class="visually-hidden">Loading...</span>
        </div>
        <div class="mt-2">${message}</div>
    `;
    document.body.appendChild(loadingEl);
}

function hideLoading() {
    const loadingEl = document.querySelector('.loading-overlay');
    if (loadingEl) {
        loadingEl.remove();
    }
}

function showError(message) {
    const alertsContainer = document.getElementById('alerts-container');
    const alert = document.createElement('div');
    alert.className = 'alert alert-danger alert-dismissible fade show';
    alert.innerHTML = `
        <strong>Error!</strong> ${message}
        <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
    `;
    alertsContainer.appendChild(alert);
    alert.scrollIntoView({ behavior: 'smooth', block: 'start' });
    setTimeout(() => alert.remove(), 5000);
}

function showSuccess(message) {
    const alertsContainer = document.getElementById('alerts-container');
    const alert = document.createElement('div');
    alert.className = 'alert alert-success alert-dismissible fade show';
    alert.innerHTML = `
        <strong>Success!</strong> ${message}
        <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
    `;
    alertsContainer.appendChild(alert);
    alert.scrollIntoView({ behavior: 'smooth', block: 'start' });
    setTimeout(() => alert.remove(), 5000);
}