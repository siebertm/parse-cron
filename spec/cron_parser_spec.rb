require "time"
require "./spec/spec_helper"
require "cron_parser"

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
    ["* * * * *",       "2011-08-15T12:00",  "2011-08-15T12:01"],
    ["* * * * *",       "2011-08-15T02:25",  "2011-08-15T02:26"],
    ["* * * * *",       "2011-08-15T02:59",  "2011-08-15T03:00"],
    ["*/15 * * * *",    "2011-08-15T02:02",  "2011-08-15T02:15"],
    ["*/15,25 * * * *", "2011-08-15T02:15",  "2011-08-15T02:25"],
    ["30 3,6,9 * * *",  "2011-08-15T02:15",  "2011-08-15T03:30"],
    ["30 9 * * *",      "2011-08-15T10:15",  "2011-08-16T09:30"],
    ["30 9 * * *",      "2011-08-31T10:15",  "2011-09-01T09:30"],
    ["30 9 * * *",      "2011-09-30T10:15",  "2011-10-01T09:30"],
    ["0 9 * * *",       "2011-12-31T10:15",  "2012-01-01T09:00"],
    ["* * 12 * *",      "2010-04-15T10:15",  "2010-05-12T00:00"],
    ["* * * * 1,3",     "2010-04-15T10:15",  "2010-04-19T00:00"],
    ["0 0 1 1 *",       "2010-04-15T10:15",  "2011-01-01T00:00"],
  ].each do |line, now, expected_next|
    it "should return #{expected_next} for '#{line}' when now is #{now}" do
      now = Time.xmlschema(now + ":00+00:00")
      expected_next = Time.xmlschema(expected_next + ":00+00:00")

      parser = CronParser.new(line)

      parser.next(now).xmlschema.should == expected_next.xmlschema
    end
  end
end
