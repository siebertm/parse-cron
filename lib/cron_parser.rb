#
# Parses cron expressions and computes the next occurence of the "job"
#
class CronParser
  # internal "mutable" time representation
  class InternalTime
    attr_accessor :year, :month, :day, :hour, :min

    def initialize(time)
      @year = time.year
      @month = time.month
      @day = time.day
      @hour = time.hour
      @min = time.min
    end

    def to_time
      Time.utc(@year, @month, @day, @hour, @min, 0)
    end
    alias :inspect :to_time
  end

  SYMBOLS = {
     "jan" => "0",
     "feb" => "1",
     "mar" => "2",
     "apr" => "3",
     "may" => "4",
     "jun" => "5",
     "jul" => "6",
     "aug" => "7",
     "sep" => "8",
     "oct" => "9",
     "nov" => "10",
     "dec" => "11",

     "sun" => "0",
     "mon" => "1",
     "tue" => "2",
     "wed" => "3",
     "thu" => "4",
     "fri" => "5",
     "sat" => "6"
  }

  def initialize(source)
    @source = source
  end


  # returns the next occurence after the given date
  def next(now = Time.now)
    t = InternalTime.new(now)

    unless time_specs[:month].include?(t.month)
      nudge_month(t)
      t.day = 0
    end

    unless t.day == 0 || interpolate_weekdays(t.year, t.month).include?(t.day)
      nudge_date(t)
      t.hour = -1
    end

    unless time_specs[:hour].include?(t.hour)
      nudge_hour(t)
      t.min = -1
    end

    # always nudge the minute
    nudge_minute(t)
    t.to_time
  end

  SUBELEMENT_REGEX = %r{^(\d+)(-(\d+)(/(\d+))?)?$}
  def parse_element(elem, allowed_range)
    elem.split(',').map do |subel|
      if subel =~ /^\*/
        step = subel.length > 1 ? subel[2..-1].to_i : 1
        stepped_range(allowed_range, step)
      else
        if SUBELEMENT_REGEX === subel
          if $5 # with range
            stepped_range($1.to_i..($3.to_i + 1), $5.to_i)
          elsif $3 # range without step
            stepped_range($1.to_i..($3.to_i + 1), 1)
          else # just a numeric
            [$1.to_i]
          end
        else
          raise "Bad Vixie-style specification #{subel}"
        end
      end
    end.flatten.sort
  end


  protected

  # returns a list of days which do both match time_spec[:dom] and time_spec[:dow]
  def interpolate_weekdays(year, month)
    t = Date.new(year, month, 1)
    valid_mday = time_specs[:dom]
    valid_wday = time_specs[:dow]

    result = []
    while t.month == month
      result << t.mday if valid_mday.include?(t.mday) && valid_wday.include?(t.wday)
      t = t.succ
    end

    result
  end

  def nudge_year(t)
    t.year = t.year + 1
  end

  def nudge_month(t)
    spec = time_specs[:month]
    next_value = find_best_next(t.month, spec)
    t.month = next_value || spec.first
    next_value.nil? ?  nudge_year(t) : t
  end

  def nudge_date(t)
    spec = interpolate_weekdays(t.year, t.month)
    next_value = find_best_next(t.day, spec)
    t.day = next_value || spec.first
    next_value.nil? ?  nudge_month(t) : t
  end

  def nudge_hour(t)
    spec = time_specs[:hour]
    next_value = find_best_next(t.hour, spec)
    t.hour = next_value || spec.first
    next_value.nil? ?  nudge_date(t) : t
  end

  def nudge_minute(t)
    spec = time_specs[:minute]
    next_value = find_best_next(t.min, spec)
    t.min = next_value || spec.first
    next_value.nil? ?  nudge_hour(t) : t
  end

  def time_specs
    @time_specs ||= begin
      # tokens now contains the 5 fields
      tokens = substitute_parse_symbols(@source).split(/\s+/)
      {
        :minute => parse_element(tokens[0], 0..59), #minute
        :hour   => parse_element(tokens[1], 0..23), #hour
        :dom    => parse_element(tokens[2], 1..31), #DOM
        :month  => parse_element(tokens[3], 1..12), #mon
        :dow    => parse_element(tokens[4], 0..6)  #DOW
      }
    end
  end

  def substitute_parse_symbols(str)
    SYMBOLS.inject(str) do |s, (symbol, replacement)|
      s.gsub(symbol, replacement)
    end
  end


  def stepped_range(rng, step = 1)
    len = rng.last - rng.first

    num = len.div(step)
    result = (0..num).map { |i| rng.first + step * i }

    result.pop if result[-1] == rng.last and rng.exclude_end?
    result
  end


  # returns the smallest element from allowed which is greater than current
  # returns nil if no matching value was found
  def find_best_next(current, allowed)
    allowed.sort.find { |val| val > current }
  end
end
