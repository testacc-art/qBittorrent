function Start-DownloadWithRetry
{
    Param
    (
        [Parameter(Mandatory)]
        [string] $Url,
        [string] $Name,
        [string] $DownloadPath = "${env:Temp}",
        [int] $Retries = 20
    )

    if ([String]::IsNullOrEmpty($Name)) {
        $Name = [IO.Path]::GetFileName($Url)
    }

    $filePath = Join-Path -Path $DownloadPath -ChildPath $Name

    #Default retry logic for the package.
    while ($Retries -gt 0)
    {
        try
        {
            Write-Host "Downloading package from: $Url to path $filePath ."
            (New-Object System.Net.WebClient).DownloadFile($Url, $filePath)
            break
        }
        catch
        {
            Write-Host "There is an error during package downloading:`n $_"
            $Retries--

            if ($Retries -eq 0)
            {
                Write-Host "File can't be downloaded. Please try later or check that file exists by url: $Url"
                exit 1
            }

            Write-Host "Waiting 30 seconds before retrying. Retries left: $Retries"
            Start-Sleep -Seconds 30
        }
    }

    return $filePath
}


Write-Host "Downloading Bootstrapper ..."
$releaseInPath = "Enterprise"
$subVersion = "16"
$channel = "release"
$bootstrapperUrl = "https://aka.ms/vs/${subVersion}/${channel}/vs_${releaseInPath}.exe"

$BootstrapperName = [IO.Path]::GetFileName($BootstrapperUrl)
$bootstrapperFilePath = Start-DownloadWithRetry -Url $BootstrapperUrl -Name $BootstrapperName
$WorkLoads = @(
    "--add Microsoft.VisualStudio.Component.VC.v141.MFC.ARM.Spectre",
    "--add Microsoft.VisualStudio.Component.VC.v141.MFC.ARM64.Spectre",
    "--add Microsoft.VisualStudio.Component.VC.ATLMFC",
    "--add Microsoft.VisualStudio.Component.VC.ATLMFC.Spectre",
    "--add Microsoft.VisualStudio.Component.VC.MFC.ARM",
    "--add Microsoft.VisualStudio.Component.VC.MFC.ARM.Spectre",
    "--add Microsoft.VisualStudio.Component.VC.MFC.ARM64",
    "--add Microsoft.VisualStudio.Component.VC.MFC.ARM64.Spectre",
    "--add Microsoft.VisualStudio.Component.VC.ATLMFC",
    "--add Microsoft.VisualStudio.Component.VC.ATLMFC.Spectre"
)
$workLoadsArgument = [String]::Join(" ", $workLoads)

Write-Host "Starting Install ..."
$bootstrapperArgumentList = ('/c', $bootstrapperFilePath, 'modify', '--installPath "C:\Program Files\Microsoft Visual Studio\2022\Preview"', $workLoadsArgument, '--quiet', '--norestart', '--wait', '--nocache' )
$process = Start-Process -FilePath cmd.exe -ArgumentList $bootstrapperArgumentList -Wait -PassThru
