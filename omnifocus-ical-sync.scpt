-- ** OVERVIEW ** --
-- This code creates macOS Calendar events from OmniFocus tasks that are due today or in the future
-- All events on the specified calendars are deleted and re-created each run to keep the calendar in sync
-- It requires you to have an iCal called 'OmniFocus'
-- Any tasks you want to sync to your calendar need to have a 'CalSync' tag applied

-- ** HISTORY ** --

-- ** USAGE ** --
-- This script can be run from the command line with two optional parameters:
-- 1. The number of days to look ahead (default is 1)
-- 2. The number of days to look back (default is 1)
-- Example: `osascript omnifocus-ical-sync.scpt 15 5`


-- ******** --
--  SCRIPT  --
-- ******** --

property default_event_duration : 30  --in minutes

on run argv

	-- Set daysAhead to 1 if not passed in
	-- Set daysBack to 1 if not passed in
	if (count of argv) > 0 then
		set daysAhead to item 1 of argv as integer
		set daysBack to item 2 of argv as integer
	else
		set daysAhead to 1
		set daysBack to 1
	end if

	-- Create global variables
	set calendar_element to missing value  --initialize to null

	-- for the days to pull tasks from, set the start date to today's date at the prior midnight
	set theStartDate to current date - (days * daysBack)
	set hours of theStartDate to 0
	set minutes of theStartDate to 0
	set seconds of theStartDate to 0

	-- for the days to pull tasks from, set the end date to today's date plus how many days to look forward
	set theEndDate to current date + (days * (daysAhead - 1))
	set hours of theEndDate to 23
	set minutes of theEndDate to 59
	set seconds of theEndDate to 59

	-- Start a stopwatch
	set stopwatchStart to current date

	-- Let the user know that the script has started
	display notification "OmniFocus is now syncing to Calendar" with title "Syncing..."

	-- Restart the Calendar app minimized
	tell application "Calendar" to quit
	delay 3
	tell application "Calendar"
		run  -- this starts the Calendar app but doesn't load its window
	end tell

	-- ********************************* --
	-- CALL THE HANDLERS WITH PARAMETERS --
	-- ********************************* --

	-- Delete all events from the affected calendars
	deleteCalendarEvents("OmniFocus")

	-- Set tags to Sync
	set tagsToSync to {"CalSync"}

	-- Sync all of the calendars
	set tasksAdded to processOmniFocusTasks(tagsToSync,"include","OmniFocus")

	-- Stop the stopwatch
	set stopwatchStop to current date
	
	-- Subtract the two dates
	set runtimeSeconds to (stopwatchStop - stopwatchStart)
	
	-- Let the user know that the script has finished
	display notification "OmniFocus is finished syncing to Calendar, took " & runtimeSeconds & " seconds. Added " & tasksAdded & " events. " with title "Syncing Complete!"

end run

--
-- HANDLER :: DELETE ALL CALENDAR EVENTS ON A GIVEN CALENDAR --
--
on deleteCalendarEvents(calendar_name)

	global calendar_element
  
	tell application "Calendar"

		set calendar_element to calendar calendar_name
		delete (every event of calendar_element)

	end tell

end deleteCalendarEvents

--
-- HANDLER :: PROCESS OMNIFOCUS TASKS BASED ON TAGS TO INCLUDE/EXCLUDE --
--
on processOmniFocusTasks(tags_considered,include_or_exclude,calendar_name)

	log("Processing tags to " & include_or_exclude & ": " & tags_considered)

	set tasksAdded to 0

	global theStartDate, theEndDate, calendar_element
	
	tell application "OmniFocus"
		tell default document
			
			-- Set task exclusion criteria
			set task_elements to flattened tasks whose ¬
				(completed is false) and ¬
				(due date ≠ missing value) and ¬
				(due date is greater than or equal to theStartDate) and ¬
				(due date is less than or equal to theEndDate)

			repeat with item_ref in task_elements
				
				-- GET OMNIFOCUS TASKS
				set the_task to contents of item_ref
				set task_tags to tags of the_task
				set task_should_sync to false

				-- Check if the task should be made into a calendar event
				repeat with aTag in task_tags
					if name of aTag is in tags_considered then
						set task_should_sync to true
						exit repeat
					end if
				end repeat

				-- If the task should be synced, then add it to the calendar
				if task_should_sync then

					-- Set the task project, default is INBOX
					-- Trying to get the name of a missing object will throw an exception here so on error we'll default
					try
						set task_project to name of (get assigned container of the_task)
					on error
						set task_project to "INBOX"
					end try			
					
					-- Set the task name
					set task_name to name of the_task

					-- Set the task date 
					set task_due to due date of the_task
					
					-- Set the task notes field, default is "No Notes"
					set task_note to note of the_task
					if task_note is missing value or task_note is "" then
						set full_task_note to "Project: " & task_project & return & "----------------------------------------" & return & "No Notes"
					else
						set full_task_note to "Project: " & task_project & return & "----------------------------------------" & return & task_note
					end if

					-- Set the task duration, or default to 30 minutes
					set task_estimate to estimated minutes of the_task
					if task_estimate is missing value then
						set task_estimate to default_event_duration
					end if

					-- Set the task URL
					set task_url to "omnifocus:///task/" & id of the_task

					-- Set if the task is flagged, this will set an alarm on the calendar entry
					set is_flagged to flagged of the_task
					
					-- BUILD CALENDAR ENTRY

					-- Set the start and end date. start date is the end date - the duration
					set end_date to task_due
					set start_date to end_date - (task_estimate * minutes)

					-- Set the calendar entry name to be Project:Task name 
					set calendar_entry_name to task_project & " : " & task_name

					-- CREATE CALENDAR EVENT
					tell application "Calendar"
						set calendar_element to calendar calendar_name
						tell calendar_element							
							set newEvent to make new event with properties {summary:calendar_entry_name, description:full_task_note, start date:start_date, end date:end_date, url:task_url} at calendar_element
							-- Set counter
							set tasksAdded to tasksAdded + 1
						end tell
						if is_flagged then
							tell newEvent
								-- Set the alert to trigger at the due date (end_date)
								make new display alarm at end with properties {trigger interval:task_estimate}
							end tell
						end if
					end tell

				end if				

			end repeat

		end tell
	end tell

	return tasksAdded

end processOmniFocusTasks

