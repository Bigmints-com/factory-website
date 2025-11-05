"use client";

import { useFormState, useFormStatus } from 'react-dom';
import type { DuplicateStrategy, LeadFormStatus } from '@/lib/types';
import { useState } from 'react';
import { LeadFormPreviewButton } from './leadform-preview-button';

type LeadFormFormState =
  | {
      success: false;
      errors: Record<string, string[]>;
    }
  | {
      success: true;
      errors?: never;
    }
  | undefined;

const defaultValues = {
  name: '',
  description: '',
  sourceOptions: ['Website', 'Referral', 'Event signup'],
  duplicateStrategy: 'reject' as DuplicateStrategy,
  status: 'active' as LeadFormStatus,
  redirectUrl: '',
  brandColor: '#2563eb',
  buttonText: 'Submit lead',
  successMessage: 'Thanks for sharing your details!',
  namePlaceholder: 'Full name',
  emailPlaceholder: 'you@example.com',
};

interface LeadFormFormProps {
  action: (formData: FormData) => Promise<LeadFormFormState | void>;
  initialValues?: Partial<typeof defaultValues> & {
    sourceOptions?: string[];
    embedToken?: string;
    leadFormId?: string;
  };
  submitLabel: string;
  footerSlot?: React.ReactNode;
}

const SubmitButton = ({ label }: { label: string }) => {
  const { pending } = useFormStatus();
  return (
    <button
      type="submit"
      disabled={pending}
      className="rounded-md bg-blue-600 px-5 py-2 text-sm font-medium text-white shadow-sm transition hover:bg-blue-700 disabled:cursor-not-allowed disabled:opacity-60"
    >
      {pending ? 'Saving…' : label}
    </button>
  );
};

export const LeadFormForm = ({
  action,
  initialValues,
  submitLabel,
  footerSlot,
}: LeadFormFormProps) => {
  const merged = { ...defaultValues, ...initialValues };
  const [sourceOptions, setSourceOptions] = useState<string[]>(
    merged.sourceOptions ?? defaultValues.sourceOptions,
  );
  const [newSource, setNewSource] = useState('');

  const addSource = () => {
    const value = newSource.trim();
    if (value && !sourceOptions.includes(value)) {
      setSourceOptions((prev) => [...prev, value]);
    }
    setNewSource('');
  };

  const formAction = async (
    _state: LeadFormFormState | undefined,
    formData: FormData,
  ) => {
    formData.set('sourceOptions', sourceOptions.join(','));
    const result = await action(formData);
    return result ?? { success: true };
  };

  const [state, dispatch] = useFormState<LeadFormFormState, FormData>(
    formAction,
    undefined,
  );

  const renderErrors = (field: string) =>
    state?.errors?.[field]?.map((error) => (
      <p key={error} className="mt-1 text-xs text-red-600">
        {error}
      </p>
    ));

  return (
    <form action={dispatch} className="space-y-6">
      <section className="rounded-lg border border-gray-200 bg-white p-6 shadow-sm space-y-6">
        <header>
          <h2 className="text-lg font-semibold text-gray-900">Lead form details</h2>
          <p className="text-sm text-gray-600 mt-1">
            Configure the name, description, status, and duplicate strategy.
          </p>
        </header>

        <div className="grid gap-4 sm:grid-cols-2">
          <div className="space-y-2 sm:col-span-2">
            <label className="text-sm font-medium text-gray-700" htmlFor="name">
              Name
            </label>
            <input
              id="name"
              name="name"
              defaultValue={merged.name}
              className="w-full rounded-md border border-gray-300 bg-white px-4 py-3 text-gray-900 placeholder:text-gray-400 focus:border-blue-500 focus:outline-none focus:ring-2 focus:ring-blue-500"
              placeholder="New product lead form"
              required
            />
            {renderErrors('name')}
          </div>

          <div className="space-y-2 sm:col-span-2">
            <label className="text-sm font-medium text-gray-700" htmlFor="description">
              Description
            </label>
            <textarea
              id="description"
              name="description"
              defaultValue={merged.description}
              rows={3}
              className="w-full rounded-md border border-gray-300 bg-white px-4 py-3 text-gray-900 placeholder:text-gray-400 focus:border-blue-500 focus:outline-none focus:ring-2 focus:ring-blue-500"
              placeholder="Short summary for this lead form"
            />
            {renderErrors('description')}
          </div>

          <div className="space-y-2">
            <label className="text-sm font-medium text-gray-700" htmlFor="status">
              Status
            </label>
            <select
              id="status"
              name="status"
              defaultValue={merged.status}
              className="w-full rounded-md border border-gray-300 bg-white px-4 py-3 text-gray-900 focus:border-blue-500 focus:outline-none focus:ring-2 focus:ring-blue-500"
            >
              <option value="active">Active</option>
              <option value="inactive">Inactive</option>
            </select>
            {renderErrors('status')}
          </div>

          <div className="space-y-2">
            <label
              className="text-sm font-medium text-gray-700"
              htmlFor="duplicateStrategy"
            >
              Duplicate handling
            </label>
            <select
              id="duplicateStrategy"
              name="duplicateStrategy"
              defaultValue={merged.duplicateStrategy}
              className="w-full rounded-md border border-gray-300 bg-white px-4 py-3 text-gray-900 focus:border-blue-500 focus:outline-none focus:ring-2 focus:ring-blue-500"
            >
              <option value="reject">Reject duplicates</option>
              <option value="update">Update existing</option>
              <option value="allow">Allow duplicates</option>
            </select>
            {renderErrors('duplicateStrategy')}
          </div>

          <div className="space-y-2 sm:col-span-2">
            <label className="text-sm font-medium text-gray-700">Lead source options</label>
            <div className="space-y-2">
              <div className="flex flex-wrap gap-2">
                {sourceOptions.map((source, index) => (
                  <span
                    key={`${source}-${index}`}
                    className="flex items-center gap-2 rounded-md border border-gray-300 bg-white px-3 py-1 text-xs text-gray-900"
                  >
                    {source}
                    <button
                      type="button"
                      onClick={() =>
                        setSourceOptions((prev) =>
                          prev.filter((_, idx) => idx !== index),
                        )
                      }
                      className="text-gray-600 hover:text-black"
                    >
                      ×
                    </button>
                  </span>
                ))}
              </div>
              <div className="flex gap-2">
                <input
                  type="text"
                  value={newSource}
                  onChange={(event) => setNewSource(event.target.value)}
                  placeholder="Add a source"
                  className="flex-1 border border-gray-300 bg-white px-4 py-2 text-sm text-black placeholder:text-gray-400 focus:border-black focus:outline-none"
                  onKeyDown={(event) => {
                    if (event.key === 'Enter') {
                      event.preventDefault();
                      addSource();
                    }
                  }}
                />
                <button
                  type="button"
                  onClick={addSource}
                  className="rounded-md border border-gray-300 bg-white px-4 py-2 text-sm font-medium text-gray-700 shadow-sm transition hover:bg-gray-50"
                >
                  Add
                </button>
              </div>
            </div>
            {renderErrors('sourceOptions')}
          </div>

          <div className="space-y-2 sm:col-span-2">
            <label className="text-sm font-medium text-gray-700" htmlFor="redirectUrl">
              Redirect URL (optional)
            </label>
            <input
              id="redirectUrl"
              name="redirectUrl"
              defaultValue={merged.redirectUrl}
              className="w-full rounded-md border border-gray-300 bg-white px-4 py-3 text-gray-900 placeholder:text-gray-400 focus:border-blue-500 focus:outline-none focus:ring-2 focus:ring-blue-500"
              placeholder="https://example.com/thanks"
            />
            {renderErrors('redirectUrl')}
          </div>
        </div>
      </section>

      <section className="rounded-lg border border-gray-200 bg-white p-6 shadow-sm space-y-6">
        <header className="flex items-center justify-between">
          <div>
            <h2 className="text-lg font-semibold text-gray-900">Form experience</h2>
            <p className="text-sm text-gray-600 mt-1">
              Customize placeholders, button text, brand color, and success
              message for the embeddable modal.
            </p>
          </div>
          <LeadFormPreviewButton 
            embedToken={merged.embedToken}
            leadFormId={merged.leadFormId}
          />
        </header>

        <div className="grid gap-4 sm:grid-cols-2">
          <div className="space-y-2">
            <label className="text-sm font-medium text-gray-700" htmlFor="brandColor">
              Brand color (hex)
            </label>
            <input
              id="brandColor"
              name="brandColor"
              defaultValue={merged.brandColor}
              className="w-full border border-gray-300 bg-white px-4 py-3 text-black placeholder:text-gray-400 focus:border-black focus:outline-none font-mono"
            />
            {renderErrors('brandColor')}
          </div>

          <div className="space-y-2">
            <label className="text-sm font-medium text-gray-700" htmlFor="buttonText">
              Button text
            </label>
            <input
              id="buttonText"
              name="buttonText"
              defaultValue={merged.buttonText}
              className="w-full rounded-md border border-gray-300 bg-white px-4 py-3 text-gray-900 placeholder:text-gray-400 focus:border-blue-500 focus:outline-none focus:ring-2 focus:ring-blue-500"
            />
            {renderErrors('buttonText')}
          </div>

          <div className="space-y-2 sm:col-span-2">
            <label className="text-sm font-medium text-gray-700" htmlFor="successMessage">
              Success message
            </label>
            <input
              id="successMessage"
              name="successMessage"
              defaultValue={merged.successMessage}
              className="w-full rounded-md border border-gray-300 bg-white px-4 py-3 text-gray-900 placeholder:text-gray-400 focus:border-blue-500 focus:outline-none focus:ring-2 focus:ring-blue-500"
            />
            {renderErrors('successMessage')}
          </div>

          <div className="space-y-2">
            <label className="text-sm font-medium text-gray-700" htmlFor="namePlaceholder">
              Name placeholder
            </label>
            <input
              id="namePlaceholder"
              name="namePlaceholder"
              defaultValue={merged.namePlaceholder}
              className="w-full rounded-md border border-gray-300 bg-white px-4 py-3 text-gray-900 placeholder:text-gray-400 focus:border-blue-500 focus:outline-none focus:ring-2 focus:ring-blue-500"
            />
            {renderErrors('namePlaceholder')}
          </div>

          <div className="space-y-2">
            <label
              className="text-sm font-medium text-gray-700"
              htmlFor="emailPlaceholder"
            >
              Email placeholder
            </label>
            <input
              id="emailPlaceholder"
              name="emailPlaceholder"
              defaultValue={merged.emailPlaceholder}
              className="w-full rounded-md border border-gray-300 bg-white px-4 py-3 text-gray-900 placeholder:text-gray-400 focus:border-blue-500 focus:outline-none focus:ring-2 focus:ring-blue-500"
            />
            {renderErrors('emailPlaceholder')}
          </div>
        </div>
      </section>

      <div className="flex items-center justify-between">
        <div>{footerSlot}</div>
        <SubmitButton label={submitLabel} />
      </div>
    </form>
  );
};
