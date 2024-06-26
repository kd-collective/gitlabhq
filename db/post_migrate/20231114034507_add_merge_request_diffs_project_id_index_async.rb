# frozen_string_literal: true

class AddMergeRequestDiffsProjectIdIndexAsync < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  milestone '16.7'

  INDEX_NAME = 'index_merge_request_diffs_on_project_id'

  # rubocop:disable Migration/PreventIndexCreation -- Legacy migration
  def up
    prepare_async_index :merge_request_diffs, :project_id, name: INDEX_NAME
  end
  # rubocop:enable Migration/PreventIndexCreation

  def down
    unprepare_async_index :merge_request_diffs, :project_id, name: INDEX_NAME
  end
end
