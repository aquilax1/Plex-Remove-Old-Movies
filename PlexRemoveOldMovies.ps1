param([String[]] $libraries, [String] $plex="http://localhost:32400", [Int] $watched=30, [Int] $unwatched=90, [Boolean] $test=$False)
Function Convert-FromUnixdate ($UnixDate) { if ($UnixDate -eq $Null) { $Null } else {(get-date "1/1/1970").AddSeconds($UnixDate) }}
$web=New-Object System.Net.WebCLient
$doc=New-Object System.Xml.XmlDocument
if ($test) { write-host (get-date) "Test mode is active, nothing will be deleted" }
#get all the library and filter them if $libraries is defined
$dirs=([xml]$web.DownloadString($plex+"/library/sections")).MediaContainer.Directory | where {$libraries -eq $Null -or $libraries -contains $_.title }
#get all  the movies of the libraries, 
$movies=$dirs | foreach{([xml]$web.DownloadString(($plex+"/library/sections/{0}/all") -F $_.key)).MediaContainer.Video | where {$_.type -eq "movie"} | select -p title, @{Name="watched"; Expression={$_.viewCount -gt 0}}, @{Name="addedAt"; Expression={Convert-FromUnixdate($_.addedAt)}}, @{Name="lastViewedAt"; Expression={Convert-FromUnixdate($_.lastViewedAt)}} , @{Name="path"; Expression={(split-path -Path ([System.Uri]::UnescapeDataString($_.Media.Part.file)))}} }
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
	$dirs | foreach{ $text=$web.DownloadString(($plex+"/library/sections/{0}/refresh") -F $_.key) }
}