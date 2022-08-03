Class Logger {
    [int32]$LogLevel
    [boolean]$Append
    [string]$LogFile
    [int32]$TW
    [boolean]$FlagExpandTab


    [string] ExpandTab([string]$Str) {
        return [logger]::ExpandTab($str, $this.TW)
    }

    static [string] ExpandTab([string]$Str, [UInt32]$TabWidth) {
        #if ( ! $this.FlagExpandTab ) { return $str }
        #if ( $TabWidth -lt 0 ) { $TabWidth = 4 }
        $line=$str
        while ( $TRUE ) {
            $i = $line.IndexOf([Char] 9)
            if ( $i -eq -1 ) { break }
            if ( $TabWidth -gt 0 )
            {
                $pad = " " * ($TabWidth — ($i % $TabWidth))
            }
            else
            {
                $pad =""
            }
            $line = $line -replace "^([^`t]{$i})`t(.*)$","`$1$pad`$2"
        }
        return $line
    } ### [string] ExpandTab([string]$Str, [UInt32]$TabWidth) {

    [string] Add([string]$msg, [int32]$Level=1) {
        return "$(Get-Date -Format 'dd.MM.yyyy hh:mm:ss'):`t$msg"
    }
    
    static [boolean]IsAbsolutePath([string]$Path) {
        $Result=$False
        if ( ($path.Substring(1, 1) -eq ':') -or ($path.Substring(0, 2) -eq '\\') ) {
            $Result=$True
        }
        return $Result
    }

    [void]InitDefault([int]$LogLevel) {
        $this.FlagExpandTab = $True
        $this.TW       = 4
        $this.Append   = $True
        $this.LogLevel = $LogLevel
        $this.LogFile  = ""
    }

    [string]InitFile ([String]$LogFile) {
        return [logger]::InitFile($LogFile, $this.Append)
    }

    static [string]InitFile ([String]$LogFile, [boolean]$Append) {
        $Result=$LogFile
        if ( !$LogFile) {
            return $Result
            throw "Not defined File logger." 
        }
        if ( !([logger]::IsAbsolutePath($LogFile)) ) {
            # абсолютный путь и имя файла
            $result = [Environment]::GetEnvironmentVariable('TEMP')
            if ( $LogFile.Substring(0,1) -ne '\' ) {
                $result += '\'
            }
            $result+=$LogFile
        }
        $FN = Split-Path -Path $Result -Leaf
        $PathLog = Split-Path -Path $Result -Parent
<#
        if (! (Test-Path $PathLog -PathType Container) ) {
            New-Item $PathLog -ItemType Directory | Out-Null
        }
#>
        if ( Test-Path $Result -PathType Any ) {
            if ( Test-Path $Result -PathType Container ) {
                $Result = ""
            }
        }
        else {
            if ( Test-Path $PathLog -PathType Any ) {
                if ( !(Test-Path $PathLog -PathType Container) ) {
                    $result = ""
                }
            } else { ### if ( Test-Path $PathLog -PathType Any ) {
                $outNI = New-Item $PathLog -ItemType Directory
                if ( !$outNI ) {
                    $result = ""
                }
            }
        } ### if ( Test-Path $Result -PathType Any ) {
        if ( $Result ) {
            if ( !($Append) -or !(Test-Path $Result) ) {
                New-Item $Result -ItemType File -Force | Out-Null
            }
            else {
                #Out-File -FilePath $Result -encoding "default" -InputObject "" -Append
            }
        }
        return $Result
    }

    Logger ([String]$LogFile){
        $this.InitDefault(1)
        $fl = $this.InitFile($LogFile)
        if ( $fl ) {
            $this.LogFile=$fl
        }
        else {
            #$this.LogFile="";
            $this.LogLevel=-1
        }
    }

    Logger ([String]$LogFile, [int]$LogLevel){
        $this.InitDefault($LogLevel)
        $fl = $this.InitFile($LogFile)
        if ( $fl ) {
            $this.LogFile=$fl
        }
        else {
            #$this.LogFile="";
            $this.LogLevel=-1
        }
    }

    Logger ([String]$LogFile, [int]$LogLevel, [boolean]$Append){
        $this.InitDefault($LogLevel)
        $this.Append = $Append

        $fl = $this.InitFile($LogFile)
        if ( $fl ) {
            $this.LogFile=$fl
        }
        else {
            $this.LogLevel=-1
        }
    }

    Logger ([String]$LogFile, [int]$LogLevel, [boolean]$Append, [int32]$Tabwidth){
        $this.InitDefault($LogLevel)
        $this.Append = $Append
        $this.TW = $Tabwidth

        $fl = $this.InitFile($LogFile)
        if ( $fl ) {
            $this.LogFile=$fl
        }
        else {
            $this.LogLevel=-1
        }
    }

    static [void] Log ([string]$FileName, [string]$Msg, [int32]$TabCount, [int32]$UseDate,
                       [int32]$Log, [int32]$LogLevel, [boolean]$Always=$False, [boolean]$FlagExpandTab,
                       [int32]$TabWidth, [string]$ClassMSG){
        #$UseDate=0,
            <#
                =0 нет даты в начале строки
                =1 дата в начале только 1-й строки
                =2 дата в начале каждой строки
                =3 нет даты в начале строки, но по длине 'дата:TAB' забито пробелами, TabCount НЕ игнорируется
                =4 1-я строка - дата в начале, TabCount игнорируется
                       следующие -  даты в начале строки нет,  но по длине 'дата:TAB-' забито пробелами, TabCount НЕ игнорируется
                =5 1-я строка - дата в начале, TabCount не игнорируется
                       следующие -  даты в начале строки нет,  но по длине 'дата:TAB-' забито пробелами, TabCount НЕ игнорируется
                =6 1-я строка - дата в начале, TabCount не игнорируется
                    следующие -  даты в начале строки нет,  но по длине 'дата:TAB+TAB-' забито пробелами, TabCount НЕ игнорируется
                =все отстальное, нет даты в начале строки, но по длине 'дата:TAB-' забито пробелами, TabCount игнорируется
            #>
        if ( !$Msg) { return }
        if ( ($LogLevel -le 0) -or ( $Log -le 0) ){ return }
        if (!$FileName -or ($FileName -eq '') ) { return }
        $PL = Split-Path $FileName -Parent
        if (! (Test-Path $PL -PathType Container) ) {
            New-Item $PL -ItemType Directory |Out-Null
        }
        if ($Log -gt 1) {
            $StrLevel=" (Level=$($Log))"
        } else {
            $StrLevel=""
        }
        if ( ($Log -le $LogLevel) -or $Always ) {
            $dt1=(Get-Date -Format "dd.MM.yyyy HH:mm:ss")
            $dt= $dt1 + ":`t"
            $dtspace="".PadLeft($dt1.Length, " ") + " `t"
            $as = $Msg.Split("`n")
            #$as
            $i=0
            foreach ($str in $as) {

                Switch ( $UseDate) {
                    0 {
                        $str = "".PadLeft($TabCount, "`t") + $str.Trim()
                    }
                    1 {
                        if ( $i -eq 0 ) {
                            $str = $dt + "".PadLeft($TabCount, "`t") + $str.Trim()
                        } else {
                            $str = $dtspace + "".PadLeft($TabCount, "`t") + $str.Trim()
                            #Log -Msg $str -TabCount $TabCount -UseDate 3 # $Always.IsPresent
                        }
                    }
                    2 {
                        $str = $dt + "".PadLeft($TabCount, "`t") + $str.Trim()
                    }
                    3 {
                        $str = $dtspace + "".PadLeft($TabCount, "`t") + $str.Trim()
                    }
                    4 {
                        if ( $i -eq 0 ) {
                            $str = $dt + $str.Trim()
                        } else {
                            $str = $dtspace + "".PadLeft($TabCount, "`t") + $str.Trim()
                        }
                    }
                    5 {
                        if ( $i -eq 0 ) {
                            $str = $dt  + "".PadLeft($TabCount, "`t") + $str.Trim()
                        } else {
                            $str = $dtspace + "".PadLeft($TabCount, "`t") + $str.Trim()
                        }
                    }
                    6 {
                        if ( $i -eq 0 ) {
                            $str = $dt  + "".PadLeft($TabCount, "`t") + $str.Trim()
                        } else {
                            $str = $dtspace + "".PadLeft($TabCount+1, "`t") + $str.Trim()
                        }
                    }
                    default {
                        $str = $str.Trim()
                    }
                }
                if ( $FlagExpandTab ) { $str=[logger]::ExpandTab($str, $TabWidth) }
                if ( $i -le 0 ) {
                    if ( $StrLevel ) {
                        $str = $str.PadRight(109, ' ')+$StrLevel
                    }
                    if ( $ClassMSG ) {
                        $str = $str.PadRight(150, ' ')+$ClassMSG
                    }
                }
                Out-File -FilePath $FileName -encoding "default" -InputObject "$($str)" -Append
                $i += 1
            } ### foreach ($str in $as) {
        }
    }

    [void] Log ([string]$Msg, [int32]$TabCount, [int32]$UseDate, [int32]$Log, [boolean]$Always=$False, [string]$ClassMSG){
        #$UseDate=0,
            <#
                =0 нет даты в начале строки
                =1 дата в начале только 1-й строки
                =2 дата в начале каждой строки
                =3 нет даты в начале строки, но по длине 'дата:TAB' забито пробелами, TabCount НЕ игнорируется
                =4 1-я строка - дата в начале, TabCount игнорируется
                       следующие -  даты в начале строки нет,  но по длине 'дата:TAB-' забито пробелами, TabCount НЕ игнорируется
                =5 1-я строка - дата в начале, TabCount не игнорируется
                       следующие -  даты в начале строки нет,  но по длине 'дата:TAB-' забито пробелами, TabCount НЕ игнорируется
                =6 1-я строка - дата в начале, TabCount не игнорируется
                    следующие -  даты в начале строки нет,  но по длине 'дата:TAB+TAB-' забито пробелами, TabCount НЕ игнорируется
                =все отстальное, нет даты в начале строки, но по длине 'дата:TAB-' забито пробелами, TabCount игнорируется
            #>

        [logger]::Log($this.LogFile, $Msg, $TabCount, $UseDate, $Log, $this.LogLevel, $Always, $this.FlagExpandTab, $this.TW, $ClassMSG)
<#
        $FileName = $this.LogFile
        if ( !$Msg) { return }
        if ( ($this.LogLevel -le 0) -or ( $Log -le 0) ){ return }
        if (!$FileName -or ($FileName -eq '') ) {
            return
        }
        if (!$FileName) { return }
        $PL = Split-Path $FileName -Parent
        if (! (Test-Path $PL -PathType Container) ) {
            New-Item $PL -ItemType Directory |Out-Null
        }
        if ($Log -gt 1) {
            $StrLevel=" (Level=$($Log))"
        } else {
            $StrLevel=""
        }
        if ( ($Log -le $this.LogLevel) -or $Always ) {
            $dt1=(Get-Date -Format "dd.MM.yyyy HH:mm:ss")
            $dt= $dt1 + ":`t"
            $dtspace="".PadLeft($dt1.Length, " ") + " `t"
            $as = $Msg.Split("`n")
            #$as
            $i=0
            foreach ($str in $as) {

                Switch ( $UseDate) {
                    0 {
                        $str = "".PadLeft($TabCount, "`t") + $str.Trim()
                    }
                    1 {
                        if ( $i -eq 0 ) {
                            $str = $dt + "".PadLeft($TabCount, "`t") + $str.Trim()
                        } else {
                            $str = $dtspace + "".PadLeft($TabCount, "`t") + $str.Trim()
                            #Log -Msg $str -TabCount $TabCount -UseDate 3 # $Always.IsPresent
                        }
                    }
                    2 {
                        $str = $dt + "".PadLeft($TabCount, "`t") + $str.Trim()
                    }
                    3 {
                        $str = $dtspace + "".PadLeft($TabCount, "`t") + $str.Trim()
                    }
                    4 {
                        if ( $i -eq 0 ) {
                            $str = $dt + $str.Trim()
                        } else {
                            $str = $dtspace + "".PadLeft($TabCount, "`t") + $str.Trim()
                        }
                    }
                    5 {
                        if ( $i -eq 0 ) {
                            $str = $dt  + "".PadLeft($TabCount, "`t") + $str.Trim()
                        } else {
                            $str = $dtspace + "".PadLeft($TabCount, "`t") + $str.Trim()
                        }
                    }
                    6 {
                        if ( $i -eq 0 ) {
                            $str = $dt  + "".PadLeft($TabCount, "`t") + $str.Trim()
                        } else {
                            $str = $dtspace + "".PadLeft($TabCount+1, "`t") + $str.Trim()
                        }
                    }
                    default {
                        $str = $str.Trim()
                    }
                }
                if ( $this.FlagExpandTab ) { $str=$this.ExpandTab($str) }
                if ( ($i -le 0) -and ($StrLevel) ) {
                    $str = $str.PadRight(109, ' ')+$StrLevel
                }
                Out-File -FilePath $FileName -encoding "default" -InputObject "$($str)" -Append
                $i += 1
            } ### foreach ($str in $as) {
        }
#>
    } ### Log

    [void] Log ([string[]]$Msg, [int32]$TabCount, [int32]$UseDate, [int32]$Log, [boolean]$Always=$False, [string]$ClassMSG){
        foreach ($str in $Msg) {
            $this.Log($str, $TabCount, $UseDate, $Log, $Always, $ClassMSG)
        }
    }

}

<#
$l=[logger]::new('d:\temp\123.log', 1)
#>
