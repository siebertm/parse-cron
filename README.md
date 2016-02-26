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
```

