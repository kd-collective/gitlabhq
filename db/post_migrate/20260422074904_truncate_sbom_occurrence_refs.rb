# frozen_string_literal: true

class TruncateSbomOccurrenceRefs < Gitlab::Database::Migration[2.3]
  milestone '19.0'

  # no-op: truncation moved to db/migrate/20260506101701_truncate_sbom_occurrence_refs_v2.rb
  # so that it runs before the unique index migration
  # db/migrate/20260506101702_add_unique_index_on_sbom_occurrence_refs.rb
  # in regular  migrations, ensuring the index is reliably present
  # for application code on self-managed instances where post-deploy migrations may be deferred.
  def up; end

  def down; end
end
