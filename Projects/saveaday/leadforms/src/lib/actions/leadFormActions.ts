"use server";

import { authOptions } from '@/lib/authOptions';
import {
  createLeadForm,
  deleteLeadForm,
  updateLeadForm,
} from '@/lib/repositories/leadFormRepository';
import type { DuplicateStrategy, LeadFormStatus } from '@/lib/types';
import { z } from 'zod';
import { getServerSession } from 'next-auth';
import { revalidatePath } from 'next/cache';
import { redirect } from 'next/navigation';

const leadFormSchema = z.object({
  name: z
    .string()
    .min(2, 'Name is required')
    .max(100, 'Name cannot exceed 100 characters'),
  description: z
    .string()
    .max(500, 'Description cannot exceed 500 characters')
    .optional()
    .default(''),
  sourceOptions: z
    .array(z.string().min(1).max(40))
    .max(10, 'Provide no more than 10 lead source options'),
  duplicateStrategy: z.enum(['reject', 'update', 'allow']),
  status: z.enum(['active', 'inactive']),
  redirectUrl: z
    .string()
    .url('Provide a valid URL')
    .optional()
    .or(z.literal('')),
  brandColor: z
    .string()
    .regex(/^#([0-9a-f]{6}|[0-9a-f]{3})$/i, 'Provide a valid hex color'),
  buttonText: z
    .string()
    .min(2, 'Button text must be provided')
    .max(40, 'Button text cannot exceed 40 characters'),
  successMessage: z
    .string()
    .min(5, 'Success message must be provided')
    .max(150, 'Success message cannot exceed 150 characters'),
  namePlaceholder: z
    .string()
    .min(2, 'Name placeholder must be provided')
    .max(100, 'Name placeholder cannot exceed 100 characters'),
  emailPlaceholder: z
    .string()
    .min(5, 'Email placeholder must be provided')
    .max(100, 'Email placeholder cannot exceed 100 characters'),
});

const getSessionOrThrow = async () => {
  const session = await getServerSession(authOptions);
  if (!session?.user?.id) {
    throw new Error('Unauthorized');
  }
  return session.user;
};

export const createLeadFormAction = async (formData: FormData) => {
  const user = await getSessionOrThrow();
  const rawSourceOptions = (formData.get('sourceOptions') ?? '')
    .toString()
    .split(',')
    .map((value) => value.trim())
    .filter(Boolean);

  const parsed = leadFormSchema.safeParse({
    name: formData.get('name'),
    description: formData.get('description') ?? '',
    sourceOptions: rawSourceOptions,
    duplicateStrategy: formData.get('duplicateStrategy'),
    status: formData.get('status'),
    redirectUrl: formData.get('redirectUrl') ?? '',
    brandColor: formData.get('brandColor'),
    buttonText: formData.get('buttonText'),
    successMessage: formData.get('successMessage'),
    namePlaceholder: formData.get('namePlaceholder'),
    emailPlaceholder: formData.get('emailPlaceholder'),
  });

  if (!parsed.success) {
    return {
      success: false,
      errors: parsed.error.flatten().fieldErrors,
    };
  }

  const payload = parsed.data;

  const leadForm = await createLeadForm({
    ownerId: user.id,
    name: payload.name,
    description: payload.description,
    sourceOptions: payload.sourceOptions,
    duplicateStrategy: payload.duplicateStrategy as DuplicateStrategy,
    status: payload.status as LeadFormStatus,
    redirectUrl: payload.redirectUrl ?? '',
    styling: {
      brandColor: payload.brandColor,
      buttonText: payload.buttonText,
      successMessage: payload.successMessage,
    },
    placeholders: {
      name: payload.namePlaceholder,
      email: payload.emailPlaceholder,
    },
  });

  revalidatePath('/leadforms');
  redirect(`/leadforms/${leadForm.id}`);
};

export const updateLeadFormAction = async (
  leadFormId: string,
  formData: FormData,
) => {
  const user = await getSessionOrThrow();

  const rawSourceOptions = (formData.get('sourceOptions') ?? '')
    .toString()
    .split(',')
    .map((value) => value.trim())
    .filter(Boolean);

  const parsed = leadFormSchema.safeParse({
    name: formData.get('name'),
    description: formData.get('description') ?? '',
    sourceOptions: rawSourceOptions,
    duplicateStrategy: formData.get('duplicateStrategy'),
    status: formData.get('status'),
    redirectUrl: formData.get('redirectUrl') ?? '',
    brandColor: formData.get('brandColor'),
    buttonText: formData.get('buttonText'),
    successMessage: formData.get('successMessage'),
    namePlaceholder: formData.get('namePlaceholder'),
    emailPlaceholder: formData.get('emailPlaceholder'),
  });

  if (!parsed.success) {
    return {
      success: false,
      errors: parsed.error.flatten().fieldErrors,
    };
  }

  const payload = parsed.data;

  await updateLeadForm(user.id, leadFormId, {
    name: payload.name,
    description: payload.description,
    sourceOptions: payload.sourceOptions,
    duplicateStrategy: payload.duplicateStrategy as DuplicateStrategy,
    status: payload.status as LeadFormStatus,
    redirectUrl: payload.redirectUrl ?? '',
    styling: {
      brandColor: payload.brandColor,
      buttonText: payload.buttonText,
      successMessage: payload.successMessage,
    },
    placeholders: {
      name: payload.namePlaceholder,
      email: payload.emailPlaceholder,
    },
  });

  revalidatePath(`/leadforms/${leadFormId}`);
  return { success: true };
};

export const deleteLeadFormAction = async (leadFormId: string) => {
  const user = await getSessionOrThrow();
  await deleteLeadForm(user.id, leadFormId);
  revalidatePath('/leadforms');
  redirect('/leadforms');
};
