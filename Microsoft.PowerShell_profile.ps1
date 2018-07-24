
<# Preferences #>
$DebugPreference = "SilentlyContinue" # https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_preference_variables
[Net.ServicePointManager]::SecurityProtocol = "tls12, tls11, tls" # Support TLS

<# Globals #>
$PSDirectory = (Get-Item $profile).DirectoryName

<# Alias / 1-Liner #>
${function:~} = { Set-Location ~ }
${function:Set-ParentLocation} = { Set-Location .. }; Set-Alias ".." Set-ParentLocation
${function:Reload-Powershell} = { & $profile }
${function:Get-Sudo} = { Start-Process powershell -ArgumentList "-executionpolicy bypass" -Verb RunAs }

<# PATH #>
function Set-EnvPath([string] $path ) {
    if ( -not [string]::IsNullOrEmpty($path) ) {
        if ( (Test-Path $path) -and (-not $env:PATH.contains($path)) ) {
            #Write-Host "PATH" $path -ForegroundColor Cyan
            $env:PATH += ';' + "$path"
       }
    }
 }

<# Profile Helpers #>
 function Test-IsAdmin {
    $user = [Security.Principal.WindowsIdentity]::GetCurrent();
    (New-Object Security.Principal.WindowsPrincipal $user).IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)
}
function Test-RegistryValue {
    param (
        [parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]$Path,
        [parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]$Value
    )

    try {
        Get-ItemProperty -Path $Path | Select-Object -ExpandProperty $Value -ErrorAction Stop | Out-Null
        return $true
    } catch {
        return $false
    }
}
<# End Profile Helpers #>

<# . Source #>
Push-Location (Split-Path -parent $profile)
"organisation" | Where-Object {Test-Path "Microsoft.PowerShell_$_.ps1"} | ForEach-Object -process {
    Invoke-Expression ". .\Microsoft.PowerShell_$_.ps1"; Write-Host Microsoft.PowerShell_$_.ps1
}
Pop-Location
<# End . Source #>

<# Support Helpers #>
function Get-ADMemberCSV {
    <#
    .SYNOPSIS
    Export AD group members to CSV.
    .DESCRIPTION
    Export AD group members to CSV.
    .EXAMPLE
    Get-ADMemberCSV -GroupObj MyAdGroup
    .PARAMETER GroupObj
    The group name. Just one.
    #>
    param (
        [parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]$GroupObj
    )

    try {
        Get-ADGroupMember "$GroupObj" | Export-CSV -path "c:\temp\$GroupObj.csv"
        explorer c:\temp
    } catch {
        return $false
    }
}

function Get-Documentation {
    <#
    .SYNOPSIS
    Quick access to edit documentation.
    .DESCRIPTION
    Lightweight documentation.
    .EXAMPLE
    Get-Documentation -DocObj printers
    .PARAMETER DocObj
    The document name. Just one.
    #>
    param (
        [parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]$DocObj
    )
    try {
        Import-Csv "$PSDirectory\$DocObj.csv" | Format-Table | Out-String -stream
        Write-Host "`nFilter with (sls) : | Select-String 'STRING'`n"
    } catch {
        Write-Host "No such document."
        return $false
    }

}; Set-Alias gd Get-Documentation

function Set-Documentation {
    <#
    .SYNOPSIS
    Quick access to edit documentation.
    .DESCRIPTION
    Lightweight documentation.
    .EXAMPLE
    Set-Documentation -DocObj printers
    .PARAMETER DocObj
    The document name. Just one.
    #>
    param (
        [parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]$DocObj
    )

    try {
        explorer "$PSDirectory\$DocObj.csv"
    } catch {
        Write-Host "No such document."
        return $false
    }

}; Set-Alias sd Set-Documentation

function Get-FilePathLength() {
    <#
    .SYNOPSIS
    Count file path characters.
    .DESCRIPTION
    Help identifying 260 chars.
    .EXAMPLE
    Get-FilePathLength -FolderPath C:\temp
    .PARAMETER FolderPath
    The folder path to query. Just one.
    #>
    param (
        [parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]$FolderPath
    )
    Get-ChildItem -Path $FolderPath -Recurse -Force |
        #Where-Object {$_.FullName.length -ge 248 } |
        Select-Object -Property FullName, @{Name="FullNameLength";Expression={($_.FullName.Length)}} |
        Sort-Object -Property FullNameLength -Descending
}

function Get-Log {
    <#
    .SYNOPSIS
    Captain's log.
    .DESCRIPTION
    A running commentary of interesting events.
    .EXAMPLE
    Get-Log
    #>
    try {
        notepad "$PSDirectory\log.txt"
    } catch {
        return $false
    }
}; Set-Alias qq Get-Log

function Get-LAPS {
    <#
    .SYNOPSIS
    https://technet.microsoft.com/en-us/mt227395.aspx
    .DESCRIPTION
    Query Active Directory for the local administrator password of a ComputerObj.
    .EXAMPLE
    Get-LAPS -ComputerObj mycomputer-1
    .PARAMETER ComputerObj
    The computer name to query. Just one.
    #>
    param (
        [parameter(Mandatory=$True)]
        [ValidateNotNullOrEmpty()]$ComputerObj
    )

    try {
        Get-ADComputer $ComputerObj -Properties ms-Mcs-AdmPwd | Select-Object name, ms-Mcs-AdmPwd
    } catch {
        return $false
    }
}; Set-Alias laps Get-LAPS

function Get-LAPSExpiry{
    <#
    .SYNOPSIS
    https://technet.microsoft.com/en-us/mt227395.aspx
    .DESCRIPTION
    Query Active Directory for the local administrator password expiry date for a ComputerObj.
    .EXAMPLE
    Get-LAPSExpiry -ComputerObj mycomputer-1
    .PARAMETER ComputerObj
    The computer name to query. Just one.
    #>
    param (
        [parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]$ComputerObj
    )

    $PwdExp = Get-ADComputer $ComputerObj -Properties ms-MCS-AdmPwdExpirationTime
    $([datetime]::FromFileTime([convert]::ToInt64($PwdExp.'ms-MCS-AdmPwdExpirationTime',10)))
}
function Get-MSIProdCode {
    <#
    .SYNOPSIS
    List all installed msi product codes.
    .DESCRIPTION
    List all installed msi product codes.
    .EXAMPLE
    Get-MSIProdCode
    #>
    get-wmiobject Win32_Product | Format-Table IdentifyingNumber, Name | Out-String -stream
    Write-Host "`nFilter with (sls) : | Select-String 'STRING'`n"
}

function Get-PowershellAs {
    <#
    .SYNOPSIS
    Run a powershell process as a specified user.
    .DESCRIPTION
    Run a powershell process as a specified user, typically an AD non-policy or elevated permissions account.
    .EXAMPLE
    Get-PowershellAs -UserObj myuser
    .PARAMETER UserObj
    The user name to "run as"
    #>
    param (
        [parameter(Mandatory=$True)]
        [ValidateNotNullOrEmpty()]$UserObj
    )
    $DomainObj = (Get-WmiObject Win32_ComputerSystem).Domain
    if ( $DomainObj -eq 'WORKGROUP' ){
        $DomainObj = (Get-WmiObject Win32_ComputerSystem).Name
    }
    runas /user:$DomainObj\$UserObj "powershell.exe -executionpolicy bypass"
}; Set-Alias pa Get-PowershellAs

function Get-PSExec {
    <#
    .SYNOPSIS
    Just a reminder... PSexec locally as SYSTEM
    .DESCRIPTION
    PSexec locally as SYSTEM for testing packages.
    .EXAMPLE
    Get-PSExec
    #>
    psexec -i -s powershell -executionpolicy RemoteSigned
}
<# End Support Helpers #>

<# HUD #>
Write-Host "$profile"
Write-Host (Get-ExecutionPolicy)

<# Prompt #>
function prompt {
    # https://github.com/dahlbyk/posh-git/wiki/Customizing-Your-PowerShell-Prompt
    $origLastExitCode = $LastExitCode

    if (Get-GitStatus){
        if (Get-Command git -TotalCount 1 -ErrorAction SilentlyContinue) {
            Set-EnvPath((Get-Item "Env:ProgramFiles").Value + "\Git\bin")
            Write-Host (git --version) -ForegroundColor Cyan
        }
    }

    if (Test-IsAdmin) {  # if elevated
        Write-Host "(Elevated $env:USERNAME ) " -NoNewline -ForegroundColor Red
    } else {
        Write-Host "$env:USERNAME " -NoNewline -ForegroundColor Blue
    }

    Write-Host "$env:COMPUTERNAME " -NoNewline -ForegroundColor DarkCyan
    Write-Host $ExecutionContext.SessionState.Path.CurrentLocation -ForegroundColor Cyan -NoNewline
    Write-VcsStatus
    $LASTEXITCODE = $origLastExitCode
    "`n$('PS>' * ($nestedPromptLevel + 1)) "
}

<# Notes #>

# Build a better function
# https://technet.microsoft.com/en-us/library/hh360993.aspx?f=255&MSPPError=-2147217396

# Research ways of using execution policy
# Set-ExecutionPolicy RemoteSigned -scope CurrentUser

# function Get-evtx {
#     wevtutil epl application c:\temp\application.evtx
# }

# function Get_Health {
#     DISM /Online /Cleanup-Image /CheckHealth
#     DISM /Online /Cleanup-Image /ScanHealth
#     DISM /Online /Cleanup-Image /RestoreHealth
# }

# function Get-Remote {
#     Start-Process C:\Windows\CmRcViewer.exe
# }

# function Get-Uptime {
#     (Get-Date)-(Get-CimInstance Win32_OperatingSystem).lastbootuptime | Format-Table
# }


<# MOVE TO HELPERS #>

# Bootstrap
function Set-BootStrap {
    Set-BootstrapOrg

    # SSH
    # Test pipe
    Get-WindowsCapability -Online | Where-Object Name -like 'OpenSSH.Client*' | Add-WindowsCapability -Online
    # Get-WindowsCapability -Online | Where-Object Name -like 'OpenSSH*'

    # Install the OpenSSH Client
    #Add-WindowsCapability -Online -Name OpenSSH.Client~~~~0.0.1.0

    # Install the OpenSSH Server
    # Add-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0

    # # Set IE
    # Set-Location HKCU:
    # New-Item -Path ".\Software\Microsoft\Internet Explorer" -Name "ContinuousBrowsing"
    # New-ItemProperty ".\Software\Microsoft\Internet Explorer\ContinuousBrowsing" -Name "Enabled" -Value 1 -PropertyType "DWord"
    # Set-ItemProperty ".\Software\Microsoft\Internet Explorer\ContinuousBrowsing" -Name "Enabled" -Value 1

    # Set Run
    Set-Location HKCU:
    Remove-Item '.\Software\Microsoft\Windows\CurrentVersion\Explorer\RunMRU'
    New-Item -Path ".\Software\Microsoft\Windows\CurrentVersion\Explorer\" -Name "RunMRU"
    New-ItemProperty ".\Software\Microsoft\Windows\CurrentVersion\Explorer\RunMRU" -Name "MRUList" -Value "ab" -PropertyType "String"
    New-ItemProperty ".\Software\Microsoft\Windows\CurrentVersion\Explorer\RunMRU" -Name "a" -Value "powershell.exe -executionpolicy remotesigned\1" -PropertyType "String"
    New-ItemProperty ".\Software\Microsoft\Windows\CurrentVersion\Explorer\RunMRU" -Name "b" -Value "powershell.exe -executionpolicy bypass -command ""start-process powershell -ArgumentList '-ExecutionPolicy Bypass' -Verb Runas""\1" -PropertyType "String"
}
