# Extracted from the dolt gem. Currently not maintained.
# Source: https://docs.omniref.com/ruby/gems/libdolt/0.33.14/symbols/Dolt::Git::Blame::PorcelainParser
module GitFame
  class BlameParser
    def initialize(output)
      @output = output
      @commits = {}
    end
    def parse
      lines = @output.split("\n")
      chunks = []
      while lines.length > 0
        chunk = extract_header(lines)
        affected_lines = extract_lines(lines, chunk[:num_lines])
        if chunks.last && chunk[:oid] == chunks.last[:oid]
          chunks.last[:lines].concat(affected_lines)
        else
          chunk[:lines] = affected_lines
          chunks << chunk
        end
      end
      chunks
    rescue Exception => error
      raise Error, "Failed parsing Porcelain: #{error.message}"
    end

    def is_header?(line)
      line =~ /^[0-9a-f]{40} \d+ \d+ \d+$/
    end

    def extract_header(lines)
      header = lines.shift
      pieces = header.scan(/^([0-9a-f]{40}) (\d+) (\d+) (\d+)$/).first
      header = { :oid => pieces.first, :num_lines => pieces[3].to_i }
      if lines.first =~ /^author/
        header[:author] = extract_hash(lines, :author)
        header[:committer] = extract_hash(lines, :committer)
        header[:summary] = extract(lines, "summary")
        header[:boundary] = extract(lines, "boundary")
        throwaway = lines.shift until throwaway =~ /^filename/
        @commits[header[:oid]] = header
      else
        header[:author] = @commits[header[:oid]][:author]
        header[:committer] = @commits[header[:oid]][:committer]
        header[:summary] = @commits[header[:oid]][:summary]
      end
      header
    end

    def extract_lines(lines, num)
      extracted = []
      num.times do
        if extracted.length > 0
          line = lines.shift # Header for next line
        end
        content = lines.shift # Actual content
        next unless content
        extracted.push(content[1..content.length]) # 8 spaces padding
      end
      extracted
    end

    def extract_hash(lines, type)
      {
        :name => extract(lines, "#{type}"),
        :mail => extract(lines, "#{type}-mail").gsub(/[<>]/, ""),
        :time => (Time.at(extract(lines, "#{type}-time").to_i).utc +
        Time.zone_offset(extract(lines, "#{type}-tz")))
      }
    end
    def extract(lines, thing)
      if thing == "boundary"
        if (line = lines.shift) == thing
          return true
        else
          return ! lines.unshift(line)
        end
      end

      lines.shift.split("#{thing} ")[1]
    end
  end
end