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
    # @param hunk [Hash] a blame hunk with the file's current path as :path
    #
    # @yieldparam lines [Integer]
    # @yieldparam path [String]
    # @yieldparam oid [String]
    # @yieldparam name [String]
    # @yieldparam email [String]
    #
    # @return [void]
    def call(hunk, &block)
      case [hunk, attributes]
      in [{ path:, final_signature: { time: created_at } }, { after: }] unless created_at > after
        say("File %s ignored due to [created > after] (%p > %p)", path, created_at, after)
      in [{ path:, final_signature: { time: created_at } }, { before: }] unless created_at < before
        say("File %s ignored due to [created < before] (%p < %p)", path, created_at, before)
      in [{ path: }, Hash] unless path?(path)
        nil
      in [{ final_signature: { name:, email: }, final_commit_id: oid, lines_in_hunk: lines, path: }, Hash]
        block[lines, path, oid, name, email]
      else
        say("Hunk ignored, author or path is missing (%p)", hunk)
      end
    end

    # Whether the file passes the [exclude], [include] and [extensions] rules
    #
    # @param path [String]
    #
    # @return [Boolean]
    def path?(path)
      case attributes
      in { exclude: excluded } if excluded.any? { File.fnmatch?(_1, path, OPT) }
        say("File %s excluded by [exclude] (%p)", path, excluded)
      in { include: included } unless included.any? { File.fnmatch?(_1, path, OPT) }
        say("File %s excluded by [include] (%p)", path, included)
      in { extensions: } unless extensions.any? { File.extname(path) == _1 }
        say("File %s excluded by [extensions] (%p)", path, extensions)
      else
        return true
      end

      false
    end
  end
end
