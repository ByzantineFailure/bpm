param (
    [switch]$isPTB = $false,
    [switch]$consent =$false
)

$node_url = "https://nodejs.org/dist/v4.2.4/win-x86/node.exe"
$node_output = "./node.exe"
$installer_directory = split-path -parent $MyInvocation.MyCommand.Definition
$install_script = $installer_directory + '\index.js'

function Download-Node {
    Write-Host "The installer could not find a 4.2.x install of Node.js.  This is needed to"
    Write-Host "run the install script.  Is it okay to download a standalone version of"
    Write-Host "Node.js v4.2.4 (about 11 MB) to run the install script then delete it right"
    Write-Host "after it runs? (Installer will quit without installing if it is not)"
    Write-Host "Press Y if it is okay (any other key if not)"
    
    if($consent){
        Write-Host "You have auto-matically consented because of a command flag."
        } else {
        $key = [Console]::ReadKey($true)
    }

    if($key.Key -eq 'y' -or $consent) {
        Write-Host "Downloading Node.js v4.2.4 standalone binary..."
        $wc = New-Object System.Net.WebClient
        $wc.DownloadFile($node_url, $node_output)
        Write-Host "Running installer..."
        if($isPTB) {
            & $node_output $install_script $installer_directory --ptb
        } else {
            & $node_output $install_script $installer_directory
        }
        Write-Host "Removing downloaded node binary..."
        Remove-Item $node_output
    } else {
        Write-Host "Input was not 'y' or 'Y', quitting without installing BPM..."
        exit
    }
}

if (Get-Command node.exe -errorAction SilentlyContinue) {
    Write-Host "Found node on path, checking version..."
    $node_version = (node --version) | Out-String
    $node_version = $node_version.trim()
    if ($node_version -like "*v4.2*") {
        Write-Host "Version is v4.2.x, running installer..."
        if($isPTB) {
            node.exe $install_script $installer_directory --ptb
        } else {
            node.exe $install_script $installer_directory
        }
    } else {
        Download-Node
    }
} else {
    Write-Host "Cannot find node on PATH"
    Download-Node
}

