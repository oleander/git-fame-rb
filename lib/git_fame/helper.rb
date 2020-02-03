module GitFame
  module Helper
    #
    # @value Fixnum Value to be formatted
    # @return String Formatted according ActionView::Helpers::NumberHelper.number_with_delimiter
    #
    def number_with_delimiter(value)
      value.to_s.gsub(/(\d)(?=(\d\d\d)+(?!\d))/, "\\1,")
    end
  end
end