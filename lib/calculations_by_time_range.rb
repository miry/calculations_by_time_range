module JetThoughts
  module CalculationsByTimeRange

    @@time_zone_offset_in_hours = Time.zone.utc_offset / 3600
    QUERY = (ActiveRecord::Base.connection.adapter_name == "PostgreSQL") ? "EXTRACT(%s FROM %s + INTERVAL '%d hour')" : "EXTRACT(%s FROM %s + INTERVAL %d hour)"

    COLUMNS = {
      :year => [:year],
      :month => [:year, :month],
      :week => [:year, :month, :week],
      :day => [:year, :month, :week, :day],
      :hour => [:year, :month, :week, :day, :hour]
    }

    OPERATIONS = ["sum", "count", "min", "max", "avg"]

    COLUMNS.each do |k,v|
      OPERATIONS.each do |o|
        define_method "#{o.pluralize}_by_#{k.to_s}" do |*args|
          column, time_column = args
          calculations_by_time_column(o.to_sym, v, :column => column || 'id', :time_column => time_column || 'created_at')
        end

        define_method "#{o.pluralize}_by" do |*args|
          range, column, time_column = args
          calculations_by_time_column(o.to_sym, COLUMNS[range.to_sym], :column => column || "id", :time_column => time_column || "created_at")
        end
      end
    end

    private

    def calculations_by_time_column(operation, fields = [], opts = {})
      options = {:time_column => 'created_at', :column => 'id'}
      options = options.merge(opts)

      fields = [fields] if !fields.is_a?(Array)
      select_q, order_by_q, group_by_q = [], [], []

      fields.each_with_index do|range, indx|
        q = QUERY % [range, options[:time_column], @@time_zone_offset_in_hours]
        select_q << ((q + " AS %s_%s") % [range.to_s, options[:time_column]])
        group_by_q << q
        order_by_q << 2 + indx
      end

      sql = "SELECT %s(%s) AS %s_all, %s FROM %s " % [operation, options[:column], operation, select_q.join(','), table_name]

      add_conditions!(sql, options[:conditions])
      sql << "GROUP BY #{group_by_q.join(',')}
                                                                                                                                      ORDER BY #{order_by_q.join(',')}"
                                                                                                                                      find_by_sql(sql)
    end

  end
end

