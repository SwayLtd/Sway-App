# Sway

## Project Description
Sway is a mobile event management application that helps users discover, organize, and manage events effortlessly. Sway aims to provide a seamless and intuitive experience for both event attendees and promoters.

## Screenshots
Coming soon

## Roadmap
Migrated to [Canny](https://swayapp.canny.io/)

### Last Updates
* Database migration #3 - Refactor artist data retrieval to use Supabase instead of local JSON storage
* Database migration #2 - Refactor promoter data retrieval to use Supabase instead of local JSON storage
* Refactor: Migrate all date fields from String to DateTime
* Refactor: Migrate all entity IDs from String to int
* Database migration #1 - Refactor genre data retrieval to use Supabase instead of local JSON storage

### Known Issues
* (Notification) The notification images and maybe other parameters are not collected correctly.
* (Timetable) The day selection show days without artists programmed.
* (FIXED)(Notification) User and group specific notifications are sent to all users.
* (FIXED)(Timetable) Overlapping artist cells in the timetable caused layout issues. The solution now displays an overlay warning of overlaps without showing the overlapping artists, keeping the layout intact.
* (FIXED)(Timetable) Artists are now correctly sorted by their start times, ensuring proper chronological order in timetable views.
* (FIXED)(Timetable) Fixed an AssertionError in the _initializeSelectedDay function by ensuring the selected day is always valid and falls within the available festival days.
* (FIXED)(Timetable) Sometimes the first load of the timetable widget doesn't get the data from the database.

See the [open issues](https://github.com/SwayLtd/Sway-App/issues) for a list of proposed features (and known issues).

## Multi-platform
Currently under development for Android and iOS. A Web, MacOS, iPadOS, Windows version will be adapted in the future.
