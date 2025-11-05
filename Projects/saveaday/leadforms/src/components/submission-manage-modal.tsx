'use client';

import { useState, useEffect } from 'react';
import type { Submission } from '@/lib/types';
import { updateSubmissionAction } from '@/lib/actions/submissionActions';

interface SubmissionManageModalProps {
  submission: Submission;
  isOpen: boolean;
  onClose: () => void;
  leadFormId: string;
}

export function SubmissionManageModal({
  submission,
  isOpen,
  onClose,
  leadFormId,
}: SubmissionManageModalProps) {
  const [isEditing, setIsEditing] = useState(false);
  const [formData, setFormData] = useState({
    name: submission.name,
    email: submission.email,
    source: submission.source || '',
  });
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    if (isOpen) {
      setFormData({
        name: submission.name,
        email: submission.email,
        source: submission.source || '',
      });
      setIsEditing(false);
      setError(null);
    }
  }, [submission, isOpen]);

  if (!isOpen) return null;

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setIsSubmitting(true);
    setError(null);

    try {
      const result = await updateSubmissionAction(
        leadFormId,
        submission.id,
        formData
      );

      if (result?.error) {
        setError(result.error);
      } else {
        setIsEditing(false);
        // Refresh the page to show updated data
        window.location.reload();
      }
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to update submission');
    } finally {
      setIsSubmitting(false);
    }
  };

  const handleCancel = () => {
    setIsEditing(false);
    setFormData({
      name: submission.name,
      email: submission.email,
      source: submission.source || '',
    });
    setError(null);
  };

  return (
    <div
      className="fixed inset-0 z-50 flex items-center justify-center bg-black/60 p-4 font-mono"
      onClick={onClose}
    >
      <div
        className="w-full max-w-2xl rounded-lg border border-gray-200 bg-white p-6 shadow-lg"
        onClick={(e) => e.stopPropagation()}
      >
        <div className="mb-6 flex items-center justify-between">
          <h2 className="text-xl font-semibold text-gray-900">Submission Details</h2>
          <button
            onClick={onClose}
            className="p-2 text-gray-600 transition hover:bg-gray-50 hover:text-black"
          >
            <svg
              className="h-5 w-5"
              fill="none"
              stroke="currentColor"
              viewBox="0 0 24 24"
            >
              <path
                strokeLinecap="round"
                strokeLinejoin="round"
                strokeWidth={2}
                d="M6 18L18 6M6 6l12 12"
              />
            </svg>
          </button>
        </div>

        {isEditing ? (
          <form onSubmit={handleSubmit} className="space-y-4">
            <div>
              <label className="mb-2 block text-sm font-normal text-black">
                Name
              </label>
              <input
                type="text"
                value={formData.name}
                onChange={(e) =>
                  setFormData({ ...formData, name: e.target.value })
                }
                className="w-full rounded-md border border-gray-300 bg-white px-4 py-2 text-gray-900 focus:border-blue-500 focus:outline-none focus:ring-2 focus:ring-blue-500"
                required
              />
            </div>

            <div>
              <label className="mb-2 block text-sm font-normal text-black">
                Email
              </label>
              <input
                type="email"
                value={formData.email}
                onChange={(e) =>
                  setFormData({ ...formData, email: e.target.value })
                }
                className="w-full rounded-md border border-gray-300 bg-white px-4 py-2 text-gray-900 focus:border-blue-500 focus:outline-none focus:ring-2 focus:ring-blue-500"
                required
              />
            </div>

            <div>
              <label className="mb-2 block text-sm font-normal text-black">
                Lead source
              </label>
              <input
                type="text"
                value={formData.source}
                onChange={(e) =>
                  setFormData({ ...formData, source: e.target.value })
                }
                className="w-full rounded-md border border-gray-300 bg-white px-4 py-2 text-gray-900 focus:border-blue-500 focus:outline-none focus:ring-2 focus:ring-blue-500"
                placeholder="Optional"
              />
            </div>

            {error && (
              <div className="rounded-md border border-red-300 bg-red-50 px-4 py-2 text-sm text-red-800">
                {error}
              </div>
            )}

            <div className="flex items-center justify-between pt-4">
              <button
                type="button"
                onClick={handleCancel}
                disabled={isSubmitting}
                className="rounded-md border border-gray-300 bg-white px-4 py-2 text-sm font-medium text-gray-700 shadow-sm transition hover:bg-gray-50 disabled:opacity-50"
              >
                Cancel
              </button>
              <button
                type="submit"
                disabled={isSubmitting}
                className="rounded-md bg-blue-600 px-4 py-2 text-sm font-medium text-white shadow-sm transition hover:bg-blue-700 disabled:opacity-50"
              >
                {isSubmitting ? 'Saving...' : 'Save Changes'}
              </button>
            </div>
          </form>
        ) : (
          <div className="space-y-6">
            <div className="grid grid-cols-2 gap-4">
              <div>
                <label className="text-xs font-normal uppercase tracking-wider text-gray-600">
                  Name
                </label>
                <p className="mt-1 text-sm text-black">{submission.name}</p>
              </div>
              <div>
                <label className="text-xs font-normal uppercase tracking-wider text-gray-600">
                  Email
                </label>
                <p className="mt-1 text-sm text-black">{submission.email}</p>
              </div>
              <div>
                <label className="text-xs font-normal uppercase tracking-wider text-gray-600">
                  Lead source
                </label>
                <p className="mt-1 text-sm text-black">
                  {submission.source || (
                    <span className="italic text-gray-600">Not provided</span>
                  )}
                </p>
              </div>
              <div>
                <label className="text-xs font-normal uppercase tracking-wider text-gray-600">
                  Status
                </label>
                <p className="mt-1">
                  {submission.isDuplicate ? (
                    <span className="inline-flex items-center rounded-full bg-amber-100 px-2.5 py-0.5 text-xs font-medium text-amber-800">
                      Duplicate
                    </span>
                  ) : (
                    <span className="inline-flex items-center rounded-full bg-emerald-100 px-2.5 py-0.5 text-xs font-medium text-emerald-800">
                      New
                    </span>
                  )}
                </p>
              </div>
              <div>
                <label className="text-xs font-normal uppercase tracking-wider text-gray-600">
                  Submitted
                </label>
                <p className="mt-1 text-sm text-black">
                  {new Date(submission.createdAt).toLocaleString(undefined, {
                    dateStyle: 'long',
                    timeStyle: 'long',
                  })}
                </p>
              </div>
              <div>
                <label className="text-xs font-normal uppercase tracking-wider text-gray-600">
                  Last Updated
                </label>
                <p className="mt-1 text-sm text-black">
                  {new Date(submission.updatedAt).toLocaleString(undefined, {
                    dateStyle: 'long',
                    timeStyle: 'long',
                  })}
                </p>
              </div>
            </div>

            {submission.metadata && (
              <div className="border border-gray-300 bg-gray-50 p-4">
                <h3 className="mb-3 text-sm font-normal text-black">
                  Metadata
                </h3>
                <div className="grid grid-cols-2 gap-4 text-xs">
                  {submission.metadata.ip && (
                    <div>
                      <label className="text-gray-600">IP Address</label>
                      <p className="mt-1 text-black">{submission.metadata.ip}</p>
                    </div>
                  )}
                  {submission.metadata.referrer && (
                    <div>
                      <label className="text-gray-600">Referrer</label>
                      <p className="mt-1 text-black break-all">
                        {submission.metadata.referrer}
                      </p>
                    </div>
                  )}
                  {submission.metadata.userAgent && (
                    <div className="col-span-2">
                      <label className="text-gray-600">User Agent</label>
                      <p className="mt-1 text-black break-all text-xs font-mono">
                        {submission.metadata.userAgent}
                      </p>
                    </div>
                  )}
                </div>
              </div>
            )}

            {submission.duplicateOf && (
              <div className="border border-black bg-white p-4">
                <p className="text-sm text-black">
                  This is a duplicate of submission ID: {submission.duplicateOf}
                </p>
              </div>
            )}

            <div className="flex items-center justify-between pt-4">
              <button
                onClick={onClose}
                className="rounded-md border border-gray-300 bg-white px-4 py-2 text-sm font-medium text-gray-700 shadow-sm transition hover:bg-gray-50"
              >
                Close
              </button>
              <button
                onClick={() => setIsEditing(true)}
                className="rounded-md bg-blue-600 px-4 py-2 text-sm font-medium text-white shadow-sm transition hover:bg-blue-700"
              >
                Edit
              </button>
            </div>
          </div>
        )}
      </div>
    </div>
  );
}
