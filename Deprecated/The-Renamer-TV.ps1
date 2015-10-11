<#
.Synopsis
   Performs the TV show renaming process.
.DESCRIPTION
   Processes the filename and attempts to move the file to the TVEpsDir and rename
   the file with the episode name in it.
.EXAMPLE
   Example of how to use this cmdlet
#>
function Start-TVRenamer
{
    [CmdletBinding()]
    [OutputType([int])]
    Param
    (
        # Param1 help description
        [Parameter(Mandatory=$true,Position=0)]
        [ValidateScript({$_.GetType().Name -eq 'FileInfo'})]
        $file
    ,
        [Parameter(Mandatory=$true,Position=1)]
        $dl
    )

    Process
    {
        Write-Log "`n*** Entering: $($MyInvocation.MyCommand.Name) ***" -DebugMode

        # Get the array of the filename to use for parsing. Pass the whole object of the file.
        $nameArray = Get-NameArray $file -TV

        $obj = Create-EpisodeObject $nameArray

        Rename-File $obj $dl


        Write-Log "Returning: $($obj.DestFile)" -DebugMode
        Write-Log "*** Leaving: $($MyInvocation.MyCommand.Name) ***`n" -DebugMode
        Send-Message -subject 'Download Complete' -body $obj.DestFile
    }
}

<#
.Synopsis
   Expects the title of a TV file as an array and returns a custom object with the properties.
.DESCRIPTION
   Uses regex to figure out the Series Name, Season Number and Episode number and extension.
.EXAMPLE
   Example of how to use this cmdlet
#>
function Create-EpisodeObject 
{
    PARAM
    (
        [Parameter(Mandatory=$true)]
        [ValidateScript({$_.GetType().Name -eq 'String'})]
        $array
    )
    
    Write-Log "`n*** Entering: $($MyInvocation.MyCommand.Name) ***" -DebugMode

    for ($i=0; $i -le $array.Count; $i++){
        # Find the SxxExx and we can assume that everything preceeding is the SeriesName
        If ($array[$i] -match "^S\w\wE\w\w$") {
            $SxxExx = @($array[$i] -split "[a-z]")
            $getSeasonNumber = [int]$SxxExx[1]
            $getEpisodeNumber = [int]$SxxExx[2]
            Break
        }
        $getSeriesName += " " + $array[$i]
    }
    
    $getSeriesName = $getSeriesName -replace '^ ','' # Remove leading whitespace
    $ext = $array[$array.Count -1] # Get the last piece of the array

    $prop = [ordered]@{
        'SeriesName' = $getSeriesName
        'SeasonNumber' =  $getSeasonNumber
        'EpisodeNumber' = $getEpisodeNumber
        'Extension' = $ext
    }

    $obj = New-Object -TypeName psobject -Property $prop

    # Get the full xml search results from tvDB
    $SearchResultsXml = Find-tvdbSeries -seriesName $obj.SeriesName

    # Get the series ID
    $seriesID = Select-tvdbSeriesID $searchResultsXml $obj.SeriesName
    # Get all the episode info from tvdb for the series
    $epInfoXml = Get-tvdbEpInfo -seriesID $seriesID

    $obj = Add-tvdbEpInfo -xml $epInfoXml -obj $obj
    $obj | Add-Member -Type NoteProperty -Name 'SourceFile' -Value $file.Name
    $obj | Add-Member -Type NoteProperty -Name 'SourcePath' -Value $file.DirectoryName
    $obj | Add-Member -Type NoteProperty -Name 'SourceFullPath' -Value $file.FullName
    $obj = Add-DestFileInfo $obj


    Write-Log "*** Leaving: $($MyInvocation.MyCommand.Name) ***`n" -DebugMode
    Return $obj
}

<#
.Synopsis
   Short description
.DESCRIPTION
   Long description
.EXAMPLE
   Example of how to use this cmdlet
#>
function Add-DestFileInfo 
{
    PARAM
    (
        [Parameter(Mandatory=$true)]$obj
    )

    Write-Log "`n*** Entering: $($MyInvocation.MyCommand.Name) ***" -DebugMode

    If ($obj.SeasonNumber -lt 10) { $s = "0" + $obj.SeasonNumber }
    Else { $s = $obj.SeasonNumber }
    If ($obj.EpisodeNumber -lt 10){ $e = "0" + $obj.EpisodeNumber }
    Else { $e = $obj.EpisodeNumber }

    $se = "S$s" + "E$e"
    [string]$DestFile = "$($obj.SeriesName).$se.$($obj.EpisodeName).$($obj.Extension)"
    [string]$DestPath = $TVEpsDir + "`\$($obj.SeriesName)\Season $s\"

    $obj | Add-Member -Type NoteProperty -Name 'DestFile' -Value $DestFile
    $obj | Add-Member -Type NoteProperty -Name 'DestPath' -Value $DestPath
    $obj | Add-Member -Type NoteProperty -Name 'DestFullPath' -Value $($DestPath + $DestFile)

    Write-Log "*** Leaving: $($MyInvocation.MyCommand.Name) ***`n" -DebugMode
    Return $obj
}