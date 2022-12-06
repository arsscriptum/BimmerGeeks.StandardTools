
<#
#̷𝓍   𝓐𝓡𝓢 𝓢𝓒𝓡𝓘𝓟𝓣𝓤𝓜
#̷𝓍   🇵​​​​​🇴​​​​​🇼​​​​​🇪​​​​​🇷​​​​​🇸​​​​​🇭​​​​​🇪​​​​​🇱​​​​​🇱​​​​​ 🇸​​​​​🇨​​​​​🇷​​​​​🇮​​​​​🇵​​​​​🇹​​​​​ 🇧​​​​​🇾​​​​​ 🇬​​​​​🇺​​​​​🇮​​​​​🇱​​​​​🇱​​​​​🇦​​​​​🇺​​​​​🇲​​​​​🇪​​​​​🇵​​​​​🇱​​​​​🇦​​​​​🇳​​​​​🇹​​​​​🇪​​​​​.🇶​​​​​🇨​​​​​@🇬​​​​​🇲​​​​​🇦​​​​​🇮​​​​​🇱​​​​​.🇨​​​​​🇴​​​​​🇲​​​​​
#>


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
