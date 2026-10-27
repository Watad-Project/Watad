// Shared by blockchain-sync (what to write) and project-evidence (what matches), so both use the same rules.
//
// Pure logic (no network): given the record the database wants on the chain and the record the chain holds,
// decide which blockchain calls bring the chain in step. Doing "compare, then write the difference" (instead of
// "replay the change") makes every run safe to repeat: a retry, a duplicate call or a lost call can never
// create a duplicate project or payment.

export interface Task { description: string; startDate?: string | null; finishDate?: string | null; status?: string | null }
export interface Payment { id: string; amount: number; date: string; note?: string | null }
export interface Project {
  id: string;
  owner: string;
  ownerId: string;
  ownerEmail: string;
  contractor: string;
  contractorId: string;
  contractorEmail: string;
  agreedPrice: number;
  currency?: string;
  milestone: Task[];
  payments: Payment[];
}

/** What POST /projects and PUT /projects/{id} accept (payments go through their own call). */
export interface ProjectBody {
  id: string;
  owner: string;
  ownerId: string;
  ownerEmail: string;
  contractor: string;
  contractorId: string;
  contractorEmail: string;
  agreedPrice: number;
  currency: string;
  milestone: Task[];
}
export interface PaymentBody { id: string; amount: number; date: string; note?: string }

export type Step =
  | { kind: 'create'; body: ProjectBody }
  | { kind: 'update'; id: string; body: ProjectBody }
  | { kind: 'payment'; id: string; body: PaymentBody };

export interface Plan {
  steps: Step[];
  /** Differences the chain cannot repair (payments are append-only); a person has to look at them. */
  notes: string[];
}

const cents = (n: number): number => Math.round(Number(n) * 100);
const orNull = (v: string | null | undefined): string | null => (v === undefined || v === null || v === '' ? null : v);

export function sameTask(a: Task, b: Task): boolean {
  return a.description === b.description
    && orNull(a.startDate) === orNull(b.startDate)
    && orNull(a.finishDate) === orNull(b.finishDate)
    && (a.status ?? 'proposed') === (b.status ?? 'proposed');
}

/** Same owner and contractor (name, id, e-mail), price, currency and task list (payments are compared separately). */
export function sameProjectData(want: Project, have: Project): boolean {
  return want.owner === have.owner
    && want.ownerId === (have.ownerId ?? '')
    && want.ownerEmail === (have.ownerEmail ?? '')
    && want.contractor === have.contractor
    && want.contractorId === (have.contractorId ?? '')
    && want.contractorEmail === (have.contractorEmail ?? '')
    && cents(want.agreedPrice) === cents(have.agreedPrice)
    && (want.currency ?? 'SAR') === (have.currency ?? 'SAR')
    && want.milestone.length === (have.milestone ?? []).length
    && want.milestone.every((t, i) => sameTask(t, have.milestone[i]));
}

export function samePayment(a: Payment, b: Payment): boolean {
  return cents(a.amount) === cents(b.amount) && a.date === b.date && (a.note ?? '') === (b.note ?? '');
}

function projectBody(p: Project): ProjectBody {
  return {
    id: p.id,
    owner: p.owner,
    ownerId: p.ownerId,
    ownerEmail: p.ownerEmail,
    contractor: p.contractor,
    contractorId: p.contractorId,
    contractorEmail: p.contractorEmail,
    agreedPrice: p.agreedPrice,
    currency: p.currency ?? 'SAR',
    milestone: p.milestone.map((t) => ({
      description: t.description,
      ...(orNull(t.startDate) ? { startDate: t.startDate as string } : {}),
      ...(orNull(t.finishDate) ? { finishDate: t.finishDate as string } : {}),
      status: t.status ?? 'proposed',
    })),
  };
}

function paymentBody(p: Payment): PaymentBody {
  return { id: p.id, amount: p.amount, date: p.date, ...(p.note ? { note: p.note } : {}) };
}

export function plan(want: Project, have: Project | null): Plan {
  const steps: Step[] = [];
  const notes: string[] = [];

  if (have === null) {
    steps.push({ kind: 'create', body: projectBody(want) });
  } else if (!sameProjectData(want, have)) {
    steps.push({ kind: 'update', id: want.id, body: projectBody(want) });
  }

  const onChain = new Map((have?.payments ?? []).map((p) => [p.id, p]));
  for (const p of want.payments) {
    const existing = onChain.get(p.id);
    if (!existing) steps.push({ kind: 'payment', id: want.id, body: paymentBody(p) });
    else if (!samePayment(p, existing)) notes.push(`payment ${p.id} differs from the database (payments on the chain can never be edited)`);
  }
  const wanted = new Set(want.payments.map((p) => p.id));
  for (const id of onChain.keys()) {
    if (!wanted.has(id)) notes.push(`payment ${id} is on the chain but is no longer a paid payment in the database (payments on the chain can never be removed)`);
  }
  return { steps, notes };
}

export function describe(step: Step): string {
  return step.kind === 'create' ? 'project created' : step.kind === 'update' ? 'project updated' : `payment ${step.body.id} added`;
}
