param (
    [string]$computerName = $env:COMPUTERNAME,
    [string]$transcriptFile = "C:\temp\Update-PowerShellDscLcm_$($computerName)_$(Get-Date -Format 'yyyyMMdd_HHmmss').log",
    [string]$domain = $((Get-CimInstance -Class Win32_ComputerSystem).Domain),
    [string[]]$modulesToInstall = @("PSDesiredStateConfiguration"),
    [string]$lcmConfigPath = "C:\temp\LcmConfigViaSCCM",
    [string]$repoName = $(switch ($domain){
                "domain.com" {
                    'PSGallery'
                }
                "otherdomain.com" {
                    'SelfHostedRepository'
                }
                Default {
                    Write-Error "Current domain is not covered"
                }
            }
        ),
    [string]$sourcePathConfig = $(switch ($domain) {
                "domain.com" {
                    '\\server1.domain.com\Dsc'
                }
                "otherdomain.com" {
                    '\\server2.otherdomain.com\Dsc'
                }
                Default {
                    Write-Error "Current domain is not covered"
                }
            }
        ),
    [string]$sourcePathResource = $(switch ($domain) {
                "domain.com" {
                    '\\server1.domain.com\Dsc\Resources'
                }
                "otherdomain.com" {
                    '\\server2.otherdomain.com\Dsc\Resources'
                }
                Default {
                    Write-Error "Current domain is not covered"
                }
            }
        )     
)

Start-Transcript -Path $transcriptFile -Append

foreach ($module in $modulesToInstall) {
    if (-not (Get-Module -ListAvailable -Name $module)) {
        Write-Output "Module $module is not installed. Installing..."
        Install-Module -Name $module -Repository $repoName -Force -Scope CurrentUser
    } else {
        Write-Output "Module $module is already installed. Importing..."
        Import-Module -Name $module
    }
}

# Create a DirectorySearcher object
$searcher = [adsisearcher]"(samaccountname=$computerName`$)"
$result = $searcher.FindOne()

if ($result -ne $null) {
    $guidBytes = $result.Properties["objectguid"][0]
    $guid = [guid]::New($guidBytes)
    Write-Output $guid.Guid
} else {
    Write-Output "Computer not found."
}

[DSCLocalConfigurationManager()]
configuration LcmConfig
{
    Node 'localhost'
    {
        Settings
        {
            RefreshMode = 'Pull'
            RefreshFrequencyMins = 30
            RebootNodeIfNeeded = $false
            ConfigurationID    = $guid
        }

         ConfigurationRepositoryShare SmbConfigShare
        {
            SourcePath = $sourcePathConfig
        }

        ResourceRepositoryShare SmbResourceShare
        {
            SourcePath = $sourcePathResource

        }
    }
}

LcmConfig -OutputPath $lcmConfigPath
New-DscChecksum -Path $lcmConfigPath -Force
Set-DscLocalConfigurationManager -Path $lcmConfigPath -Verbose -Force

# Verify LCM settings
$lcm = Get-DscLocalConfigurationManager

if ($lcm.RefreshMode -eq 'Pull' -and $lcm.ConfigurationID -eq $guid.Guid) {
    Write-Output "LCM is configured correctly with RefreshMode 'Pull' and the correct ConfigurationID."
    Exit 0
} else {
    Write-Output "LCM configuration is incorrect."
    Exit 1001
}

Stop-Transcript