#
# Unit tests for core PSDocs functionality
#

[CmdletBinding()]
param (

)

# Setup error handling
$ErrorActionPreference = 'Stop';

# Setup tests paths
$rootPath = (Resolve-Path $PSScriptRoot\..\..).Path;
$here = Split-Path -Parent $MyInvocation.MyCommand.Path;
$src = ($here -replace '\\tests\\', '\\src\\') -replace '\.Tests', '';
$temp = "$here\..\..\build";
# $sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path) -replace '\.Tests\.', '.';

Import-Module $src -Force;
Import-Module $src\..\PSDocs -Force;

$outputPath = "$temp\PSDocs.Dsc.Tests\Common";
Remove-Item -Path $outputPath -Force -Recurse -Confirm:$False -ErrorAction SilentlyContinue;
New-Item -Path $outputPath -ItemType Directory -Force | Out-Null;

$Global:TestVars = @{ };

configuration TestConfiguration {

    param (
        [Parameter(Mandatory = $True)]
        [String[]]$ComputerName
    )

    Import-DscResource -ModuleName PSDesiredStateConfiguration;

    node $ComputerName {

        File FileResource {
            Ensure = 'Present'
            Type = 'File'
            DestinationPath = 'C:\environment.tag'
            Contents = "Node=$($Node.NodeName)"
        }

        WindowsFeature SMB1 {
            Ensure = 'Absent'
            Name = 'FS-SMB1'
        }
    }
}

configuration TestConfiguration2 {
    
        param (
            [Parameter(Mandatory = $True)]
            [String[]]$ComputerName
        )
    
        Import-DscResource -ModuleName PSDesiredStateConfiguration;
    
        node $ComputerName {
    
            File FileResource {
                Ensure = 'Present'
                Type = 'File'
                DestinationPath = 'C:\environment.tag'
                Contents = "Node=$($Node.NodeName)"
            }
        }
    }

Describe 'PSDocs.Dsc' {
    Context 'Generate a document without an instance name' {

        # Define a test document with a table
        document 'WithoutInstanceName' {
            
            $InputObject.ResourceType.File | Table -Property Contents,DestinationPath;
        }

        TestConfiguration -OutputPath $outputPath -ComputerName 'WithoutInstanceName';

        $outputDoc = "$outputPath\WithoutInstanceName.md";
        Invoke-DscNodeDocument -DocumentName 'WithoutInstanceName' -Path $outputPath -OutputPath $outputPath;

        It 'Should generate an output named WithoutInstanceName.md' {
            Test-Path -Path $outputDoc | Should be $True;
        }

        It 'Should contain document name' {
            Get-Content -Path $outputDoc -Raw | Should match '\|Node\=WithoutInstanceName\|';
        }
    }

    Context 'Generate a document with an instance name' {
        
        # Define a test document with a table
        document 'WithInstanceName' {
            
            $InputObject.ResourceType.File | Table -Property Contents,DestinationPath;
        }

        TestConfiguration -OutputPath $outputPath -ComputerName 'Instance1';

        Invoke-DscNodeDocument -DocumentName 'WithInstanceName' -InstanceName 'Instance1' -Path $outputPath -OutputPath $outputPath;

        It 'Should not create a output with the document name' {
            Test-Path -Path "$outputPath\WithInstanceName.md" | Should be $False;
        }

        It 'Should generate an output named Instance1.md' {
            Test-Path -Path "$outputPath\Instance1.md" | Should be $True;
        }

        It 'Should contain instance name' {
            Get-Content -Path "$outputPath\Instance1.md" -Raw | Should match '|Content=Instance1|';
        }
    }

    Context 'Generate a document with multiple instance names' {
        
        # Define a test document with a table
        document 'WithMultiInstanceName' {
            $InputObject.ResourceType.File | Table -Property Contents,DestinationPath;
        }

        TestConfiguration -OutputPath $outputPath -ComputerName 'Instance2','Instance3';

        Invoke-DscNodeDocument -DocumentName 'WithMultiInstanceName' -InstanceName 'Instance2','Instance3' -Path $outputPath -OutputPath $outputPath;

        It 'Should not create a output with the document name' {
            Test-Path -Path "$outputPath\WithMultiInstanceName.md" | Should be $False;
        }

        It 'Should generate an output named Instance2.md' {
            Test-Path -Path "$outputPath\Instance2.md" | Should be $True;
        }

        It 'Should contain instance name Instance2' {
            Get-Content -Path "$outputPath\Instance2.md" -Raw | Should match '\|Node\=Instance2\|';
        }

        It 'Should generate an output named Instance3.md' {
            Test-Path -Path "$outputPath\Instance3.md" | Should be $True;
        }

        It 'Should contain instance name Instance3' {
            Get-Content -Path "$outputPath\Instance3.md" -Raw | Should match '\|Node\=Instance3\|';
        }
    }

    Context 'Generate a document with an external script' {

        TestConfiguration -OutputPath $outputPath -ComputerName 'WithExternalScript';

        Invoke-DscNodeDocument -Script "$here\Templates\WithExternalScript.ps1" -DocumentName 'WithExternalScript' -InstanceName 'WithExternalScript' -Path $outputPath -OutputPath $outputPath;

        It 'Should generate an output named WithExternalScript.md' {
            Test-Path -Path "$outputPath\WithExternalScript.md" | Should be $True;
        }

        It 'Should contain instance name' {
            Get-Content -Path "$outputPath\WithExternalScript.md" -Raw | Should match '\|FS\-SMB1\|';
        }
    }

    Context 'Generate a document with missing data' {
        
        # Define a test document with a table
        document 'WithMissingData' {

            Section 'Windows features' {
            
                # Reference a resource type that is not included in the configuration
                $InputObject.ResourceType.WindowsFeature | Table -Property Name,Ensure;
            }
        }

        TestConfiguration2 -OutputPath $outputPath -ComputerName 'WithMissingData';

        Invoke-DscNodeDocument -DocumentName 'WithMissingData' -InstanceName 'WithMissingData' -Path $outputPath -OutputPath $outputPath;

        It 'Should output' {
            Test-Path -Path "$outputPath\WithMissingData.md" | Should be $True;
        }
    }
}
