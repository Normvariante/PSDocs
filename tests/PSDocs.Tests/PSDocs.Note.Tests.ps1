#
# Unit tests for the Note keyword
#

[CmdletBinding()]
param (

)

# Setup error handling
$ErrorActionPreference = 'Stop';
Set-StrictMode -Version latest;

# Setup tests paths
$rootPath = (Resolve-Path $PSScriptRoot\..\..).Path;
$here = Split-Path -Parent $MyInvocation.MyCommand.Path;
$src = ($here -replace '\\tests\\', '\\src\\') -replace '\.Tests', '';
$temp = "$here\..\..\build";
# $sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path) -replace '\.Tests\.', '.';

Import-Module $src -Force;
Import-Module $src\PSDocsProcessor\Markdown -Force;

$outputPath = "$temp\PSDocs.Tests\Note";
New-Item $outputPath -ItemType Directory -Force | Out-Null;

$dummyObject = New-Object -TypeName PSObject;

$Global:TestVars = @{ };

Describe 'PSDocs -- Note keyword' {
    Context 'Note' {

        # Define a test document with a note
        document 'NoteVisitor' {
            
            Note {
                'This is a note'
            }
        }

        Mock -CommandName 'VisitNote' -ModuleName 'Markdown' -Verifiable -MockWith {
            param (
                $InputObject
            )

            $Global:TestVars['VisitNote'] = $InputObject;
        }

        Invoke-PSDocument -Name 'NoteVisitor' -InputObject $dummyObject -OutputPath $outputPath;

        It 'Should process Note keyword' {
            Assert-MockCalled -CommandName 'VisitNote' -ModuleName 'Markdown' -Times 1;
        }

        It 'Should be Note object' {
            $Global:TestVars['VisitNote'].Type | Should be 'Note';
        }

        It 'Should have expected content' {
            $Global:TestVars['VisitNote'].Content | Should be 'This is a note';
        }
    }

    Context 'Note single line markdown' {
        
        # Define a test document with a note
        document 'NoteSingleMarkdown' {
            
            Note {
                'This is a single line note'
            }
        }

        $outputDoc = "$outputPath\NoteSingleMarkdown.md";
        Invoke-PSDocument -Name 'NoteSingleMarkdown' -InputObject $dummyObject -OutputPath $outputPath;

        It 'Should have generated output' {
            Test-Path -Path $outputDoc | Should be $True;
        }

        It 'Should match expected format' {
            Get-Content -Path $outputDoc -Raw | Should match '\> \[\!NOTE\]\r\n\> This is a single line note';
        }
    }

    Context 'Note multi-line markdown' {
        
        # Define a test document with a note
        document 'NoteMultiMarkdown' {
            
            Note {
                'This is the first line of the note.'
                'This is the second line of the note.'
            }
        }

        $outputDoc = "$outputPath\NoteMultiMarkdown.md";
        Invoke-PSDocument -Name 'NoteMultiMarkdown' -InputObject $dummyObject -OutputPath $outputPath;

        It 'Should have generated output' {
            Test-Path -Path $outputDoc | Should be $True;
        }

        It 'Should match expected format' {
            Get-Content -Path $outputDoc -Raw | Should match '\> \[\!NOTE\]\r\n\> This is the first line of the note.\r\n\> This is the second line of the note.';
        }
    }
}
