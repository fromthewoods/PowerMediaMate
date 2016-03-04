$here = Split-Path -Parent $MyInvocation.MyCommand.Path

$moduleName = "PowerMediaMate"
Import-Module $here\$moduleName.psd1 -Force
Import-Module ..\Write-Log\Write-Log.psd1 -Force


#region ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ SETUP ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# uTorrent cmd line:
# C:\Windows\System32\WindowsPowerShell\v1.0\Powershell.exe -ExecutionPolicy Bypass -WindowStyle Hidden  -file "D:\Git\PowerMediaMate\_Start.ps1" -Name "%F" -Dir "%D" -Title "%N" -PreviousState "%P" -Label "%L" -Tracker "%T" -StatusMessage "%M" -HexInfoHash "%I" -State "%S" -Kind "%K"




$expected = @()
$prop = [ordered]@{
    Name          = "blow-mad.max.fury.road.2015.720p.bluray.x264.jpg"      
    Dir           = "TestDrive:\Downloads\Mad.Max.Fury.Road.2015.720p.BluRay.x264-BLOW"
    Title         = "Mad.Max.Fury.Road.2015.720p.BluRay.x264-BLOW"
    PreviousState = "5"
    Label         = "Movie"
    Tracker       = "http://announce.torrentday.com:60000/26e41edb869914982de746b113f1a173/announce"
    StatusMessage = "Initial-Seeding"
    HexInfoHash   = "B0789868229ED838C9D624BDA0CAA7AAB5F6D536"
    State         = "5"
    Kind          = "multi"
}
$expected += (New-Object PSObject -Property $prop)

# Create fake SFV eval file


#endregion

Describe -Tags 'DP' 'Get-SevenZip' {
    InModuleScope -ModuleName $moduleName {
        # Overwrite Write-Log while in testing
        Mock -CommandName Write-Log -MockWith { Write-Host $args[1] }
		#Mock -CommandName Write-Log -MockWith {} 

        Mock -CommandName Get-InstalledApp -MockWith { New-Object -TypeName psobject -Property @{AppID = '7-Zip'; InstallLocation = 'D:\derp\' } }
        It 'Should return a fake location' {
            Get-SevenZip | Should Be 'D:\derp\7z.exe'
        }

        Mock -CommandName Get-InstalledApp -MockWith { Return $null }
        Mock -CommandName Get-Item -MockWith { Return $true }
        Mock -CommandName Get-ItemProperty -MockWith { New-Object -TypeName psobject -Property @{ Path = 'D:\derp\'} }
        It 'Should return a fake location' {
            Get-SevenZip | Should Be 'D:\derp\7z.exe'
        }

        Mock -CommandName Get-InstalledApp -MockWith { Return $null }
        Mock -CommandName Get-Item -MockWith { Return $null }
        It 'Should return false.' {
            Get-SevenZip | Should Be $false
        }
    }
} 

#Describe -Tags "DP" "Get-Dependencies" {
#    InModuleScope -ModuleName $moduleName {
#        # Overwrite Write-Log while in testing
#        Mock -CommandName Write-Log -MockWith { Write-Host $args[1] }
#		#Mock -CommandName Write-Log -MockWith {} 
#
#        
#        Mock -CommandName Get-InstalledApp.ps1 -MockWith { Return $null }
#        
#        It "Should return null" {
#            Test-Domain -Name "SHRHST" | Should Be $true
#        }
#
#        It "The domain should NOT match." {
#            Test-Domain -Name "fail" | Should Be $false
#        }
#    }
#} 



#Describe -Tags "Module" "Module: $moduleName.psm1" {
#
#    InModuleScope -ModuleName $moduleName {
#
## The location where uTorrent lives.
#$uTorrent = "TestDrive:\"
#
#$prop = [ordered] @{
#    Base = $uTorrent
#    
#    uTorrentDL      = $uTorrent + "Downloads"          # The location where uTorrent downloads files to.
#    tempExtractPath = $uTorrent + "ExtractedDownloads" # The directory where you want the files to be temporarily extracted to. 
#    logLocation     = $uTorrent + "Logs"               # Where the PMM log file will be to written to.
#    sfvLogsDir      = $uTorrent + "SfvLogs"            # Where the sfv evaulations will be logged to
#    MoviesDir       = $uTorrent + "Movies"             # Directories where the Renamers output files
#    TVEpsDir        = $uTorrent + "TV"                 # Directories where the Renamers output files
#    
#    videofiletypes = @('*.avi','*.mkv','*.m2ts','*.mpg','*.mpeg','*.mp4') # Files types to include when resorting to copying files
#    
#    # DEPENDENCIES
#    SevenZip = "$((.\Get-InstalledApp.ps1 -AppID '7-Zip').InstallLocation)7z.exe"       # Placeholder for the 7z.exe location
#    Quicksfv = (Get-ItemProperty HKLM:\SOFTWARE\Classes\File_Verification_Database\DefaultIcon).'(default)'.split(',')[0] # Placeholder for the QuickSFV.exe location
#}
#$uTorrent = New-Object PSObject  -Property $prop
#
#        # Overwrite Write-Log while in testing
#        Mock -CommandName Write-Log -MockWith { Write-Host $args[1] }
#        
#        #It "Get-SFV: no dir" {
#        #    Get-SFV -Directory $uTorrent.uTorrentDL | Should Throw
#        #} Need to work on throwing and error handling
#        
#        It "Get-SFV: 0 sfv in dir" {
#            New-Item -Path $uTorrent.uTorrentDL -ItemType Directory | Out-Null
#            $actual = Get-SFV -Directory $uTorrent.uTorrentDL
#            $actual.Count  | Should Be 1
#            $actual.GetType().Name | Should Be 'DirectoryInfo'
#        }
#
#        It "Get-SFV: 1 sfv in dir." {
#            New-Item -Path $($uTorrent.uTorrentDL + "\test.sfv")
#            $actual = Get-SFV -Directory $uTorrent.uTorrentDL
#            $actual.Count  | Should Be 1
#            $actual.GetType().Name | Should Be 'FileInfo'
#        }
#
#        It "Get-SFV: 2 sfv's in sub-dirs." {
#            mkdir "$($uTorrent.uTorrentDL)\test"
#            New-Item -Path $($uTorrent.uTorrentDL + "\test\test2.sfv")
#            $actual = Get-SFV -Directory $uTorrent.uTorrentDL
#            $actual.Count  | Should Be 2
#            $actual.GetType().Name | Should Be 'Object[]'
#        }
#    }
#}
#
#Describe -Tags "Module" "Module: $moduleName.psm1" {
#
#    InModuleScope -ModuleName $moduleName {
#        # Overwrite Write-Log while in testing
#        Mock -CommandName Write-Log -MockWith { Write-Host $args[1] }
#		#Mock -CommandName Write-Log -MockWith {} 
#
#        New-Item -Path $uTorrent.sfvLogsDir -ItemType Directory | Out-Null
#        
#        It "The domain should match." {
#            Test-Domain -Name "SHRHST" | Should Be $true
#        }
#
#        It "The domain should NOT match." {
#            Test-Domain -Name "fail" | Should Be $false
#        }
#    }
#} 

#Describe -Tags "Script" "Script: _Start.ps1" {
#
#    It "Driver passes minimum age test." {
#        Mock Get-WmiObject -MockWith { $Global:expected[0] } `
#                           -ParameterFilter { $Class -like "Win32_PnPSignedDriver" } `
#                           -ModuleName $Global:moduleName
#        & $Global:here\$Global:moduleName.ps1 | Should Be $true
#    }
#}

#Get-Module $moduleName | Remove-Module
#Remove-Variable -Name moduleName -Scope Global
#Remove-Variable -Name here -Scope Global 