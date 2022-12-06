
<#
#̷𝓍   𝓐𝓡𝓢 𝓢𝓒𝓡𝓘𝓟𝓣𝓤𝓜
#̷𝓍   🇵​​​​​🇴​​​​​🇼​​​​​🇪​​​​​🇷​​​​​🇸​​​​​🇭​​​​​🇪​​​​​🇱​​​​​🇱​​​​​ 🇸​​​​​🇨​​​​​🇷​​​​​🇮​​​​​🇵​​​​​🇹​​​​​ 🇧​​​​​🇾​​​​​ 🇬​​​​​🇺​​​​​🇮​​​​​🇱​​​​​🇱​​​​​🇦​​​​​🇺​​​​​🇲​​​​​🇪​​​​​🇵​​​​​🇱​​​​​🇦​​​​​🇳​​​​​🇹​​​​​🇪​​​​​.🇶​​​​​🇨​​​​​@🇬​​​​​🇲​​​​​🇦​​​​​🇮​​​​​🇱​​​​​.🇨​​​​​🇴​​​​​🇲​​​​​
#>

[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory = $false)] 
    [Alias('d')]
    [switch]$Divide,
    [Parameter(Mandatory = $false)] 
    [Alias('c')]
    [switch]$Combine,
    [Parameter(Mandatory = $false)] 
    [Alias('t')]
    [switch]$Test
)

function CombineSplitFiles{

    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory = $true)] 
        [STRING] $Path,
        [Parameter(Mandatory = $true)] 
        [int] $TotalSize,
        [Parameter(Mandatory = $false)] 
        [STRING] $OutFilePath
    )
    $Basename = ''
    Write-Verbose   "Path is $Path"
    $Files = (gci $Path -File).Name
    ForEach($f in $Files){
        if($f.Contains('01.cpp')){
            $Basename = $f.TrimEnd('01.cpp')
            
        }
    }
    Write-Verbose   "Basename is $Basename"
    $Files = (gci $Path -File).FullName
    $FilesCount = $Files.Count
    $Path = $Path.TrimEnd('\')
    $Position = 0 
   
    [byte[]]$NewOutArray = [byte[]]::new($TotalSize)
    Write-Verbose " + CREATING $OutFilePath"
    For($x = 1 ; $x -le $FilesCount ; $x++){
        $DataFileName = "{0}\{1}{2,2:00}{3}" -f ($Path, $Basename, $x, '.cpp')
        Write-Verbose   "Working on $DataFileName"
        if(-not (Test-Path -Path "$DataFileName")){ 
            Write-Verbose   "ERROR NO SUCH FILE $DataFileName"
            continue;
        }
        $ReadBytes = get-content -LiteralPath $DataFileName
        $ReadBytesCount = $ReadBytes.Length
        Write-Verbose   "ReadBytesCount $ReadBytesCount"
        [byte[]] $outArray =[convert]::FromBase64String($ReadBytes);
        $outArraySize = $outArray.Length
        Write-Verbose "   >>> WRITING $outArraySize bytes (pos $Position)"
        $outArray.CopyTo($NewOutArray,$Position)
        $Position += $outArraySize
    }

   
    [io.file]::WriteAllBytes($OutFilePath,$NewOutArray)
    Write-Host "Wrote All Bytes to $OutFilePath"
}


function SplitDataFile{

[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory = $true)] 
    [STRING] $Path,
    [Parameter(Mandatory = $false)] 
    [INT64] $Newsize = 1MB,
    [Parameter(Mandatory = $false)] 
    [STRING] $OutPath,
    [Parameter(Mandatory = $false)] 
    [switch] $AsString
)

    if ($Newsize -le 0)
    {
        Write-Error "Only positive sizes allowed"
        return
    }

    if($PSBoundParameters.ContainsKey('OutPath') -eq $False){
        $OutPath = [IO.Path]::GetDirectoryName($Path)

        Write-Verbose "Using OutPath from Path $Path"
    }else{
        Write-Verbose "Using OutPath $OutPath"
    }
    $OutPath = $OutPath.TrimEnd('\')

    if(-not (Test-Path -Path "$OutPath")){ 
        Write-Verbose "CREATING $OutPath"
        $Null= New-Item $OutPath -ItemType Directory -Force -ErrorAction Ignore
    }

    $FILENAME = [IO.Path]::GetFileNameWithoutExtension($Path)
    $EXTENSION  = [IO.Path]::GetExtension($Path)

    $MAXVALUE = 1GB # Hard maximum limit for Byte array for 64-Bit .Net 4 = [INT32]::MaxValue - 56, see here https://stackoverflow.com/questions/3944320/maximum-length-of-byte
    # but only around 1.5 GB in 32-Bit environment! So I chose 1 GB just to be safe
    $PASSES = [MATH]::Floor($Newsize / $MAXVALUE)
    $REMAINDER = $Newsize % $MAXVALUE
    if ($PASSES -gt 0) { $BUFSIZE = $MAXVALUE } else { $BUFSIZE = $REMAINDER }

    $OBJREADER = New-Object System.IO.BinaryReader([System.IO.File]::Open($Path, [System.IO.FileMode]::Open, [System.IO.FileAccess]::Read))
    [Byte[]]$BUFFER = New-Object Byte[] $BUFSIZE
    $NUMFILE = 1

    do {
        $NEWNAME = "{0}\{1}{2,2:00}{3}" -f ($OutPath, $FILENAME, $NUMFILE, '.cpp')

        $COUNT = 0
        $OBJWRITER = $NULL
        [INT32]$BYTESREAD = 0
        while (($COUNT -lt $PASSES) -and (($BYTESREAD = $OBJREADER.Read($BUFFER, 0, $BUFFER.Length)) -gt 0))
        {
            Write-Verbose " << READING $BYTESREAD bytes"
            if($AsString){
                $DataString = [convert]::ToBase64String($BUFFER, 0, $BYTESREAD)
                Write-Verbose "   >>> WRITING DataString to $NEWNAME"
                Set-Content $NEWNAME $DataString  
            }else{
                if (!$OBJWRITER)
                {
                    $OBJWRITER = New-Object System.IO.BinaryWriter([System.IO.File]::Create($NEWNAME))
                    Write-Verbose " + CREATING $NEWNAME"
                }
                Write-Verbose "   >>> WRITING $BYTESREAD bytes to $NEWNAME"
                $OBJWRITER.Write($BUFFER, 0, $BYTESREAD)  
            }
            $COUNT++
        }
        if (($REMAINDER -gt 0) -and (($BYTESREAD = $OBJREADER.Read($BUFFER, 0, $REMAINDER)) -gt 0))
        {
            Write-Verbose " << READING $BYTESREAD bytes"
            if($AsString){
                $DataString = [convert]::ToBase64String($BUFFER, 0, $BYTESREAD)
                Write-Verbose "   >>> WRITING DataString to $NEWNAME"
                Set-Content $NEWNAME $DataString  
            }else{
                if (!$OBJWRITER)
                {
                    $OBJWRITER = New-Object System.IO.BinaryWriter([System.IO.File]::Create($NEWNAME))
                    Write-Verbose " + CREATING $NEWNAME"
                }
                Write-Verbose "   >>> WRITING $BYTESREAD bytes to $NEWNAME"
                $OBJWRITER.Write($BUFFER, 0, $BYTESREAD)  
            }
        }

        if ($OBJWRITER) { $OBJWRITER.Close() }
        ++$NUMFILE
    } while ($BYTESREAD -gt 0)

    $OBJREADER.Close()
}



try{
    function Get-Script([string]$prop){
        $ThisFile = $script:MyInvocation.MyCommand.Path
        return ((Get-Item $ThisFile)|select $prop).$prop
    }

    $MakeScriptPath = split-path $script:MyInvocation.MyCommand.Path
    $ScriptFullName =(Get-Item -Path $script:MyInvocation.MyCommand.Path).FullName
    $ScriptsPath = Join-Path $MakeScriptPath 'scripts'
    $PackagePath = Join-Path $MakeScriptPath 'package'
    $DataPath = Join-Path $MakeScriptPath 'data'
    $FileUtilsScriptPath = Join-Path $ScriptsPath 'FileUtils.ps1'
    $DataFilePath = Join-Path $PackagePath 'BimmerGeeksStandardTools.7z'
    $CombinedDataFilePath = Join-Path $PackagePath 'CombinedBimmerGeeksStandardTools.7z'
    $SizeDataFile = Join-Path $DataPath 'Size.dat'

    #===============================================================================
    # Root Path
    #===============================================================================
    $Global:ConsoleOutEnabled              = $true
    $Global:CurrentRunningScript           = Get-Script basename
    $Script:CurrPath                       = $MakeScriptPath
    $Script:RootPath                       = (Get-Location).Path
    If( $PSBoundParameters.ContainsKey('Path') -eq $True ){
        $Script:RootPath = $Path
    }
 
    #===============================================================================
    # Script Variables
    #===============================================================================
    $Global:CurrentRunningScript           = Get-Script basename
    $Script:Time                           = Get-Date
    $Script:Date                           = $Time.GetDateTimeFormats()[13]

   
    Write-Host "MAKE" -f DarkRed
   
    if($Combine){
        [int]$FileLength = Get-Content $SizeDataFile 
        CombineSplitFiles -Path $DataPath -OutFilePath $CombinedDataFilePath -TotalSize $FileLength -Verbose
    }
    elseif($Divide){
        if(-not (Test-Path -Path "$DataFilePath")){ throw "Cannot DIvide: no file $DataFilePath" }
        $FileLength = (gi -Path "$DataFilePath").Length
        $Newsize = 5MB
        
        SplitDataFile -Path $DataFilePath -Newsize 1Mb -OutPath $DataPath -AsString -Verbose
        Set-Content $SizeDataFile -Value $FileLength
    }
    elseif($Test){
        [string]$CheckSum1 = ''
        [string]$CheckSum2 = ''
        [byte[]] $inArray = [byte[]]::new(256)
        for ($x = 0; $x -lt $inArray.Length; $x++)
        {
            $inArray[$x] = [byte]$x;
            $CheckSum1 += "{0:X2} " -f  $inArray[$x]

        }

        $s = [convert]::ToBase64String($inArray, 0, $inArray.Length)
        $NewFilePath = Join-Path "$PSScriptRoot" "test.txt"
  
        Write-Host "Writing $NewFilePath"
        Set-Content $NewFilePath $s

        Write-Host "READING $NewFilePath"
        $ReadBytes = get-content -LiteralPath $NewFilePath
        [byte[]] $outArray = [byte[]]::new(256)
        $outArray =[convert]::FromBase64String($ReadBytes);
        for ($x = 0; $x -lt $outArray.Length; $x++)
        {
            $CheckSum2 += "{0:X2} " -f  $outArray[$x]
        }
        if($CheckSum1 -eq $CheckSum2){
            Write-Host "SUCCESS" -f Green
        }else{
            Write-Host "FAILURE" -f Red
        }

        Remove-Item "$NewFilePath" -Force
    }


}catch{
    Write-Error $_
}