<#
.Synopsis
   Searches a given directory for any rar files.
.DESCRIPTION
   Includes a recurse switch. If one file is found, this function returns a FileSystem
   object. If multiple files are found it returns an array of fileSystem objects. If no 
   rar files are found it returns false.
.EXAMPLE
   Find-RarFile <directory> -Recurse
#>
function Find-RarFile
{
    [CmdletBinding()]
    [OutputType([int])]
    Param
    (
        # A directory that may contain rar files.
        [Parameter(Mandatory=$true,
                   ValueFromPipeline=$true,
                   Position=0)]
        [ValidateScript({$_.GetType().Name -eq 'DirectoryInfo'})]
        $dir
    ,
        [switch]$Recurse
    )

    Process
    {
        If ($Recurse) { $rar = Get-ChildItem -Path $dir -Filter *.rar -Recurse }
        Else { $rar = Get-ChildItem -Path $dir -Filter *.rar }
        
        If ($rar) { Return $rar } 
        Else { Write-Log "No rar files to analyze in: $dir"; Return Get-Item $dir }
    }
}

<#
.Synopsis
   Executes 7-zip on a rar file.
.DESCRIPTION
   Executes 7-Zip on a rar file and extracts the contained files to a temp location.
   Then it returns the directory where the files were extracted to. If it receives 
   a directory object, then it simply passes it back to the pipeline.
.EXAMPLE
   Example of how to use this cmdlet
.EXAMPLE
   Another example of how to use this cmdlet
#>
function Extract-File
{
    [CmdletBinding()]
    [OutputType([int])]
    Param
    (
        # Rar file system object or a the directory where no rar's exist
        [Parameter(Mandatory=$true,
                   ValueFromPipeline=$true,
                   Position=0)]
        [ValidateScript({($_.GetType().Name -eq 'FileInfo') -or
                         ($_.GetType().Name -eq 'DirectoryInfo')})]
        $item
    )

    Process
    {
        If ($item.GetType().Name -eq 'FileInfo') {
            $extractLog = "$env:TEMP\PMM.$($item.Directory.Name).log"
            $destPath = "$tempExtractPath`\$($item.Directory.Name)"
            $output = "-o$destPath"
	
	        # Create the destination if it doesn't exist
	        If (!(Test-Path $destPath)) {
    		    Write-Log "Creating: $destPath"
	    	    New-Item -ItemType Directory $destPath | Out-Null
	        }
		    # Extraction!!
		    Write-Log "Starting 7-zip"
		    sz x -aos "$($item.FullName)" $output 2>&1 | Out-file -FilePath $extractLog
            If (Read-ExtractLog $extractLog) { Return Get-Item $destPath }
            Else { Exit }
        } Else { Return $item }
    }
}

<#
.Synopsis
   Short description
.DESCRIPTION
   Long description
.EXAMPLE
   Example of how to use this cmdlet
.EXAMPLE
   Another example of how to use this cmdlet
#>
function Read-ExtractLog
{
    [CmdletBinding()]
    [OutputType([int])]
    Param
    (
        # Param1 help description
        [Parameter(Mandatory=$true,
                   ValueFromPipeline=$true,
                   Position=0)]
        [ValidateScript({$_.GetType().Name -eq 'String'})]
        $File
    )

    Process
    {
        $logFile = Get-Item $File
		If (Test-Path -PathType Leaf $logFile){ 
            # Write the contents of the extract log to the "log".
			Get-Content -Path $logFile | Foreach {
				If (($_) -and !($_ -match "7-zip")) { Write-Log "  $_"}
            }
            If (Select-String -SimpleMatch "Everything is Ok" $logFile) { 
                #$output = $(Select-String -SimpleMatch "Extracting*" $logFile) -split ' '
                Remove-Item -Path $logFile
                Return $true
            } Else { Write-Log "ERROR: Extraction Failed."; Return $false }
 		} Else { Write-Log "Could not find: $logFile"; Return $false }
    }
}