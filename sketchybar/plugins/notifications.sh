#!/bin/sh

osascript -e 'tell application "System Events" to tell process "ControlCenter"
            tell menu bar item 1 of menu bar 1
                click
            end tell
        end tell'
