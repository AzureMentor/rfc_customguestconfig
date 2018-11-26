<#
    .SYNOPSIS
        Retrieves the localized string data based on the machine's culture.
        Falls back to en-US strings if the machine's culture is not supported.

    .PARAMETER ResourceName
        The name of the resource as it appears before '.strings.psd1' of the localized string file.
        For example:
            AuditPolicySubcategory: MSFT_AuditPolicySubcategory
            AuditPolicyOption: MSFT_AuditPolicyOption
#>
function Get-LocalizedData
{
    [OutputType([String])]
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true, ParameterSetName = 'resource')]
        [ValidateNotNullOrEmpty()]
        [String]
        $ResourceName,

        [Parameter(Mandatory = $true, ParameterSetName = 'helper')]
        [ValidateNotNullOrEmpty()]
        [String]
        $HelperName
    )

    # With the helper module just update the name and path variables as if it were a resource.
    if ($PSCmdlet.ParameterSetName -eq 'helper')
    {
        $resourceDirectory = $PSScriptRoot
        $ResourceName = $HelperName
    }
    else
    {
        # Step up one additional level to build the correct path to the resource culture.
        $resourceDirectory = Join-Path -Path (Split-Path -Path (Split-Path -Path $PSScriptRoot -Parent) -Parent) `
                                       -ChildPath "DSCResources\$ResourceName"
    }

    $localizedStringFileLocation = Join-Path -Path $resourceDirectory -ChildPath $PSUICulture

    if (-not (Test-Path -Path $localizedStringFileLocation))
    {
        # Fallback to en-US
        $localizedStringFileLocation = Join-Path -Path $resourceDirectory -ChildPath 'en-US'
    }

    Import-LocalizedData `
        -BindingVariable 'localizedData' `
        -FileName "$ResourceName.strings.psd1" `
        -BaseDirectory $localizedStringFileLocation

    return $localizedData
}

# This must be loaded after the Get-LocalizedData function is created.
$script:localizedData = Get-LocalizedData -HelperName 'SecurityPolicyResourceHelper'

<#
    .SYNOPSIS
        Returns security policies configuration settings

    .PARAMETER Area
        Specifies the security areas to be returned

    .NOTES
    General notes
#>
function Get-SecurityPolicy
{
    [OutputType([Hashtable])]
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateSet("SECURITYPOLICY","GROUP_MGMT","USER_RIGHTS","REGKEYS","FILESTORE","SERVICES")]
        [System.String]
        $Area,

        [Parameter()]
        [System.String]
        $FilePath
    )

    if ($FilePath)
    {
        $currentSecurityPolicyFilePath = $FilePath
    }
    else
    {
        $currentSecurityPolicyFilePath = Join-Path -Path $env:temp -ChildPath 'SecurityPolicy.inf'

        Write-Debug -Message ($localizedData.EchoDebugInf -f $currentSecurityPolicyFilePath)

        secedit.exe /export /cfg $currentSecurityPolicyFilePath /areas $Area | Out-Null
    }

    $policyConfiguration = @{}
    switch -regex -file $currentSecurityPolicyFilePath
    {
        "^\[(.+)\]" # Section
        {
            $section = $matches[1]
            $policyConfiguration[$section] = @{}
            $CommentCount = 0
        }
        "^(;.*)$" # Comment
        {
            $value = $matches[1]
            $commentCount = $commentCount + 1
            $name = "Comment" + $commentCount
            $policyConfiguration[$section][$name] = $value
        }
        "(.+?)\s*=(.*)" # Key
        {
            $name,$value =  $matches[1..2] -replace "\*"
            $policyConfiguration[$section][$name] = $value
        }
    }

    Switch($Area)
    {
        "USER_RIGHTS"
        {
            $returnValue = @{}
            $privilegeRights = $policyConfiguration.'Privilege Rights'
            foreach ($key in $privilegeRights.keys )
            {
                $policyName = Get-UserRightConstant -Policy $key -Inverse
                $identity = ConvertTo-LocalFriendlyName -Identity $($privilegeRights[$key] -split ",").Trim() -Policy $policyName -Verbose:$VerbosePreference
                $returnValue.Add( $key,$identity )
            }

            continue
        }
        Default
        {
            $returnValue = $policyConfiguration
        }
    }

    return $returnValue
}

<#
    .SYNOPSIS
        Retrieves the Security Option Data to map the policy name and values as they appear in the Security Template Snap-in

    .PARAMETER FilePath
        Path to the file containing the Security Option Data
#>
function Get-PolicyOptionData
{
    [OutputType([hashtable])]
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory = $true)]
        [Microsoft.PowerShell.DesiredStateConfiguration.ArgumentToConfigurationDataTransformation()]
        [hashtable]
        $FilePath
    )
    return $FilePath
}

<#
    .SYNOPSIS
        Returns all the set-able parameters in the SecurityOption resource
#>
function Get-PolicyOptionList
{
    [OutputType([array])]
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory = $true)]
        [string]
        $ModuleName
    )

    $commonParameters = @( 'Name' )
    $commonParameters += [System.Management.Automation.PSCmdlet]::CommonParameters
    $commonParameters += [System.Management.Automation.PSCmdlet]::OptionalCommonParameters
    $moduleParameters = ( Get-Command -Name "Set-TargetResource" -Module $ModuleName ).Parameters.Keys |
        Where-Object -FilterScript { $PSItem -notin $commonParameters }

    return $moduleParameters
}
