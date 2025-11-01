# omnifocus-ical-sync
Sync future dated task from OmniFocus to iCal

---

### Key Points

- Create macOS Calendar events from OmniFocus tasks that are due today/soon
- Designed for a single Calendar called 'OmniFocus'
- Only Tasks that are tagged 'CalSync' are synced 
- Flagged tasks will have its calendar event have an alert occur on the task's due date
- A notification is displayed when the script starts and when the script ends, including info about runtime and events created
- Using the .plist, a launchd user agent can be created to run the script in the background on an interval

---

### Usage

This script can be run from the command line with two optional parameters:
1. The number of days to look ahead (default is 1)
2. The number of days to look back (default is 1)
Example: `osascript omnifocus-ical-sync.scpt 15 5`

---

### Overview

This is design as a simple script to allow you to sync you tasks into a custom calendar for OmniFocus. The tasks need to be tagged to sync, non-tagged tasks won't be moved. Calendar entries are created with a Project : Task title. If there is no Project then the default is "INBOX'. Notes and URL also sync. The default time is 30 minutes, if a task does not have a duration in OmniFocus. 

Task details that are synced to the calendar:

 - the task's project and name is made the calendar event's title
 - the note of the calendar event will include at the top "Project:" and the task's project name (if there is one) and then task's note below that
 - the task's duration is applied to the event, so a task with a due date of 4pm with its duration of 2 hours would make a calendar event from 2pm to 4pm, and if the task doesn't have a duration, the calendar event is made for 30 minutes
 - for calendar alerts, any task that would be added to the calendar and is also flagged will have a calendar alert at the time of the task's due date/time
 - the URL of the calendar event includes the OmniFocus task's URL so that you can click into the task from the calendar

This was inspired by https://github.com/willjasen/omnifocus-tasks-to-calendar so a big shout out to willjasen

---

### Logic

The handler structure for processOmniFocusTasks is:

- Parse the parameters
- Filter the tasks
- Iterate over the tasks and 
    - Extract the data from each task (name, date, duration, etc)
    - Create the calendar entry
- Alert when it's complete