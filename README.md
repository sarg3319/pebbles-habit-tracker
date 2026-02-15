# pebbles_habit_tracker

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

# Pebbles Habit Tracker 🪨

# Session's To do's

## Next Steps 🚀
- [ ] Create Google Apps Script to pull data into Google Sheets
- [ ] Custom styling and fonts // https://www.notion.so/Pebbles-23980f4987e2809abeece470f5aad8de?source=copy_link#30480f4987e28058888fe98c5bfc3c1e
- [ ] How to collapse sections in here? 
- [ ] Plan health list and configurations
- [ ] Depening cycle tracking capabilities (phases not just days) + placebo
- [ ] Note toggle for certain habits - fix it
- [ ] Add health tracking capabilites 
- [ ] figure out how to print code in PDF
- [ ] Data integrity check
- [ ] "Cloud Function" or a local helper that calculates your Completion Percentage per Tag.
- [ ] Think about in app analytics. "Neutral tracking"
- [ ] JSON data export ("Middle Step":
        Format Ready: The "JSON" format is basically the universal language of data. Once you're ready for Google Sheets, we just tell the Sheets script to read this exact same format.
        Zero Maintenance: You don't need a server or a paid Firebase plan for this. It uses your phone's built-in sharing power.
        Audit Tool: You can open this file yourself to see exactly how "Habit A" relates to "Mood B" without any filters in the way.)

-[ ] More complicated data export 
    (Moving to Point 3: Automating Data to Google Sheets, you hit the nail on the head. Using Firebase as the bridge to Google Sheets is a standard industry practice, but it does add a layer of complexity because Google Sheets lives outside the "Firebase bubble."
    How the Bridge Works
    To get your data from Firebase to Google Sheets automatically, we usually use a Google Cloud Function (or a Firebase Function).
    Here is the breakdown of how this would function:
    The Trigger: You can set it to trigger every time you check a habit, or (more efficiently) once every 24 hours (a "Scheduled Function").
    The Translator: The Function reads your Firestore "Maps" and "Daily Metrics."
    The Delivery: It uses the Google Sheets API to find the right row and column and "plop" the data in.
    The "Prototype-Friendly" Alternative
    Cloud Functions can be a bit of a hurdle to set up (they require a Firebase "Blaze" pay-as-you-go plan, though the free tier is huge). Since we are in the prototype phase, we have a simpler "Middle Step":
    The "Sheet Sync" Button: Instead of a background server, we can add a button in your "Manage" screen that, when pressed, sends your current data directly to a Google Script URL (Webapp). It’s "automatic" in the sense that you don't have to type anything, but "manual" in the sense that you trigger the sync.
    Why this is better for your reports:
    Once the data is in Google Sheets, you can use standard formulas to create:
    Correlation Reports: Does "Migraine" (Health Tag) always follow a "Late Night" (Sleep Metric)?
    Heatmaps: Which days of the week are most "Active" across all tags?
    Pivot Tables: Summarizing monthly totals without needing to write more Flutter code.
    Should we try to build the "Sync" button?
    To do this, I would need to help you set up a tiny bit of code inside a Google Sheet first (called Apps Script).
    Would you like me to walk you through setting up the Google Sheet side first, or should we just add the "Export to Console" button in the app so you can at least see the raw data format we'll be sending?)
# Done ✅ : 

15.02.2026
- [x] Not possible to rearrange "mood" and diary and sleep as a habit
- [x] Not possible to rearrange "mood" and diary and sleep as a habit
- [x] Mood imput not possible from board

14.02.2026
- [x] Global diary
- [x] Note toggle for certain habits (but no working right now)
- [x] change colours for tags

12.02.2026
- [x] Set up Firebase and connected it to the cloud
- [x] Added "Streak" option, categories. 
- [x] Set up inital table UI
11.02.2026
- [x] Initial app structure
- [x] Synced horizontal scrolling (Dates + Checkboxes)
- [x] Bottom Navigation Bar
- [x] Global state management (habits don't reset on tab switch)
- [x] Category support for habits
- [x] Drag-and-drop reordering


## My Personal Notes ✍️
- 