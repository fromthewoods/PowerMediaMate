<#
.Synopsis
   Short description
.DESCRIPTION
   Long description
.EXAMPLE
   Example of how to use this cmdlet
#>

Param
(
    [alias("f")]$Name
,
    [alias("d")]$Dir
,
    [alias("n")]$Title
,
    [alias("p")]$PreviousState
,
    [alias("l")]$Label
,
    [alias("t")]$Tracker
,
    [alias("m")]$StatusMessage
,
    [alias("i")]$HexInfoHash
,
    [alias("s")]$State
,
    [alias("k")]$Kind
)

#Locate the invocation directory and cd to it to be able to load local functions.
$Global:here = Split-Path -Parent $MyInvocation.MyCommand.Path

$Global:moduleName = "PowerMediaMate"
Import-Module $Global:here\$Global:moduleName.psd1 -Force

# Set up the log file name.
$date = Get-Date -UFormat %Y-%m-%d_%H-%M-%S
$Global:log = "$logLocation\$date`_$Title.log"
Check-Dependencies

Write-Log "########## STARTING JOB ##########" -Stamp # Make the log pretty
Write-Log " Name: $Name `
         `n Dir: $Dir `
         `n Title: $Title `
         `n Previous State: $PreviousState `
         `n Label: $Label `
         `n Tracker: $Tracker `
         `n StatusMessage: $StatusMessage `
         `n HexInfoHash: $HexInfoHash `
         `n State: $State `
         `n Kind: $Kind"
Write-Log "########## ############ ##########" -Stamp

$prop = [ordered]@{
    'Title' = $Title
    'Label' = $Label
    'Directory' = $Dir
    'TempExtractPath' = $tempExtractPath
    
}

$dl = New-Object -TypeName psobject -Property $prop

$dl | Get-Sfv | Test-SfvLog | Find-RarFile | Extract-File # | Start-TheRenamer -dl $dl