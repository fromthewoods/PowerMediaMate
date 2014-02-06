<#
.Synopsis
   Short description
.DESCRIPTION
   Processes the filename and attempts to move the file to the MoviesDir and
   rename the file.
.EXAMPLE
   Example of how to use this cmdlet
#>

function Start-MovieRenamer 
{
    PARAM
    (
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=0)]
        [ValidateScript({$_.GetType().Name -eq 'FileInfo'})]
        $file
    ,
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=1)]
        $dl
    )

    Process
    {
        Write-Log "`n*** Entering: $($MyInvocation.MyCommand.Name) ***" -DebugMode

        # Get the move file name array
        $movieArray = Get-NameArray $dl.Title -Movie
        # Get the name of the movie to search for
        $searchObj = Create-SearchMovieObject $movieArray $file
        # Get the JSON results from tmdb
        $resultObj = Find-tmdbMovie -query $searchObj.SearchTitle

        $obj = Select-Movie $searchObj $resultObj
        
        Rename-File $obj $dl
        ########Create-Links $obj

        Write-Log "Returning: $($obj.DestFile)" -DebugMode
        Write-Log "*** Leaving: $($MyInvocation.MyCommand.Name) ***`n" -DebugMode
        Send-Message -subject 'Download Complete' -body $obj.DestFile
    }
}

<#
.Synopsis
   Creates an object out of the array of the title
.DESCRIPTION
   Parses the source file name array and returns an object.
.EXAMPLE
   Example of how to use this cmdlet
#>
function Create-SearchMovieObject
{
    PARAM
    (
        [Parameter(Mandatory=$true,
                   Position=0,
                   ValuefromPipeline=$True)]
        [ValidateScript({$_.GetType().Name -eq 'String'})]
        $array
     ,   
        # File item for Movie extension
        [Parameter(Position=1)]
        [ValidateScript({$_.GetType().Name -eq 'FileInfo'})]
        $file
    )

    Process
    {
        Write-Log "`n*** Entering: $($MyInvocation.MyCommand.Name) ***" -DebugMode

        for ($i=0; $i -le $array.Count; $i++){
            # Find the year "19xx" or "20xx" and we can assume everything preceeding is the move Name
            If (($array[$i] -match "^20\d\d$") -or ($array[$i] -match "^19\d\d$")) { 
                [string]$MovieYear = $array[$i]
                Break
            }
            $MovieName += " " + $array[$i]
        }
        $MovieName = $MovieName -replace '^ ','' # Remove leading whitespace
        #$ext = $array[$array.Count -1] # Get the last piece of the array

        $prop = [ordered]@{
            'SearchTitle'   = $MovieName
            'SearchYear'    = $MovieYear
            'SourceFile'    = $file.Name
            'SourcePath'    = $file.DirectoryName
            'SourceFullPath'= $file.FullName
            'Extension'     = $file.Extension
        }
        $obj = New-Object -TypeName psobject -Property $prop
        Write-Log "*** Leaving: $($MyInvocation.MyCommand.Name) ***`n" -DebugMode
        Return $obj
    }
}

<#
.Synopsis
   Short description
.DESCRIPTION
   Long description
.EXAMPLE
   Example of how to use this cmdlet
#>
function Select-Movie
{
    [CmdletBinding()]
    [OutputType([int])]
    Param
    (
        # Param1 help description
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=0)]
        [ValidateScript({$_.GetType().Name -eq 'PSCustomObject'})]
        $searchObj,

        # Param2 help description
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=1)]
        [ValidateScript({$_.GetType().Name -eq 'PSCustomObject'})]
        $resultObj
    )

    Process
    {
        Write-Log "`n*** Entering: $($MyInvocation.MyCommand.Name) ***" -DebugMode

        If ($resultObj.total_results -gt 1) {
            Foreach ($r in $resultObj.results) {
                If (($r.title -eq $searchObj.SearchTitle) -and ($r.release_date.Contains($($searchObj.searchYear)))) {
                    Write-Log "Match: $($r.title) -eq $($searchObj.SearchTitle)" -DebugMode
                    Write-Log "Match: $($r.release_date) -contains $($searchObj.searchYear)" -DebugMode
                    $movieTitle = Remove-IllegalCharacters $r.title
                    $prop = [ordered]@{
                        'SearchTitle'   = $searchObj.SearchTitle
                        'SearchYear'    = $searchObj.searchYear
                        'Title'         = $r.title
                        'id'            = $r.id
                        'ReleaseDate'   = $r.release_date
                        #'Genres'        = $(Get-tmdbMovie -movieID $($r.id)).Genres
                        'Extension'     = $searchObj.Extension
                        'SourceFile'    = $searchObj.SourceFile
                        'SourcePath'    = $searchObj.SourcePath
                        'SourceFullPath'= $searchObj.SourceFullPath
                        'DestFile'      = "$($movieTitle)$($searchObj.Extension)"
                        'DestPath'      = "$MoviesDir`\$($movieTitle) ($($searchObj.searchYear))`\"
                        'DestFullPath'  = "$MoviesDir`\$($movieTitle) ($($searchObj.searchYear))`\$($searchObj.SourceFile)"
                    }
                    $obj = New-Object -TypeName psobject -Property $prop
                    Write-Log "*** Leaving: $($MyInvocation.MyCommand.Name) ***`n" -DebugMode
                    Return $obj
                }
            }
            Write-Log "Could not find an exact match for: $($searchObj.SearchTitle) and: $($searchObj.searchYear)"
            Exit
        } Else {
            $movieTitle = Remove-IllegalCharacters $resultObj.results.title
            $prop = [ordered]@{
                'SearchTitle  ' = $searchObj.SearchTitle
                'SearchYear'    = $searchObj.searchYear
                'Title'         = $resultObj.results.title
                'id'            = $resultObj.results.id
                'ReleaseDate'   = $resultObj.results.release_date
                #'Genres'        = $(Get-tmdbMovie -movieID $($resultObj.results.id)).Genres
                'Extension'     = $searchObj.Extension
                'SourceFile'    = $searchObj.SourceFile
                'SourcePath'    = $searchObj.SourcePath
                'SourceFullPath'= $searchObj.SourceFullPath
                'DestFile'      = "$movieTitle$($searchObj.Extension)"
                'DestPath'      = "$MoviesDir`\$movieTitle ($($searchObj.searchYear))`\"
                'DestFullPath'  = "$MoviesDir`\$movieTitle ($($searchObj.searchYear))`\$($searchObj.SourceFile)"
            }
            $obj = New-Object -TypeName psobject -Property $prop
            Write-Log "*** Leaving: $($MyInvocation.MyCommand.Name) ***`n" -DebugMode
            Return $obj
        }
    }
}