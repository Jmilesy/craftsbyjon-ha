# Home Assistant / IoT — Current State

**Live document — reflects "now", not history.** Distilled from ha-truth.md (v1.7.0, 13 Aug 2026) as of the 13 Sep 2026 cutover. ha-truth.md itself is frozen from this date — historical reference only. Update THIS file when current state changes; log the reasoning in craftsbyjon-docs/decision-log/ if it's a real decision.

**Caution:** ha-truth.md was found to contain at least one known-stale line as of this cutover (its own header still said "Tailscale PENDING SETUP" while later VPS truth.md entries confirm Tailscale has been live and fully operational since 9 Jun 2026) — this is the exact class of bug this restructure exists to prevent. Facts below are cross-checked against truth.md where possible; anything not cross-checked is flagged.

## Access & infrastructure

| Item | Detail |
|---|---|
| HA instance | NUC at 192.168.1.104, HA version 2026.8.1 (as of 13 Aug 2026 - check HA_VERSION file for current) |
| External URL | https://ha.craftsbyjon.co.uk |
| Internal URL | https://192.168.1.104:8123 |
| Media server | 192.168.1.76 (Grafana, OctoPrint, Tautulli, Plex) |
| Zigbee | Sonoff Zigbee 3.0 USB Dongle Plus (ZHA) |
| MQTT broker | 192.168.1.104 |
| MCP server | ha.craftsbyjon.co.uk/api/mcp (HA native MCP) |
| Tailscale | LIVE (confirmed via truth.md v6.58.0/6.59.0, 9-10 Jun 2026) - VPS 100.64.239.100, NUC 100.96.170.59, media server 100.85.254.25. ha-truth.md's own "PENDING SETUP" line is stale. |

## Working integrations (as of 13 Aug 2026 ha-truth.md snapshot)

ZHA, ESPHome (14 devices), Alexa Media (15+ Echo devices), Philips JS TV (occasionally offline), Meross LAN, WLED, UniFi, OctoPrint, Alarmo (alarm panel, active/disarmed), Google Calendar, mobile apps (Jon/Joseph/Jacob phones), Met Office/Open Meteo/Pirate Weather, F1 sensor, SILAM pollen, Waste Collection (broken - see issues), Anniversaries, Watchman, OpenAI/Google Gemini conversation agents, Spook, HACS, go2rtc, iBeacon, CO2 Signal, Falcon Pi Player.

## Known open issues (as of 13 Aug 2026 - verify current status before acting)

- Waste Collection Schedule - DDC calendar source broken (DDC rebuilt as Next.js, scraper needs fixing).
- bedroom DHT11 reading 43.7C - sensor likely dead or miswired.
- Hall + dining room multi-sensors - both at 10% battery as of last check.
- wled Christmas Master / valance - unreachable/offline, firmware update pending retry.
- automation.school_panel_wake_on_landing_motion naming mismatch (friendly name says "Kitchen Motion", entity says landing) - not resolved.
- Weather duplicate automations (weather/weather_2) - cleanup pending.
- Second alarm entity alarm_control_panel.home_alarm - unused/undeployed template alias, not live.
- binary_sensor.front_door_2 (Wing TS0203 door sensor, ZHA) looks stale as of 8 Oct 2026: it has shown on (open) since the 20 Sep 2026 HA restart, automation.front_door last triggered on 26 Aug, and ZHA's cached zone status was last updated on 3 Sep, while the sensor was still sending battery reports on 8 Oct (10:12 UTC). Its parent is the Zigbee coordinator (link quality 94 of 255). Whether the door was physically open was not checked. Open question for Jon: open and close the front door once and see whether HA registers either change.

## School automations

- 14 Sep 2026: merged jacob_school_evening_prep and joseph_school_evening_prep (both fired at 19:00 Sun-Thu, both announced "for both boys" over all 4 speakers, duplicating notifications and the YouTube block - a leftover from when the boys were at different schools) into a single automation.family_school_evening_prep, which computes each boy's school-day status independently and only sends each boy's own notifications when he has school.
- 8 Oct 2026, FIXED: input_text.boys_school (the headline shown on the Downstairs school screen) has a 100 character limit in HA. automation.school_day_manager used to write the joined timetable lessons from both boys into it on school days, which was over 170 characters on 8 Oct, so HA rejected it (log at 14:05 BST: length range 0 - 100) and the helper kept its old value, Enjoy your day off, since 20 Sep 11:05 UTC. The school day branch now writes the fixed text School day. The weekend and holiday branch is unchanged. The lessons are not lost: the four per-boy timetable helpers (limit 255) still hold them and the panel polls them. Merged to main and automations reloaded on 8 Oct 2026.

## Alarm Panel V2 (upstairs, landing) - ESP32/Arduino

Two-board split: screen board (Freenove FNK0104N, Arduino - ST77922 display not in ESPHome's chip list) + brain board (ESP32-WROOM-32, ESPHome). Full reasoning/history lives in Alarm_Panel_V2_Decision_Log.md / Alarm_Panel_V2_Current_State_Spec.md. As of 13 Aug 2026: pin maps, power plan, OTA, and standalone power all confirmed/done. Still open: UART bench test, backup battery/enclosure, voice build-out, arm/disarm control screen, TTS/audio, function of 2 retained PCF8574 buttons.

## AlarmPanel_Downstairs - ESP32/Arduino (school panel + downstairs alarm control)

Freenove FNK0104S (ST7796 display, different chip from upstairs' ST77922 - do not copy pin/driver assumptions across). Static IP 192.168.20.115 on IoT VLAN. Three screens: ARMED (status + on-screen keypad wired to Alarmo disarm), INFO (school content only - weather widget exists in code but not yet wired in), MENU (3x3 room grid). Old school-reminders 20x4 LCD still running in parallel, not yet decommissioned. Built via ChatGPT (not Claude) - flagged in ha-truth.md as reconstructed from code/chat history rather than a first-hand build log, so treat with extra caution versus the upstairs section.

Added 8 Oct 2026 (checked against the live HA request log, the sketch source and the sketch repo's git history):

- Source: GitHub repo Jmilesy/AlarmPanel_Downstairs, working copy C:\dev\AlarmPanel_Downstairs on JonPC. Build and library notes are in that repo's BUILD_NOTES.md and EXTERNAL_LIBRARY_NOTES.md. The repo is not yet listed in the RULES.md repositories table.
- The panel polls HA's REST API about every 5 minutes over HTTPS, 15 requests per poll. The list of entities is in BUILD_NOTES.md under 'School screen data sources'. HA also pushes to the panel through rest_command (refresh, wake, alert and alert-clear endpoints).
- The headline label on the school screen shows input_text.boys_school exactly as HA holds it. See the 8 Oct 2026 entry under School automations for why it was stuck on Enjoy your day off and how that was fixed.
- Sandown: the panel still sends calendar.sandown_school_calendar (deleted from HA) in its calendar/get_events request every 5 minutes, and HA logs a missing-entity warning each time. Confirmed from timing in the HA request log (the warning lands inside the panel's get_events request; request bodies are not logged). The fix is committed on branch fix/school-panel-remove-sandown in the sketch repo (commit 36d42da). It compiled cleanly but has NOT been merged or flashed as of 8 Oct 2026, so the warnings continue.
- OTA: POST /update on port 80 with HTTP Basic Auth (ota.cpp in the sketch). Whether JonPC can reach 192.168.20.115 directly or needs the NUC relay used for the upstairs board has not been confirmed.
- Weather: weather data is polled, but no references to lcarsWeather were found in AlarmPanel_Downstairs.ino, lcars_ui.cpp, lcars_menu.cpp or lcars_school.cpp on 8 Oct 2026, consistent with the widget not being wired in.

## Notify services

notify.alexa_media_lounge_plus, notify.alexa_media_everywhere, notify.alexa_media_kitchen_dot, notify.alexa_media_bedroom_dot, notify.alexa_media_diningroom_dot, notify.alexa_media_boy_s_new_dot, notify.mobile_app_jon_phone, notify.mobile_app_joseph, notify.natalie_notify, notify.jacob_notify.

## For full history and the complete planned-improvements backlog

See ha-truth.md (frozen 13 Sep 2026) for the full integration tables, automation list, and the tiered (tonight/short-term/longer-term) improvements backlog - none of that was reproduced here since it's a task list, not current state; check the task DB (priorities-api) for what's actually still open.
