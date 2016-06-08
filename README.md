# Plex-Remove-Old-Movies

##Introduction
Powershell script to remove old movies from Plex media server

If you aren't a movies collector and periodically you have to delete movies from your hard disks to free space, this script will automate this work.

##How this script works
This script uses the [Plex rest service](https://support.plex.tv/hc/en-us/articles/201638786-Plex-Media-Server-URL-Commands)
 to get the required information about the movie collections and the movies, and precisely the movie added date and last time watched date. These dates are used to calculate an expiring date, and in case that the expiring date is older than the actual date, the movie will be deleted.
The default values are 30 days for a watched movie and 90 days for an unwatched movie, this means that after 30 days that a movie has been watched the last time it will be automatically deleted, and an unwatched movie after 90 days that has been added to Plex.

##Parameters
The script accepts some parameters but they are all optionals. If no parameters are passed to the script, it will delete watched movies after 30 days of the last time and unwatched movies after 90 days that have been added to Plex.
* libraries: This parameter filter the Plex libraries, if omitted, the script processes all the movies in all the libraries, otherwise only the specified one, for example to process only the "Movies" library use the following argument ```-libraries Movies```
* plex: This parameter is to change the Plex URL, if omitted, the script uses the default URL and port, which is ```http://localhost:32400```
* watched: This parameter afects only the watched movies, and it defines after how many days after the last time, that the movie has been watched, it has to be deleted. The default value is 30 days, to deleted watched movies after a week use the following arguments ```-watched 7```
* unwatched: This parameter afects only the unwatched movies, and it defines after how many days after the added date the movie has to be deleted. To never delete unwatched movies set this parameter to 0. The default value is 90 days, to never deleted unwatched movies use the following arguments ```-unwatched 0```
* test: This parameter is only to test the script without delete anything, just to check if the result is what is expected, a dry run. To activate the test mode use the following arguments ```-test 1```
 
##Installation
This script hasn't an installer, just save the script somewhere in the hard disk and execute it: ```powershell -command .\PlexRemoveOldMovies.ps1```.
To automate the process I have included a Windows scheduler task to execute the script daily at 3 o'clock in the morning. Just import the "Plex Remove Old Movies.xml" file in Windows scheduler, once imported double click on the task and change the "working directory" in the "action" panel to the folder where you have saved the script.
