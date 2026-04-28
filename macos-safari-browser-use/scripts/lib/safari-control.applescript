-- Internal backend for macos-safari-browser-use/scripts/safari.
-- Public callers should use scripts/safari or scripts/commands/**.

on run argv
	try
		if (count of argv) is 0 then return my jsonFail("missing command")
		set commandName to item 1 of argv

		if commandName is "version" then return my commandVersion()
		if commandName is "activate" then return my commandActivate()

		if commandName is "windows" then return my commandWindows()
		if commandName is "window-count" then return my commandWindowCount()
		if commandName is "focus-window" then return my commandFocusWindow(argv)
		if commandName is "close-window" then return my commandCloseWindow(argv)

		if commandName is "tabs" then return my commandTabs(argv)
		if commandName is "tab-count" then return my commandTabCount(argv)
		if commandName is "current" then return my commandCurrent()
		if commandName is "focus-tab" then return my commandFocusTab(argv)
		if commandName is "close-tab" then return my commandCloseTab(argv)
		if commandName is "reload" then return my commandReload(argv)
		if commandName is "wait" then return my commandWait(argv)
		if commandName is "url" then return my commandUrl(argv)
		if commandName is "title" then return my commandTitle(argv)
		if commandName is "source" then return my commandSource(argv)
		if commandName is "text" then return my commandText(argv)
		if commandName is "links" then return my commandLinks(argv)
		if commandName is "query" then return my commandQuery(argv)
		if commandName is "click" then return my commandClick(argv)
		if commandName is "type" then return my commandType(argv)
		if commandName is "screenshot" then return my commandScreenshot(argv)

		if commandName is "open" then return my commandOpen(argv)
		if commandName is "new-tab" then return my commandNewTab(argv)
		if commandName is "new-window" then return my commandNewWindow(argv)

		if commandName is "js" then return my commandJS(argv)
		if commandName is "js-json" then return my commandJSJson(argv)

		if commandName is "reading-list-add" then return my commandReadingListAdd(argv)

		return my jsonFail("unknown command: " & commandName)
	on error errMsg number errNum
		return my jsonFail(errMsg)
	end try
end run

on commandVersion()
	set osVersion to ""
	try
		set osVersion to do shell script "/usr/bin/sw_vers -productVersion"
	end try
	tell application "Safari"
		set safariVersion to version as text
	end tell
	return "{\"success\":true,\"app\":\"Safari\",\"version\":" & my jsonString(safariVersion) & ",\"macos\":" & my jsonString(osVersion) & "}"
end commandVersion

on commandActivate()
	tell application "Safari" to activate
	return "{\"success\":true,\"action\":\"activate\"}"
end commandActivate

on commandWindows()
	tell application "Safari"
		set windowCount to count of windows
		set parts to {}
		repeat with wi from 1 to windowCount
			set w to window wi
			set windowName to ""
			try
				set windowName to name of w as text
			end try
			set visibleValue to "false"
			try
				if visible of w then set visibleValue to "true"
			end try
			set miniValue to "false"
			try
				if miniaturized of w then set miniValue to "true"
			end try
			set tabsCount to count of tabs of w
			set currentIndex to my currentTabIndex(w)
			set end of parts to "{\"index\":" & wi & ",\"name\":" & my jsonString(windowName) & ",\"tabs_count\":" & tabsCount & ",\"current_tab\":" & currentIndex & ",\"visible\":" & visibleValue & ",\"miniaturized\":" & miniValue & "}"
		end repeat
	end tell
	return "{\"success\":true,\"windows\":[" & my joinList(parts, ",") & "]}"
end commandWindows

on commandWindowCount()
	tell application "Safari" to set windowCount to count of windows
	return "{\"success\":true,\"count\":" & windowCount & "}"
end commandWindowCount

on commandFocusWindow(argv)
	if (count of argv) < 2 then return my jsonFail("missing window index")
	set wi to my asInteger(item 2 of argv, "window index")
	tell application "Safari"
		if wi < 1 or wi > (count of windows) then error "window " & wi & " not found"
		set index of window wi to 1
		activate
	end tell
	return "{\"success\":true,\"window\":" & wi & "}"
end commandFocusWindow

on commandCloseWindow(argv)
	set wi to 0
	if (count of argv) >= 2 then set wi to my asInteger(item 2 of argv, "window index")
	tell application "Safari"
		if (count of windows) is 0 then error "no Safari windows open"
		if wi is 0 then
			close front window
			return "{\"success\":true,\"closed\":\"front-window\"}"
		else
			if wi < 1 or wi > (count of windows) then error "window " & wi & " not found"
			close window wi
			return "{\"success\":true,\"closed_window\":" & wi & "}"
		end if
	end tell
end commandCloseWindow

on commandTabs(argv)
	set wiArg to my targetWindowIndex(argv)
	tell application "Safari"
		if (count of windows) is 0 then return "{\"success\":true,\"tabs\":[]}"
		set parts to {}
		if wiArg is 0 then
			repeat with wi from 1 to (count of windows)
				set w to window wi
				set currentIndex to my currentTabIndex(w)
				repeat with ti from 1 to (count of tabs of w)
					set t to tab ti of w
					set isCurrent to "false"
					if ti = currentIndex then set isCurrent to "true"
					set end of parts to my tabJson(wi, ti, t, isCurrent)
				end repeat
			end repeat
		else
			if wiArg < 1 or wiArg > (count of windows) then error "window " & wiArg & " not found"
			set w to window wiArg
			set currentIndex to my currentTabIndex(w)
			repeat with ti from 1 to (count of tabs of w)
				set t to tab ti of w
				set isCurrent to "false"
				if ti = currentIndex then set isCurrent to "true"
				set end of parts to my tabJson(wiArg, ti, t, isCurrent)
			end repeat
		end if
	end tell
	return "{\"success\":true,\"tabs\":[" & my joinList(parts, ",") & "]}"
end commandTabs

on commandTabCount(argv)
	set wiArg to my targetWindowIndex(argv)
	tell application "Safari"
		if (count of windows) is 0 then return "{\"success\":true,\"count\":0}"
		if wiArg is 0 then set wiArg to 1
		if wiArg < 1 or wiArg > (count of windows) then error "window " & wiArg & " not found"
		set tabCount to count of tabs of window wiArg
	end tell
	return "{\"success\":true,\"window\":" & wiArg & ",\"count\":" & tabCount & "}"
end commandTabCount

on commandCurrent()
	tell application "Safari"
		if (count of windows) is 0 then error "no Safari windows open"
		set w to front window
		set t to current tab of w
		set ti to my currentTabIndex(w)
		set wi to index of w
		return "{\"success\":true,\"tab\":" & my tabJson(wi, ti, t, "true") & "}"
	end tell
end commandCurrent

on commandFocusTab(argv)
	if (count of argv) < 3 then return my jsonFail("usage: focus-tab <window> <tab>")
	set wi to my asInteger(item 2 of argv, "window index")
	set ti to my asInteger(item 3 of argv, "tab index")
	tell application "Safari"
		if wi < 1 or wi > (count of windows) then error "window " & wi & " not found"
		set w to window wi
		if ti < 1 or ti > (count of tabs of w) then error "tab " & ti & " not found in window " & wi
		set current tab of w to tab ti of w
		set index of w to 1
		activate
	end tell
	return "{\"success\":true,\"window\":" & wi & ",\"tab\":" & ti & "}"
end commandFocusTab

on commandCloseTab(argv)
	set wiArg to my targetWindowIndex(argv)
	set tiArg to my targetTabIndex(argv)
	tell application "Safari"
		if (count of windows) is 0 then error "no Safari windows open"
		if wiArg is 0 then set wiArg to index of front window
		if wiArg < 1 or wiArg > (count of windows) then error "window " & wiArg & " not found"
		set w to window wiArg
		if tiArg is 0 then set tiArg to my currentTabIndex(w)
		if tiArg < 1 or tiArg > (count of tabs of w) then error "tab " & tiArg & " not found in window " & wiArg
		close tab tiArg of w
	end tell
	return "{\"success\":true,\"closed_window\":" & wiArg & ",\"closed_tab\":" & tiArg & "}"
end commandCloseTab

on commandReload(argv)
	set targetRefs to my getTargetTab(argv)
	set targetWindowIndex to item 1 of targetRefs
	set targetTabIndex to item 2 of targetRefs
	tell application "Safari"
		do JavaScript "location.reload()" in tab targetTabIndex of window targetWindowIndex
	end tell
	return "{\"success\":true,\"window\":" & targetWindowIndex & ",\"tab\":" & targetTabIndex & ",\"action\":\"reload\"}"
end commandReload

on commandWait(argv)
	set timeoutSeconds to 15
	if (count of argv) >= 2 then set timeoutSeconds to my asInteger(item 2 of argv, "timeout seconds")
	set targetRefs to my getTargetTab(argv)
	set targetWindowIndex to item 1 of targetRefs
	set targetTabIndex to item 2 of targetRefs
	set startTime to current date
	set finalState to "unknown"
	tell application "Safari"
		repeat
			try
				set finalState to do JavaScript "document.readyState" in tab targetTabIndex of window targetWindowIndex
			end try
			if finalState is "complete" then exit repeat
			if ((current date) - startTime) >= timeoutSeconds then exit repeat
			delay 0.5
		end repeat
	end tell
	set elapsedSeconds to ((current date) - startTime)
	set loadedValue to "false"
	if finalState is "complete" then set loadedValue to "true"
	return "{\"success\":true,\"loaded\":" & loadedValue & ",\"readyState\":" & my jsonString(finalState) & ",\"elapsed_seconds\":" & elapsedSeconds & ",\"timeout_seconds\":" & timeoutSeconds & "}"
end commandWait

on commandUrl(argv)
	set targetRefs to my getTargetTab(argv)
	set targetWindowIndex to item 1 of targetRefs
	set targetTabIndex to item 2 of targetRefs
	tell application "Safari" to set tabURL to URL of tab targetTabIndex of window targetWindowIndex
	return "{\"success\":true,\"url\":" & my jsonString(tabURL) & ",\"window\":" & targetWindowIndex & ",\"tab\":" & targetTabIndex & "}"
end commandUrl

on commandTitle(argv)
	set targetRefs to my getTargetTab(argv)
	set targetWindowIndex to item 1 of targetRefs
	set targetTabIndex to item 2 of targetRefs
	tell application "Safari" to set tabTitle to name of tab targetTabIndex of window targetWindowIndex
	return "{\"success\":true,\"title\":" & my jsonString(tabTitle) & ",\"window\":" & targetWindowIndex & ",\"tab\":" & targetTabIndex & "}"
end commandTitle

on commandSource(argv)
	set targetRefs to my getTargetTab(argv)
	set targetWindowIndex to item 1 of targetRefs
	set targetTabIndex to item 2 of targetRefs
	set jsCode to "document.documentElement ? document.documentElement.outerHTML : ''"
	tell application "Safari" to set pageSource to do JavaScript jsCode in tab targetTabIndex of window targetWindowIndex
	return "{\"success\":true,\"source\":" & my jsonString(pageSource) & ",\"window\":" & targetWindowIndex & ",\"tab\":" & targetTabIndex & "}"
end commandSource

on commandText(argv)
	set selectorText to ""
	if (count of argv) >= 2 then
		set possibleArg to item 2 of argv
		if possibleArg does not start with "--" then set selectorText to possibleArg
	end if
	set targetRefs to my getTargetTab(argv)
	set targetWindowIndex to item 1 of targetRefs
	set targetTabIndex to item 2 of targetRefs
	if selectorText is "" then
		set jsCode to "document.body ? document.body.innerText : ''"
	else
		set jsCode to "(function(){ const el = document.querySelector(" & my jsStringLiteral(selectorText) & "); return el ? el.innerText : ''; })()"
	end if
	tell application "Safari" to set pageText to do JavaScript jsCode in tab targetTabIndex of window targetWindowIndex
	return "{\"success\":true,\"text\":" & my jsonString(pageText) & ",\"selector\":" & my jsonString(selectorText) & ",\"window\":" & targetWindowIndex & ",\"tab\":" & targetTabIndex & "}"
end commandText

on commandLinks(argv)
	set targetRefs to my getTargetTab(argv)
	set targetWindowIndex to item 1 of targetRefs
	set targetTabIndex to item 2 of targetRefs
	set jsCode to "JSON.stringify(Array.from(document.querySelectorAll('a[href]')).map((a, i) => ({index: i + 1, text: (a.textContent || '').trim().replace(/\\s+/g, ' ').slice(0, 200), href: a.href})))"
	tell application "Safari" to set rawJson to do JavaScript jsCode in tab targetTabIndex of window targetWindowIndex
	return "{\"success\":true,\"links\":" & rawJson & ",\"window\":" & targetWindowIndex & ",\"tab\":" & targetTabIndex & "}"
end commandLinks

on commandQuery(argv)
	if (count of argv) < 2 then return my jsonFail("missing selector")
	set selectorText to item 2 of argv
	set targetRefs to my getTargetTab(argv)
	set targetWindowIndex to item 1 of targetRefs
	set targetTabIndex to item 2 of targetRefs
	set jsCode to "(function(){ const selector = " & my jsStringLiteral(selectorText) & "; return JSON.stringify(Array.from(document.querySelectorAll(selector)).map((el, i) => ({index: i + 1, text: (el.innerText || el.textContent || '').trim().replace(/\\s+/g, ' '), tag: el.tagName.toLowerCase()}))); })()"
	tell application "Safari" to set rawJson to do JavaScript jsCode in tab targetTabIndex of window targetWindowIndex
	return "{\"success\":true,\"matches\":" & rawJson & ",\"selector\":" & my jsonString(selectorText) & ",\"window\":" & targetWindowIndex & ",\"tab\":" & targetTabIndex & "}"
end commandQuery

on commandClick(argv)
	if (count of argv) < 2 then return my jsonFail("missing selector")
	set selectorText to item 2 of argv
	set targetRefs to my getTargetTab(argv)
	set targetWindowIndex to item 1 of targetRefs
	set targetTabIndex to item 2 of targetRefs
	set jsCode to "(function(){ const selector = " & my jsStringLiteral(selectorText) & "; const el = document.querySelector(selector); if (!el) return JSON.stringify({clicked:false, error:'selector not found', selector}); el.scrollIntoView({block:'center', inline:'center'}); el.click(); return JSON.stringify({clicked:true, selector, tag:el.tagName.toLowerCase(), text:(el.innerText || el.textContent || '').trim().replace(/\\s+/g, ' ').slice(0, 200)}); })()"
	tell application "Safari" to set rawJson to do JavaScript jsCode in tab targetTabIndex of window targetWindowIndex
	return "{\"success\":true,\"result\":" & rawJson & ",\"window\":" & targetWindowIndex & ",\"tab\":" & targetTabIndex & "}"
end commandClick

on commandType(argv)
	if (count of argv) < 3 then return my jsonFail("usage: type <selector> <text>")
	set selectorText to item 2 of argv
	set valueText to item 3 of argv
	set targetRefs to my getTargetTab(argv)
	set targetWindowIndex to item 1 of targetRefs
	set targetTabIndex to item 2 of targetRefs
	set jsCode to "(function(){ const selector = " & my jsStringLiteral(selectorText) & "; const text = " & my jsStringLiteral(valueText) & "; const el = document.querySelector(selector); if (!el) return JSON.stringify({typed:false, error:'selector not found', selector}); el.scrollIntoView({block:'center', inline:'center'}); el.focus(); if (el.isContentEditable) { el.textContent = text; } else if ('value' in el) { el.value = text; } else { el.textContent = text; } try { el.dispatchEvent(new InputEvent('input', {bubbles:true, inputType:'insertText', data:text})); } catch(e) { el.dispatchEvent(new Event('input', {bubbles:true})); } el.dispatchEvent(new Event('change', {bubbles:true})); return JSON.stringify({typed:true, selector, tag:el.tagName.toLowerCase(), textLength:text.length}); })()"
	tell application "Safari" to set rawJson to do JavaScript jsCode in tab targetTabIndex of window targetWindowIndex
	return "{\"success\":true,\"result\":" & rawJson & ",\"window\":" & targetWindowIndex & ",\"tab\":" & targetTabIndex & "}"
end commandType

on commandScreenshot(argv)
	set outputPath to "/tmp/safari-screenshot.png"
	if (count of argv) >= 2 then set outputPath to item 2 of argv
	tell application "Safari"
		if (count of windows) is 0 then error "no Safari windows open"
		activate
		set winId to id of front window
	end tell
	set shellCommand to "/usr/sbin/screencapture -x -l " & winId & " " & quoted form of outputPath
	do shell script shellCommand
	return "{\"success\":true,\"path\":" & my jsonString(outputPath) & "}"
end commandScreenshot

on commandOpen(argv)
	if (count of argv) < 2 then return my jsonFail("usage: open <url> [current|new-tab|background-tab|new-window]")
	set urlText to my normalizeURL(item 2 of argv)
	set targetMode to "current"
	if (count of argv) >= 3 then set targetMode to item 3 of argv
	if targetMode is "tab" then set targetMode to "new-tab"
	if targetMode is "window" then set targetMode to "new-window"
	tell application "Safari"
		activate
		if targetMode is "new-window" then
			make new document with properties {URL:urlText}
		else if targetMode is "new-tab" then
			if (count of windows) is 0 then
				make new document with properties {URL:urlText}
			else
				tell front window
					set newTab to make new tab with properties {URL:urlText}
					set current tab to newTab
				end tell
			end if
		else if targetMode is "background-tab" then
			if (count of windows) is 0 then
				make new document with properties {URL:urlText}
			else
				tell front window to make new tab with properties {URL:urlText}
			end if
		else if targetMode is "current" then
			if (count of windows) is 0 then
				make new document with properties {URL:urlText}
			else
				set URL of current tab of front window to urlText
			end if
		else
			error "unknown open target: " & targetMode
		end if
	end tell
	return "{\"success\":true,\"url\":" & my jsonString(urlText) & ",\"target\":" & my jsonString(targetMode) & "}"
end commandOpen

on commandNewTab(argv)
	set urlText to "about:blank"
	if (count of argv) >= 2 then set urlText to my normalizeURL(item 2 of argv)
	return my commandOpen({"open", urlText, "new-tab"})
end commandNewTab

on commandNewWindow(argv)
	set urlText to "about:blank"
	if (count of argv) >= 2 then set urlText to my normalizeURL(item 2 of argv)
	return my commandOpen({"open", urlText, "new-window"})
end commandNewWindow

on commandJS(argv)
	if (count of argv) < 2 then return my jsonFail("missing JavaScript code")
	set jsCode to item 2 of argv
	set targetRefs to my getTargetTab(argv)
	set targetWindowIndex to item 1 of targetRefs
	set targetTabIndex to item 2 of targetRefs
	tell application "Safari" to set jsResult to do JavaScript jsCode in tab targetTabIndex of window targetWindowIndex
	return "{\"success\":true,\"result\":" & my jsonAny(jsResult) & ",\"window\":" & targetWindowIndex & ",\"tab\":" & targetTabIndex & "}"
end commandJS

on commandJSJson(argv)
	if (count of argv) < 2 then return my jsonFail("missing JavaScript expression")
	set jsExpression to item 2 of argv
	set targetRefs to my getTargetTab(argv)
	set targetWindowIndex to item 1 of targetRefs
	set targetTabIndex to item 2 of targetRefs
	set jsCode to "(function(){ const value = (" & jsExpression & "); return JSON.stringify(value === undefined ? null : value); })()"
	tell application "Safari" to set rawJson to do JavaScript jsCode in tab targetTabIndex of window targetWindowIndex
	return "{\"success\":true,\"result\":" & rawJson & ",\"window\":" & targetWindowIndex & ",\"tab\":" & targetTabIndex & "}"
end commandJSJson

on commandReadingListAdd(argv)
	if (count of argv) < 2 then return my jsonFail("missing url")
	set urlText to my normalizeURL(item 2 of argv)
	tell application "Safari"
		add reading list item urlText
	end tell
	return "{\"success\":true,\"url\":" & my jsonString(urlText) & ",\"action\":\"reading-list-add\"}"
end commandReadingListAdd

on getTargetTab(argv)
	set wiArg to my targetWindowIndex(argv)
	set tiArg to my targetTabIndex(argv)
	tell application "Safari"
		if (count of windows) is 0 then error "no Safari windows open"
		if wiArg is 0 then set wiArg to index of front window
		if wiArg < 1 or wiArg > (count of windows) then error "window " & wiArg & " not found"
		set w to window wiArg
		if tiArg is 0 then set tiArg to my currentTabIndex(w)
		if tiArg < 1 or tiArg > (count of tabs of w) then error "tab " & tiArg & " not found in window " & wiArg
	end tell
	return {wiArg, tiArg}
end getTargetTab

on targetWindowIndex(argv)
	set valueText to my getFlagValue(argv, "--window", "0")
	return my asInteger(valueText, "--window")
end targetWindowIndex

on targetTabIndex(argv)
	set valueText to my getFlagValue(argv, "--tab", "0")
	return my asInteger(valueText, "--tab")
end targetTabIndex

on getFlagValue(argv, flagName, defaultValue)
	set argc to count of argv
	set i to 1
	repeat while i <= argc
		if (item i of argv) is flagName then
			if i is less than argc then return item (i + 1) of argv
		end if
		set i to i + 1
	end repeat
	return defaultValue
end getFlagValue

on currentTabIndex(w)
	tell application "Safari"
		set currentTabRef to current tab of w
		set tabsCount to count of tabs of w
		repeat with ti from 1 to tabsCount
			if tab ti of w is currentTabRef then return ti
		end repeat
	end tell
	return 1
end currentTabIndex

on tabJson(wi, ti, t, isCurrent)
	tell application "Safari"
		set tabName to ""
		set tabURL to ""
		try
			set tabName to name of t as text
		end try
		try
			set tabURL to URL of t as text
		end try
	end tell
	return "{\"window\":" & wi & ",\"index\":" & ti & ",\"current\":" & isCurrent & ",\"name\":" & my jsonString(tabName) & ",\"url\":" & my jsonString(tabURL) & "}"
end tabJson

on normalizeURL(urlText)
	set u to urlText as text
	if u is "" then return "about:blank"
	if u starts with "about:" then return u
	if u starts with "file:" then return u
	if u starts with "http:" then return u
	if u starts with "https:" then return u
	if u starts with "x-" then return u
	if u contains "://" then return u
	return "https://" & u
end normalizeURL

on asInteger(valueText, labelText)
	try
		return valueText as integer
	on error
		error labelText & " must be an integer"
	end try
end asInteger

on jsonAny(value)
	try
		if value is missing value then return "null"
		set valueClass to class of value
		if valueClass is boolean then
			if value then return "true"
			return "false"
		end if
		if valueClass is integer or valueClass is real then return value as text
		if valueClass is list then
			set parts to {}
			repeat with itemValue in value
				set end of parts to my jsonAny(itemValue)
			end repeat
			return "[" & my joinList(parts, ",") & "]"
		end if
		return my jsonString(value as text)
	on error
		return "null"
	end try
end jsonAny

on jsonString(valueText)
	return "\"" & my jsonEscape(valueText as text) & "\""
end jsonString

on jsStringLiteral(valueText)
	return my jsonString(valueText as text)
end jsStringLiteral

on jsonFail(messageText)
	return "{\"success\":false,\"error\":" & my jsonString(messageText) & "}"
end jsonFail

on jsonEscape(valueText)
	set escapedText to valueText as text
	set escapedText to my replaceText("\\", "\\\\", escapedText)
	set escapedText to my replaceText("\"", "\\\"", escapedText)
	set escapedText to my replaceText(return, "\\n", escapedText)
	set escapedText to my replaceText(linefeed, "\\n", escapedText)
	set escapedText to my replaceText(tab, "\\t", escapedText)
	return escapedText
end jsonEscape

on replaceText(findText, replaceWith, sourceText)
	set oldDelimiters to AppleScript's text item delimiters
	set AppleScript's text item delimiters to findText
	set textItems to every text item of sourceText
	set AppleScript's text item delimiters to replaceWith
	set replacedText to textItems as text
	set AppleScript's text item delimiters to oldDelimiters
	return replacedText
end replaceText

on joinList(valueList, delimiterText)
	set oldDelimiters to AppleScript's text item delimiters
	set AppleScript's text item delimiters to delimiterText
	set joinedText to valueList as text
	set AppleScript's text item delimiters to oldDelimiters
	return joinedText
end joinList
