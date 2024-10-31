# Sway

## Project Description
Sway is a mobile event management application that helps users discover, organize, and manage events effortlessly. Sway aims to provide a seamless and intuitive experience for both event attendees and promoters.

## Screenshots
Coming soon

## Roadmap
Migrated to [Canny](https://swayapp.canny.io/)

### Last Updates
* Add dissociate ticket from group option in TicketDetailScreen - Local management of event tickets
* Implement PDF multi-page ticket splitting and grouping - Local management of event tickets
* Remove swipe navigation on tickets (conflict navigation bug fix), add zoom on image tickets, add PDFController for future programmatic control - Local management of event tickets
* PDF pinch zoom, multiple PDF pages ticket, multiple ticket navigation bug fix, ticket deletation - Local management of event tickets
* Feature: Implement local ticket organization System and remove fake ticket showcase

### Known Issues
* (Ticketing) Delete white margins on PDF during import
* (Notification) The notification images and maybe other parameters are not collected correctly.
* (Timetable) The day selection show days without artists programmed.
* (FIXED)(Ticketing) Multiple pages PDF are not unpacked a multiple tickets
* (FIXED)(Ticketing) Multiple ticckets navigation for one event fixed.
* (FIXED)(Images bug) Error handler added to all screen images
* (FIXED)(Notification) User and group specific notifications are sent to all users.
* (FIXED)(Timetable) Overlapping artist cells in the timetable caused layout issues. The solution now displays an overlay warning of overlaps without showing the overlapping artists, keeping the layout intact.
* (FIXED)(Timetable) Artists are now correctly sorted by their start times, ensuring proper chronological order in timetable views.
* (FIXED)(Timetable) Fixed an AssertionError in the _initializeSelectedDay function by ensuring the selected day is always valid and falls within the available festival days.
* (FIXED)(Timetable) Sometimes the first load of the timetable widget doesn't get the data from the database.

See the [open issues](https://github.com/SwayLtd/Sway-App/issues) for a list of proposed features (and known issues).

## Multi-platform
Currently under development for Android and iOS. A Web, MacOS, iPadOS, Windows version will be adapted in the future.
