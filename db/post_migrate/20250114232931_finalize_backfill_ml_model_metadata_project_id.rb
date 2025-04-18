# frozen_string_literal: true

class FinalizeBackfillMlModelMetadataProjectId < Gitlab::Database::Migration[2.2]
  milestone '17.8'

  disable_ddl_transaction!

  restrict_gitlab_migration gitlab_schema: :gitlab_main_cell

  def up
    ensure_batched_background_migration_is_finished(
      job_class_name: 'BackfillMlModelMetadataProjectId',
      table_name: :ml_model_metadata,
      column_name: :id,
      job_arguments: [:project_id, :ml_models, :project_id, :model_id],
      finalize: true
    )
  end

  def down; end
end
