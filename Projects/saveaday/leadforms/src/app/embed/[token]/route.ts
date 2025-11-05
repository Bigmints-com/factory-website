import { getLeadFormByEmbedToken } from '@/lib/repositories/leadFormRepository';

const appUrl = process.env.NEXT_PUBLIC_APP_URL ?? '';

export const GET = async (
  _request: Request,
  { params }: { params: Promise<{ token: string }> },
) => {
  const { token: rawToken } = await params;
  console.log('[Embed] Received token from URL:', rawToken);
  const normalizedToken = rawToken.endsWith('.js')
    ? rawToken.slice(0, -3)
    : rawToken;
  console.log('[Embed] Normalized token:', normalizedToken);

  console.log('[Embed] Looking for leadForm with token:', normalizedToken);
  const leadForm = await getLeadFormByEmbedToken(normalizedToken);
  console.log('[Embed] LeadForm found:', leadForm ? { id: leadForm.id, name: leadForm.name, status: leadForm.status } : 'null');
  if (!leadForm || leadForm.status !== 'active') {
    console.log('[Embed] LeadForm not available - exists:', !!leadForm, 'status:', leadForm?.status);
    return new Response('console.warn("LeadForm not available")', {
      headers: {
        'Content-Type': 'application/javascript; charset=utf-8',
      },
      status: 404,
    });
  }

  const fetchPath = `/api/public/leadforms/${leadForm.embedToken}`;
  const submitPath = `/api/public/leadforms/${leadForm.embedToken}/submit`;

  const script = `(() => {
  const TOKEN = ${JSON.stringify(leadForm.embedToken)};
  const FETCH_PATH = ${JSON.stringify(fetchPath)};
  const SUBMIT_PATH = ${JSON.stringify(submitPath)};
  const resolveBaseUrl = () => {
    try {
      const current = document.currentScript;
      if (current) {
        const url = new URL(current.src);
        return url.origin;
      }
    } catch (error) {
      console.warn('LeadForm modal: unable to derive origin', error);
    }
    return "${appUrl}" || window.location.origin;
  };

  const BASE = resolveBaseUrl();
  const REGISTRY_KEY = '__leadFormModalRegistry';
  const registry = (window[REGISTRY_KEY] = window[REGISTRY_KEY] || {});
  if (registry[TOKEN]) {
    return;
  }

  const state = {
    config: null,
    overlay: null,
    modal: null,
    loading: false,
  };
  let loadingConfig = false;

  const ensureStyles = () => {
    if (document.getElementById('leadForm-modal-styles')) return;
    const style = document.createElement('style');
    style.id = 'leadForm-modal-styles';
    style.textContent = [
      '.leadForm-overlay { position: fixed; inset: 0; background: rgba(0, 0, 0, 0.5); display: flex; align-items: center; justify-content: center; z-index: 9999; animation: leadForm-fade-in 200ms ease-out; }',
      ".leadForm-modal { width: min(420px, 92vw); background: #ffffff; color: #171717; border-radius: 8px; padding: 24px; box-shadow: 0 10px 25px rgba(0, 0, 0, 0.15); font-family: ui-monospace, SFMono-Regular, 'SF Mono', Menlo, Consolas, 'Liberation Mono', monospace; position: relative; border: 1px solid #e5e7eb; }",
      '.leadForm-close { position: absolute; right: 16px; top: 16px; background: transparent; border: none; color: #6b7280; font-size: 24px; cursor: pointer; padding: 4px; line-height: 1; transition: color 150ms ease; }',
      '.leadForm-close:hover { color: #171717; }',
      '.leadForm-field { display: flex; flex-direction: column; gap: 6px; margin-bottom: 16px; }',
      '.leadForm-field label { font-size: 14px; font-weight: 500; color: #374151; }',
      '.leadForm-input, .leadForm-select { border-radius: 6px; border: 1px solid #d1d5db; background: #ffffff; color: #171717; padding: 10px 14px; font-size: 14px; font-family: inherit; transition: border-color 150ms ease, box-shadow 150ms ease; }',
      '.leadForm-input:focus, .leadForm-select:focus { outline: none; border-color: #3b82f6; box-shadow: 0 0 0 3px rgba(59, 130, 246, 0.1); }',
      '.leadForm-input::placeholder { color: #9ca3af; }',
      '.leadForm-submit { width: 100%; border: none; border-radius: 6px; padding: 10px 18px; font-weight: 500; font-size: 14px; cursor: pointer; margin-top: 8px; transition: opacity 150ms ease, transform 150ms ease; font-family: inherit; }',
      '.leadForm-submit[disabled] { opacity: 0.6; cursor: not-allowed; }',
      '.leadForm-submit:not([disabled]):hover { transform: translateY(-1px); }',
      '.leadForm-error { color: #dc2626; font-size: 13px; margin-top: 8px; }',
      '.leadForm-success { color: #059669; font-size: 14px; margin-top: 16px; text-align: center; font-weight: 500; }',
      '@keyframes leadForm-fade-in { from { opacity: 0; } to { opacity: 1; } }',
    ].join(' ');
    document.head.appendChild(style);
  };

  const closeModal = () => {
    if (!state.overlay) return;
    document.body.style.overflow = '';
    state.overlay.remove();
    state.overlay = null;
    state.modal = null;
  };

  const handleSubmit = async (event) => {
    event.preventDefault();
    if (!state.modal || !state.config || state.loading) return;
    const form = event.target;
    const name = form.querySelector('input[name="name"]').value.trim();
    const email = form.querySelector('input[name="email"]').value.trim();
    const sourceElement = form.querySelector('select[name="source"]');
    const source = sourceElement ? sourceElement.value : null;

    const errorNode = state.modal.querySelector('.leadForm-error');
    const successNode = state.modal.querySelector('.leadForm-success');
    if (errorNode) errorNode.textContent = '';
    if (successNode) successNode.textContent = '';

    if (!name || !email) {
      if (errorNode) errorNode.textContent = 'Name and email are required.';
      return;
    }

    state.loading = true;
    const submitButton = state.modal.querySelector('.leadForm-submit');
    if (submitButton) submitButton.setAttribute('disabled', 'true');

    try {
      const response = await fetch(BASE + SUBMIT_PATH, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ name, email, source }),
      });
      const payload = await response.json();
      if (!response.ok) {
        if (errorNode) {
          errorNode.textContent = payload?.message || 'Unable to submit right now.';
        }
      } else {
        form.reset();
        if (successNode) {
          successNode.textContent = payload.successMessage || 'Thanks for joining!';
        }
        if (payload.redirectUrl) {
          setTimeout(() => {
            window.location.href = payload.redirectUrl;
          }, 900);
        } else {
          setTimeout(() => closeModal(), 1200);
        }
      }
    } catch (error) {
      if (errorNode) {
        errorNode.textContent = 'Network error. Please try again.';
      }
    } finally {
      state.loading = false;
      if (submitButton) submitButton.removeAttribute('disabled');
    }
  };

  const buildModal = () => {
    ensureStyles();
    const overlay = document.createElement('div');
    overlay.className = 'leadForm-overlay';
    const modal = document.createElement('div');
    modal.className = 'leadForm-modal';

    const close = document.createElement('button');
    close.className = 'leadForm-close';
    close.type = 'button';
    close.innerHTML = '&times;';
    close.addEventListener('click', closeModal);

    const title = document.createElement('h3');
    title.style.fontSize = '20px';
    title.style.fontWeight = '600';
    title.style.color = '#171717';
    title.style.marginBottom = '8px';
    title.textContent = state.config.name;

    const description = document.createElement('p');
    description.style.fontSize = '14px';
    description.style.color = '#6b7280';
    description.style.marginBottom = '20px';
    description.textContent = state.config.description || 'Share your details and we will get in touch.';

    const form = document.createElement('form');
    form.addEventListener('submit', handleSubmit);

    const nameField = document.createElement('div');
    nameField.className = 'leadForm-field';
    const nameLabel = document.createElement('label');
    nameLabel.textContent = 'Name';
    const nameInput = document.createElement('input');
    nameInput.name = 'name';
    nameInput.placeholder = state.config.placeholders.name;
    nameInput.className = 'leadForm-input';
    nameInput.maxLength = 100;
    nameField.appendChild(nameLabel);
    nameField.appendChild(nameInput);

    const emailField = document.createElement('div');
    emailField.className = 'leadForm-field';
    const emailLabel = document.createElement('label');
    emailLabel.textContent = 'Email';
    const emailInput = document.createElement('input');
    emailInput.name = 'email';
    emailInput.type = 'email';
    emailInput.placeholder = state.config.placeholders.email;
    emailInput.className = 'leadForm-input';
    emailField.appendChild(emailLabel);
    emailField.appendChild(emailInput);

    if ((state.config.sourceOptions || []).length > 0) {
      const sourceField = document.createElement('div');
      sourceField.className = 'leadForm-field';
      const sourceLabel = document.createElement('label');
      sourceLabel.textContent = 'Lead source';
      const sourceSelect = document.createElement('select');
      sourceSelect.name = 'source';
      sourceSelect.className = 'leadForm-select';
      const emptyOption = document.createElement('option');
      emptyOption.value = '';
      emptyOption.textContent = 'Select an option';
      sourceSelect.appendChild(emptyOption);
      (state.config.sourceOptions || []).forEach((option) => {
        const optionNode = document.createElement('option');
        optionNode.value = option;
        optionNode.textContent = option;
        sourceSelect.appendChild(optionNode);
      });
      sourceField.appendChild(sourceLabel);
      sourceField.appendChild(sourceSelect);
      form.appendChild(sourceField);
    }

    const submitButton = document.createElement('button');
    submitButton.type = 'submit';
    submitButton.className = 'leadForm-submit';
    submitButton.textContent = state.config.styling.buttonText;
    submitButton.style.background = state.config.styling.brandColor;
    submitButton.style.color = '#ffffff';

    const errorNode = document.createElement('div');
    errorNode.className = 'leadForm-error';

    const successNode = document.createElement('div');
    successNode.className = 'leadForm-success';

    form.appendChild(nameField);
    form.appendChild(emailField);
    form.appendChild(submitButton);
    form.appendChild(errorNode);
    form.appendChild(successNode);

    modal.appendChild(close);
    modal.appendChild(title);
    modal.appendChild(description);
    modal.appendChild(form);

    overlay.addEventListener('click', (event) => {
      if (event.target === overlay) closeModal();
    });

    overlay.appendChild(modal);
    state.overlay = overlay;
    state.modal = modal;
  };

  const openModal = () => {
    if (!state.config) {
      if (!loadingConfig) {
        loadConfig().then(() => {
          if (state.config) openModal();
        });
      }
      return;
    }
    if (!state.overlay) {
      buildModal();
    }
    document.body.appendChild(state.overlay);
    document.body.style.overflow = 'hidden';
  };

  registry[TOKEN] = { open: openModal, close: closeModal };
  window.showLeadFormModal = openModal;
  window.closeLeadFormModal = closeModal;

  const loadConfig = async () => {
    if (state.config || loadingConfig) return;
    loadingConfig = true;
    try {
      const response = await fetch(BASE + FETCH_PATH);
      if (!response.ok) throw new Error('Failed to load lead form configuration');
      state.config = await response.json();
    } catch (error) {
      console.error('LeadForm modal: unable to load configuration', error);
    } finally {
      loadingConfig = false;
    }
  };

  loadConfig();
})();
`;

  return new Response(script, {
    status: 200,
    headers: {
      'Content-Type': 'application/javascript; charset=utf-8',
      'Cache-Control': 'max-age=60',
    },
  });
};
