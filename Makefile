################################################################################
##
## This file is part of BetterPonymotes.
## Copyright (c) 2015 Typhos.
##
## This program is free software: you can redistribute it and/or modify it
## under the terms of the GNU Affero General Public License as published by
## the Free Software Foundation, either version 3 of the License, or (at your
## option) any later version.
##
## This program is distributed in the hope that it will be useful, but WITHOUT
## ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
## FITNESS FOR A PARTICULAR PURPOSE.  See the GNU Affero General Public License
## for more details.
##
## You should have received a copy of the GNU Affero General Public License
## along with this program.  If not, see <http://www.gnu.org/licenses/>.
##
################################################################################

# Release process:
# - Bump version, update we-updates.json
# $ make
# - Upload Chrome addon
# - Upload webext
# $ make www
# $ make sync
# - chmod 644
# $ git ci -m "Bump version to x.y"
# $ git push github master
# - Test
# - Make thread

VERSION = 66.264

# Discord release process:
# - Bump DISCORD_VERSION (format = discord-v[semantic version]-[alpha/beta/release])
# - Commit code to git
# $ make release/discord
# - Upload generated 7z to tag's release on Github, flag draft as pre-release (maybe automate in the future)
# - Smoke test release locally
# - Flag pre-release as ready, edited and good to go 
# - Notify interested parties

DISCORD_VERSION = discord-v0.11.3-beta
DISCORD_RELEASE_BASE_BRANCH = discord
GITHUB_API_HOST = https://api.github.com
GITHUB_USER = ByzantineFailure
GITHUB_REPO_NAME = BPM-for-Discord

CONTENT_SCRIPT := \
    addon/bpm-header.js addon/bpm-utils.js addon/bpm-browser.js \
    addon/bpm-store.js addon/bpm-search.js addon/bpm-inject.js \
    addon/bpm-searchbox.js addon/bpm-frames.js addon/bpm-alttext.js \
    addon/bpm-post.js addon/bpm-reddit.js addon/bpm-global.js addon/bpm-main.js

EMOTE_DATA = emotes/*.json tags/*.json data/rules.yaml data/tags.yaml

ADDON_DATA = \
    build/bpm-resources.js build/emote-classes.css build/betterponymotes.js \
    addon/bpmotes.css addon/combiners-nsfw.css addon/extracss-pure.css addon/extracss-webkit.css \
    addon/bootstrap.css addon/options.html addon/options.css addon/options.js \
    addon/pref-setup.js

default: build/betterponymotes-$(VERSION).xpi build/webext-$(VERSION).zip build/chrome.zip build/BPM.safariextension build/export.json.bz2 build/gif-animotes.css

clean:
	rm -fr build

www: web/* build/betterponymotes-$(VERSION).xpi build/betterponymotes.update.rdf build/betterponymotes-$(VERSION)-an+fx.xpi addon/we-updates.json
	cp web/firefox-logo.png www
	cp web/chrome-logo.png www
	cp web/safari-logo.png www
	cp web/relay-logo.png www
	cp web/ponymotes-logo.png www
	sed "s/\/\*{{version}}\*\//$(VERSION)/" < web/index.html > www/index.html

	rm -f www/*.xpi

	cp build/betterponymotes-$(VERSION).xpi www/xul/betterponymotes.xpi
	cp build/betterponymotes-$(VERSION).xpi www/xul/betterponymotes-$(VERSION).xpi

	cp build/betterponymotes-$(VERSION)-an+fx.xpi www/we/betterponymotes.xpi
	cp build/betterponymotes-$(VERSION)-an+fx.xpi www/we/betterponymotes-$(VERSION)-an+fx.xpi

sync:
	chmod 644 www/*
	chmod 755 www/we www/xul
	chmod 644 animotes/*
	rsync -e "ssh -p 40719" -zvLr --delete www/ lyra@ponymotes.net:/var/www/ponymotes.net/bpm
	rsync -e "ssh -p 40719" -zvLr --delete animotes/ lyra@ponymotes.net:/var/www/ponymotes.net/animotes

build/betterponymotes.js: $(CONTENT_SCRIPT)
	mkdir -p build
	cat $(CONTENT_SCRIPT) > build/betterponymotes.js

build/bpm-resources.js build/emote-classes.css: $(EMOTE_DATA)
	mkdir -p build
	./bpgen.py

build/export.json.bz2: build/export.json
	bzip2 < build/export.json > build/export.json.bz2

build/export.json: $(EMOTE_DATA)
	./bpexport.py --json build/export.json

build/gif-animotes.css: $(EMOTE_DATA)
	mkdir -p build
	./dlanimotes.py

build/betterponymotes-$(VERSION).xpi: $(ADDON_DATA) addon/fx-main.js addon/fx-install.rdf addon/fx-package.json
	mkdir -p build/firefox/data

	sed "s/\/\*{{version}}\*\//$(VERSION)/" < addon/fx-package.json > build/firefox/package.json

	cp addon/fx-main.js build/firefox/index.js

	cp build/betterponymotes.js build/firefox/data
	cp build/bpm-resources.js build/firefox/data
	cp build/bpm-resources.js build/firefox
	cp build/emote-classes.css build/firefox/data

	cp addon/bootstrap.css build/firefox/data
	cp addon/bpmotes.css build/firefox/data
	cp addon/combiners-nsfw.css build/firefox/data
	cp addon/extracss-pure.css build/firefox/data
	cp addon/extracss-webkit.css build/firefox/data
	cp addon/options.css build/firefox/data
	cp addon/options.html build/firefox/data
	cp addon/options.js build/firefox/data
	cp addon/pref-setup.js build/firefox

	cd build/firefox && ../../node_modules/.bin/jpm xpi
	./mungexpi.py $(VERSION) addon/fx-install.rdf build/firefox/*.xpi build/betterponymotes-$(VERSION).xpi

build/betterponymotes.update.rdf: build/betterponymotes-$(VERSION).xpi
	uhura -k betterponymotes.pem build/betterponymotes-$(VERSION).xpi https://ponymotes.net/bpm/xul/betterponymotes-$(VERSION).xpi > build/betterponymotes.update.rdf

build/webext-$(VERSION).zip: $(ADDON_DATA) addon/cr-background.html addon/cr-background.js addon/we-manifest.json
	mkdir -p build/webext

	sed "s/\/\*{{version}}\*\//$(VERSION)/" < addon/we-manifest.json > build/webext/manifest.json

	cp addon/cr-background.html build/webext/background.html
	cp addon/cr-background.js build/webext/background.js

	cp build/betterponymotes.js build/webext
	cp build/bpm-resources.js build/webext
	cp build/emote-classes.css build/webext

	cp addon/bootstrap.css build/webext
	cp addon/bpmotes.css build/webext
	cp addon/combiners-nsfw.css build/webext
	cp addon/extracss-pure.css build/webext
	cp addon/extracss-webkit.css build/webext
	cp addon/options.css build/webext
	cp addon/options.html build/webext
	cp addon/options.js build/webext
	cp addon/pref-setup.js build/webext

	cd build/webext && zip ../webext-$(VERSION).zip *

build/chrome.zip: $(ADDON_DATA) addon/cr-background.html addon/cr-background.js addon/cr-manifest.json
	mkdir -p build/chrome

	sed "s/\/\*{{version}}\*\//$(VERSION)/" < addon/cr-manifest.json > build/chrome/manifest.json

	cp addon/cr-background.html build/chrome/background.html
	cp addon/cr-background.js build/chrome/background.js

	cp build/betterponymotes.js build/chrome
	cp build/bpm-resources.js build/chrome
	cp build/emote-classes.css build/chrome

	cp addon/bootstrap.css build/chrome
	cp addon/bpmotes.css build/chrome
	cp addon/combiners-nsfw.css build/chrome
	cp addon/extracss-pure.css build/chrome
	cp addon/extracss-webkit.css build/chrome
	cp addon/options.css build/chrome
	cp addon/options.html build/chrome
	cp addon/options.js build/chrome
	cp addon/pref-setup.js build/chrome

	cp betterponymotes.pem build/chrome/key.pem
	# Uncompressed due to prior difficulties with the webstore
	cd build/chrome && zip -0 ../chrome.zip *

build/BPM.safariextension: $(ADDON_DATA) addon/sf-Settings.plist addon/sf-background.html addon/sf-background.js
	mkdir -p build/BPM.safariextension

	sed "s/\/\*{{version}}\*\//$(VERSION)/" < addon/sf-Info.plist > build/BPM.safariextension/Info.plist

	cp addon/icons/sf-Icon-128.png build/BPM.safariextension/Icon-128.png
	cp addon/icons/sf-Icon-64.png build/BPM.safariextension/Icon-64.png
	cp addon/sf-background.html build/BPM.safariextension/background.html
	cp addon/sf-background.js build/BPM.safariextension/background.js
	cp addon/sf-Settings.plist build/BPM.safariextension/Settings.plist

	cp build/betterponymotes.js build/BPM.safariextension
	cp build/bpm-resources.js build/BPM.safariextension
	cp build/emote-classes.css build/BPM.safariextension

	cp addon/bootstrap.css build/BPM.safariextension
	cp addon/bpmotes.css build/BPM.safariextension
	cp addon/combiners-nsfw.css build/BPM.safariextension
	cp addon/extracss-pure.css build/BPM.safariextension
	cp addon/extracss-webkit.css build/BPM.safariextension
	cp addon/options.css build/BPM.safariextension
	cp addon/options.html build/BPM.safariextension
	cp addon/options.js build/BPM.safariextension
	cp addon/pref-setup.js build/BPM.safariextension

	cd build/BPM.safariextension && zip ../BPM.safariextension.zip *

#Set via environment variable
#DC_BPM_ARCHIVE_PASSWORD= 

DISCORD_INTEGRATION := \
	discord/integration/package.json discord/integration/bpm.js discord/integration/README.md

DISCORD_SETTINGS_SCRIPT := \
	discord/addon/settings/options.js discord/addon/settings/options.css \
	discord/addon/settings/options.html discord/addon/settings/index.js 
    #discord/addon/settings/about.js discord/addon/settings/emotes.js \
    discord/addon/settings/general.js discord/addon/settings/search.js \
    discord/addon/settings/subreddits.js discord/addon/settings/updates.js \
    discord/addon/settings/settings.js discord/addon/utils.js \
    discord/addon/updates/update-functions.js \
	discord/addon/settings/html/emotes.html discord/addon/settings/html/general.html \
	discord/addon/settings/html/search.html discord/addon/settings/html/base-panel.html \
	discord/addon/settings/html/subreddits.html discord/addon/settings/html/about.html \
	discord/addon/settings/html/updates.html 

DISCORD_UPDATES_SCRIPT := \
	discord/addon/updates/update-functions.js discord/addon/updates/updates.js \
    discord/addon/updates/updates.css discord/addon/utils.js

DISCORD_SEARCH_SCRIPT := \
	discord/addon/utils.js discord/addon/search/search.js discord/addon/search/search.css

DISCORD_CORE_SCRIPT := \
	discord/addon/core/background.js discord/addon/core/core.js

DISCORD_ADDON_SCRIPT := $(DISCORD_CORE_DATA) $(DISCORD_SEARCH_SCRIPT) $(DISCORD_UPDATES_SCRIPT) \
                        $(DISCORD_SETTINGS_SCRIPT) $(ADDON_DATA) build/gif-animotes.css

discord/bpm.js: $(DISCORD_ADDON_SCRIPT)
	mkdir -p build/discord/addon
	
	cp addon/bootstrap.css discord/addon/core/
	cp addon/bpmotes.css discord/addon/core/
	cp addon/combiners-nsfw.css discord/addon/core/
	cp addon/extracss-pure.css discord/addon/core/
	cp addon/extracss-webkit.css discord/addon/core/
	cp addon/pref-setup.js discord/addon/core/
	cp build/betterponymotes.js discord/addon/core/
	cp build/bpm-resources.js discord/addon/core/
	cp build/emote-classes.css discord/addon/core/
	cp build/gif-animotes.css discord/addon/core/
	
	cd discord/addon && npm install
	cd discord/addon && webpack bpm.js ../../build/discord/bpm.js
	
	sed -i.bak "s/<\!-- REPLACE-WITH-DC-VERSION -->/$(DISCORD_VERSION)/g" build/discord/bpm.js
	sed -i.bak "s/<\!-- REPLACE-WITH-BPM-VERSION -->/$(VERSION)/g" build/discord/bpm.js
	sed -i.bak "s/REPLACE-WITH-DC-VERSION/$(DISCORD_VERSION)/g" build/discord/bpm.js
	rm build/discord/bpm.js.bak

discord/bpm.asar: discord/bpm.js
	mkdir -p build/discord
	mkdir -p build/discord/addon
	
	asar pack build/discord/addon/ build/discord/bpm.asar
	rm -rf build/discord/addon

DISCORD_INSTALLER_LIB := discord/installer/lib/addon.js discord/installer/lib/integration.js discord/installer/lib/paths.js \
    discord/installer/lib/constants.js

DISCORD_INSTALLER := discord/installer/index.js discord/installer/package.json \
    discord/installer/install_mac.command discord/installer/install_linux.sh discord/installer/install_windows.bat discord/installer/win_ps.ps1 \
    discord/installer/install_windows_PTB.bat discord/installer/README.md discord/installer/install_mac_PTB.command \
	discord/installer/install_windows_canary.bat discord/installer/install_mac_canary.command discord/installer/install_linux_ptb.sh discord/installer/install_linux_canary.sh

#Phony target we can use to force things to build every run
FORCE: 

# Note, requires node, globally installed asar (npm install asar -g)
discord/installer: FORCE $(DISCORD_INSTALLER) $(DISCORD_INSTALLER_LIB)
	mkdir -p build/discord
	mkdir -p build/discord/lib	
	
	for INSTALLER_FILE in $(DISCORD_INSTALLER); \
	do \
		cp $$INSTALLER_FILE build/discord/; \
	done
	
	for INSTALLER_FILE in $(DISCORD_INSTALLER_LIB); \
	do \
		cp $$INSTALLER_FILE build/discord/lib; \
	done	
	
	cd build/discord && npm install --production

discord/integration.asar: $(DISCORD_INTEGRATION)
	mkdir -p build/discord
	asar pack discord/integration/ build/discord/integration.asar

discord/betterDiscord-bpm.plugin.js: discord/bpm.js
	mkdir -p build/better-discord
	rm -f build/better-discord/betterDiscord-bpm.plugin.js
	cat discord/better-discord/plugin-head.js >> build/better-discord/betterDiscord-bpm.plugin.js
	cat build/discord/bpm.js >> build/better-discord/betterDiscord-bpm.plugin.js
	cat discord/better-discord/plugin-foot.js >> build/better-discord/betterDiscord-bpm.plugin.js
	sed -i.bak 's/IS_BETTER_DISCORD = false/IS_BETTER_DISCORD = true/g' build/better-discord/betterDiscord-bpm.plugin.js

discord: discord/bpm.js discord/betterDiscord-bpm.plugin.js discord/integration.asar discord/installer

clean/discord:
	rm -rf build/discord
	rm -rf build/better-discord

discord/generate-notes:
	# Create release notes
	echo 'Creating release notes...'
	sed 's/%TAG-NAME%/$(DISCORD_VERSION)/g' discord/RELEASE_NOTES_TEMPLATE.md > discord/RELEASE_NOTES.md

#Ideally we'd also upload the 7z to the release, but that's notably more difficult than it would seem 
discord/release: discord
	#Commit release notes
	cat discord/RELEASE_NOTES.md | python -c 'import sys,json;print(json.dumps(sys.stdin.read()))' > build/DISCORD_RELEASE_NOTES.md
	git add discord/RELEASE_NOTES.md	
	git commit -m "Adding release notes for $(DISCORD_VERSION)"
	git push
	
	#Make sure we know what we're releasing
	git status 
	git log -1 
	read -r -p "Tag with above commit as $(DISCORD_VERSION) (y/n)? " DC_RELEASE_CONFIRM;\
	if [ "$$DC_RELEASE_CONFIRM" != "y" ] && [ "$$DC_RELEASE_CONFIRM" != "Y" ]; then \
		exit 1; \
	fi
	
	#Push a tag to git
	git tag -a "$(DISCORD_VERSION)" -m "Release of discord version $(DISCORD_VERSION)" 
	git push origin $(DISCORD_VERSION) 
	
	#Create a 7z archive
	rm -rf ./build/BPM\ for\ Discord\ $(DISCORD_VERSION).7z
	7z a ./build/BPM\ for\ Discord\ $(DISCORD_VERSION).7z -r ./build/discord
	
	#Create release
	NOTES_TEXT=$$(cat build/DISCORD_RELEASE_NOTES.md);\
	UPLOAD_URL=$$(curl -X POST -H "Authorization: token $(DISCORD_RELEASE_GITHUB_API_TOKEN)" --data \
		"{\
			\"tag_name\":\"$(DISCORD_VERSION)\",\
			\"target_commitish\":\"$(DISCORD_RELEASE_BASE_BRANCH)\",\
			\"name\":\"$(DISCORD_VERSION)\",\
			\"body\": $$NOTES_TEXT,\
			\"draft\":false,\
			\"prerelease\":true\
		}"\
		"$(GITHUB_API_HOST)/repos/$(GITHUB_USER)/$(GITHUB_REPO_NAME)/releases" \
		| jq '.upload_url' | sed 's/"//g' | sed 's/name,label}//g' | sed 's/{//g' ); \
	
	#I'm leaving the password-protected code here just in case
	#Mac doesn't have a good 7z client that handles password protected so we create a zip.
	#rm -rf ./build/BPM\ for\ Discord\ $(DISCORD_VERSION)\ MAC.zip
	#cd ./build/discord && zip -r --password $(DC_BPM_ARCHIVE_PASSWORD) ../BPM\ for\ Discord\ $(DISCORD_VERSION)\ MAC.zip . 
	#
	#Windows actually can't extract a zipped version because the built in tools don't support the long directory paths
	#that node's module tree creates.  So, we use 7z for Windows.  In other news, what the fuck, MS.
	#rm -rf ./build/BPM\ for\ Discord\ $(DISCORD_VERSION)\ WINDOWS.7z
	#7z a ./build/BPM\ for\ Discord\ $(DISCORD_VERSION)\ WINDOWS.7z -r ./build/discord/* -p$(DC_BPM_ARCHIVE_PASSWORD) -mhe 
	

# This does not yet function.  I think github actually refuses to allow you to upload files to a pre-release?
discord/upload-release-assets:
	Z_NAME_PARAM="name=BPM%20for%20Discord%20$(DISCORD_VERSION).7z";\
	JS_NAME_PARAM="name=betterDiscord-bpm.plugin.js";\
    echo $$UPLOAD_URL; \
	curl -X POST -H "Authoriztion: token $(DISCORD_RELEASE_GITHUB_API_TOKEN)" -H "Content-Type: application/x-7z-compressed" \
		--data-binary @./build/BPM\ for\ Discord\ $(DISCORD_VERSION).7z $$UPLOAD_URL$$Z_NAME_PARAM;\
	curl -X POST -H "Authoriztion: token $(DISCORD_RELEASE_GITHUB_API_TOKEN)" -H "Content-Type: application/javascript" \
		--data-binary @./build/better-discord/betterDiscord-bpm.plugin.js "$$UPLOAD_URL$$JS_NAME_PARAM";

# For testing
discord/clean-tag:
	git tag -d $(DISCORD_VERSION)
	git push origin :refs/tags/$(DISCORD_VERSION)

discord/7z: discord
	rm -rf ./build/BPM\ for\ Discord\ $(DISCORD_VERSION).7z
	7z a ./build/BPM\ for\ Discord\ $(DISCORD_VERSION).7z -r ./build/discord

