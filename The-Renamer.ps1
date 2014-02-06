<#
.Synopsis
   Finds video files and invokes the renamers.
.DESCRIPTION
   Searches the dir for approved video files. Based on the label, starts the proper
   renamer.
.EXAMPLE
   Example of how to use this cmdlet
#>
function Start-TheRenamer
{
    [CmdletBinding()]
    [OutputType([int])]
    Param
    (
        # The directory that contains file to rename
        [Parameter(Mandatory=$true,
                   ValueFromPipeline=$true)]
        [ValidateScript({$_.GetType().Name -eq 'DirectoryInfo'})]
        $dir
    ,
        # uTorrent info
        [Parameter(Mandatory=$true)]
        [ValidateScript({$_.GetType().Name -eq 'PSCustomObject'})]
        $dl
    )

    Process
    {
        Write-Log "`n*** Entering: $($MyInvocation.MyCommand.Name) ***" -DebugMode

        If ($dir -like $uTorrentDL) { $search = Get-ChildItem -Path $dir\* -Include $videofiletypes }
        Else { $search = Get-ChildItem -Path $dir\* -Include $videofiletypes -Recurse }

        $search | Write-Log -DebugMode

        # Get rid of files that contain 'sample' in the name are less than 100MB.
        $file = @()
        $search | foreach {
            If((!($_.Name.Contains('sample'))) -and ($_.Length -gt 104857600)) {
                $file += $_
            }
        }

        If ($file.count -eq 0) { 
            Write-Log " Count not find any approved video files in: $dir"
        } #ElseIf ($file.count -gt 1) {
          #  # Need to add functionality for multiple video files here.
          #  Write-Log " Found multiple videos files in $dir"
          #  Exit
          #} 
        Else {
            Foreach ($f in $file) {
                Write-Log " Found: $f" -DebugMode
                If ($dl.Label -eq 'TV' -or $f.Name -match "\w\.S\d\dE\d\d\.") {
                    Start-TVRenamer $f $dl
                }
                ElseIf ($dl.Label -eq 'Movie' -or $dl.Title -match "\w*20\d\d\w*" -or $dl.Title -match "\w*19\d\d\w*") {
                    Start-MovieRenamer $f $dl
                }
                Else { Write-Log " No label found for: $dir" }
                # Need to add function to search for names like Pandorum.HD.720p.XViD-WOW.avi
            }
        }
        Write-Log "*** Leaving: $($MyInvocation.MyCommand.Name) ***`n" -DebugMode
    }
}

<#
.Synopsis
   Accepts a string and finds a delimiter and then returns the array.
.DESCRIPTION
   Long description
.EXAMPLE
   Example of how to use this cmdlet
#>
function Get-NameArray 
{
    PARAM
    (
        # A string containing the title of the file.
        [Parameter(Position=0,Mandatory=$true,
                   ValuefromPipeline=$True)]
        #[ValidateScript({$_.GetType().Name -eq 'String'})]
        $file
    ,
        [switch]$TV
    ,
        [switch]$Movie
    )

    Write-Log "`n*** Entering: $($MyInvocation.MyCommand.Name) ***" -DebugMode

    $delimiters = @('\.','_','-',' ')

    # Check for the SxxExx in either the file name or the directory name.
    If ($TV) { 
        If ($file.Name -match "S\d\dE\d\d") { 
            Write-Log "   Using actual file name: $($file.Name)"
            $fileName = $file.Name
        }
        ElseIf ($file.Directory.Name -match "S\d\dE\d\d") { 
            Write-Log "   Using Directory name: $($file.Directory.Name) `
                      `n    ... instead of actual file name: $($file.name)"
            $fileName = $file.Directory.Name + $file.Extension }
    } ElseIf ($Movie) { $fileName = $file }

    foreach ($delimiter in $delimiters){
        $array = $fileName -split $delimiter
        foreach ($element in $array) {
            #$delimiter=$delimiters[$i]
            # Look for "SxxExx"
            If ($element -match "^S\d\dE\d\d$" -and ($TV)) { 
                Write-Log "  Found delimiter: $delimiter" -DebugMode
                Write-Log "  Get-NameArray :Return: $array" -DebugMode
                Write-Log "*** Leaving: $($MyInvocation.MyCommand.Name) ***`n" -DebugMode
                Return $array
            }
            # Look for the year "19xx" or "20xx"
            ElseIf (($element -match "^20\d\d$" -or $element -match "^19\d\d$") -and ($Movie)) {
                Write-Log "  Found delimiter: $delimiter" -DebugMode
                Write-Log "  Get-NameArray :Return: $array" -DebugMode
                Write-Log "*** Leaving: $($MyInvocation.MyCommand.Name) ***`n" -DebugMode
                Return $array
            }
        }
    }
    Write-Log "  Could not find delimiter or could not find SxxExx or 19xx or 20xx. Exiting...";
    Exit
}

<#
.Synopsis
   Performs the logic required for moving/copying/deleting files
.DESCRIPTION
   Expects an obj that contains all the information needed for performing the file operations.
.EXAMPLE
   Example of how to use this cmdlet
#>
function Rename-File
{
    [CmdletBinding()]
    [OutputType([int])]
    Param
    (
        # file object info containing source and destination info
        [Parameter(Mandatory=$true,Position=0)]
        $obj
    ,
        # uTorrent info
        [Parameter(Mandatory=$true,Position=1)]
        [ValidateScript({$_.GetType().Name -eq 'PSCustomObject'})]
        $dl
    )
    Process
    {
        Write-Log "`n*** Entering: $($MyInvocation.MyCommand.Name) ***" -DebugMode

        # Create the new path if it doesn't exist
        If (!(Test-Path $obj.DestPath)) {
            mkdir $obj.DestPath | Out-Null
            Write-Log "  Created directory: $($obj.DestPath)"
        }

        If (!($isDebug) -and ($obj.SourcePath -notcontains $dl.Directory)) {
            If (Test-Path $obj.DestFullPath) {
                Write-Log "  File already exists: $($obj.DestFullPath)"
                Remove-Item -Path $obj.SourcePath -Recurse
                Write-Log "  Removed directory: $($obj.SourcePath)"
            } Else {
                Write-Log "  Moving: $file `n  :to: $($obj.DestFullPath)"
                Move-Item -Path $file -Destination $obj.DestFullPath
                If (!($?)) { Write-Log "ERROR: failed to move file."; Exit }
                Write-Log "  Removing directory: $($obj.SourcePath)"
                Remove-Item -Path $obj.SourcePath -Recurse
            }
        } ElseIf (Test-Path $obj.DestFullPath) {
            Write-Log "  File exists: $($obj.DestFullPath)"
            Write-Log "  Skipping removal of: $($obj.SourcePath)"
        } Else {
            Write-Log "  Copying: $file `n   :to: $($obj.DestFullPath)"
            Copy-Item -Path $file -Destination $obj.DestFullPath
            If (!($?)) { Write-Log "ERROR: failed to copy file."; Exit }
        }
        Write-Log "*** Leaving: $($MyInvocation.MyCommand.Name) ***`n" -DebugMode
    }
}

<#
.Synopsis
   Removes illegal filename characters from string
.DESCRIPTION
   Long description
.EXAMPLE
   Example of how to use this cmdlet
.EXAMPLE
   Another example of how to use this cmdlet
#>
function Remove-IllegalCharacters
{
    [CmdletBinding()]
    [OutputType([int])]
    Param
    (
        # A string containing illegal characters
        [Parameter(Mandatory=$true,
                   ValueFromPipeline=$true,
                   Position=0)]
        [ValidateScript({$_.GetType().Name -eq 'String'})]
        $file
    )
    Process
    {
        Write-Log "`n*** Entering: $($MyInvocation.MyCommand.Name) ***" -DebugMode

        Write-Log " Original string: $file"

        $pattern = '[:*?"<>|/\\]'
        # Hardcore way, removes spaces as well.
        #$pattern = "[{0}]" -f ([Regex]::Escape([String][System.IO.Path]::GetInvalidFileNameChars()))              
        $newfile = [Regex]::Replace($file, $pattern, '')

        Write-Log " New string: $newfile"
        Write-Log "*** Leaving: $($MyInvocation.MyCommand.Name) ***`n" -DebugMode
        Return $newfile
    }
}