param($path)
$definition = (Get-Content $path | ConvertFrom-Json -AsHashtable).Values
New-AzureRMPolicyDefinition @definition -verbose