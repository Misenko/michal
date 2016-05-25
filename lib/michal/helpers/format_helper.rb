# Data formating helper class
#
class Michal::Helpers::FormatHelper
  class << self
    # Recursively converts strings in hash representing number into Fixnums
    #
    # @param [Hash] element
    # @return [Hash] element with Fixnum types
    def convert_numbers!(element)
      if element.is_a? Hash
        element.each_pair do |key, value|
          element[key] = convert_numbers!(value)
        end
      elsif element.is_a? Array
        element.map! { |x| convert_numbers!(x) }
      elsif element.is_a? String
        number(element)
      else
        element
      end
    end

    private
    def number(element)
      Integer(element)
    rescue ArgumentError
      float(element)
    end

    def float(element)
      Float(element)
    rescue ArgumentError
      element
    end
  end
end
