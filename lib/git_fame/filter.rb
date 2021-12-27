# frozen_string_literal: true

module GitFame
  class Filter < Base
    OPT = File::FNM_EXTGLOB | File::FNM_DOTMATCH | File::FNM_CASEFOLD | File::FNM_PATHNAME

    attribute? :before, Types::JSON::DateTime
    attribute? :after, Types::JSON::DateTime
    attribute? :extensions, Types::Set
    attribute? :include, Types::Set
    attribute? :exclude, Types::Set

    schema schema.strict(false)

    def call(changes, &block)
      case [changes, attributes]
      in [{ file_path:, final_signature: { time: created_at } }, { after: }] unless created_at > after
        say("File %s ignored due to [created > after] (%p > %p)", file_path, created_at, after)
      in [{ file_path:, final_signature: { time: created_at } }, { before: }] unless created_at < before
        say("File %s ignored due to [created < before] (%p < %p)", file_path, created_at, before)
      in [{ file_path: }, { exclude: excluded }] if excluded.any? { file_path.fnmatch?(_1, OPT) }
        say("File %s excluded by [exclude] (%p)", file_path, excluded)
      in [{ file_path: }, { include: included }] unless included.any? { file_path.fnmatch?(_1, OPT) }
        say("File %s excluded by [include] (%p)", file_path, included)
      in [{ file_path: }, { extensions: }] unless extensions.include?(file_path.extname)
        say("File %s excluded by [extensions] (%p)", file_path, extensions)
      in [{final_signature: { name:, email:}, final_commit_id: oid, lines_in_hunk: lines, file_path:}, Hash]
        block[lines, file_path, oid, name, email]
      end
    end
  end
end
