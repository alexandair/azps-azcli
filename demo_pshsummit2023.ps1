# Best practices for automating Azure with PowerShell and Azure CLI


#region Installation, release notes, breaking changes...

# Azure PowerShell works with PowerShell 5.1 or higher on Windows, or PowerShell 7 or higher on any platform.
# If you are using PowerShell 5 on Windows, you also need .NET Framework 4.7.2 installed.

# https://github.com/Azure/azure-powershell

# https://docs.microsoft.com/powershell/azure/install-az-ps
# https://www.powershellgallery.com/packages/Az/

# Install-Module -Name Az -Repository PSGallery -Scope CurrentUser -AllowClobber 

# Release notes and the .MSI files (the MSI installer only works for PowerShell 5.1 on Windows)
# https://github.com/Azure/azure-powershell/releases/

# Release notes and the breaking changes (migration guides)
# https://learn.microsoft.com/en-us/powershell/azure/release-notes-azureps
# https://learn.microsoft.com/en-us/powershell/azure/upcoming-breaking-changes
# https://learn.microsoft.com/en-us/powershell/azure/migrate-az-9.0.1

# Azure AD to Microsoft Graph migration changes in Azure PowerShell
# https://learn.microsoft.com/en-us/powershell/azure/azps-msgraph-migration-changes

# Update-Module installs the new version side-by-side with previous versions
# It does not uninstall the previous versions
# It's a good idea to have the last 2 versions
Update-Module -Name Az

# Check a version
Get-Module az -ListAvailable
Get-InstalledModule -Name Az

# Az and AzureRM coexistence
# Microsoft doesn't support having both the AzureRM and Az modules installed for PowerShell 5.1 on Windows at the same time.
 
# In a scenario where you want to install both AzureRM and the Az PowerShell module on the same system, AzureRM must be installed only in the user scope for Windows PowerShell.
# Install the Az PowerShell module on PowerShell 7 or higher on the same system.

https://github.com/Azure/azure-cli
https://learn.microsoft.com/en-us/cli/azure/install-azure-cli
https://learn.microsoft.com/en-us/cli/azure/release-notes-azure-cli
https://learn.microsoft.com/en-us/cli/azure/microsoft-graph-migration

# Upgrade Azure CLI and extensions
az upgrade

#endregion

#region How to uninstall Azure PowerShell modules

# Uninstallation can be complicated if you have more than one version of the Az PowerShell module installed.
# Because of this complexity, Microsoft only supports uninstalling all versions of the Az PowerShell module that are currently installed.

# A list of all the Az PowerShell module versions installed on a system
Get-InstalledModule -Name Az -AllVersions -OutVariable AzVersions

# A list of all the Az PowerShell modules that need to be uninstalled in addition to the Az module
($AzVersions | ForEach-Object {
  Import-Clixml -Path (Join-Path -Path $_.InstalledLocation -ChildPath PSGetModuleInfo.xml)
}).Dependencies.Name | Sort-Object -Unique -OutVariable AzModules

# Remove the Az modules from memory and then uninstall them
$AzModules | ForEach-Object {
  Remove-Module -Name $_ -ErrorAction SilentlyContinue
  Write-Output "Attempting to uninstall module: $_"
  Uninstall-Module -Name $_ -AllVersions
}

# The final step is to remove the Az PowerShell module
Remove-Module -Name Az -ErrorAction SilentlyContinue
Uninstall-Module -Name Az -AllVersions

#endregion

#region Login experience

Connect-AzAccount

# Converting a SecureString to a string

$cred = Get-Credential -UserName $env:USERNAME -Message 'Enter Azure password'
$plainText = $cred.GetNetworkCredential().Password
"Your password is: $plainText"

$password = Read-Host -Prompt 'Enter Azure password' -AsSecureString
$password -is [SecureString]

$BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($Password)
[System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)

[System.Net.NetworkCredential]::new('', $password).Password

[System.Net.NetworkCredential]::new

# If you have managed identity enabled (Azure VM, Azure Arc-enabled server, Azure Automation)
# Connect-AzAccount -Identity

<# Azure DevOps Pipeline
# Create a service connection to Azure
$servicePrincipal = New-AzAdServicePrincipal -DisplayName 'ps2023' -Role Contributor -Scope /subscriptions/XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX

# In interactive mode, the az devops service-endpoint azurerm create command asks for a service principal password/secret using a prompt message. For automation purposes, set the service principal password/secret using the AZURE_DEVOPS_EXT_AZURE_RM_SERVICE_PRINCIPAL_KEY environment variable.
$servicePrincipalKey = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($servicePrincipal.Secret))
$env:AZURE_DEVOPS_EXT_AZURE_RM_SERVICE_PRINCIPAL_KEY = $servicePrincipalKey

$serviceConnectionName = 'ps2023-conn'
$AzContext = Get-AzContext

az devops service-endpoint azurerm create --name $serviceConnectionName --azure-rm-service-principal-id $servicePrincipal.ApplicationId --azure-rm-subscription-id $AzContext.Subscription.Id --azure-rm-subscription-name $AzContext.Subscription.Name --azure-rm-tenant-id $AzContext.Tenant.Id       

# NOTE: Add permissions for the service connection using a web interface
#>


<# GitHub Actions
# cd c:\<YOUR_LOCAL_REPO>
$ServicePrincipal = az ad sp create-for-rbac --name "pssummit" --role contributor --scopes /subscriptions/XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX --sdk-auth

$PublicKey = ConvertFrom-Json (gh api /repos/:owner/:repo/actions/secrets/public-key)

$encryptedvalue = ConvertTo-SodiumEncryptedString -Text "$ServicePrincipal" -PublicKey $PublicKey.key

gh api /repos/:owner/:repo/actions/secrets/AZURE_CREDENTIALS --method PUT -f encrypted_value=$EncryptedValue -f key_id=$($PublicKey.key_id)
#>

#endregion

#region Service coverage, default values, feedback...

# Service coverage
Get-Module Az.* -ListAvailable

# Default values
# $PSDefaultParameterValues vs Set-AzDefault
# Set-AzDefault only sets default resource group, but it's tied to the context so it changes when you switch accounts or subscriptions. It doesn't work in Azure Cloud Shell.
Get-Command Set-AzDefault -Syntax

$PSDefaultParameterValues
$PSDefaultParameterValues['Get-AzVM:ResourceGroupName'] = 'pssummit-rg'
$PSDefaultParameterValues.Add("*:Verbose", { $verbose -eq $true })

Get-AzVM
$verbose -eq $true
Get-AzFunctionApp
dir variable:
$verbose = $null
Get-AzFunctionApp

az config get
# Hide warnings and only show errors with `core.only_show_errors`
az config set core.only_show_errors=true
# Turn on client-side telemetry.
az config set core.collect_telemetry=true
# Turn on file logging and set its location.
az config set logging.enable_log_file=true
az config set logging.log_dir=~/az-logs
# Set the default location to `westeurope` and default resource group to `pssummit-rg`.
az config set defaults.location=westeurope defaults.group=pssummit-rg
az find "az config"

az config set extension.use_dynamic_install=no # this is default value
az graph query -q "resources"
az config set extension.use_dynamic_install=yes_prompt
az graph query -q "resources"
# for automation
az config set extension.use_dynamic_install=yes_without_prompt

# Feedback
Send-Feedback
Resolve-AzError

# Send feedback to the Azure CLI Team.
# This command is interactive.
# If possible, it launches the default web browser to open GitHub issue creation page with the body auto-generated and pre-filled.
az feedback

# To suppress breaking change warning messages, set the environment variable 'SuppressAzurePowerShellBreakingChangeWarnings' to 'true'.
Set-Item Env:\SuppressAzurePowerShellBreakingChangeWarnings "true"

#endregion

#region Use persisted parameters

# When you are using a local install of the Azure CLI, persisted parameter values are stored in the working directory on your machine.
mkdir azcli && cd azcli

# Using persisted parameters
# Reminder: function app and storage account names must be unique.

# Turn persisted parameters on.
az config param-persist on

# Create a resource group.
az group create --name RG2forpssummit --location westeurope

# See the stored parameter values.
az config param-persist show

# Create an Azure storage account in the resource group omitting "--location" and "--resource-group" parameters.
az storage account create `
  --name sa3forpssummit `
  --sku Standard_LRS

# Create a serverless function app in the resource group omitting "--storage-account" and "--resource-group" parameters.
az functionapp create `
  --name FAforpssummit `
  --consumption-plan-location westeurope `
  --functions-version 4

# See the stored parameter values.
az config param-persist show

# Without persisted parameters

# Reminder: function app and storage account names must be unique.

# turn persisted parameters off
az config param-persist off

# Create a resource group.
az group create --name RG2forpssummit --location westeurope

# Create an Azure storage account in the resource group.
az storage account create `
  --name sa3forpssummit `
  --location westeurope `
  --resource-group RG2forpssummit `
  --sku Standard_LRS

# Create a serverless function app in the resource group.
az functionapp create `
  --name FAforpssummit `
  --storage-account sa3forpssummit `
  --consumption-plan-location westeurope `
  --resource-group RG2forpssummit `
  --functions-version 4

#endregion

#region Let PowerShell help and tell you what to type

# Windows PowerShell

Find-Module psreadline -AllowPrerelease
Install-Module psreadline -AllowPrerelease -Scope CurrentUser -Verbose
# Install-Module psreadline -AllowPrerelease -Scope CurrentUser -Verbose -Force

# When the cursor is at the end of a fully expanded cmdlet, pressing F1 displays the help for that cmdlet.
# When the cursor is at the end of a fully expanded parameter, pressing F1 displays the help beginning at the parameter.
# Pressing the Alt-h key combination provides dynamic help for parameters.

Get-PSReadLineKeyHandler | where function -Match help

# Press Alt-a to rapidly select and change the arguments of a command

Get-AzConnectedMachineExtension -ResourceGroupName hybrid2-rg -MachineName luka-winvm | fl *

# Predictive IntelliSense
# matching predictions from the user’s history and additional domain specific plugins

Set-PSReadLineOption -PredictionSource History

Get-PSReadLineOption | fl *prediction*
Get-PSReadLineOption

# The default light-grey prediction text color
Set-PSReadLineOption -Colors @{ InlinePrediction = "$([char]0x1b)[48;5;238m" }

Set-PSReadLineOption -Colors @{ InlinePrediction = '#8A0303' }
Set-PSReadLineOption -Colors @{ InlinePrediction = '#2F7004' }
Set-PSReadLineOption -Colors @{ InlinePrediction = "$([char]0x1b)[36;7;238m" }

# By default, pressing RightArrow accepts an inline suggestion when the cursor is at the end of the current line.

# Predictions are displayed in one of two views depending on the user preference

# InlineView – This is the default view and displays the prediction inline with the user’s typing. This view is similar to other shells Fish and ZSH.
# ListView – ListView provides a dropdown list of predictions below the line the user is typing.

# You can change the view at the command line using the keybinding F2 or
# Set-PSReadLineOption -PredictionViewStyle ListView

# Start PowerShell 7.2 and show Az Predictor (use Windows Terminal)
Import-Module Az.Tools.Predictor

#endregion

#region PowerShell in Azure Cloud Shell

# Azure PSDrive

Get-PSDrive 

cd azure:

# Select a subscription and browse to the pssummit-rg resource group

# Context-aware commands
Get-AzVM
$PSDefaultParameterValues

Get-Module -ListAvailable
Get-Command -Module PSCloudShellUtility

Get-PackageVersion

# Open a resource in the Azure portal
Get-AzVM -ResourceGroupName pssummit-rg | select id | portal
Get-AzVM -ResourceGroupName pssummit-rg | fl id | portal
Get-AzVM -ResourceGroupName pssummit-rg -Name lon-cl1 | select -expand id | portal

# Open a link in new tab from the Cloud Shell
browse https://microsoft.com/powershell

# Increase a font size in command palette
# Map a file share

#endregion

#region Filtering the result

#output
# AzPS > an object
# AzCLI > JSON string
# --output -o : Output format. Allowed values: json, jsonc, none, table, tsv, yaml, yamlc. Default: json.

# filtering
# --query : JMESPath query string. See http://jmespath.org/ for more information and examples.

az account list-locations --query "sort_by([].{DisplayName: displayName, ARMName:name}, &DisplayName)" --output table

Get-AzLocation | Select-Object DisplayName, Location | Sort-Object DisplayName

az functionapp list --query "[].{resource:resourceGroup, name:name, defaultHostName:defaultHostName}" -o table
# az functionapp list --query "[].{resource:resourceGroup, name, defaultHostName}" -o table
Get-AzFunctionApp | Select-Object @{n = 'resource'; e = { $_.resourceGroup } }, name, defaultHostName

az functionapp list | ConvertFrom-Json | Select-Object @{n = 'resource'; e = { $_.resourceGroup } }, name, defaultHostName

az functionapp list --query "[?state=='Running'].{resource:resourceGroup, name:name, defaultHostName:defaultHostName}" -o table
Get-AzFunctionApp | Where-Object { $_.State -eq 'Running' } | Format-Table resourceGroup, name, defaultHostName
Get-AzFunctionApp | where State -EQ 'Running' | ft resourceGroup, name, defaultHostName

#endregion

#region Tab-completion, IntelliSense

# Completers in Azure PowerShell
# Get-AzVm -Name L<TAB> -ResourceGroupName <Ctrl+Space> 
# Get-AzVm -ResourceGroupName l<TAB> -Name <Ctrl+Space>
# Stop-AzVM -Id *demovm*<TAB>

#endregion

#region #requires statement

# Use #requires in your scripts so it's clear which version of the Azure PowerShell modules are required
# https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_requires

# -Modules <Module-Name> | <Hashtable>
<#
  ModuleName - Required; Specifies the module name.
  GUID - Optional; Specifies the GUID of the module.
It's also required to specify one of the three below keys. These keys can't be used together.
  ModuleVersion - Specifies a minimum acceptable version of the module.
  RequiredVersion - Specifies an exact, required version of the module.
  MaximumVersion - Specifies the maximum acceptable version of the module.
#>

#Requires -Modules @{ ModuleName="Az.Accounts"; RequiredVersion="2.5.3" }
#Requires -Modules @{ ModuleName="Az.Compute"; RequiredVersion="4.17.0" } # Don't specify 4.17

#endregion

#region Troubleshooting (Enable debug logging)

# One of the first steps you should take in troubleshooting a problem with the Azure Az PowerShell module is to enable debug logging.

# To enable debug logging on a per command basis, specify the Debug parameter.
Get-AzResource -Name 'DoesNotExist' -Debug

# To enable debug logging for an entire PowerShell session, you set the value of the DebugPreference variable to Continue.
$DebugPreference = 'Continue'

#endregion

#region Idempotency

#Azure CLI
az group create --name pssummit23-rg --location eastus

az storage account create --name pssummit23cli --resource-group pssummit23-rg --location eastus
az storage account create --name pssummit23cli --resource-group pssummit23-rg --location eastus

# Azure PowerShell
New-AzResourceGroup -Name pssummit23-rg -Location eastus
New-AzResourceGroup -Name pssummit23-rg -Location eastus -Force

New-AzStorageAccount -Name pssummit23cli -ResourceGroupName pssummit23-rg -Location eastus -SkuName Standard_LRS 
# New-AzStorageAccount: The storage account named pssummit23cli is already taken. (Parameter 'Name')

#endregion

# VARIOUS TIPS

#region Discovering Public IP Address

Invoke-RestMethod -Uri 'ipinfo.io/json'

#endregion

#region Redisplay a header

# The output now is paused per page until you press SPACE. 
# However, the column headers are displayed only on the first page.

Get-AzVM | Out-Host -Paging 
 
# A better output can be produced like this:
Get-AzVM | Format-Table -RepeatHeader | Out-Host -Paging 

$PSDefaultParameterValues["Format-Table:RepeatHeader"] = $true
Get-AzVM | Format-Table | Out-Host -Paging 
#endregion

#region A List of HTTP Response Codes

[Enum]::GetValues([System.Net.HttpStatusCode]) |
ForEach-Object {
  [PSCustomObject]@{
    Code        = [int]$_
    Description = $_.toString()
  }
}

#endregion