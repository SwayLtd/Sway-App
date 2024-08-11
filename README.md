# Sway Events

## Project Description
Sway Events is a mobile event management application that helps users discover, organize, and manage events effortlessly. Sway Events aims to provide a seamless and intuitive experience for both event attendees and promoters.

## Screenshots
Coming soon

## Roadmap

### Planned Features
* **Filters for all search types**: Filters are currently only working on events. Need to be updated to work on other entities type.
* **Verified User System**: Verified user mark to allow creation of events, venues, and promoters.
* **User Verification Form**: In-app form for users to apply for verification.
* **Real Databases**: Transition from fake files to real databases with genuine information.
* **Ticketing System**: Implementation of a ticketing system.
* **Social Media Integrations for users**: Links to Spotify, Instagram, etc., on user profiles.
* **Location System**: Geographical positioning and location-based event discovery.
* **Map Interactions**: Interactive maps for event locations and meeting points.
* **Insights**: Advanced data insights for event promoters.
* **Admin Dashboard**: Dashboard for promoters to manage events, tickets, and promotions.
* **Community Features**: Group messages, shared timetables.
* **E-commerce Features**: Promo codes, gift cards, and product sales.
* **Advanced Notifications**: Notifications for promoters and general notifications
* **Gamification**: Profile gamification to enhance user engagement.
* **Sharing sysem**: Ability to share different entities, like music genres, venues, etc.
* **Rating system**: Rate venues, promoters and maybe artists

### Implemented Features
* Security integration using environment variables, root and jailbreak detection, and secure storage
* Timetable v4.6 (multiple artists, list and grid view, filters, follow, design, status management)
* Event ticketing
* Purchasing system v0.5 (sales orders, invoices, items - only backend)
* Discovery suggestions v1
* Search system v1
* Sharing system v1
* Implementation of music genres, events, artists, venues and promoters
* Discovery screen v1
* Search screen v1
* Following system for events, venues, promoters, artists, music genres and users.
* Management system for events, venues, and promoters.
* Responsive design with light and dark theme integration.

### Last Updates
* Timetable v4.6 (fixing issues, sorting artists by start time, overlapping artists)
* Security integration using environment variables, root and jailbreak detection, and secure storage
* Notification system v1 (only backend)
* Timetable v4.2 (fine-tuning operation)
* Timetable v4 (multiple artist and custom names management, status management and artist image rotator widget)
* Timetable v3 (automatic time scrolling and saving of scroll offset, automatic day selection and saving day selection)
* Timetable v2 (filters, follow, new design)
* Event ticketing v1

### Known Issues
* (Timetable) The day selection show days without artists programmed.
* (Timetable) If there is multiple artists programmed at the same time, the cells are overlapped. The timetable widget need to puts them on top of each other.
* (FIXED)(Timetable) Artists are now correctly sorted by their start times, ensuring proper chronological order in timetable views.
* (FIXED)(Timetable) Fixed an AssertionError in the _initializeSelectedDay function by ensuring the selected day is always valid and falls within the available festival days.
* (FIXED)(Timetable) Sometimes the first load of the timetable widget doesn't get the data from the database.

See the [open issues](https://github.com/Sway/Sway-Events/issues) for a list of proposed features (and known issues).

## Multi-platform
Currently under development for Android and iOS. A Web, MacOS, iPadOS, Windows version will be adapted in the future.
