<#
.Synopsis
   Checks for the Dependencies required for this script.
.DESCRIPTION
   Runs through a list of checks required to allow this script to run properly.
#>
Function Check-Dependencies { 
    Write-Log "*** Entering: $($MyInvocation.MyCommand.Name) ***" -DebugMode

    # Check for PowerShell v3
    If ((Get-Host).Version.Major -lt 3) { Write-Log "ERROR: PowerShell 3 is required."; Exit }

	# Check for 7-Zip
    Set-Alias sz $SevenZip -Scope Global
	If (!(Test-Path $SevenZip)) {Write-Log "ERROR: Could not find 7z.exe at $SevenZip"; Exit}

	# Check for QuickSFV
	If (!(Test-Path $QuickSFV)) {Write-Log "ERROR: Could not find QuickSFV.exe at $QuickSFV"; Exit}

    #Create the SFV output dir
    If (!(Test-Path $sfvLogsDir)) { Write-Log "Creating $sfvLogsDir"; mkdir $sfvLogsDir | Out-Null }

    #Create the output dir
    If (!(Test-Path $tempExtractPath)) { Write-Log "Creating $tempExtractPath"; mkdir $tempExtractPath | Out-Null }
    
    Write-Log "Dependency check passed." -DebugMode
}

<#
.Synopsis
   Logs the passed "message" to a designated log file.
.DESCRIPTION
   Accepts a string input as a message and outputs it into a log file. If the log file
   doesn't exist, it will create it. If the stamp param is passed it will prefix with
   the time stamp. If debug mode is false it will skip writing to the log. If the log
   gets bigger than 1MB it will roll it rename it and append the current date.
.EXAMPLE
   Write-Log "This is a message" -Stamp
#>
Function Write-Log 
{
	[cmdletBinding()]
	Param
    (
        [Parameter(Position=0,
                   ValueFromPipeline=$true)]
        [ValidateNotNullOrEmpty()]
        $Message
    ,
        [switch]$Stamp
    ,
        [switch]$DebugMode
    )
    
    Begin
    {
        #Create log file if it doesn't exist
        If (!(Test-Path $log)) { 
            If (!(Test-Path $logLocation)) { mkdir $logLocation | Out-Null }
            New-Item $log -ItemType "file"
        }
    }
    Process
    { 
        If ((!($DebugMode)) -or ($DebugMode -and $isDebug)) {
            # Add the time stamp if specified
            If ($Stamp) { $Message = "$(Get-Date) $Message" }
            # Write to the log
            Write-Host "$Message"
            Write-Output "$Message" | Out-File -FilePath $log -Append
        }
    }
    End
    {
        # Roll the log over if it gets bigger than 1MB
        $date = Get-Date -UFormat -%Y-%m-%d
	    If ((Get-ChildItem $log).Length -gt 1048576) {
		    Rename-Item -Path $log -NewName "$($MyInvocation.MyCommand.Name)-$date.log"
	    }
    }
}

<#
.Synopsis
   Sends a text
.DESCRIPTION
   Long description
.EXAMPLE
   Example of how to use this cmdlet
#>
function Send-Message
{
    [CmdletBinding()]
    [OutputType([int])]
    Param
    (
        # The name of the file that is ready
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=0)]
        $subject
    ,
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=1)]
        $body
    )

    Process
    {
        Write-Log "`n*** Entering: $($MyInvocation.MyCommand.Name) ***" -DebugMode
        Send-MailMessage -To $emailTo -From $emailFrom -Subject $subject -Body $body -SmtpServer $smtpServer
        Write-Log "Sent completion message to: $emailTo"
        Write-Log "*** Leaving: $($MyInvocation.MyCommand.Name) ***`n" -DebugMode
    }
}