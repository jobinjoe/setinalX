# Walkthrough

Open `SentinalX.xcodeproj` in Xcode and run the **SentinalX** scheme. The project is multiplatform. iPhone, iPad, and Mac all build the same target. The deployment target matches the Xcode project: 26.2.

## Sign in

The first screen is the mock login.

| Field | Value |
| --- | --- |
| Email | `operator@sentinalx.app` |
| Password | `sentinal` |

Tap **Use demo access**, or type the password and tap **Sign in**. An empty field or a wrong password stays on this screen with a short error. The session is remembered, so the next launch opens on Zones.

The disarm PIN is separate from the password. It starts as `2468`.

## Zones

The list opens in **Home**.

- Front Door and Garage Entry are armed.
- Living Room and Hallway are interior, so they are disarmed on purpose.
- Kitchen Window is disarmed because its battery is 18%, under the 20% floor.
- Back Gate is disarmed because the contact is open.

Each row shows a sensor icon, an Armed or Disarmed pill, the battery, and a warning when the zone cannot arm. The three-way control under the status card is Disarm, Home, and Away.

Try this:

1. Open **Kitchen Window**. The detail screen shows the battery ring, the closed contact, signal, temperature, and the last check-in. **Cannot arm** is disabled, and the card explains the battery floor.
2. Open **Back Gate**. The contact reads **Open**. Arming is refused until that contact is closed. Disarm is not the path here, because the gate is already disarmed.
3. Open **Living Room**. It is a motion sensor: the reading is an activity percentage, not a contact. Tap **Arm zone**. The pill turns Armed, and the site badge becomes **Custom**, because an interior zone is now on while the site is otherwise in Home.
4. Long-press a zone in the list for the same Arm or Disarm actions.
5. Tap **Away**. Front Door, Garage, Living Room, and Hallway arm. Kitchen Window and Back Gate stay off, and a banner names them. Activity gains a panel event plus one skip event per zone.
6. Tap **Disarm**. The PIN sheet opens. `0000` shakes and does not change anything. `2468` disarms every zone.
7. Tap **Home** again to return to the starter mix, still with the two faulted zones left off.

## Activity

Open the **Activity** tab. A local "Panel online" event is already there from the first launch, plus any arm or disarm you just did.

The header shows **Checking**, then **Live**. The app requests a page of posts from `https://jsonplaceholder.typicode.com/posts` and appends the ones it has not stored. Titles and bodies are the payload from that API. The zone name and the severity are added locally so the feed reads as monitoring traffic. New rows trickle in, and the dot on the header pulses while the link is live.

Pull to refresh, or tap the refresh button, to fetch the next page without waiting. The interval is 15, 30, or 60 seconds in Settings. Turn **Live event feed** off and the automatic poll stops; **Check now** still works. If the Mac or simulator is offline, the header switches to **Offline** and the rows already saved remain.

Cloud rows are tagged **Cloud**. Rows created by arming or disarming are tagged **Panel**. The Alerts chip keeps warnings and critical rows.

## Settings

- Rename the operator. The greeting on Zones uses that name.
- Change the disarm PIN. The sign-in password stays `sentinal`.
- Pick a theme. Dark is the default; Light and System are both designed.
- **Clear activity** drops the log and lets the feed refill from the start of the mock API.
- **Restore demo zones** puts the six starter zones back and clears the log.
- **Sign out** returns to the login. Zones and events stay on the device.

## Persistence

After you arm a zone or receive a few cloud events, stop the app and run it again. You should land on Zones, still signed in, with the same arming mix and the same activity. That data is the SwiftData store, not a fixture rebuilt on every launch. Restore demo zones is the way back to the screenshot layout.

## Tests

The arm and disarm rules are covered by 24 tests in `SentinalXTests`. From the project directory:

```bash
xcodebuild test -project SentinalX.xcodeproj -scheme SentinalX -destination 'platform=macOS'
```

Or in Xcode: Product → Test. The suite does not need a network connection or a signed-in session. A failure names the rule, for example a wrong PIN, an open contact, or a Home layout that left an interior zone armed.
