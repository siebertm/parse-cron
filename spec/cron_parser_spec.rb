require "time"
require "./spec/spec_helper"
require "cron_parser"
require "time"

def parse_date(str)
  dt = DateTime.strptime(str, "%Y-%m-%d %H:%M")
  Time.local(dt.year, dt.month, dt.day, dt.hour, dt.min, 0)
end

describe "CronParser#parse_element" do
  [
    ["*", 0..60, (0..60).to_a],
    ["*/10", 0..60, [0, 10, 20, 30, 40, 50]],
    ["10", 0..60, [10]],
    ["10,30", 0..60, [10, 30]],
    ["10-15", 0..60, [10, 11, 12, 13, 14, 15]],
    ["10-40/10", 0..60, [10, 20, 30, 40]],
  ].each do |element, range, expected|
    it "should return #{expected} for '#{element}' when range is #{range}" do
      parser = CronParser.new('')
      parser.parse_element(element, range) == expected
    end
  end
end

describe "CronParser#next" do
  [
    ["* * * * *",       "2011-08-15 12:00",  "2011-08-15 12:01"],
    ["* * * * *",       "2011-08-15 02:25",  "2011-08-15 02:26"],
    ["* * * * *",       "2011-08-15 02:59",  "2011-08-15 03:00"],
    ["*/15 * * * *",    "2011-08-15 02:02",  "2011-08-15 02:15"],
    ["*/15,25 * * * *", "2011-08-15 02:15",  "2011-08-15 02:25"],
    ["30 3,6,9 * * *",  "2011-08-15 02:15",  "2011-08-15 03:30"],
    ["30 9 * * *",      "2011-08-15 10:15",  "2011-08-16 09:30"],
    ["30 9 * * *",      "2011-08-31 10:15",  "2011-09-01 09:30"],
    ["30 9 * * *",      "2011-09-30 10:15",  "2011-10-01 09:30"],
    ["0 9 * * *",       "2011-12-31 10:15",  "2012-01-01 09:00"],
    ["* * 12 * *",      "2010-04-15 10:15",  "2010-05-12 00:00"],
    ["* * * * 1,3",     "2010-04-15 10:15",  "2010-04-19 00:00"],
    ["0 0 1 1 *",       "2010-04-15 10:15",  "2011-01-01 00:00"],
    ["0 0 * * 1",       "2011-08-01 00:00",  "2011-08-08 00:00"],
    ["0 0 * * 1",       "2011-07-25 00:00",  "2011-08-01 00:00"],
    ["45 23 7 3 *",     "2011-01-01 00:00",  "2011-03-07 23:45"],
  ].each do |line, now, expected_next|
    it "should return #{expected_next} for '#{line}' when now is #{now}" do
      now = parse_date(now)
      expected_next = parse_date(expected_next)

      parser = CronParser.new(line)

      parser.next(now).xmlschema.should == expected_next.xmlschema
    end
  end
end

describe "CronParser#last" do
  [
    ["* * * * *",       "2011-08-15 12:00",  "2011-08-15 11:59"],
    ["* * * * *",       "2011-08-15 02:25",  "2011-08-15 02:24"],
    ["* * * * *",       "2011-08-15 03:00",  "2011-08-15 02:59"],
    ["*/15 * * * *",    "2011-08-15 02:02",  "2011-08-15 02:00"],
    ["*/15,45 * * * *", "2011-08-15 02:55",  "2011-08-15 02:45"],
    ["*/15,25 * * * *", "2011-08-15 02:35",  "2011-08-15 02:30"],
    ["30 3,6,9 * * *",  "2011-08-15 02:15",  "2011-08-14 09:30"],
    ["30 9 * * *",      "2011-08-15 10:15",  "2011-08-15 09:30"],
    ["30 9 * * *",      "2011-09-01 08:15",  "2011-08-31 09:30"],
    ["30 9 * * *",      "2011-10-01 08:15",  "2011-09-30 09:30"],
    ["0 9 * * *",       "2012-01-01 00:15",  "2011-12-31 09:00"],
    ["* * 12 * *",      "2010-04-15 10:15",  "2010-04-12 23:59"],
    ["* * * * 1,3",     "2010-04-15 10:15",  "2010-04-14 23:59"],
    ["0 0 1 1 *",       "2010-04-15 10:15",  "2010-01-01 00:00"],
  ].each do |line, now, expected_next|
    it "should return #{expected_next} for '#{line}' when now is #{now}" do
      now = parse_date(now)
      expected_next = parse_date(expected_next)

      parser = CronParser.new(line)

      parser.last(now).should == expected_next
    end
  end
end

describe "time source" do
  it "should use an alternate specified time source" do
    ExtendedTime = Class.new(Time)
    ExtendedTime.should_receive(:local).once
    CronParser.new("* * * * *",ExtendedTime).next
  end
end
