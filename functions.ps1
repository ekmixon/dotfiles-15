function script:Append-Path([string] $path ) {
   if ( -not [string]::IsNullOrEmpty($path) ) {
      if ( (test-path $path) -and (-not $env:PATH.contains($path)) ) {
          Write-Host "Appending Path" $path
         $env:PATH += ';' + "$path"
      }
   }
}

function Reload-Powershell {
    $newProcess = new-object System.Diagnostics.ProcessStartInfo "PowerShell";
    [System.Diagnostics.Process]::Start($newProcess);
    exit
}

function Set-Git {
    try {
        $git = (git --version)
        Write-Host $git
        Import-Module posh-git
        Append-Path((Get-Item "Env:ProgramFiles").Value + "\Git\bin")
    } catch {
        Write-Host "Git not found, will install."
        # Install git using PowerShellGet (-gt PS2)
        If ($PSVersionTable.PSVersion.Major -gt 2) { 
            PowerShellGet\Install-Module posh-git -Scope CurrentUser
            Update-Module posh-git
        } else {
            # Install git using chocolatey (-gt PS2) but I don't like this so warn...
            Write-Host "PowerShellGet requires PS3 or higher to install git."
            #choco install poshgit (-lt PS3)
        }
        # Maybe not required
        Reload-Powershell
    }

    <#
        .SYNOPSIS
            Checks if git is available and attempts to install it. https://github.com/dahlbyk/posh-git
        .EXAMPLE
            PS C:\> Test-Git
        .OUTPUTS
            System.Boolean
                True if git is installed, false if not.
    #>
}

# function Set-GitHub {
#     If ($PSVersionTable.PSVersion.Major -gt 2) { 
#         . (Resolve-Path "$env:LOCALAPPDATA\GitHub\shell.ps1")
#         . $env:github_posh_git\profile.example.ps1
#     }
#     $GitPath = Get-ChildItem -Recurse -Force "$HOME\AppData\Local\GitHub" -ErrorAction SilentlyContinue | Where-Object { ($_.PSIsContainer -eq $true) -and  ( $_.Name -like "*cmd*") } | % { $_.fullname }
#     $env:Path += ";$GitPath"
# }

function Set-UI {
    # $Host.UI.RawUI.WindowTitle = "Elevated"
    $Host.UI.RawUI.BackgroundColor = 'Black'
    # $Host.UI.RawUI.ForegroundColor = 'White'
    # $Host.PrivateData.ErrorForegroundColor = 'Red'
    # $Host.PrivateData.ErrorBackgroundColor = $bckgrnd
    # $Host.PrivateData.WarningForegroundColor = 'Magenta'
    # $Host.PrivateData.WarningBackgroundColor = $bckgrnd
    # $Host.PrivateData.DebugForegroundColor = 'Yellow'
    # $Host.PrivateData.DebugBackgroundColor = $bckgrnd
    # $Host.PrivateData.VerboseForegroundColor = 'Green'
    # $Host.PrivateData.VerboseBackgroundColor = $bckgrnd
    # $Host.PrivateData.ProgressForegroundColor = 'Cyan'
    # $Host.PrivateData.ProgressBackgroundColor = $bckgrnd
    Clear-Host
}

function Sudo-PowerShell {
    if ($args.Length -eq 1) {
        start-process $args[0] -verb "runAs"
        write-host 'ok'
    }
    if ($args.Length -gt 1) {
        start-process $args[0] -ArgumentList $args[1..$args.Length] -verb "runAs"
    }
}

function Test-ExecutionPolicy {
    if((Get-Executionpolicy) -eq 'RemoteSigned') {
        Write-Host "Relax with 'RemoteSigned' : Set-ExecutionPolicy RemoteSigned -scope CurrentUser"
    }
}

function Test-IsAdmin {
    try {
        $identity = [Security.Principal.WindowsIdentity]::GetCurrent();
        $principal = New-Object Security.Principal.WindowsPrincipal -ArgumentList $identity
        return $principal.IsInRole( [Security.Principal.WindowsBuiltInRole]::Administrator )
    } catch {
        throw "Failed to determine if the current user has elevated privileges. The error was: '{0}'." -f $_
    }

    <#
        .SYNOPSIS
            Checks if the current Powershell instance is running with elevated privileges or not.
        .EXAMPLE
            PS C:\> Test-IsAdmin
        .OUTPUTS
            System.Boolean
                True if the current Powershell is elevated, false if not.
    #>
}

function prompt {
    # https://github.com/dahlbyk/posh-git/wiki/Customizing-Your-PowerShell-Prompt
    $origLastExitCode = $LastExitCode
    
    if (Test-IsAdmin) {  # if elevated
        Write-Host "(Elevated $env:USERNAME ) " -NoNewline -ForegroundColor Red
    } else {
        Write-Host "$env:USERNAME " -NoNewline -ForegroundColor DarkYellow
    }

    Write-Host "$env:COMPUTERNAME" -NoNewline -ForegroundColor Cyan
    Write-Host " " $ExecutionContext.SessionState.Path.CurrentLocation.Path -ForegroundColor Blue
    $LastExitCode = $origLastExitCode
    "`n$('PS >') "

    Write-VcsStatus
}