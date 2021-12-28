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

    # Invokes block if hunk is valid
    #
    # @param hunk [Hash]
    #
    # @yieldparam lines [Integer]
    # @yieldparam orig_path [Pathname]
    # @yieldparam oid [String]
    # @yieldparam name [String]
    # @yieldparam email [String]
    #
    # @return [void]
    def call(hunk, &block)
      case [hunk, attributes]
      in [{ orig_path: path, final_signature: { time: created_at } }, { after: }] unless created_at > after
        say("File %s ignored due to [created > after] (%p > %p)", path, created_at, after)
      in [{ orig_path: path, final_signature: { time: created_at } }, { before: }] unless created_at < before
        say("File %s ignored due to [created < before] (%p < %p)", path, created_at, before)
      in [{ orig_path: path}, { exclude: excluded }] if excluded.any? { File.fnmatch?(_1, path, OPT) }
        say("File %s excluded by [exclude] (%p)", path, excluded)
      in [{ orig_path: path }, { include: included }] unless included.any? { File.fnmatch?(_1, path, OPT) }
        say("File %s excluded by [include] (%p)", path, included)
      in [{ orig_path: path }, { extensions: }] unless extensions.any? { File.extname(path) == _1 }
        say("File %s excluded by [extensions] (%p)", path, extensions)
      in [{final_signature: { name:, email:}, final_commit_id: oid, lines_in_hunk: lines, orig_path: path}, Hash]
        block[lines, path, oid, name, email]
      end
    end
  end
end
