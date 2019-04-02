<#
.SYNOPSIS
Powershell script to remove old movies from the hard disk and consequently from PLEX

.DESCRIPTION
This powershell script scans PLEX for movies added since X days and remove them to save space on the hard drive and to have shorted list of only recently add movies in PLEX

.PARAMETER libraries
A list of PLEX libraries, which will be scanned for new movies, if omitted all the libraries will be scanned.

.PARAMETER plex
The URL of PLEX, if omitted it will be used the default URL http://localhost:32400, which is the URL of the local instance of PLEX

.PARAMETER watched
The number of the days after them a movie will be removed if it has been watched, if omitted it will be used the default value of 30 days

.PARAMETER unwatched
The number of the days after them a movie will be removed if it hasn't been watched yet, if omitted it will be used the default value of 90 days

.PARAMETER token
Authentication token to access PLEX WEB API, required if the origin IP has not be added to the list of the allowed networks without authentication.
For more information about authentication token and allowed network without authentication follow those links:
https://support.plex.tv/hc/en-us/articles/200890058-Require-authentication-for-local-network-access
https://support.plex.tv/hc/en-us/articles/204059436-Finding-an-authentication-token-X-Plex-Token

.PARAMETER test
If test is active no file will be deleted, it is more a debug parameter

.EXAMPLE
./PlexRemoveOldMovies.ps1
It deletes from all the libraries of PLEX all watched movies that have been added more than 30 days ago and all the unwatched movies that have been added more than 90 days ago

.EXAMPLE
./PlexNewAddedMovies.ps1 -libraries Series -watched 5 -unwatched 10
It deletes from from the library Series all watched movies that have been added more than 5 days ago and all the unwatched movies that have been added more than 10 days ago

.LINK
https://github.com/aquilax1/Plex-Remove-Old-Movies
#>
param([String[]] $libraries, [String] $plex="http://localhost:32400", [Int] $watched=30, [Int] $unwatched=30, [string] $token, [Switch] $test)

Function Convert-FromUnixdate ($UnixDate) { if ($UnixDate -eq $Null) { $Null } else {(get-date "1/1/1970").AddSeconds($UnixDate) }}

$web=New-Object System.Net.WebCLient
$doc=New-Object System.Xml.XmlDocument

if ($test) { write-host (get-date) "Test mode is active, nothing will be deleted" }
#replace 127.0.0.1 and localhost with the machine ip because otherwiese plex returns a 401 access deneied
$plex=$plex -replace "localhost|127\.0\.0\.1", ((ipconfig | findstr [0-9].\.)[0]).Split()[-1]
#if the token is available, prepare it to be added at the end of each request
if (-not [String]::IsNullOrEmpty($token)) { $token="?X-Plex-Token="+$token }
#get all the library and filter them if $libraries is defined
$dirs=([xml]$web.DownloadString($plex+"/library/sections"+$token)).MediaContainer.Directory | where {$libraries -eq $Null -or $libraries -contains $_.title }
#get all  the movies of the libraries, 
$movies=$dirs | foreach{([xml]$web.DownloadString(($plex+"/library/sections/{0}/all"+$token) -F $_.key)).MediaContainer.Video | where {$_.type -eq "movie"} | select -p title, @{Name="watched"; Expression={$_.viewCount -gt 0}}, @{Name="addedAt"; Expression={Convert-FromUnixdate($_.addedAt)}}, @{Name="lastViewedAt"; Expression={Convert-FromUnixdate($_.lastViewedAt)}} , @{Name="path"; Expression={(split-path -Path ([System.Uri]::UnescapeDataString(([Array]$_.Media)[0].Part.file)))}} }
#calculate the expires dates for watched and unwatched movies
$movies=$movies | select -p *, @{Name="expires"; Expression={ if ($_.watched) { $_.lastViewedAt.AddDays($watched).Date } elseif ($unwatched -gt 0) { $_.addedAt.AddDays($unwatched).Date } else {$Null} }} 
#get all expired movies
$today=(get-date).Date
$movies=$movies | where {$_.expires -ne $Null -and $_.expires -le $today}
if ($movies -eq $Null) { write-host (get-date) "There are no expired movies in the libraries" }
else
{
	$movies | foreach{ write-host (get-date) added at $_.addedAt.ToString("d") watched $_.watched expires at $_.expires.ToString("d") deleting $_.title; if (!$test) { try { remove-item -recurse -force -LiteralPath $_.path } catch {  Write-Host (get-date) "Error:" $_.Exception.Message } } }
	write-host (get-date) "Refresh all libraries"
	$dirs | foreach{ $text=$web.DownloadString(($plex+"/library/sections/{0}/refresh"+$token) -F $_.key) }
}
