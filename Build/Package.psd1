@{
    Root = '..\Scripts\Main.ps1'
    OutputPath = '.\winstools'
    Package = @{
        Enabled = $true
        DotNetVersion = 'net8.0-windows'
        PackageType = 'Console' 
        HideConsoleWindow = $false
        HighDPISupport = $true
        Platform = 'x64'
        PowerShellArguments = ''
        IconFile = '..\Icons\window.ico'
    }
    Bundle = @{
        Enabled = $true
        Modules = $true
    }
}
