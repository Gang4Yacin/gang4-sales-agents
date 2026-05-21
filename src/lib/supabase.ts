import { createClient, type SupabaseClient } from '@supabase/supabase-js';
import type { AgentTodo, DryRunProposal, ProcessedStatus, SyncSource } from '../types.ts';

const SCHEMA = 'sales';

let _client: SupabaseClient | null = null;

export function supabase(): SupabaseClient {
  if (_client) return _client;
  const url = process.env.SUPABASE_URL;
  const key = process.env.SUPABASE_SERVICE_ROLE_KEY;
  if (!url || !key) throw new Error('SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY are required');
  _client = createClient(url, key, { db: { schema: SCHEMA } });
  return _client;
}

export async function startRun(agent: string, params: Record<string, unknown>): Promise<string> {
  const { data, error } = await supabase()
    .from('run_log')
    .insert({ agent, params })
    .select('id')
    .single();
  if (error) throw error;
  return data.id as string;
}

export async function endRun(
  runId: string,
  summary: Record<string, unknown>,
  errorMessage?: string,
): Promise<void> {
  const { error } = await supabase()
    .from('run_log')
    .update({ ended_at: new Date().toISOString(), summary, error: errorMessage ?? null })
    .eq('id', runId);
  if (error) throw error;
}

export async function getCursor(
  source: SyncSource,
  account: string,
): Promise<{ last_processed_at: string | null; last_external_id: string | null } | null> {
  const { data, error } = await supabase()
    .from('sync_cursors')
    .select('last_processed_at, last_external_id')
    .eq('source', source)
    .eq('account', account)
    .maybeSingle();
  if (error) throw error;
  return data;
}

export async function setCursor(
  source: SyncSource,
  account: string,
  lastProcessedAt: string,
  lastExternalId: string | null,
): Promise<void> {
  const { error } = await supabase()
    .from('sync_cursors')
    .upsert({
      source,
      account,
      last_processed_at: lastProcessedAt,
      last_external_id: lastExternalId,
      updated_at: new Date().toISOString(),
    });
  if (error) throw error;
}

export async function isProcessed(source: SyncSource, externalId: string): Promise<boolean> {
  const { data, error } = await supabase()
    .from('processed_items')
    .select('external_id')
    .eq('source', source)
    .eq('external_id', externalId)
    .maybeSingle();
  if (error) throw error;
  return !!data;
}

export async function markProcessed(args: {
  source: SyncSource;
  external_id: string;
  status: ProcessedStatus;
  content_hash?: string;
  attio_object_type?: string;
  attio_record_id?: string;
  run_id: string;
  error?: string;
}): Promise<void> {
  const { error } = await supabase().from('processed_items').upsert({
    source: args.source,
    external_id: args.external_id,
    status: args.status,
    content_hash: args.content_hash ?? null,
    attio_object_type: args.attio_object_type ?? null,
    attio_record_id: args.attio_record_id ?? null,
    run_id: args.run_id,
    error: args.error ?? null,
    processed_at: new Date().toISOString(),
  });
  if (error) throw error;
}

export async function recordProposal(runId: string, p: DryRunProposal): Promise<void> {
  const { error } = await supabase()
    .from('dry_run_proposals')
    .insert({ run_id: runId, ...p });
  if (error) throw error;
}

export async function addTodo(runId: string, todo: AgentTodo): Promise<void> {
  const { error } = await supabase()
    .from('agent_todos')
    .insert({ run_id: runId, ...todo });
  if (error) throw error;
}
