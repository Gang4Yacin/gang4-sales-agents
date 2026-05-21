export type SyncSource = 'gmail' | 'gcal' | 'drive_doc' | 'fireflies';

export type ActionType =
  | 'create_note'
  | 'update_stage'
  | 'create_task'
  | 'update_next_step'
  | 'create_person'
  | 'create_deal'
  | 'link_person_to_deal'
  | 'update_company_status';

export type AttioObjectType = 'people' | 'companies' | 'deals';

export type ProcessedStatus = 'processed' | 'skipped' | 'error' | 'proposed_dry_run';

export interface DryRunProposal {
  action_type: ActionType;
  target_object_type: AttioObjectType | null;
  target_record_id: string | null;
  payload: Record<string, unknown>;
  reasoning: string;
  source_refs: Record<string, unknown>;
}

export interface AgentTodo {
  kind: string;
  summary: string;
  attio_object_type?: AttioObjectType;
  attio_record_id?: string;
  suggested_action?: Record<string, unknown>;
}
