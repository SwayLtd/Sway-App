# Sway

## Project Description

Sway is a mobile event management application that helps users discover,
organize, and manage events effortlessly. Sway aims to provide a seamless and
intuitive experience for both event attendees and promoters.

## Screenshots

![Event Details screenshot of Paralel 2nd edition](assets/images/screenshots/event.png)

## Roadmap

Migrated to [Canny](https://swayapp.canny.io/)

### Last Updates

- Only showing upcoming events on promoter screens.
- Delete "links" data for artists
- Allow optional performance times for artist assignments
- Refactor and improve styling for the entities management screen
- New border side on dialog
- Remove "price" field from Event model and related components
- Fix display of upcoming events in PromoterScreen
- Fix metadata loading issue in EditEventScreen and refresh flow
- Implement metadata system for Event with UI integration in EventScreen

### Known Issues

- Residents don't need to be limited in modal bottom sheets
- (Notification) Ticket notification actions are not working
- (Notification) Ticket notification doesn't show the ticket on click
- (Notification) Remote notification preferences not linked to notification
  channels
- (Timetable) The day selection show days without artists programmed.
- (FIXED)(Ticketing) Delete white margins on PDF during import
- (FIXED)(Ticketing) Multiple pages PDF are not unpacked a multiple tickets
- (FIXED)(Ticketing) Multiple ticckets navigation for one event fixed.

See the [open issues](https://github.com/SwayLtd/Sway-App/issues) for a list of
proposed features (and known issues).

## Multi-platform

Currently under development for Android and iOS. A Web, MacOS, iPadOS, Windows
version will be adapted in the future.
