module GitFlame
  module Helper
    #
    # @value Fixnum Value to be formated
    # @return String Formated according ActionView::Helpers::NumberHelper.number_with_delimiter
    #
    def number_with_delimiter(value)
      value.to_s.gsub(/(\d)(?=(\d\d\d)+(?!\d))/, "\\1,")
    end
  end
end