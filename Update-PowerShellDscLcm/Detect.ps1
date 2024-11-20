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

Start-Transcript -Path $transcriptFile -Append  | Out-Null

# Create a DirectorySearcher object
$searcher = [adsisearcher]"(samaccountname=$computerName`$)"
$result = $searcher.FindOne()

if ($result -ne $null) {
    $guidBytes = $result.Properties["objectguid"][0]
    $guid = [guid]::New($guidBytes)
}

# Verify LCM settings
try {
    $lcm = Get-DscLocalConfigurationManager
    if (
        $lcm.RefreshMode -eq 'Pull' -and $lcm.ConfigurationID -eq $guid.Guid -and
        $lcm.ConfigurationDownloadManagers.SourcePath -eq $sourcePathConfig -and
        $lcm.ResourceModuleManagers.SourcePath -eq $sourcePathResource
        ) {
        Write-Output "Installed"
        Exit 0
    }
} catch {
}

Stop-Transcript  | Out-Null