'use client';

import { useState } from 'react';
import type { Submission } from '@/lib/types';
import { SubmissionManageModal } from './submission-manage-modal';

interface SubmissionsTableProps {
  submissions: Submission[];
  leadFormId: string;
}

export function SubmissionsTable({
  submissions,
  leadFormId,
}: SubmissionsTableProps) {
  const [selectedSubmission, setSelectedSubmission] =
    useState<Submission | null>(null);
  const [isModalOpen, setIsModalOpen] = useState(false);

  const handleManage = (submission: Submission) => {
    setSelectedSubmission(submission);
    setIsModalOpen(true);
  };

  const handleCloseModal = () => {
    setIsModalOpen(false);
    setSelectedSubmission(null);
  };

  if (submissions.length === 0) {
    return (
      <div className="rounded-lg border border-gray-200 bg-white p-6 text-sm text-gray-600 shadow-sm">
        No submissions yet. Share the embed to start collecting signups.
      </div>
    );
  }

  return (
    <>
      <div className="overflow-x-auto rounded-lg border border-gray-200 bg-white shadow-sm">
        <table className="min-w-full divide-y divide-gray-200">
          <thead className="bg-gray-50">
            <tr>
              <th className="px-6 py-3 text-left text-xs font-medium uppercase tracking-wider text-gray-500">
                Name
              </th>
              <th className="px-6 py-3 text-left text-xs font-medium uppercase tracking-wider text-gray-500">
                Email
              </th>
              <th className="px-6 py-3 text-left text-xs font-medium uppercase tracking-wider text-gray-500">
                Lead source
              </th>
              <th className="px-6 py-3 text-left text-xs font-medium uppercase tracking-wider text-gray-500">
                Submitted
              </th>
              <th className="px-6 py-3 text-left text-xs font-medium uppercase tracking-wider text-gray-500">
                Status
              </th>
              <th className="px-6 py-3 text-right text-xs font-medium uppercase tracking-wider text-gray-500">
                Actions
              </th>
            </tr>
          </thead>
          <tbody className="divide-y divide-gray-200 bg-white">
            {submissions.map((submission) => (
              <tr
                key={submission.id}
                className="transition hover:bg-gray-50"
              >
                <td className="whitespace-nowrap px-6 py-4">
                  <div className="text-sm font-medium text-gray-900">{submission.name}</div>
                </td>
                <td className="whitespace-nowrap px-6 py-4">
                  <div className="text-sm text-gray-600">{submission.email}</div>
                </td>
                <td className="whitespace-nowrap px-6 py-4">
                  <div className="text-sm text-gray-600">
                    {submission.source || (
                      <span className="italic text-gray-400">Not provided</span>
                    )}
                  </div>
                </td>
                <td className="whitespace-nowrap px-6 py-4">
                  <div className="text-sm text-gray-600">
                    {new Date(submission.createdAt).toLocaleString(undefined, {
                      dateStyle: 'short',
                      timeStyle: 'short',
                    })}
                  </div>
                </td>
                <td className="whitespace-nowrap px-6 py-4">
                  {submission.isDuplicate ? (
                    <span className="inline-flex items-center rounded-full bg-amber-100 px-2.5 py-0.5 text-xs font-medium text-amber-800">
                      Duplicate
                    </span>
                  ) : (
                    <span className="inline-flex items-center rounded-full bg-emerald-100 px-2.5 py-0.5 text-xs font-medium text-emerald-800">
                      New
                    </span>
                  )}
                </td>
                <td className="whitespace-nowrap px-6 py-4 text-right text-sm font-medium">
                  <button
                    onClick={() => handleManage(submission)}
                    className="rounded-md bg-blue-600 px-3 py-1.5 text-xs font-medium text-white shadow-sm transition hover:bg-blue-700"
                  >
                    Manage
                  </button>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>

      {selectedSubmission && (
        <SubmissionManageModal
          submission={selectedSubmission}
          isOpen={isModalOpen}
          onClose={handleCloseModal}
          leadFormId={leadFormId}
        />
      )}
    </>
  );
}
