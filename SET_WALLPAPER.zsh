#!/bin/zsh --no-rcs
# set -x

##################################### VARIABLES ##########################################

vers="1.50"
myPID=$$
scriptName=$( /usr/bin/basename ${0} )
myTimeStamp()
{
	/bin/date | /usr/bin/awk  '{ printf "%02s %02s %02s %02s\n", $1,$2,$3,$4 }'
}
Numb_Arguments=$#
argument_1="${1}"
myHost=$( /usr/sbin/scutil --get ComputerName )
myUserShortName=$( /usr/sbin/scutil <<< "show State:/Users/ConsoleUser" | /usr/bin/awk '/Name :/ && ! /loginwindow/ { print $3 }' )
myID=$( /usr/bin/id -u ${myUserShortName} )
desktoppr="/usr/local/bin/desktoppr"
myHome=$( /usr/bin/dscl . read Users/${myUserShortName} NFSHomeDirectory | /usr/bin/awk '{print $2}' )
myLog="${myHome}/Library/Logs/.$(/usr/bin/basename ${scriptName} | /usr/bin/cut -d "." -f 1 ).log"
wallpaperPlist="/Library/Managed Preferences/edu.stonybrook.doit.wallpaper.plist"
URL="https://api.github.com/repos/scriptingosx/desktoppr/releases/latest"
localAdminAcct="desktopsupport"

##################################### FUNCTIONS ##########################################

function logging()
{
    /bin/echo "$(myTimeStamp) ${myHost} ${scriptName}[${myPID}]: ${1}" | /usr/bin/tee -a "${myLog}"
}
function START_SCRIPT()
{
	/bin/echo "" | /usr/bin/tee -a "${myLog}"
	logging "Starting ${scriptName}, Version: ${vers}."
}
function EXIT_SCRIPT()
{
	logging "Ending ${scriptName}, Version: ${vers}."
	/bin/echo "" | /usr/bin/tee -a "${myLog}"
	exit 0
}
function MAKE_TEMP_DIR()
{
	logging "MAKE_TEMP_DIR: Starting MAKE_TEMP_DIR."
		# Make a temp directory to store downloaded files and such.
	myTmpDir=$( /usr/bin/mktemp -d )
	logging "MAKE_TEMP_DIR: Making temp directory: ${myTmpDir}"
	logging "MAKE_TEMP_DIR: Ending MAKE_TEMP_DIR."
}
function REMOVE_TEMP_DIR()
{
	logging "REMOVE_TEMP_DIR: Starting REMOVE_TEMP_DIR."
	logging "REMOVE_TEMP_DIR: Removing temp directory: ${myTmpDir}"
	/bin/rm -Rf "${myTmpDir}"
	logging "REMOVE_TEMP_DIR: Ending REMOVE_TEMP_DIR."
}
function DOWNLOAD_INSTALL_FROM_GITHUB()
{
	MAKE_TEMP_DIR
	DOWNLOAD_URL=$( /usr/bin/curl --silent --url "${URL}" | /usr/bin/plutil -extract assets.0.browser_download_url raw -  )
	logging "DOWNLOAD_INSTALL_FROM_GITHUB: Installing from ${DOWNLOAD_URL}"
	/usr/bin/curl --silent --location --url "${DOWNLOAD_URL}" --output "${myTmpDir}/package.pkg"
	/usr/sbin/installer -pkg "${myTmpDir}/package.pkg" -target / -verbose
	/bin/rm -Rfv "${myTmpDir}/package.pkg"
	REMOVE_TEMP_DIR
}
function WALLPAPER()
{
	local funcName=$( /usr/bin/basename ${0} )
	
		# Check to see if desktoppr is present on the system.
	if  [ ! -e "${desktoppr}" ]; then
		logging "WALLPAPER: desktoppr was NOT found."
		logging "WALLPAPER: Installing from GitHub..."
		DOWNLOAD_INSTALL_FROM_GITHUB
	else
		logging "WALLPAPER: Setting the wallpaper for ${myUserShortName}."
		if [[ "${myUserShortName}" == "${localAdminAcct}" ]]; then
			myWallpaper=$( /usr/bin/defaults read "${wallpaperPlist}" Admin_Wallpaper )
			if [ ! -e "/Library/Desktop Pictures/${myWallpaper}" ]; then
				myWallpaper="SBUBlack.png"
			fi
		else
			myWallpaper=$( /usr/bin/defaults read "${wallpaperPlist}" User_Wallpaper )
			if [ ! -e "/Library/Desktop Pictures/${myWallpaper}" ]; then
				myWallpaper="SBURed.jpg"
			fi
		fi
		myResult=$( /bin/launchctl asuser "${myID}" /usr/local/bin/desktoppr )
		while [ "${myResult}" != "/Library/Desktop Pictures/${myWallpaper}" ]; do
			logging "WALLPAPER: Setting the wallpaper to ${myWallpaper}."
			/bin/launchctl asuser "${myID}" "${desktoppr}" "/Library/Desktop Pictures/${myWallpaper}"
			sleep 2
			unset myResult
			myResult=$( /bin/launchctl asuser "${myID}" "${desktoppr}" )
		done
		/bin/launchctl asuser "${myID}" "${desktoppr}" scale stretch
	fi
}
function MY_VERSION()
{
	if [[ "$1" -eq 1 ]]; then
		case $2 in
			(-v|--version)
				/bin/echo "${vers}"
				exit 0
				;;
			(*)
				exit 0
				;;
		esac
	fi
}
function CHECK_FOR_PLIST()
{
if [ ! -e "${wallpaperPlist}" ]; then
	logging "CHECK_FOR_PLIST: Can not find the plist file with the configuration settings."
	exit 1
fi
}
##################################### MAIN ##########################################

MY_VERSION ${Numb_Arguments} ${argument_1}
CHECK_FOR_PLIST
START_SCRIPT
WALLPAPER
EXIT_SCRIPT
