import { readFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

const __dirname = dirname(fileURLToPath(import.meta.url));

export const headOfSalesSystemPrompt = readFileSync(
  join(__dirname, 'prompts/head-of-sales.md'),
  'utf-8',
);

export const crmSyncSystemPrompt = readFileSync(
  join(__dirname, 'prompts/crm-sync.md'),
  'utf-8',
);
