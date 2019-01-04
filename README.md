# Custom Guest Configuration Request for Comments
![Azure Guest Configuration](https://contosodev.blob.core.windows.net/img/GuestConfigurationIcon.jpg)

The build is currently broken (on purpose).
See the details below to understand the reasoning behind this approach.

[![Build Status](https://dev.azure.com/azvmguestpolicy/CustomGuestConfiguration/_apis/build/status/Microsoft.rfc_customguestconfig?branchName=master)](https://dev.azure.com/azvmguestpolicy/CustomGuestConfiguration/_build/latest?definitionId=3?branchName=master)

[![Deployment Gate Status](https://vsrm.dev.azure.com/azvmguestpolicy/_apis/public/Release/badge/8cf7364a-2490-4dd7-8353-5c7e17e8728d/1/1)](https://vsrm.dev.azure.com/azvmguestpolicy/_apis/public/Release/badge/8cf7364a-2490-4dd7-8353-5c7e17e8728d/1/1)

This repository is the home for a *theoretical* design for Azure Guest Configuration
to support customer-provided content.
As part of an open collaboration with the community
we welcome you to review the information on this page,
the project examples,
and **please provide feedback** using the survey in the
[Issues](https://github.com/Microsoft/rfc_customguestconfig/issues)
list.

## What is the scenario we would like to support?

In Spring 2019,
we would like to offer support for customers to use their own content
in Azure Guest Configuration scenarios.
Azure already offers built-in Policy content to audit settings
inside virtual machines such as which application are installed and/or not installed.
This change would empower customers to author
and use custom configurations.

Examples include:

- Security configuration baselines (many settings)
- Key security checks such as which accounts have administrative privileges inside VMs
- Application settings

To validate this scenario,
we will work through iterations of what we will ask to be validated.

An early iteration of this capability in preview would support
configurations for Windows authored in Desired State Configuration
and profiles for Linux authored in Chef Inspec.
Only resources provided in the Guest Configuration module
would be recommended.

In future iterations,
custom DSC resources would also be recommended for testing.

## What are we proposing we do to support this scenario?

For built-in policies,
the
[Azure Guest Configuration API](https://docs.microsoft.com/en-us/rest/api/guestconfiguration/guestconfigurationassignments/get#guestconfigurationnavigation)
accepts a GET operation that returns properties
including a contentURI path to the configuration package
and contentHash value so the content can be verified.
A potential solution to support custom content
would be to allow a PUT operation to also set the properties
for the location and hash value.
This would mean the content package could be hosted in locations
such GitHub repo's, GitHub releases, blob storage,
or static links to NuGet feeds (pending validation).

The current package format for Guest Configuration
is a .zip format that contains the configuration content
(DSC mof/resources or InSpec profile).
A consideration for custom content is whether
to support packages in NuGet format.
This would potentially fill multiple gaps:

- NuGet is an industry standard package format
- NuGet includes metadata such as version, author, description, and release notes, which would benefit cross-team collaboration
- Implementing NuGet with the current solution should be straight-forward

We also believe there is a need for additional tooling
to simplify the process of authoring configuration content.
New cmdlets would be available to provide assistance for authors
creating custom content.

## Theoretical example repo

This repo demonstrates how a project
to centrally manage a custom policy
might be organized.

The folder
[customPolicyFiles](https://github.com/Microsoft/rfc_customguestconfig/tree/master/customPolicyFiles)
contains the Azure Policy definitions
and a theoretical Password Policy
authored in Desired State Configuration.
The configuration content is located
within the guestConfiguration subfolder,
including a custom DSC resource based on the community maintained resource
[SecurityPolicyDSC](https://github.com/PowerShell/SecurityPolicyDsc).

The variables **contentUri** and **contentHash**
in the file
[deployIfNotExists.rules.json](https://github.com/Microsoft/rfc_customguestconfig/blob/master/customPolicyFiles/deployIfNotExists.rules.json#L85)
are automatically populated during the Build phase.
This is to test using the
[Azure DevOps NuGet task](https://docs.microsoft.com/en-us/azure/devops/pipelines/tasks/package/nuget?view=vsts)
to create the package.
It will then need to be downloaded to calculate the hash value.
This is a component of the build we could potentially simplify using new cmdlets.

## Give us feedback!

We are very interested in understanding how you would leverage
Azure Guest Configuration to audit settings
inside your virtual machines.
Please contribute to the Issues list with ideas for content
that could be validated in this RFC repo,
and any requirements you have for tools that improve your authoring experience.

## Contributing

This project welcomes contributions and suggestions.  Most contributions require you to agree to a
Contributor License Agreement (CLA) declaring that you have the right to, and actually do, grant us
the rights to use your contribution. For details, visit https://cla.microsoft.com.

When you submit a pull request, a CLA-bot will automatically determine whether you need to provide
a CLA and decorate the PR appropriately (e.g., label, comment). Simply follow the instructions
provided by the bot. You will only need to do this once across all repos using our CLA.

This project has adopted the [Microsoft Open Source Code of Conduct](https://opensource.microsoft.com/codeofconduct/).
For more information see the [Code of Conduct FAQ](https://opensource.microsoft.com/codeofconduct/faq/) or
contact [opencode@microsoft.com](mailto:opencode@microsoft.com) with any additional questions or comments.
