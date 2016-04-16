# Parse-Cron
## Parse crontab syntax to determine scheduled run times [![Build Status](https://travis-ci.org/siebertm/parse-cron.png)](https://travis-ci.org/siebertm/parse-cron)

The goal of this gem is to parse a crontab timing specification and determine when the
job should be run. It is not a scheduler, it does not run the jobs.

## API example

```
cron_parser = CronParser.new('30 * * * *')

# Next occurrence
next_time = cron_parser.next(Time.now)

# Last occurrence
most_recent_time = cron_parser.last(Time.now)

# next 5 occurences
next_times = cron_parser.next(Time.now,5)

# last 5 occurences
previous_times = cron_parser.last(Time.now,5)
```

## Strict Matching AKA Friday the 13th matching

From the crontab manpage:
```
If both fields are restricted (i.e., aren't '*'), the command will be run when either field matches the current time. For example, ``30 4 1,15 * 5'' would cause a command to be run at 4:30 am on the 1st and 15th of each month, plus every Friday.
```

While this is the designed behavior, Some might not find it to be desireable or expected. If you want to match based on Day of Week AND Day of month, you can turn on strict matching with a parameter when you initialize.

Let's take a look at the difference between the two modes. 

```
# Normal behavior
CronParser.new('0 1 13 * 5', Time).next(Time.now, 4)
=> [Fri 25 Mar 2016, Fri 01 Apr 2016, Fri 08 Apr 2016, Wed 13 Apr 2016]

# Strict Matching
CronParser.new('0 1 13 * 5', Time,true).next(Time.now, 4)
=> [Fri 13 May 2016, Fri 13 Jan 2017, Fri 13 Oct 2017, Fri, 13 Apr 2018]

```