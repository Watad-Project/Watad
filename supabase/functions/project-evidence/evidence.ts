// Pure logic of project-evidence (no network): compare the record the database sends to the chain with the chain's
// copy, field by field, with the same rules blockchain-sync uses (../_shared/reconcile.ts), and write the evidence
// as canonical JSON so its fingerprint and signature can be checked again later.

import { type Payment, type Project, samePayment, sameProjectData, sameTask, type Task } from '../_shared/reconcile.ts';

/** The project's fields on the chain, without its milestones and payments (compared one by one below). */
export const PROJECT_FIELDS = [
  'owner',
  'ownerId',
  'ownerEmail',
  'contractor',
  'contractorId',
  'contractorEmail',
  'agreedPrice',
  'currency',
] as const;

export type ProjectField = typeof PROJECT_FIELDS[number];

export interface FieldComparison { field: ProjectField; database: unknown; chain: unknown; matches: boolean }
export interface MilestoneComparison { index: number; database: Task | null; chain: Task | null; matches: boolean }
export interface PaymentComparison {
  id: string;
  database: Payment | null;
  chain: Payment | null;
  /** False for a paid payment the sync hasn't written yet, or one on the chain that is no longer paid here. */
  matches: boolean;
}

export interface Comparison {
  /** Everything matches: the chain holds exactly what the database would send. */
  matches: boolean;
  fields: FieldComparison[];
  milestones: MilestoneComparison[];
  payments: PaymentComparison[];
}

/**
 * Each field is checked with sameProjectData() itself, on a copy of [want] where only that field comes from
 * [have]: so a field matches exactly when the sync would see no difference in it.
 */
export function compare(want: Project, have: Project): Comparison {
  const fields = PROJECT_FIELDS.map((field): FieldComparison => ({
    field,
    database: want[field] ?? null,
    chain: have[field] ?? null,
    matches: sameProjectData(want, { ...want, [field]: have[field] }),
  }));

  const haveMilestones = have.milestone ?? [];
  const milestones: MilestoneComparison[] = [];
  for (let i = 0; i < Math.max(want.milestone.length, haveMilestones.length); i++) {
    const database = want.milestone[i] ?? null;
    const chain = haveMilestones[i] ?? null;
    milestones.push({ index: i, database, chain, matches: database !== null && chain !== null && sameTask(database, chain) });
  }

  const onChain = new Map((have.payments ?? []).map((p) => [p.id, p]));
  const payments: PaymentComparison[] = want.payments.map((database) => {
    const chain = onChain.get(database.id) ?? null;
    return { id: database.id, database, chain, matches: chain !== null && samePayment(database, chain) };
  });
  const wanted = new Set(want.payments.map((p) => p.id));
  for (const chain of have.payments ?? []) {
    if (!wanted.has(chain.id)) payments.push({ id: chain.id, database: null, chain, matches: false });
  }

  return {
    matches: sameProjectData(want, have) && payments.every((p) => p.matches),
    fields,
    milestones,
    payments,
  };
}

/**
 * JSON with every object's keys sorted and no spaces, so the same evidence always gives the same text, the same
 * fingerprint and the same signature. Arrays keep their order; undefined values are left out, as JSON.stringify does.
 */
export function canonicalJson(value: unknown): string {
  if (value === null || typeof value !== 'object') return JSON.stringify(value) ?? 'null';
  if (Array.isArray(value)) return `[${value.map((v) => (v === undefined ? 'null' : canonicalJson(v))).join(',')}]`;
  const entries = Object.keys(value as Record<string, unknown>)
    .sort()
    .filter((key) => (value as Record<string, unknown>)[key] !== undefined)
    .map((key) => `${JSON.stringify(key)}:${canonicalJson((value as Record<string, unknown>)[key])}`);
  return `{${entries.join(',')}}`;
}

/** Lower-case hex, as stored in project_evidence_exports.fingerprint. */
export function toHex(bytes: ArrayBuffer): string {
  return [...new Uint8Array(bytes)].map((b) => b.toString(16).padStart(2, '0')).join('');
}

export function toBase64(bytes: ArrayBuffer): string {
  let text = '';
  for (const b of new Uint8Array(bytes)) text += String.fromCharCode(b);
  return btoa(text);
}

export function fromBase64(text: string): Uint8Array {
  const raw = atob(text.replace(/\s+/g, ''));
  return Uint8Array.from(raw, (c) => c.charCodeAt(0));
}

/** The evidence's SHA-256 (hex) and its Ed25519 signature (base64), both of its canonical JSON. */
export async function fingerprintAndSign(
  evidence: unknown,
  privateKey: CryptoKey,
): Promise<{ canonical: string; fingerprint: string; signature: string }> {
  const canonical = canonicalJson(evidence);
  const bytes = new TextEncoder().encode(canonical);
  const fingerprint = toHex(await crypto.subtle.digest('SHA-256', bytes));
  const signature = toBase64(await crypto.subtle.sign('Ed25519', privateKey, bytes));
  return { canonical, fingerprint, signature };
}
