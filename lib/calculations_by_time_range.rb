require 'calculations_by_time_range/active_record/calculations'
module ActiveRecord
  class Base
    class << self; include CalculationsByTimeRange::ActiveRecord::Calculations end
  end
end
