function Get-InstalledApp {
<#
.Synopsis
   Outputs installed applications on one or more computers that match one or more criteria.
.DESCRIPTION
   Long description
.EXAMPLE
   Get-InstalledApp -AppID '7-Zip'
.EXAMPLE
   Get-InstalledApp -AppName '*7-Zip*'
.LINK
   http://windowsitpro.com/powershell/what-applications-are-installed-computers-your-network
#>
# Written by Bill Stewart (bstewart@iname.com)
#
# Outputs installed applications on one or more computers that match one or
# more criteria.

    param([String[]] $ComputerName,
          [String] $AppID,
          [String] $AppName,
          [String] $Publisher,
          [String] $Version,
          [Switch] $MatchAll,
          [Switch] $Help
         )
    
    $HKLM = [UInt32] "0x80000002"
    $UNINSTALL_KEY = "SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall"
    
    # Outputs a usage message and ends the script.
    function usage {
      $scriptname = $SCRIPT:MYINVOCATION.MyCommand.Name
    
      "NAME"
      "    $scriptname"
      ""
      "SYNOPSIS"
      "    Outputs installed applications on one or more computers that match one or"
      "    more criteria."
      ""
      "SYNTAX"
      "    $scriptname [-computername <String[]>] [-appID <String>]"
      "    [-appname <String>] [-publisher <String>] [-version <String>] [-matchall]"
      ""
      "PARAMETERS"
      "    -computername <String[]>"
      "        Outputs applications on the named computer(s). If you omit this"
      "        parameter, the local computer is assumed."
      ""
      "    -appID <String>"
      "        Select applications with the specified application ID. An application's"
      "        appID is equivalent to its registry subkey in the location"
      "        HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall. For Windows"
      "        Installer-based applications, this is the application's product code"
      "        GUID (e.g. {3248F0A8-6813-11D6-A77B-00B0D0160060})."
      ""
      "    -appname <String>"
      "        Select applications with the specified application name. The appname is"
      "        the application's name as it appears in the Add/Remove Programs list."
      ""
      "    -publisher <String>"
      "        Select applications with the specified publisher name."
      ""
      "    -version <String>"
      "        Select applications with the specified version."
      ""
      "    -matchall"
      "        Output all matching applications instead of stopping after the first"
      "        match."
      ""
      "NOTES"
      "    All installed applications are output if you omit -appID, -appname,"
      "    -publisher, and -version. Also, the -appID, -appname, -publisher, and"
      "    -version parameters all accept wildcards (e.g., -version 5.2.*)."
    
      exit
    }
    
    function main {
      # If -help is present, output the usage message.
      if ($Help) {
        usage
      }
    
      # Create a hash table containing the requested application properties.
      #CALLOUT A
      $propertyList = @{}
      if ($AppID -ne "")     { $propertyList.AppID = $AppID }
      if ($AppName -ne "")   { $propertyList.AppName = $AppName }
      if ($Publisher -ne "") { $propertyList.Publisher = $Publisher }
      if ($Version -ne "")   { $propertyList.Version = $Version }
      #END CALLOUT A
    
      # Use the local computer's name if no computer name(s) specified.
      if ($ComputerName -eq $NULL) {
        $ComputerName = $ENV:COMPUTERNAME
      }
    
      # Iterate the computer name(s).
      foreach ($machine in $ComputerName) {
        $err = $NULL
    
        # If WMI throws a RuntimeException exception,
        # save the error and continue to the next statement.
        #CALLOUT B
        trap [System.Management.Automation.RuntimeException] {
          set-variable err $ERROR[0] -scope 1
          continue
        }
        #END CALLOUT B
    
        # Connect to the StdRegProv class on the computer.
        #CALLOUT C
        $regProv = [WMIClass] "\\$machine\root\default:StdRegProv"
    
        # In case of an exception, write the error
        # record and continue to the next computer.
        if ($err) {
          write-error -errorrecord $err
          continue
        }
        #END CALLOUT C
    
        # Enumerate the Uninstall subkey.
        $subkeys = $regProv.EnumKey($HKLM, $UNINSTALL_KEY).sNames
        foreach ($subkey in $subkeys) {
          # Get the application's display name.
          $name = $regProv.GetStringValue($HKLM,
            (join-path $UNINSTALL_KEY $subkey), "DisplayName").sValue
          # Only continue of the application's display name isn't empty.
          if ($name -ne $NULL) {
            # Create an object representing the installed application.
            $output = new-object PSObject
            $output | add-member NoteProperty ComputerName -value $machine
            $output | add-member NoteProperty AppID -value $subkey
            $output | add-member NoteProperty AppName -value $name
            $output | add-member NoteProperty Publisher -value `
              $regProv.GetStringValue($HKLM,
              (join-path $UNINSTALL_KEY $subkey), "Publisher").sValue
            $output | add-member NoteProperty Version -value `
              $regProv.GetStringValue($HKLM,
              (join-path $UNINSTALL_KEY $subkey), "DisplayVersion").sValue
    
            $output | add-member NoteProperty InstallLocation -value `
              $regProv.GetStringValue($HKLM,
              (join-path $UNINSTALL_KEY $subkey), "InstallLocation").sValue
    
            $output | add-member NoteProperty UninstallString -value `
              $regProv.GetStringValue($HKLM,
              (join-path $UNINSTALL_KEY $subkey), "UninstallString").sValue
            # If the property list is empty, output the object;
            # otherwise, try to match all named properties.
            if ($propertyList.Keys.Count -eq 0) {
              $output
            } else {
              #CALLOUT D
              $matches = 0
              foreach ($key in $propertyList.Keys) {
                if ($output.$key -like $propertyList.$key) {
                  $matches += 1
                }
              }
              # If all properties matched, output the object.
              if ($matches -eq $propertyList.Keys.Count) {
                $output
                # If -matchall is missing, break out of the foreach loop.
                if (-not $MatchAll) {
                  break
                }
              }
              #END CALLOUT D
            }
          }
        }
      }
    }
    
    main
}

function Get-SevenZip {
<#
.Synopsis
   Returns the location of 7z.exe, if detected. Otherwise it returns false.
#>

    Try
    {
        #. .\Get-InstalledApp.ps1
    	$SevenZip = Get-InstalledApp -AppName '*7-Zip*'
        If ($SevenZip.InstallLocation)
        {
            $SevenZip = $SevenZip.InstallLocation + '7z.exe'
        }
        ElseIf (Get-Item -Path HKLM:\SOFTWARE\7-Zip)
        {
            $SevenZip = (Get-ItemProperty -Path HKLM:\SOFTWARE\7-Zip -Name Path).Path + '7z.exe'
        }
        Else { $SevenZip = $false }

        Return $SevenZip
    }
    Catch
    {
        Write-Log "ERROR: $($_.Exception.Message)"
        Write-Log "ERROR: $($_.InvocationInfo.PositionMessage.Split('+')[0])"
        Exit 1
    } 
}

function Get-QuickSfv {
<#
.Synopsis
   Returns the location of QuickSfv.exe, if detected. Otherwise it returns false.
#>

    Try
    {
        $regkey = Get-ItemProperty -Path HKLM:\SOFTWARE\Classes\File_Verification_Database\DefaultIcon -ErrorAction SilentlyContinue
        If ($regkey)
        {
            $Quicksfv = $regkey.'(default)'.split(',')[0]
        } 
        Else { $Quicksfv = $false }

        Return $Quicksfv
    }
    Catch
    {
        Write-Log "ERROR: $($_.Exception.Message)"
        Write-Log "ERROR: $($_.InvocationInfo.PositionMessage.Split('+')[0])"
        Exit 1
    }
}

function Get-Dependencies {
<#
.Synopsis
   Short description
.DESCRIPTION
   Long description
.EXAMPLE
   Example of how to use this cmdlet
#>

    Try
    {
        $allDependenciesArePresent = $true

        #region ~~~~~ Detect 7z.exe ~~~~~~~~~~~~~~~~~~~~~~~
        $SevenZip = Get-SevenZip
        If ($SevenZip -eq $false)
        {
            $allDependenciesArePresent = $false
        }
        ElseIf (-not (Test-Path -Path $SevenZip -ErrorAction SilentlyContinue))
        {
            $allDependenciesArePresent = $false
        }
        #endregion ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

        #region ~~~~~ Detect QuickSFV.exe ~~~~~~~~~~~~~~~~~
        $Quicksfv = Get-QuickSFV
        If (!$Quicksfv)
        {
            $allDependenciesArePresent = $false
        }
        ElseIf (-not (Test-Path -Path $Quicksfv -ErrorAction SilentlyContinue))
        {
            $allDependenciesArePresent = $false
        }
        #endregion ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

        If ($allDependenciesArePresent)
        {
            New-Object -TypeName psobject -Property { SevenZip = $SevenZip
                                                      QuickSfv = $Quicksfv }
        }
        Else { $false }
    }
    Catch
    {
        Write-Log "ERROR: $($_.Exception.Message)"
        Write-Log "ERROR: $($_.InvocationInfo.PositionMessage.Split('+')[0])"
        Exit 1
    } 
}

function Get-Sfv {
    <#
    .Synopsis
       Searches a given directory for any sfv files.
    .DESCRIPTION
       Includes a recurse switch. Searches in a given directory for any sfv files. If only one sfv
       file is found it returns the System.IO.FileSystemInfo object of the found file. If multiple 
       sfv files are found then this function returns an array of FileSystemInfo objects. If no 
       sfv files are found it returns false.
    .EXAMPLE
       Get-Sfv <directoryname>
    #>
    
    [CmdletBinding()]
    Param
    (
        # The directory to scan for .sfv files
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true)]
        [ValidateScript({$_.GetType().Name -eq 'String'})]
        $Directory
    )

    If (Test-Path -PathType Container $Directory)
    {
        # Looking for a download in the base uTorrent directory
        If ($Directory -like $uTorrentDL)
        {
            $objSFV = Get-ChildItem -Path $Directory -Filter *.sfv
        }
        Else
        {
            $objSFV = Get-ChildItem -Path $Directory -Filter *.sfv -Recurse
        }

        If ($objSFV)
        {
            Return $objSFV
        }
        Else
        {
            Write-Log "No sfv files to analyze in: $Directory"
            Return Get-Item $Directory
        }
    }
    Else
    {
        Write-Log "Could not find the directory: $Directory"
        Exit
    }
}

function Test-SfvLog {
    <#
    .Synopsis
       Look in the log file for the sfv for a success or failure
    .DESCRIPTION
       If success is found then return the directory of the sfv that was evaluated. If not
       successful, then return false. If the log isn't found, then invoke the Sfv so it can
       be evaluated.
    .EXAMPLE
       Test-SfvLog <log.Fullname>
    #>
    
    [CmdletBinding()]
    Param
    (
        # The sfv file to be evaluated.
        [Parameter(Mandatory=$true,
                   ValueFromPipeline=$true,
                   Position=0)]
        [ValidateScript({($_.GetType().Name -eq 'FileInfo') -or
                         ($_.GetType().Name -eq 'DirectoryInfo')})]
        $item
    ,
        [Parameter(Mandatory=$true,
                   ValueFromPipeline=$false,
                   Position=1)]
        [string]$sfvLogsDir
    )

    Process
    {
        If ($item.GetType().Name -eq 'FileInfo')
        {
            $sfvLog = "$sfvLogsDir`\$($item.Name).txt"

            If (Test-Path -PathType Leaf $sfvLog)
            {
                $sfvLog = Get-Item $sfvLog
	    	    If (Select-String -SimpleMatch "All files OK" $sfvLog)
                {
    	    		Write-Log "Evaluation SUCCEEDED for: $($sfvLog.Name)" -Stamp
			        Return $item.Directory
		        }
                Else
                {
			        Write-Log "Evaluation FAILED for: $($sfvLog.Name)" -Stamp
                    Send-Message -subject "Evaluation FAILED for:" -body $sfvLog.Name
    			    Exit
		        }
	        }
            Else
            {
                Invoke-Sfv $item $sfvLog
            }
        }
        Else
        {
            Return $item
        }
    }
}

function Invoke-Sfv {
<#
.Synopsis
   Execute QuickSFV on a given sfv file and write the results to a file.
.DESCRIPTION
   Given an Sfv file, execute QuickSfv on it with the output logged to a 
   file. If the log is successfull created then pass back to Read-SfvLog.
.EXAMPLE
   Invoke-Sfv <sfv file> <sfv log file>
#>
    [CmdletBinding()]
    [OutputType([int])]
    Param
    (
        # The sfv file to be evaluated.
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=0)]
        $file,

        # The location of the log file.
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=1)]
        $sfvLog
    )

    Process
    {
        [string]$arguments = "`"$($file.FullName)`" OUTPUT:`"$sfvLog`""

        Write-Log "Evaluating SFV: $file" -Stamp
	    Start-Process -NoNewWindow -Wait -FilePath $QuickSFV -ArgumentList $arguments

        If (Test-Path $sfvLog) { Read-SfvLog $file }
        Else { Write-Log "  Could not find the sfv log: $sfvLog `n  Probably failed to evaluate the sfv file."; Exit }
    }
}

function Find-RarFile {
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

function Extract-File {
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

function Read-ExtractLog {
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