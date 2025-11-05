import { LeadFormForm } from '@/components/leadform-form';
import { createLeadFormAction } from '@/lib/actions/leadFormActions';

export default function NewLeadFormPage() {
  return (
    <div className="space-y-8 font-mono">
      <div>
        <h1 className="text-3xl font-semibold">Create lead form</h1>
        <p className="text-sm text-gray-600">
          Configure fields, styling, and duplicate handling for your new lead form.
        </p>
      </div>

      <LeadFormForm action={createLeadFormAction} submitLabel="Create lead form" />
    </div>
  );
}
