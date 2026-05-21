import 'dotenv/config';
import { parseArgs } from 'node:util';
import { query } from '@anthropic-ai/claude-agent-sdk';
import { crmSyncSystemPrompt, headOfSalesSystemPrompt } from '../src/agents/index.ts';
import { endRun, startRun } from '../src/lib/supabase.ts';

const { values } = parseArgs({
  options: {
    'backfill-days': { type: 'string', default: '90' },
    'window-start': { type: 'string' },
    'window-end': { type: 'string' },
  },
});

const backfillDays = Number(values['backfill-days']);
const windowEnd = values['window-end'] ?? new Date().toISOString();
const windowStart =
  values['window-start'] ??
  new Date(Date.now() - backfillDays * 24 * 60 * 60 * 1000).toISOString();

async function main() {
  console.log(`[crm-sync] window: ${windowStart} → ${windowEnd}`);

  const runId = await startRun('crm-sync', { backfillDays, windowStart, windowEnd });
  console.log(`[crm-sync] run_id=${runId}`);

  const userPrompt = [
    `Lance un run de \`crm-sync\` en mode dry-run.`,
    ``,
    `Paramètres du run :`,
    `- run_id Supabase: ${runId}`,
    `- window_start: ${windowStart}`,
    `- window_end: ${windowEnd}`,
    `- backfill_days: ${backfillDays}`,
    ``,
    `Ingère tous les emails (Gmail samuel@gang4.io), meetings (Google Calendar des 3 comptes via partage),`,
    `transcripts (Google Drive dossiers "Meet Recordings", fallback Fireflies) sur la fenêtre.`,
    `Pour chaque item, résous l'entité Attio cible, propose les modifs nécessaires, et persiste-les dans`,
    `Supabase (schéma \`sales\`). N'écris RIEN dans Attio.`,
    ``,
    `À la fin, retourne un rapport markdown structuré : synthèse, propositions par deal, todos à arbitrer.`,
  ].join('\n');

  const summary: Record<string, unknown> = {};
  let errorMsg: string | undefined;

  try {
    const response = query({
      prompt: userPrompt,
      options: {
        systemPrompt: headOfSalesSystemPrompt,
        agents: {
          'crm-sync': {
            description: 'Ingest emails/meetings/transcripts and propose Attio updates (dry-run).',
            prompt: crmSyncSystemPrompt,
          },
        },
      },
    });

    for await (const message of response) {
      if (message.type === 'assistant') {
        for (const block of message.message.content) {
          if (block.type === 'text') {
            process.stdout.write(block.text);
          }
        }
      } else if (message.type === 'result') {
        summary.total_cost_usd = message.total_cost_usd;
        summary.num_turns = message.num_turns;
        summary.duration_ms = message.duration_ms;
      }
    }
  } catch (err) {
    errorMsg = err instanceof Error ? err.message : String(err);
    console.error('\n[crm-sync] ERROR:', errorMsg);
  }

  await endRun(runId, summary, errorMsg);
  console.log(`\n[crm-sync] done. summary=${JSON.stringify(summary)}`);
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
