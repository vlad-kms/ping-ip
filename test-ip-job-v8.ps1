Param (
    [Parameter(ValueFromPipeline=$True,Position=0)]
    $FileCFG,
    $version=2
)

$ps = Split-Path $psCommandPath -Parent
. "$ps\classLogger.ps1"
. "$ps\classSMS_ZTE.ps1"
#. '\\MROVO\sysvol\mrovo.lan\scripts\ps\modules\avvClasses\classLogger.ps1'
#. '\\MROVO\sysvol\mrovo.lan\scripts\ps\modules\avvClasses\classSMS_ZTE.ps1'

<#---------------------------------
    ���������������
-----------------------------------#>

function DateToStr([datetime]$Date) {
    if (!$Date) { Date = Get-Date }
    return [string]$Date.Year+([string]$Date.Month).PadLeft(2,"0")+([string]$Date.Day).PadLeft(2,"0")+
           ([string]$Date.Hour).PadLeft(2,"0")+([string]$Date.Minute).PadLeft(2,"0")+([string]$Date.Second).PadLeft(2,"0")
}

<# ���������� �������� ���������� ����� #>
function GetEnvironmentVariable() {
param(
  [Parameter(Mandatory=$True, ValueFromPipeline=$True)]
  [String] $Name
)
    BEGIN {}
    PROCESS {
        #$result = [Environment]::GetEnvironmentVariable('TEMP')
        $result = [Environment]::GetEnvironmentVariable($Name)
        if (!$Result) { $result = '' }
        return $result
    <#
        if (Test-Path env:$Name) {
          return (gi env:$Name).value
        } else {
            return ''
        }
    #>
    }
    END {}
}

<# ������� ��� ����� ��� ����� �� ��������� ������ �� INI ����� � ������ �� ip ������: #>
function Get-NameFileLog() {
param(
    [string]$LP,
    [string]$LFN,
    [int32] $LA,
    [string]$parIP,
    [string]$parIpDNS,
    [string]$parIpStr
)
    $FileLog = ""
    $Temp=("Temp"|GetEnvironmentVariable)
    if ( !$LP -or ($LP -eq "") ) {
        $FileLog = $Temp
    } else {
        if ( ($LP.Substring(1, 1) -eq ':') -or ($LP.Substring(0, 2) -eq '\\') ) {
            # ����� ���������� ����
            $FileLog = $LP
        } else {
            # ����� ������������� ����, �.�. ����� ������ � %TEMP%
            $FileLog = Join-Path -Path $Temp -ChildPath $LP
        }
    } ### if ( !$LogPath -or ($LogPath -eq "") ) {

    if ( !$LFN -or ($LFN -eq "") ) {
        if ( $PSCommandPath ) {
            $BeginNameFileLog = (Split-Path $PSCommandPath -Leaf).Trim()
        }
        else {
            $BeginNameFileLog = 'test-ip'
        }
    } else {
        $BeginNameFileLog = $LFN
    }
    #$script:LogFileCommon=[boolean]($LA -lt 0)
    $dt=Get-Date
    $dtstr=DateToStr -Date $dt
    $LFN=""
    switch ($LA) {
        -2 {
            $LFN = "$BeginNameFileLog($($dtstr)).log"
        }
        -1 {
            $LFN = "$BeginNameFileLog.log"
        }
        0 {
            $LFN = "$BeginNameFileLog-$parIpDNS-$parIP.log"
        }
        1 {
            $LFN = "$BeginNameFileLog-$parIpDNS-$parIP($dtstr).log"
        }
        2 {
            $LFN = "$BeginNameFileLog-$parIpDNS-$parIP($parIPStr=$dtstr).log"
        }
        3 {
            $LFN = "$BeginNameFileLog-$parIpDNS-$parIP($parIPStr).log"
        }
        default {
            $LFN = "$BeginNameFileLog-$parIpDNS-$parIP($parIPStr).log"
        }
    } ### switch ($LA) {
    return (Join-Path -Path $FileLog -ChildPath $LFN)
}

# ������� ��� �����������
function Log () {
    Param(
        [Parameter(ValueFromPipeline=$True, Position=0)]
        [String[]]$Msgs,
        [Parameter(Position=1)]
        [String]$FileName,
        [int32] $TabCount=0,
        [int32]$UseDate=0,
            <#
                =0 ��� ���� � ������ ������
                =1 ���� � ������ ������ 1-� ������
                =2 ���� � ������ ������ ������
                =3 ��� ���� � ������ ������, �� �� ����� '����:TAB' ������ ���������, TabCount �� ������������
                =4 1-� ������ - ���� � ������, TabCount ������������
                   ��������� -  ���� � ������ ������ ���,  �� �� ����� '����:TAB-' ������ ���������, TabCount �� ������������
                =5 1-� ������ - ���� � ������, TabCount �� ������������
                   ��������� -  ���� � ������ ������ ���,  �� �� ����� '����:TAB-' ������ ���������, TabCount �� ������������
                =6 1-� ������ - ���� � ������, TabCount �� ������������
                   ��������� -  ���� � ������ ������ ���,  �� �� ����� '����:TABTAB-' ������ ���������, TabCount �� ������������
                =��� ����������, ��� ���� � ������ ������, �� �� ����� '����:TAB-' ������ ���������, TabCount ������������
            #>
        [int32]$Log,
        [Int32]$Level=1000,
        [Switch]$Always,
        [string]$ClassMSG=""
    )
    BEGIN {
    }
    PROCESS {
    #static [void] Log ([string]$FileName, [string]$Msg, [int32]$TabCount, [int32]$UseDate, [int32]$Log, [int32]$LogLevel, [boolean]$Always=$False, [boolean]$FlagExpandTab, [int32]$TabWidth){
        foreach ($Msg in $Msgs) {
            [logger]::Log($FileName, $Msg, $TabCount, $UseDate, $Log, $Level, $Always, $True, 4, $ClassMSG)
        }
    }
    END {
    }
}

# ������� ��� ��������� �� Telegram
#     $TelegramTo - ������ ID telegram ��������� ��� �����������. ����������� ',' ��� ';'.
#                 ����:
#                      1111111,-1111111;41111111
#                       ���
#                      1111111:Time1,-1111111:Time2;41111111
#                 ��� Time1, Time2 � ��.- ������ �� ������ � ���������� ����������� �� ���� ������,
#                 ���� ������ ���, �� ������������ $StrInterval
# 
function Notify-Telegram {
Param(
    [string]$textSMS,
    [string]$StrInterval,
    [hashtable]$pHashCFG,
    [System.Collections.Specialized.OrderedDictionary]$pCurrentSection=[ordered]@{},
    [boolean]$TelegramUse=$False,
    [string]$TelegramTo="",
    [string]$TelegramBot="",
    [string]$TelegramURL
)
    $ResStr = '�� ������ ��������� ����������� �� telegram �����. �� ������� ������ ��� �������������'
    if ( ($TelegramTo -eq "") -or ($TelegramBot -eq "") -or ($TelegramURL -eq "") ) {
        return $ResStr
    }
    $ResStr = '�� ��������� �������� ����������� �� telegram �����'
    $realSendMessage = $TelegramUse -and ($TelegramTo -ne "") -and ($TelegramBot -ne "") -and ($TelegramURL -ne "")
    if ( ! $realSendMessage ) {
        return $ResStr
    }
    $ResStr=""
    #$arrTelegramID=[array[]]@()
    $arrTelegramID=$TelegramTo.Split(',;')
    # ��������� ���� �� �������
    $arrTelegramID.ForEach({
        $oneContact = $_.trim()
        if ($oneContact.Contains(':') ) {
            # ����� ���� � ID telegram ������ ������ � ����������
            $arr1 = $oneContact.Split(':')
            $oneContact = $arr1[0]
            # ������������ ������ ��������� �� ������ ����������
            #     ��
            #     [Time1]
            #     UseSMSSendTime=1
            #     1=7-9
            #     2=9-11
            #     5=0
            #     �
            #     ���� �����������, �� $StrInterval4Phone='7-9'
            #     ���� �������,     �� $StrInterval4Phone='9-11'
            #     ���� �����,       �� $StrInterval4Phone=$StrInterval
            #     ���� �������,     �� $StrInterval4Phone=$StrInterval
            #     ���� �������,     �� $StrInterval4Phone='0'
            #     ���� �������,     �� $StrInterval4Phone=$StrInterval
            #     ���� �����������, �� $StrInterval4Phone=$StrInterval
            #     [Time2]
            #     UseSMSSendTime=0
            #     1=7-9
            #     2=9-11
            #     5=0
            #     �
            #     ���� �����������, �� $StrInterval4Phone='7-9'
            #     ���� �������,     �� $StrInterval4Phone='9-11'
            #     ���� �����,       �� $StrInterval4Phone=''
            #     ���� �������,     �� $StrInterval4Phone=''
            #     ���� �������,     �� $StrInterval4Phone='0'
            #     ���� �������,     �� $StrInterval4Phone=''
            #     ���� �����������, �� $StrInterval4Phone=''
            $SectionName = $arr1[1]
            $StrInterval4Phone = ''
            if ($pHashCFG.ContainsKey($SectionName) ) {
                # ����� ��� ������ ������� ����
                $dow = [string]((Get-Date).DayOfWeek.value__)
                if ($dow -eq 0) { $dow=7 }
                $dow=[string]$dow
                # ������ ���������� ������� �� ���� ������
                $SIDOW = [hashtable]($pHashCFG.$SectionName)
                $UseInteravlFromCFG = $False
                if ( $SIDOW.ContainsKey('UseSMSSendTime') ) {
                    $UseInteravlFromCFG = [boolean][int]$SIDOW.UseSMSSendTime
                }
                if ($SIDOW.ContainsKey($dow)) {
                    $StrInterval4Phone = $SIDOW.$dow
                }
                else {
                    if ($UseInteravlFromCFG) {
                        $StrInterval4Phone = $StrInterval
                    }
                    else {
                        $StrInterval4Phone = '0'
                    }
               }
            }
            else {
                $StrInterval4Phone = $StrInterval
            }

            #echo "oneContact: $oneContact"
            #echo "SectionName: $SectionName"
        } else {
            # ID telegram ��� ������� ':'
            #echo "��� ������ Time"
            $StrInterval4Phone = $StrInterval
        }
        # ���������� �������� �����������
        #echo "StrInterval4Phone: $StrInterval4Phone"
        $ResStr += "`n=========== ���������� Telegram ========================="
        $ResStr += "`nURL API Telegram`t:$($TelegramURL)"
        $ResStr += "`nUse Telegram`t:$($TelegramUse)"
        $ResStr += "`nID contact`t`t:$($oneContact)"
        $ResStr += "`nTelegram Bot`t:$($TelegramBot)"
        $ResStr += "`nSMSText`t`t:$($textSMS)"
        $ResStr += "`nSend Time`t:$($StrInterval4Phone)"
        $IsTime = TimeInStrInterval -SI $StrInterval4Phone -DT (Get-Date)
        $ResStr += "`nIsTime`t`t:$($IsTime)"
        if ($realSendMessage -and $IsTime) {
            # ����������� �������� ���
            echo "��������� ���������"
            try {
                $ResReq = (Invoke-WebRequest -Uri "$($TelegramURL)$($TelegramBot)/SendMessage?chat_id=$($oneContact)&text=$($textSMS)").Content
            } catch {
                $ResReq = $Error[0].ToString()
            }
            $ResStr += "`nResponse:`t:$($ResReq)"
        }

    })

    return $ResStr
}

# ������� ��� �������� ���
#     $SMSPhone - ������ ��������� ��� �����������. ����������� ',' ��� ';'.
#                 ����:
#                      +79141111111,89141111111;+79141111111
#                       ���
#                      +79141111111:Time1,89141111111:Time2;+79141111111
#                 ��� Time1, Time2 � ��.- ������ �� ������ � ���������� ����������� �� ���� ������,
#                 ���� ������ ���, �� ������������ $StrInterval
# 
function Notify-SMS {
Param(
    [string]$SMSPhone,
    [string]$textSMS,
    [string]$SMSTypeModem,
    [string]$SMSIPManager,
    [string]$SMSComPort,
    [boolean]$SendSMSReal,
    [string]$StrInterval,
    [hashtable]$pHashCFG
)

    if ( !$script:SMSZTE ) {
        #$script:SMSZTE = [SMS_ZTE]::new($SMSIPManager)
        $SMSZTE = [SMS_ZTE]::new($SMSIPManager)
    }
    $ResStr = ''
        #SMS
    $SMSTypeModem = $SMSTypeModem.ToUpper()
    if ( $SMSPhone -and $SMSTypeModem ) {
     #-and $SMSIPManager) {
        switch ($SMSTypeModem) {
            'ZTE' {
                if ($SMSIPManager) {
                    $SendSMSReal = $SendSMSReal -and $True
                    Break
                }
            }
            'COM' {
                if ($SMSComPort ) {
                    $SendSMSReal = $SendSMSReal -and $False
                    Break
                }
            }
            default {
                #$IsDublicate=$False
                $SendSMSReal = $False
            }
        } ### switch ($SMSTypeModem) {
    } ### if ( $SMSPhone -and $SMSTypeModem ) {

    # ������ $SMSPhone
    # ���� � $SMSPhone ���� ������ ':', ����� � ������ � ���������� ���� ������
    # �� ������ �� �������� ��� ����� ��������
    if ( $SMSPhone.Contains(':') ) {
        $arrPhones = [string[]]@()
        $SMSPhone.foreach({
            #$Result+=$_.Split(',;').foreach({ [regex]::replace(([regex]::replace($_.trim(), '\s', '')), '-', '')  })
            $arrPhones+=$_.Split(',;').foreach({ [regex]::replace($_.trim(), '[\s,-]', '')  })
        })
        foreach ( $ph in $arrPhones ) {
            if ($ph.Contains(':') ) {
                # ����� ���� � �������� ������ ������ � ����������
                $arr1 = $ph.split(':')
                $phone = $arr1[0]
                # ������������ ������ ��������� �� ������ ����������
                #     ��
                #     [Time1]
                #     UseSMSSendTime=1
                #     1=7-9
                #     2=9-11
                #     5=0
                #     �
                #     ���� �����������, �� $StrInterval4Phone='7-9'
                #     ���� �������,     �� $StrInterval4Phone='9-11'
                #     ���� �����,       �� $StrInterval4Phone=$StrInterval
                #     ���� �������,     �� $StrInterval4Phone=$StrInterval
                #     ���� �������,     �� $StrInterval4Phone='0'
                #     ���� �������,     �� $StrInterval4Phone=$StrInterval
                #     ���� �����������, �� $StrInterval4Phone=$StrInterval
                #     [Time2]
                #     UseSMSSendTime=0
                #     1=7-9
                #     2=9-11
                #     5=0
                #     �
                #     ���� �����������, �� $StrInterval4Phone='7-9'
                #     ���� �������,     �� $StrInterval4Phone='9-11'
                #     ���� �����,       �� $StrInterval4Phone=''
                #     ���� �������,     �� $StrInterval4Phone=''
                #     ���� �������,     �� $StrInterval4Phone='0'
                #     ���� �������,     �� $StrInterval4Phone=''
                #     ���� �����������, �� $StrInterval4Phone=''
                $SectionName = $arr1[1]
                $StrInterval4Phone = ''
                if ($pHashCFG.ContainsKey($SectionName) ) {
                    # ����� ��� ������ ������� ����
                    $dow = [string]((Get-Date).DayOfWeek.value__)
                    if ($dow -eq 0) { $dow=7 }
                    $dow = [string]$dow
                    # ������ ���������� ������� �� ���� ������
                    $SIDOW = [hashtable]($pHashCFG.$SectionName)
                    $UseInteravlFromCFG = $False
                    if ( $SIDOW.ContainsKey('UseSMSSendTime') ) {
                        $UseInteravlFromCFG = [boolean][int]$SIDOW.UseSMSSendTime
                    }
                    if ($SIDOW.ContainsKey($dow)) {
                        $StrInterval4Phone = $SIDOW.$dow
                    }
                    else {
                        if ($UseInteravlFromCFG) {
                            $StrInterval4Phone = $StrInterval
                        }
                        else {
                            $StrInterval4Phone = '0'
                        }
                    }
                }
                else {
                    $StrInterval4Phone = $StrInterval
                }
                if ( $StrInterval4Phone -eq '' ) { $StrInterval4Phone = '0' }
                $ResStr += (Notify-SMS -SMSPhone $phone `
                                    -SMSTypeModem $SMSTypeModem `
                                    -SMSIPManager $SMSIPManager `
                                    -SMSComPort $SMSComPort `
                                    -SendSMSReal $SendSMSReal `
                                    -textSMS $SMSText `
                                    -StrInterval $StrInterval4Phone `
                                    -pHashCFG $phashCFG)
            } ### if ($ph.Contains(':') ) {
            else {
                # ������� ��� ������� ':'
                $ResStr += (Notify-SMS -SMSPhone $ph `
                                    -SMSTypeModem $SMSTypeModem `
                                    -SMSIPManager $SMSIPManager `
                                    -SMSComPort $SMSComPort `
                                    -SendSMSReal $SendSMSReal `
                                    -textSMS $SMSText `
                                    -StrInterval $StrInterval `
                                    -pHashCFG $phashCFG)
            } ### else if ($ph.Contains(':') ) {
        } ### foreach ( $ph in $arrPhones ) {
    } else {
        $ResStr += "`n=========== ���������� SMS ========================="
        $ResStr += "`nSMSPhone`t:$($SMSPhone)"
        $ResStr += "`nSMSTypeModem`t:$($SMSTypeModem)"
        $ResStr += "`nSMSIPManager`t:$($SMSIPManager)"
        $ResStr += "`nSMSComPort`t:$($SMSComPort)"
        $ResStr += "`nSMSTest`t:$($textSMS)"
        $ResStr += "`nSendSMSReal`t:$($SendSMSReal)"
        $ResStr += "`nSMSSendTime`t:$($StrInterval)"
        $IsTime = TimeInStrInterval -SI $StrInterval -DT (Get-Date)
        $ResStr += "`nIsTime`t:$($IsTime)"
        if ($SendSMSReal -and $IsTime) {
            # ����������� �������� ���
            #SendSMS -Phones $SMSPhone -hostSMS $SMSIPManager -textSMS $textSMS -SMSComPort $SMSComPort -SMSTypeModem $SMSTypeModem
            $SMSZTE.SendSMS($textSMS, $SMSPhone)
        }
    }

    return $ResStr
}
 
# �������� ������ �� E-Mail
function SendEMail {
Param(
    [string]$SMTPServer=$SMTPServer,
    [string]$Login=$Login,
    [string]$Password=$Password,
    [string]$From=$From,
    [int]   $port=$port,
    [string[]]$To=$mailTo,
    [string]$subject="",
    [string]$Body,
    [boolean]$UseSSL=$UseSSL,
    [boolean]$SendEMail=$SendEMail,
    [boolean]$SendMailReal=$SendMailReal
<#
    [string[]]$SMSPhone,
    [string]$SMSTypeModem,
    [string]$SMSIPManager,
    [string]$SMSComPort,
    [boolean]$SendSMSReal
#>
)
    $ResStr = ""
    if (! $SendEMail) {
        return $ResStr
    }
    $ResStr += "�������� ������:`n"
    $ResStr += "SMTP server`t:$SMTPServer`n"
    $ResStr += "Port`t`t:$port`n"
    $ResStr += "Login`t`t:$Login`n"
    $ResStr += "Password`t:$Password`n"
    $ResStr += "UseSSL`t`t:$UseSSL`n"
    $ResStr += "From`t`t:$From`n"
    $ResStr += "To`t`t:$To`n"
    $ResStr += "Subject`t`t:$subject`n"
    $ResStr += "Body`t`t:$Body"
    if ( !$SendMailReal ) { $ResStr += "`nSendMailReal`t`t:$SendMailReal" }
    if ( ($To -eq "") -or ($From -eq "") -or ($SMTPServer -eq "") ) 
    {
        return $ResStr
    }
    if ($Login -eq "") {
        $Login=$From
    }
    if ($subject -eq "") {
        $subject="�������� ������."
    }
    $encoding = [System.Text.Encoding]::UTF8
    $secpasswd = ConvertTo-SecureString $Password -AsPlainText -Force
    $mycreds = New-Object System.Management.Automation.PSCredential ($Login, $secpasswd)

    if ($SendMailReal) {
        Send-MailMessage -to $To -from $From -Body $Body  -SmtpServer $SMTPServer -Subject $subject -UseSsl -Credential $mycreds -Encoding $encoding
    }
    return $ResStr
}

function Test-JobTestBad {
param(
    $Job=$null,
    $TimeWait=40,
    $Receive=$True,
    $ForceRemove=$False
)
    $result = $null
    $j=($Job|Get-Job -ErrorAction SilentlyContinue)
    if ( !$J -or ($j -eq $null) ) {
        return $result
    }
    if ($Job.State -eq [System.Management.Automation.JobState]::Running) {
        Wait-Job $Job -Timeout $TimeWait  -ErrorAction SilentlyContinue -Force
    }
    if ($Receive) {
        $result = (Receive-Job $Job  -ErrorAction SilentlyContinue)
    }
    if ($ForceRemove) {
        Remove-Job $Job -Force -ErrorAction SilentlyContinue
    }
    return $result
} ### function Test-JobTestBad {

<#---------------------------------
 ������ � SectionVariable
-----------------------------------#>

<# ������� ������ [VAR] � ��������������� �� ���������� �� ��������� #>
function New-SectionVariables () {
    $variables = [ordered]@{
        AbortScript=0
        CountPing=-1
        BadCount=3
        DelaySleep=5
        TimeOut=1500
        Log=0
        LogPath=""
        LogFileName=""
        LogAuto=0
        mailTo=""
        SMTPServer=""
        Login=""
        Password=''
        From=''
        port=''
        UseSSL=1
        SendEMail=1
        IntervalRepeatEMail=0
        SendOneMail=1
        ForceAddr=0
        SendMailReal=1
        SendResultFirst=1
        FileScript=$PSCommandPath
        BreakAfterStartJobs=0
        SMSPhone=''
        SMSTypeModem="ZTE"
        SMSIPManager="192.168.0.1"
        SMSComPort=""
        SendSMSReal=1
        SMSIntervalRepeat=0
        SMSSendResultFirst=0
        #SMSSendTimes=(,(@{h=0;m=0},@{h=23;m=59}))
        SMSSendTime="0-24"
        TelegramUse=1
        TelegramURL="https://api.telegram.org/bot"
        TelegramBot=""
        TelegramTo=""
    }
    return $variables
}

<# ������� ����� ������ [VAR] �� ���������� #>
function Copy-SectionVariables ([hashtable]$SectionVariables) {
    $result = New-SectionVariables
    $SectionVariables.Keys.ForEach({
        $result[$_]=$SectionVariables[$_]
    }) ### $SectionVariables.Keys.ForEach({
    return $result
}

<#---------------------------------
 ������ � ItemAddressList
-----------------------------------#>

<# ����� ������ ItemAddressList #>
function New-ItemAddressList ($SectionName, $IPNameIni, $FileLog) {
    $result = [ordered]@{
        Section=$SectionName
        IPNameINI=$IpNameINI
        Filelog=$FileLog
        ParamScript=$null
        Job=$null
        FlagExit=$false
    }
    return $result
}

function Combine-TwoIPsList ($OldList, $NewList, $OldHashCFG, $NewHashCFG) {
    $result = $OldList
    foreach ($e in [object[]]$result.Keys) {
        #$e
        if ( !($NewList.Contains($e)) ) {
            $ItIPL=$Result[$e]
            $CurrSect=$OldHashCFG[$ItIPL.Section].VAR
            $Job = $result[$e].Job
            If ($Job) {
                $Job = ($Job | Get-Job -ErrorAction SilentlyContinue)
            }
            if ( $Job ) {
                $job|Stop-Job -ErrorAction SilentlyContinue
                $job|Remove-Job -Force -ErrorAction SilentlyContinue
            }
            "����� $e ������ �� ������ �����������"| `
                Log -Level $CurrSect.Log -UseDate 4 -Log 2 -FileName $ItIPL.FileLog -TabCount 1 -ClassMSG ":DEL_ADDR:"
            $Result.Remove($e)
        }
    }
    foreach ($e in [object[]]$NewList.Keys) {
        #$e
        if ( !($Result.Contains($e)) ) {
            $Result.Add($e, $NewList[$e])
            $ItIPL=$Result[$e]
            $CurrSect=$NewHashCFG[$ItIPL.Section].VAR
            "����� $e �������� � ������ �����������" | `
                Log -Level $CurrSect.Log -UseDate 4 -Log 2 -FileName $ItIPL.FileLog -TabCount 1 -ClassMSG ":ADD_ADDR:"
        }
    }
    return $result
} ### function Combine-TwoIPsList ($OldList, $NewList) {


<#---------------------------------
 ������ � ResultPing � ItemResult
-----------------------------------#>

function New-ResultPing ($IPAddress, $Result, $Status, $DateStatus) {
    $ObjectRP = [ordered]@{
        #Computername = $Computername
        IPAddress = $IPAddress
        Result = $Result
        Status = $Status
        DateStatus = $DateStatus
        PrevStatus = $null
        PrevDateStatus = [datetime]0
        CurrentRepeatMail = 0
        JobTestBad=$null
        DateRepeatMail = [datetime]0
    }
    return $ObjectRP
}

function New-ItemResult($Code, $CodeString, $Msg) {
    #$arrResult=@{Code=0;CodeString='Sucess';Msg=@()}
    $result = @{
        Code=$Code
        CodeString=$CodeString
        Msg=$Msg
    }
    return $result
}

function Copy-ResultsPings ($Source) {
    $result = [ordered]@{}
#    Write-host ($ValueStatus -eq $null)
    $Source.keys.foreach({
        $Result.Add($_, (New-ResultPing) )
        $CurrIP=$_
        $Source[$CurrIP].Keys.ForEach({
            $Result[$CurrIP].$_ = $Source[$CurrIP].$_
        })
    })
    return $result
}

<#---------------------------------
 ������ � ��������� ���������
-----------------------------------#>

function ParseOneElement {
param (
    [Parameter(Mandatory=$true,ValueFromPipeline=$true)]
    [string] $OneElement
)
    begin{
        $result = [ordered]@{};
    }
    process{
        $h=[int32](($OneElement.Split(':')[0]));
        $m=[int32](($OneElement.Split(':')[1]));
        #echo "h=$h";
        #echo "m=$m";
        $e = (($h -gt 24) -or ($h -lt 0)) -or (($m -gt 59) -or ($m -lt 0));
        if ($h -eq 24) {
            $e = $e -or ($m -ne 0);
        }
        if (!$e) {
            $result.Add('h', $h);
            $result.Add('m', $m);
        } else {
            $result = $null;
        }
    }
    end{
        return $result;
    }
}

<# ������� ������ ��������� ���������� � ������ ��������� ����:
"0-24" ������������� �
@(
    @(
        @{h=0;m=0}, @{h=23;m=59}
    )
)
"6:20-13;16:20-20:15;23:20-5:15" ������������� �
@(
    @(
        @{h=6;m=20}, @{h=13;m=00}
    ),
    @(
        @{h=16;m=20}, @{h=20;m=15}
    ),
    @(
        @{h=23;m=20}, @{h=23;m=59}
    ),
    @(
        @{h=0;m=0}, @{h=5;m=15}
    )
)
"1-2;3:30-5:15;444;35-45;17:20-20:60;23:58-1:32;19:00-24:1;19:50-19:40;18:40-18:50;17:40-18" ������������� �

@(
    @(
        @{h=1;m=0}. @{h=2,m=0}
    )
    @(
        @{h=3;m=30}. @{h=5,m=15}
    )
    @(
        @{h=5;m=15}. @{h=3,m=30}
    )
    @(
        @{h=23;m=58}. @{h=23,m=59}
    )
    @(
        @{h=0;m=0}. @{h=1,m=32}
    )
    @(
        @{h=18;m=40}. @{h=18,m=50}
    )
    @(
        @{h=17;m=40}. @{h=18,m=0}
    )
#>
function StrInterval2Array {
param (
    # ������ ��������� ����������.
    [Parameter(Mandatory=$true,ValueFromPipeline=$true)]
    [string] $StrInterval
)

    begin
    {
        Write-Verbose "$($MyInvocation.Line)"
        $result = @()
    }
    process
    {
        $arrIs = $StrInterval.Split(";");
        $arrIs.ForEach({
            #echo $_;
            $arrIo = $_.Split('-');
            if ($arrIo.Count -eq 2) {
                #echo $_;
                #echo "arrio[0]=$($arrIo[0])";
                #echo "arrio[1]=$($arrIo[1])";
                $rB = ParseOneElement($arrIo[0]);
                $rE = ParseOneElement($arrIo[1]);
                if ($rB -and $rE) {
                    if ($rB.h -eq 24) { $rB.h = 0; }
                    if ($rE.h -eq 24) { $rE.h = 23; $rE.m=59; }
                    if ($rB.h -lt $rE.h) {
                        $result += ,@($rB, $rE);
                    } elseif ($rB.h -eq $rE.h) {
                        if ($rB.m -le $rE.m) {
                            $result += ,@($rB, $rE);
                        }
                    } else {
                        $result += ,@($rB, [ordered]@{h=23;m=59});
                        $result += ,@([ordered]@{h=0;m=0}, $rE);
                    }
                }
            }
        })
        #$result = $arrIs;
    }
    end
    {
        if ($result.Count -eq 1) {
            $result +=  ,@($result[0][0], $result[0][1]);
        }
        return $result;
    }
}

function TimeInStrInterval {
param (
    [Parameter(Mandatory=$true)]
    $SI,
    [Parameter(Mandatory=$true)]
    [DateTime]$DT
)
    if ( $SI -eq "24") {
        $result = $True;
    } else {
        $arrInterval = ($SI | StrInterval2Array);
        $result = $false;
        $vDate=[datetime]::new(1,1,1,$DT.Hour,$DT.Minute,0);
        foreach ($El In $arrInterval) {
#            $arrInterval.foreach({
           $DB=[datetime]::new(1,1,1,($El[0].h), ($El[0].m), 0);
            $DE=[datetime]::new(1,1,1,($El[1].h), ($El[1].m), 0);
            if ( ($vDate -ge $DB) -and ($vDate -le $DE) ) {
                $result = $True;
            }
            if ($result) {break;}
        }#)
    }
    return $result;
}

<#---------------------------------
 ������ � ������ ������������
-----------------------------------#>

<# ������ (������) ���������� �� ����� ������������ � hashtable. ������ � ������ #>
function avvImport-Ini {
#[CmdletBinding()]
param (
    # Name of the iniFile to be parsed.
    [Parameter(Mandatory=$true,ValueFromPipeline=$true)]
    [ValidateScript({ Test-Path -PathType:Leaf -Path:$_ })]
    [string] $IniFile
)

    begin
    {
        Write-Verbose "$($MyInvocation.Line)"
        $iniObj = [ordered]@{}
    }

    process
    {
        switch -regex -File $IniFile {
            "^\[(.+)\]$" {
                $section = $matches[1]
                $iniObj[$section] = [ordered]@{}
                #Continue
            }
            "(?<key>^[^\#\;\=]*)[=?](?<value>.+)" {
                $key  = $matches.key.Trim()
                $value  = $matches.value.Trim()

                if ( ($value -like '$(*)') -or ($value -like '"*"') ) {
                    # � INI ����� �������������� ���������� (�������) �� ������� 
                    # key1=$($var1)
                    # key2="$var1"
                    $value = Invoke-Expression $value
                }
                if ( $section ) {
                    $iniObj[$section][$key] = $value
                } else {
                    $iniObj[$key] = $value
                }
                continue
            }
            "(?<key>^[^\#\;\=]*)[=?]" {
                $key  = $matches.key.Trim()
                if ( $section ) {
                    $iniObj[$section][$key] = ""
                } else {
                    $iniObj[$key] = ""
                }
            }
        } ### switch -regex -File $IniFile {
    }
    end
    {
        return $iniObj
    }
}

<# ������� ��������� �� ����� ������������. ������ ����� � ������ #>
function Init-VariableCFG {
Param (
  [Parameter(ValueFromPipeline=$true,Position=0)]
  [string]$FileIni
)
    $result = $null
    try {
        # ������� ��������� �� .CFG �����
        $hashCFG=avvImport-Ini -IniFile $FileINI
            # ��������� � ���������������� ����� ���������� �� ������ [cfg] INI �����
        $hc=$hashCFG.cfg
        $Variables = [ordered]@{Global=(New-SectionVariables)}
        $vg=$Variables.Global
        $hc.Keys.Foreach({
            if ( $vg.Contains($_) ) {
                $vg[$_] = [Convert]::ChangeType($hc[$_], ($vg[$_]).GetType())
                #$vg[$_] = $hc[$_]
            }
        }) ### $vg.Keys.Foreach({
        $hc.Add('VAR', $vg)
            <#
            ��������� ���� ������ �������������� ����������� ������ �� [ipaddresses] ipaddress1='����������� ����� 1"
            [ipaddress1]
            CountPing=1
            ��� �������� �������������� �������� ���������� �� ����� ������ [cfg]
            #>
        $hashCFG.ipaddresses.keys.ForEach({
            if ( !($hashCFG[$_]) ) {
                # ���� ������ [ipaddress1] �� ����������, �� �������� � hastable �� ������
                $hashCFG.Add($_, [ordered]@{})
            } ### if ( !($hashCFG[$_]) ) {
            #if ( !($hashCFG[$_].VAR) ) {
            $hashCFG.$_.Add('VAR', (Copy-SectionVariables $vg) )
            $currSect=$_
            $hashCFG.$_.Keys.ForEach({
                #if ( $vg.Contains($_) ) {
                if ( $hashCFG.$currSect.var.Contains($_) ) {
                    $hashCFG.$currSect.var.$_ = [Convert]::ChangeType($hashCFG.$currSect.$_, ($hashCFG.$currSect.var.$_).GetType())
                    #$hashCFG.$currSect.var.$_ = $hashCFG.$currSect.$_
                }
            }) ### $hashCFG.$_.Keys.ForEach({
        }) ### $hashCFG.ipaddresses.keys.ForEach({
        $Result = $hashCFG
    }
    catch {
       $result = $null
    }
    return $result
}

<# ���������������� ������ �� ������ [ipaddresses] #>
function Init-IpAddresses {
param(
    [Parameter(ValueFromPipeline=$true,Position=0)]
    [hashtable]$CFG
)
    $Result=[ordered]@{}
    $CFG.ipaddresses.keys.foreach({
        try {
            $IPS=[System.Net.Dns]::GetHostAddresses($_).ipaddresstostring
        } catch {
            $IPS=$null
        }
        if ( $IPS -ne $null ) {
            foreach ($adr in $IPS) {
                if ( !($CFG[$_].VAR.AbortScript) ) {
                    $l=[logger]::new((Get-NameFileLog -parIP $_ -parIpDNS $adr -parIpStr $CFG.ipaddresses.$_ -LP $CFG.$_.VAR.LogPath -LFN $CFG.$_.VAR.LogFileName -LA $CFG.$_.VAR.LogAuto))
                    $result.Add($adr, (New-ItemAddressList $_ $CFG.ipaddresses.$_ $L.LogFile))
                }
            }
        } else {
            if ( $CFG.$_.VAR.ForceAddr ) {
                if ( !($CFG[$_].VAR.AbortScript) ) {
                    $L=[logger]::new((Get-NameFileLog -parIP $_ -parIpDNS $_ -parIpStr $CFG.ipaddresses.$_ -LP $CFG.$_.VAR.LogPath -LFN $CFG.$_.VAR.LogFileName -LA $CFG.$_.VAR.LogAuto))
                    $result.Add($_,   (New-ItemAddressList $_ $CFG.ipaddresses.$_ $L.LogFile))
                }
            }
        } ### if ( $IPS -ne $null ) {
    }) ### $CFG.ipaddresses.keys.foreach({
    return $Result
}

<#---------------------------------
 ArrayIP
-----------------------------------#>

function Remove-ArrayIPs($arrIPs, $Value) {
    $result=@()
    foreach ($e in $arrIPs) {
        if ( $e -ne $Value ) {
            $result +=$e
        }
    }
    return $result
} ### function Remove-ArrayIPs($arrIPs, $Value) {

<#---------------------------------
 �����, �������� ����� �� ��������� 1
-----------------------------------#>

<#
    result codes
    Success                       :0
    DestinationNetworkUnreachable :11002
    DestinationHostUnreachable    :11003
    DestinationProhibited         :11004
    DestinationProtocolUnreachable:11004
    DestinationPortUnreachable    :11005
    NoResources                   :11006
    BadOption                     :11007
    HardwareError                 :11008
    PacketTooBig                  :11009
    TimedOut                      :11010
    BadRoute                      :11012
    TtlExpired                    :11013
    TtlReassemblyTimeExceeded     :11014
    ParameterProblem              :11015
    SourceQuench                  :11016
    BadDestination                :11018
    DestinationUnreachable        :11040
    TimeExceeded                  :11041
    BadHeader                     :11042
    UnrecognizedNextHeader        :11043
    IcmpError                     :11044
    DestinationScopeMismatch      :11045
    Unknown                       :-1
#>
Function Test-ConnectionAsync {
#    [OutputType('Net.AsyncPingResult')]
#    [OutputType('System.Collections.Specialized.OrderedDictionary')]
    [cmdletbinding()]
    Param (
        [parameter(ValueFromPipeline=$True)]
        [string[]]$Computername,
        [parameter()]
        [int32]$Timeout = 100,
        [parameter()]
        [Alias('Ttl')]
        [int32]$TimeToLive = 128,
        [parameter()]
        [switch]$Fragment,
        [parameter()]
        [byte[]]$Buffer,
        [ref]$ReturnArray=([ref]$null)
    )
    Begin {
        
        If (-NOT $PSBoundParameters.ContainsKey('Buffer')) {
            $Buffer = 0x61, 0x62, 0x63, 0x64, 0x65, 0x66, 0x67, 0x68, 0x69, 0x6a, 0x6b, 0x6c, 0x6d, 0x6e, 0x6f, 
            0x70, 0x71, 0x72, 0x73, 0x74, 0x75, 0x76, 0x77, 0x61, 0x62, 0x63, 0x64, 0x65, 0x66, 0x67, 0x68, 0x69
        }
        $PingOptions = New-Object System.Net.NetworkInformation.PingOptions
        $PingOptions.Ttl = $TimeToLive
        If (-NOT $PSBoundParameters.ContainsKey('Fragment')) {
            $Fragment = $False
        }
        $PingOptions.DontFragment = $Fragment
        $Computerlist = New-Object System.Collections.ArrayList
        If ($PSBoundParameters.ContainsKey('Computername')) {
            [void]$Computerlist.AddRange($Computername)
        } Else {
            $IsPipeline = $True
        }
        if ( (($ReturnArray.Value) -eq $Null) -or ($ReturnArray -eq $Null) ) {
            $OnlyReturn=$True
        } else {
            $OnlyReturn=$False
        }
    }
    Process {
        If ($IsPipeline) {
            [void]$Computerlist.Add([string]$Computername)
        }
    }
    End {
        #Write-Host "OnlyReturn: $OnlyReturn" -BackgroundColor Red
        if ( !$OnlyReturn ) {
            $tt=New-Object System.Collections.ArrayList
            foreach ( $e in $Computerlist ) {
                if ( $ReturnArray.Value[$e].JobTestBad -eq $null ) {
                    $tt.Add($e)
                }
            }
            $Computerlist = $tt
        }
#        $Task = ForEach ($Computer in $Computername) {
        $Task = ForEach ($Computer in $ComputerList) {
            [pscustomobject] @{
                Computername = $Computer
                Task = (New-Object System.Net.NetworkInformation.Ping).SendPingAsync($Computer,$Timeout, $Buffer, $PingOptions)
            }

        }
        Try {
            [void][Threading.Tasks.Task]::WaitAll($Task.Task)
        } Catch {}
        $res = [ordered]@{}
        $datePing = Get-Date
        $Task | ForEach {
            If ($_.Task.IsFaulted) {
                # Exception operation
                #$Result = $_.Task.Exception.InnerException.InnerException.Message
                #$IPAddress = $Null
                $Result = -2
                $IPAddress = $_.Task.Exception.InnerException.InnerException.Message
            } Else {
                $Result = $_.Task.Result.Status
                $IPAddress = $_.task.Result.Address.ToString()
            }
            $Object = New-ResultPing -IPAddress $IPAddress -Result $Result `
                        -Status ($Result -eq ([System.Net.NetworkInformation.IPStatus]::Success)) `
                        -DateStatus $datePing
            #$Object.IPAddress = $IPAddress
            #$Object.Result = $Result
            #$Object.Status = $Result -eq ([System.Net.NetworkInformation.IPStatus]::Success)
            $res.Add($_.Computername, $Object)
            if ( !$OnlyReturn ) {
                $rav=($ReturnArray.Value)
                if ( $rav.Contains($_.ComputerName) ) {
                    $rav[$_.ComputerName].PrevStatus = $rav[$_.ComputerName].Status
                    $rav[$_.ComputerName].PrevDateStatus = $rav[$_.ComputerName].DateStatus
                    $rav[$_.ComputerName].IPAddress = $IPAddress
                    $rav[$_.ComputerName].Result = $Result
                    $rav[$_.ComputerName].Status = $Result -eq ([System.Net.NetworkInformation.IPStatus]::Success)
                    $rav[$_.ComputerName].DateStatus = $datePing
                } else {
                    $rav.Add($_.Computername, $Object)
                }
            }
        }
        return [System.Collections.Specialized.OrderedDictionary]$res
    }
}

<#
Return:
    =1     - ���������� AbortScript
    =2     - ������ ������ ���������� �� ����� ������������

    =4     - � ����� �������� ��� ������� � IP �������� ��� ��������
    =5     - ���� �������� �� ����������
    =100   - ������� �������� �������� CountPing (����������). ��������� �����
#>

function Test-IPALL-v1 ([string]$FileCFG='') {
    $Result=@()
    $DateBegin = Get-Date -Format "dd.MM.yyyy HH:mm:ss"
    if ( !$FileCFG -or !(Test-Path -Path $FileCFG) ) {
        $strErr="���� �������� $($FileCFG) �� ����������. ������ ����������."
        #Write-Host $StrErr -BackgroundColor Red
        $Result += @{Code=5;Msg=$StrErr}
        Return $Result
    }
    $hashCFG = Init-VariableCFG -FileIni $FileCFG
    ### ���� �� ��� �������� � ������ VAR
    ### $v=$hashCFG.cfg.var;$v.Keys.ForEach({ $s="$_ ($($v.$_.GetType()))";"$($s.PadRight(30,' ')):$($v.$_)" })
    if ( !($hashCFG) ) {
        $StrErr="������ ������ ���������� �� ����� ������������ $($FileCFG)"
        #Write-Host $StrErr -BackgroundColor Red
        $Result += @{Code=2;Msg=$StrErr}
        Return $Result
    }
    if ($hashCFG.ipaddresses.Count -eq 0) {
        $StrErr="� ����� ��������  $($FileCFG) ��� ������� � IP �������� ��� �������� (������ [ipaddresses])"
        #Write-Host $strErr -BackgroundColor Red
        $Result += @{Code=4;Msg=$StrErr}
        Return $Result
    }
    $IPList = ($hashCFG|Init-IpAddresses)
        #�������������� �����������
    $IPList.Keys.Foreach({
        $CurrIPList=$IPList[$_]
        $CurrSection=$hashCFG[$CurrIPList.Section]
        "$($_):::$($CurrIPList.IPNameINI)" | `
            Log -UseDate 1 -Log 1 -FileName $CurrIPList.Filelog -Level $CurrSection.VAR.Log -ClassMSG ":START_TEST:"


        $Str_logInit3="���������:
        CountPing`t:$($CurrSection.VAR.CountPing)
        BadCount`t:$($CurrSection.VAR.BadCount)
        DelaySleep`t:$($CurrSection.VAR.DelaySleep)
        TimeOut`t`t:$($CurrSection.VAR.TimeOut)
        Log`t`t`t:$($CurrSection.VAR.Log)
        LogPath`t`t:$($CurrSection.VAR.LogPath)
        LogFileName`t:$($CurrSection.VAR.LogFileName)
        LogAuto`t`t:$($CurrSection.VAR.LogAuto)
        mailTo`t`t:$($CurrSection.VAR.mailTo)
        SMTPServer`t:$($CurrSection.VAR.SMTPServer)
        Login`t`t:$($CurrSection.VAR.Login)
        Password`t:$($CurrSection.VAR.Password)
        From`t`t:$($CurrSection.VAR.From)
        port`t`t:$($CurrSection.VAR.port)
        UseSSL`t`t:$($CurrSection.VAR.UseSSL)
        SendEMail`t:$($CurrSection.VAR.SendEMail)
        SendOneEMail`t`t:$($CurrSection.VAR.SendOneMail)
        SendMailReal`t`t:$($CurrSection.VAR.SendMailReal)
        IntervalRepeatEMail`t:$($CurrSection.VAR.IntervalRepeatEMail)
        ForceAddr`t`t:$($CurrSection.VAR.ForceAddr)
        SendResultFirst`t`t:$($CurrSection.VAR.SendResultFirst)
        SendMailReal`t`t:$($CurrSection.VAR.SendMailReal)
        AbortScript`t`t:$($CurrSection.VAR.AbortScript)
        SMSPhone`t`t:$($CurrSection.VAR.SMSPhone)
        SMSTypeModem`t:$($CurrSection.VAR.SMSTypeModem)
        SMSIPManager`t:$($CurrSection.VAR.SMSIPManager)
        SMSComPort`t:$($CurrSection.VAR.SMSComPort)
        SendSMSReal`t:$($CurrSection.VAR.SendSMSReal)
        SMSIntervalRepeat`t:$($CurrSection.VAR.SMSIntervalRepeat)
        SMSSendResultFirst`t:$($CurrSection.VAR.SMSSendResultFirst)
        SMSSendTime`t:$($CurrSection.VAR.SMSSendTime)
        TelegramTo`t:$($CurrSection.VAR.TelegramTo)"
        $Str_logInit3 | Log -Level $CurrSection.VAR.Log -UseDate 6 -Log 2 -FileName $CurrIPList.FileLog -TabCount 2
    })

    $FirstRun=$True
    $FlagExit=$False
    $I=0

    $resPing=[ordered]@{}
    [string[]]$arrIPs=[string[]]($IPList.keys)
    #$arrIPs=[string[]]@()
    #foreach ( $e in [string[]]$IPList.keys) {
    #    $arrIPs+=$e
    #}
    $tr=[ordered]@{}
    $ReturnFlag=0
    while ( !($FlagExit) ) {
        $DateBeginWhile = Get-Date
        $DelaySleep=$hashCFG.cfg.VAR.DelaySleep
        $TimeOut=$hashCFG.cfg.VAR.TimeOut
        $CountPing=$hashCFG.cfg.VAR.CountPing

        $FlagExit = [boolean]$hashCFG.cfg.VAR.AbortScript
        if ($FlagExit) {
            $ReturnFlag=1 ### ���������� AbortScript
            Break
        }
        if ( $arrIPs.Count -lt 0 ) {
            $ReturnFlag=3
            Break
        }
        $tr=Test-ConnectionAsync -Computername $arrIPs -Timeout $TimeOut -ReturnArray ([ref]$resPing)
        $arrKeyResPing=[string[]]$resPing.Keys
        foreach ($ipaddr in $arrKeyResPing) { ## ��������� ���������� ������ �����
            $CurrResPing = $ResPing[$ipaddr]
            $CurrStatus  = $CurrResPing.Status

#            if ($CurrSection -and $CurrIPList) {
            if ( ($IPList[$ipaddr]) -and ($hashCFG[($IPList[$ipaddr]).Section]) ) {
                $CurrIPList = $IPList[$ipaddr]
                $CurrSection = $hashCFG[$CurrIPList.Section]
                    # ���������� ����� �� ping
                $CurrCountPing = [int64]$CurrSection.VAR.CountPing
                $PingOfCount="$([string]($i+1)) �� $([string]$CurrCountPing)"
                $PingOfCountStr="ping $([string]($i+1)) �� $([string]$CurrCountPing)"
                $paramSendEMail = @{
                    SMTPServer=$CurrSection.VAR.SMTPServer
                    Login=$CurrSection.VAR.Login
                    Password=$CurrSection.VAR.Password
                    From=$CurrSection.VAR.From
                    port=$CurrSection.VAR.port
                    To=$CurrSection.VAR.mailTo
                    subject=""
                    Body=""
                    UseSSL=$CurrSection.VAR.UseSSL
                    SendEMail=$CurrSection.VAR.SendEMail
                    SendMailReal=$CurrSection.VAR.SendMailReal
                }

                if ($CurrStatus) {
                    $StrSt = "UP"
                } else {
                    $StrSt = "DOWN"
                }
                if ( !($CurrResPing.JobTestBad) ) {
                    "$($CurrStatus):::$($ipaddr):::$($CurrIPList.Section):::$($CurrIPList.IPNameINI) ($PingOfCountStr)"| `
                            Log -UseDate 1 -Log 1 -FileName $CurrIPList.Filelog -Level $CurrSection.VAR.Log -ClassMSG ":PING:"
                    if ($FirstRun) {
                        # �������� � ���������� ������� �����, ���� ��������� �� EMail � SMS 
                        if ($CurrStatus) {
                            $CurrResPing.DateRepeatMail=0
                        } else {
                            $CurrResPing.DateRepeatMail=(Get-Date)
                        }
                        # �������� ������ ��� ������� (������ �������)
                        if ( $CurrSection.VAR.SendResultFirst ) {
                            $subjText = "$StrSt --- First run test $($CurrIPList.Section):::$($CurrIPList.IPNameINI). $PingOfCountStr"
                            $bodyText = "$(Get-Date ($CurrResPing.DateStatus) -Format 'dd.MM.yyyy HH:mm:ss') --- IP address $($CurrIPList.Section):::$ipaddr:::$($CurrIPList.IPNameINI) is $StrSt."
                            if ($CurrStatus) {
                                $bodyText += "`n`t��� �� ���� ���������� ��������.`n`t$PingOfCountStr`n"
                            } else {
                                $bodyText += "`n`t�� ���� ���������� �� �������� ����. ������� ���������� ��� ��������������.`n`t$PingOfCountStr`n"
                            }
                            $paramSendEMail.Body=$BodyText
                            $paramSendEMail.subject=$subjText
                            $logStr=(SendEMail @paramSendEMail)
                            $logStr | Log -UseDate 6 -Log 5 -TabCount 1 -FileName $CurrIPList.Filelog -Level $CurrSection.VAR.Log -ClassMSG ":SEND_MAIL:"
                        }
                            # �������� SMS ��� ������� (������ �������)
                        if ( $CurrSection.VAR.SMSSendResultFirst ) {
                            $SMSText = "$StrSt $($CurrIPList.Section):::$ipaddr:::$($CurrIPList.IPNameINI). $PingOfCountStr"
                            $LogStr=(Notify-SMS -SMSPhone $CurrSection.VAR.SMSPhone `
                                    -SMSTypeModem $CurrSection.VAR.SMSTypeModem `
                                    -SMSIPManager $CurrSection.VAR.SMSIPManager `
                                    -SMSComPort $CurrSection.VAR.SMSComPort `
                                    -SendSMSReal $CurrSection.VAR.SendSMSReal `
                                    -textSMS $SMSText `
                                    -StrInterval $CurrSection.VAR.SMSSendTime `
                                    -pHashCFG $hashCFG)
                            $LogStr| Log -UseDate 6 -Log 5 -TabCount 1 -FileName $CurrIPList.Filelog -Level $CurrSection.VAR.Log -ClassMSG ":SEND_SMS:"
                        } ### if ( $CurrSection.VAR.SMSSendResultFirst ) {
                            # ��������  message over telegram ��� ������� (������ �������)
                        if ( $CurrSection.VAR.TelegramUse ) {
                            #$SMSText = "$StrSt $($CurrIPList.Section):::$ipaddr:::$($CurrIPList.IPNameINI). $PingOfCountStr"
                            $LogStr=(Notify-Telegram `
                                    -textSMS $SMSText `
                                    -StrInterval $CurrSection.VAR.SMSSendTime `
                                    -pHashCFG $hashCFG `
                                    -pCurrentSection $CurrSection `
                                    -TelegramUse $CurrSection.VAR.TelegramUse `
                                    -TelegramTo $CurrSection.VAR.TelegramTo `
                                    -TelegramBot $CurrSection.VAR.TelegramBot `
                                    -TelegramURL $CurrSection.VAR.TelegramURL)
                            $LogStr| Log -UseDate 6 -Log 5 -TabCount 1 -FileName $CurrIPList.Filelog -Level $CurrSection.VAR.Log -ClassMSG ":SEND_SMS:"
                        } ### if ( $CurrSection.VAR.TelegramUse ) {
                    }
                    else { ### if ($FirstRun) {
                            # �� ������ ���������� ������
                        $CurrPrevStatus = $CurrResPing.PrevStatus
                        if ($CurrStatus) {
                                # ���� ���� � ������� ���������
                            # ��������� ���� �� ����� ���.��������, � ���� ���� ������� ���
                            if ( $CurrResPing.JobTestBad ) {
                                $resBadJob=Test-JobTestBad -Job $CurrResPing.JobTestBad -Receive $False -TimeWait 2 -ForceRemove $True
                                $CurrResPing.JobTestBad = $null
                            }
                            if ( $CurrPrevStatus -ne $CurrStatus ) {
                                    # �������� ������ ����� � ���� �� ������
                                "True:::$($ipaddr):::$($CurrIPList.Section):::$($CurrIPList.IPNameINI) �������� �����"| `
                                    Log -UseDate 2 -Log 2 -FileName $CurrIPList.Filelog -Level $CurrSection.VAR.Log -ClassMSG ":APPEARED:"
                                    #  ������ � ��������� ������
                                $CurrResPing.DateRepeatMail=0
                                $subjText = "UP --- $($CurrIPList.Section):::$($CurrIPList.IPNameINI). $PingOfCountStr"
                                $bodyText = "$(Get-Date ($CurrResPing.DateStatus) -Format 'dd.MM.yyyy HH:mm:ss') --- IP address $($CurrIPList.Section):::$ipaddr:::$($CurrIPList.IPNameINI) is $StrSt."
                                $bodyText += "`n`t��� �� ���� ���������� ��������.`n`t$PingOfCountStr`n"
                                $paramSendEMail.Body=$BodyText
                                $paramSendEMail.subject=$subjText
                                $LogStr=(SendEMail @paramSendEMail)
                                $LogStr | Log -UseDate 6 -Log 5 -TabCount 1 -FileName $CurrIPList.Filelog -Level $CurrSection.VAR.Log -ClassMSG ":SEND_MAIL:"
                                    # SMS
                                $SMSText =  "UP $($CurrIPList.Section):::$ipaddr:::$($CurrIPList.IPNameINI). $PingOfCountStr"
                                $LogStr=(Notify-SMS -SMSPhone $CurrSection.VAR.SMSPhone `
                                        -SMSTypeModem $CurrSection.VAR.SMSTypeModem `
                                        -SMSIPManager $CurrSection.VAR.SMSIPManager `
                                        -SMSComPort $CurrSection.VAR.SMSComPort `
                                        -SendSMSReal $CurrSection.VAR.SendSMSReal `
                                        -textSMS $SMSText `
                                        -StrInterval $CurrSection.VAR.SMSSendTime `
                                        -pHashCFG $hashCFG)
                                $LogStr | Log -UseDate 6 -Log 5 -TabCount 1 -FileName $CurrIPList.Filelog -Level $CurrSection.VAR.Log -ClassMSG ":SEND_SMS:"
                                    # ��������  message over telegram ��� ������� (������ �������)
                                if ( $CurrSection.VAR.TelegramUse ) {
                                    #$SMSText = "$StrSt $($CurrIPList.Section):::$ipaddr:::$($CurrIPList.IPNameINI). $PingOfCountStr"
                                    $LogStr=(Notify-Telegram `
                                            -textSMS $SMSText `
                                            -StrInterval $CurrSection.VAR.SMSSendTime `
                                            -pHashCFG $hashCFG `
                                            -pCurrentSection $CurrSection `
                                            -TelegramUse $CurrSection.VAR.TelegramUse `
                                            -TelegramTo $CurrSection.VAR.TelegramTo `
                                            -TelegramBot $CurrSection.VAR.TelegramBot `
                                            -TelegramURL $CurrSection.VAR.TelegramURL)
                                    $LogStr| Log -UseDate 6 -Log 5 -TabCount 1 -FileName $CurrIPList.Filelog -Level $CurrSection.VAR.Log -ClassMSG ":SEND_SMS:"
                                } ### if ( $CurrSection.VAR.TelegramUse ) {
                            } ### if ( $CurrPrevStatus -ne $CurrStatus ) {
                        }
                        else { ###if ($CurrStatus) {
                                # ��� ����� � ������� ���������
                            if ( $CurrPrevStatus -ne $CurrStatus ) {
                                    # �������� ������ � ������ �� ����
                                # ���� ��������� ����� (job) � ��������� �� BAD
                                if ( !$CurrResPing.JobTestBad ) {
                                    $CurrResPing.JobTestBad=
                                        Start-Job -ScriptBlock $sbTestBadPing -ArgumentList $ipaddr, $CurrSection.VAR.BadCount, $CurrSection.VAR.TimeOut
                                    "$($ipaddr):::$($CurrIPList.Section):::$($CurrIPList.IPNameINI) ������� job ��� ���.�������� ����� (Count:$($CurrSection.VAR.BadCount))" | `
                                        Log -UseDate 4 -Log 5 -TabCount 1 -FileName $CurrIPList.Filelog -Level $CurrSection.VAR.Log -ClassMSG ":START_JOB:"
                                }
                                $CurrResPing.DateRepeatMail=(Get-Date)

                            }
                            else { ### if ( $CurrPrevStatus -ne $CurrStatus ) {
                                    # ��� � ������� ������ ����
                                    # ��������� ��������� ������ ���� ���������
                                if ($CurrSection.VAR.IntervalRepeatEMail -gt 0) {
                                    $DDiff = (New-TimeSpan -Start $CurrResPing.DateRepeatMail -End (Get-Date)).TotalMinutes
                                    "��������� �� ������ ������:`t$(($CurrSection.VAR.IntervalRepeatEMail -gt 0))" | `
                                        Log -UseDate 2 -Log 10 -FileName $CurrIPList.Filelog -Level $CurrSection.VAR.Log -ClassMSG ":REQUIRE_REPEAT:"
                                    "���� � ������� ������� ������ ����:`t$($CurrResPing.DateRepeatMail)" | `
                                        Log -UseDate 2 -Log 10 -FileName $CurrIPList.Filelog -Level $CurrSection.VAR.Log -ClassMSG ":BEGIN_BADPING:"
                                    "��������� �������� � �������:`t$DDiff �� $($CurrSection.VAR.IntervalRepeatEMail)" | `
                                        Log -UseDate 2 -Log 10 -FileName $CurrIPList.Filelog -Level $CurrSection.VAR.Log -ClassMSG ":PAST_INTERVAL:"
                                    if ($DDiff -ge $CurrSection.VAR.IntervalRepeatEMail) {
                                        $CurrResPing.DateRepeatMail = Get-Date
                                        $CurrResPing.CurrentRepeatMail += 1
                                        "��������� ������: ��� ������ �� $($ipaddr):::$($CurrIPList.Section):::$($CurrIPsList.IPNameINI)" | `
                                            Log -UseDate 2 -Log 2 -FileName $CurrIPList.Filelog -Level $CurrSection.VAR.Log -ClassMSG ":REPEAT_MAIL:"
                                        $subjText = "DOWN REPEAT ($($CurrResPing.CurrentRepeatMail))--- $($CurrIPList.Section):::$($CurrIPList.IPNameINI). $PingOfCountStr"
                                        $bodyText += "$(Get-Date ($CurrResPing.DateStatus) -Format 'dd.MM.yyyy HH:mm:ss') --- IP address $($CurrIPList.Section):::$ipaddr:::$($CurrIPList.IPNameINI) is DOWN.`n"
                                        $bodyText += "�� ���� ���������� �� �������� ����. ������� ���������� ��� ��������������.`n"
                                        $bodyText += "$PingOfCountStr`n"
                                        $bodyText += "��������!!! ��������� ������.`n"

                                        $paramSendEMail.subject = $subjText
                                        $paramSendEMail.Body = $bodyText
                                        $LogStr=(SendEMail @paramSendEMail)
                                        $LogStr | Log -UseDate 6 -Log 5 -TabCount 1 -FileName $CurrIPList.Filelog -Level $CurrSection.VAR.Log -ClassMSG "SEND_MAIL"
                                            #SMS
                                        "��������� SMS: DOWN (R $(Get-Date ($CurrResPing.DateStatus) -Format 'dd.MM.yyyy HH:mm:ss')) $($CurrIPList.Section):::$ipaddr:::$($CurrIPList.IPNameINI). $PingOfCountStr" | `
                                            Log -UseDate 2 -Log 2 -FileName $CurrIPList.Filelog -Level $CurrSection.VAR.Log -ClassMSG ":REPEAT_SMS:"
                                        $SMSText = "DOWN (R) $($CurrIPList.Section):::$ipaddr:::$($CurrIPList.IPNameINI). $PingOfCountStr"
                                        $LogStr=(Notify-SMS -SMSPhone $CurrSection.VAR.SMSPhone `
                                                -SMSTypeModem $CurrSection.VAR.SMSTypeModem `
                                                -SMSIPManager $CurrSection.VAR.SMSIPManager `
                                                -SMSComPort $CurrSection.VAR.SMSComPort `
                                                -SendSMSReal $CurrSection.VAR.SendSMSReal `
                                                -textSMS $SMSText `
                                                -StrInterval $CurrSection.VAR.SMSSendTime `
                                                -pHashCFG $hashCFG)
                                        $LogStr | Log -UseDate 6 -Log 5 -TabCount 1 -FileName $CurrIPList.Filelog -Level $CurrSection.VAR.Log -ClassMSG "SEND_SMS"
                                            # ��������  message over telegram ��� ������� (������ �������)
                                        if ( $CurrSection.VAR.TelegramUse ) {
                                            #$SMSText = "$StrSt $($CurrIPList.Section):::$ipaddr:::$($CurrIPList.IPNameINI). $PingOfCountStr"
                                            $LogStr=(Notify-Telegram `
                                                    -textSMS $SMSText `
                                                    -StrInterval $CurrSection.VAR.SMSSendTime `
                                                    -pHashCFG $hashCFG `
                                                    -pCurrentSection $CurrSection `
                                                    -TelegramUse $CurrSection.VAR.TelegramUse `
                                                    -TelegramTo $CurrSection.VAR.TelegramTo `
                                                    -TelegramBot $CurrSection.VAR.TelegramBot `
                                                    -TelegramURL $CurrSection.VAR.TelegramURL)
                                            $LogStr| Log -UseDate 6 -Log 5 -TabCount 1 -FileName $CurrIPList.Filelog -Level $CurrSection.VAR.Log -ClassMSG ":SEND_SMS:"
                                        } ### if ( $CurrSection.VAR.TelegramUse ) {
                                    } ### if ($DDiff -ge $IntervalRepeatEMail) {
                                } ### if ($CurrSection.VAR.IntervalRepeatEMail -gt 0) {
                            } ### if ( $CurrPrevStatus -ne $CurrStatus ) {
                        } ### if ($CurrStatus) {
                    } ### if ($FirstRun) {
                } ### if ( !($CurrResPing.JobTestBad) ) {
                else {  ### if ( !($CurrResPing.JobTestBad) ) {
                    # ���� ��������� ����� ��� �������� BAD ����
                    # 1) job'� BadTest
                    $currJob=$CurrResPing.JobTestBad
                    if ( $currJob -and ($currJob.State -eq [System.Management.Automation.JobState]::Completed) ) {
                        #$res=receive-job $currJob -Force
                        $res=receive-job $currJob
                        # ���������� ������ �����
                        foreach ($e in $res.ArrLog) {
                            $e.msg | Log -UseDate 0 -Log $e.LogLevel -TabCount 1 -FileName $CurrIPList.Filelog -Level $CurrSection.VAR.Log -ClassMSG ":RES_BAD:"
                        }
                        if ($res.Status) {
                            # �������� ���� � �������� ���.��������
                            Test-JobTestBad -Job $CurrResPing.JobTestBad -Receive $False -TimeWait 2 -ForceRemove $True
                            $CurrResPing.JobTestBad = $null
                            $CurrResPing.PrevStatus = $True
                            $CurrResPing.Status = $True
                            $CurrResPing.DateStatus = Get-Date
                            $CurrResPing.PrevDateStatus = Get-Date
                            #$CurrResPing.DateRepeatMail=0
                        }
                        else {
                            # �� �������� ���� � �������� ���.��������
                            Test-JobTestBad -Job $CurrResPing.JobTestBad -Receive $False -TimeWait 2 -ForceRemove $True
                            $CurrResPing.JobTestBad = $null
                            $CurrResPing.PrevStatus = $False
                            $CurrResPing.PrevDateStatus = Get-Date
                            # ��������� EMail
                            $subjText = "DOWN --- $($CurrIPList.Section):::$($CurrIPList.IPNameINI). $PingOfCountStr"
                            $bodyText += "$(Get-Date ($CurrResPing.DateStatus) -Format 'dd.MM.yyyy HH:mm:ss') --- IP address $($CurrIPList.Section):::$ipaddr:::$($CurrIPList.IPNameINI) is DOWN.`n"
                            $bodyText += "�� ���� ���������� �� �������� ����. ������� ���������� ��� ��������������.`n"
                            $bodyText += "$PingOfCountStr`n"
                            $paramSendEMail.subject = $subjText
                            $paramSendEMail.Body = $bodyText
                            $LogStr=(SendEMail @paramSendEMail)
                            $LogStr | Log -UseDate 6 -Log 5 -TabCount 1 -FileName $CurrIPList.Filelog -Level $CurrSection.VAR.Log -ClassMSG ":SEND_MAIL:"
                                #SMS
                            $SMSText = "DOWN $($CurrIPList.Section):::$ipaddr:::$($CurrIPList.IPNameINI). $PingOfCountStr"
                            $LogStr=(Notify-SMS -SMSPhone $CurrSection.VAR.SMSPhone `
                                    -SMSTypeModem $CurrSection.VAR.SMSTypeModem `
                                    -SMSIPManager $CurrSection.VAR.SMSIPManager `
                                    -SMSComPort $CurrSection.VAR.SMSComPort `
                                    -SendSMSReal $CurrSection.VAR.SendSMSReal `
                                    -textSMS $SMSText `
                                    -StrInterval $CurrSection.VAR.SMSSendTime `
                                    -pHashCFG $hashCFG)
                            $logStr | Log -UseDate 6 -Log 5 -TabCount 1 -FileName $CurrIPList.Filelog -Level $CurrSection.VAR.Log -ClassMSG ":SEND_SMS:"
                                # ��������  message over telegram ��� ������� (������ �������)
                            if ( $CurrSection.VAR.TelegramUse ) {
                                #$SMSText = "$StrSt $($CurrIPList.Section):::$ipaddr:::$($CurrIPList.IPNameINI). $PingOfCountStr"
                                $LogStr=(Notify-Telegram `
                                        -textSMS $SMSText `
                                        -StrInterval $CurrSection.VAR.SMSSendTime `
                                        -pHashCFG $hashCFG `
                                        -pCurrentSection $CurrSection `
                                        -TelegramUse $CurrSection.VAR.TelegramUse `
                                        -TelegramTo $CurrSection.VAR.TelegramTo `
                                        -TelegramBot $CurrSection.VAR.TelegramBot `
                                        -TelegramURL $CurrSection.VAR.TelegramURL)
                                $LogStr| Log -UseDate 6 -Log 5 -TabCount 1 -FileName $CurrIPList.Filelog -Level $CurrSection.VAR.Log -ClassMSG ":SEND_SMS:"
                            } ### if ( $CurrSection.VAR.TelegramUse ) {
                            $CurrResPing.DateRepeatMail=(Get-Date)
                        }
                        "$([boolean]($res.Status)):::$($ipaddr):::$($CurrIPList.Section):::$($CurrIPList.IPNameINI) �������� job ��� ���.�������� ����� (Count:$($CurrSection.VAR.BadCount))" | `
                            Log -UseDate 4 -Log 5 -TabCount 1 -FileName $CurrIPList.Filelog -Level $CurrSection.VAR.Log -ClassMSG ":COMPLETED_JOB:"
                    } ###  ### if ( $currJob -and ($currJob.State -eq [System.Management.Automation.JobState]2) ) {
                } ###  ### if ( !($CurrResPing.JobTestBad) ) {
            } ### if ($CurrSection -and $CurrIPList) {
            else {
                # ��� ������ IP � INI �����,
                # �.�. ���� ������� �� ������� ������������ �������, ��� ���� �������
                # ���� ��������� � ����� JobTestBad
                if ( $CurrResPing.JobTestBad ) {
                    #Remove-Job $CurrResPing.JobTestBad -Force -ErrorAction SilentlyContinue
                    Test-JobTestBad -Job $CurrResPing.JobTestBad -TimeWait 2 -Receive $False -ForceRemove $True
                }
                $resPing.Remove($ipaddr)
                $arrIPs = Remove-ArrayIPs -arrIPs $arrIPs -Value $ipaddr
            } ### if ( $CurrSection -and $CurrIPList ) {
        } ### foreach ($ipaddr in $arrKeyResPing) { ## ��������� ���������� ������ �����
        $FirstRun = $False
            # ��������� AbortScript, ������� ip ������, CountPing, ����������������� ����������
            # � ������ �������
        # ����������������� hashCFG
        $hashCFGNew = Init-VariableCFG -FileIni $FileCFG
        if ( !($hashCFGNew) ) {
            $FlagExit   = $True
            $ReturnFlag =2;
            Break
        }
        if ($hashCFGNew.ipaddresses.Count -eq 0) {
            $FlagExit   = $True
            $ReturnFlag = 4
            Break
        }
        # ���������� AbortScript
        $FlagExit = [boolean]$hashCFGNew.cfg.VAR.AbortScript
        if ($FlagExit) {
            $ReturnFlag=1 ### ���������� AbortScript
            Break
        }
        # ����������������� IPList
        $IPListNew = ($hashCFGNew|Init-IpAddresses)
        [string[]]$tk=[string[]]@()
        $IPLT = $IPListNew
        $IPLT.keys.foreach({
            if ($HashCFGNew[$IPLT.$_.Section]) {
                $CP = $HashCFGNew[$IPLT.$_.Section].VAR.CountPing
                $AbS = $HashCFGNew[$IPLT.$_.Section].VAR.AbortScript
                if ( $CP -ge 0 ) {
                    if ($i -ge ($CP-1) ) {
                        $tk+=$_
                    }
                }
                if ( $AbS ) {
                    $tk+=$_
                }
            }
        }) ### $IPList.keys.foreach ({
        $tk.ForEach({
            $IPLT.Remove($_)
        })
        $IPList = Combine-TwoIPsList -OldList $IPList -NewList $IPListNew -OldHashCFG $HashCFG -NewHashCFG $hashCFGNew
        $HashCFG = $hashCFGNew
        # ��������� CountPing e ������� ������ � ������� ��, � ������� �� ������ $I
        $arrIPs=[string[]]($IPList.keys)

        # ������� �������� ����������
        $i++
        if ( $CountPing -ge 0 ) {
            $FlagExit = ($i -ge $CountPing)
            $ReturnFlag=100; ### ������� �������� �������� CountPing (����������)
        }
        if ( $FlagExit ) { break }
        $SecondWorkWhile = (New-TimeSpan -Start $DateBeginWhile -End (Get-Date)).TotalSeconds
        $tempSecond=$DelaySleep-$SecondWorkWhile-1
        if ( $tempSecond -gt 0 ) {
            Start-Sleep $DelaySleep
        }
    } ### while ( !($FlagExit) ) {

    #������� ��� Job's
    $resPing.Keys.foreach({
        if ($resPing.$_.JobTestBad) {
            Test-JobTestBad -Job $resPing.$_.JobTestBad -TimeWait 2 -Receive $False -ForceRemove $True
        }
    })

    switch ($ReturnFlag) {
        1 { # ���������� AbortScript
            $Result += @{Code=$ReturnFlag;Msg="� ������ CFG ����� ������������ ���������� ���� AbortScript"}
        }
        2 { # ������ ������ ���������� �� ����� ������������
            $Result += @{Code=$ReturnFlag;Msg="������ ������ ���������� �� ����� ������������ $($FileCFG)"}
        }
        3 { ### � ������� ��� ������ ($arrIP) ��� IP �������.
            $Result += @{Code=$ReturnFlag;Msg="� ������� ��� ������ ��� IP �������."}
        }
        4 { # � ����� �������� ��� ������� � IP �������� ��� ��������
            $Result += @{Code=$ReturnFlag;Msg="� ����� ��������  $($FileCFG) ��� ������� � IP �������� ��� �������� (������ [ipaddresses])"}
        }
        5 { # ���� �������� �� ����������
            $Result += @{Code=$ReturnFlag;Msg="���� �������� $($FileCFG) �� ����������. ������ ����������."}
        }
        100 { # ������� �������� �������� CountPing (����������). ��������� �����
            $Result += @{Code=$ReturnFlag;Msg="��������� ����. ������� �������� �������� CFG.CountPing (����������)."}
        }
        Default {
        }
    }
    Return $Result
}


#################################################################
#################################################################
#################################################################
#################################################################

#--------------------------------------------------------------
# ������ ���� ��� ������ BAD test ����� JOB
#--------------------------------------------------------------
$sbTestBadPing={
param(
    $ip,
    $Count,
    $TimeOut
)

    if ( ($Timeout -le 0) -or ($Timeout -gt 4) ) {
        $TimeOut = 2
    }
    if ( ($Count -lt 0) -or ($Count -gt 10) ) {
        $Count = 5
    }
    $result=@{Status=$False;arrLog=[object[]]@()}
    $Filter = 'Address="{0}" and Timeout={1}' -f $ip, (1000*$TimeOut)
    for ($bc=1; $bc -le $Count; $bc++) {
        if ( ($bc -ge 1) -and ($bc -le 5) ) {
            $EX = 3*$bc
        }
        else {
            $EX = 3
        }
        $dt=Get-Date -Format "dd.MM.yyyy HH:mm:ss"                    
        $result.arrLog += (@{
            msg="$ip:::$(Get-Date -Format 'dd.MM.yyyy HH:mm:ss')`t`t��������� �������� ($bc �� $Count) ����� $EX ������ Timeout=$($TimeOut)"
            LogLevel=10
        })
            #���������� �������� ����
        $ResPing = Get-WmiObject -Class Win32_PingStatus -Filter $Filter
        if ($ResPing.ResponseTime) {
            $RT = $ResPing.ResponseTime
        } else {
            $RT = $ResPing.TimeOut
        }
        $St = ($ResPing.StatusCode -eq 0)
        $result.arrLog += (@{
            msg="$ip:::$(Get-Date -Format 'dd.MM.yyyy HH:mm:ss')`t`t$($bc)-� �� $Count �������� ��� ���������� ����� - $St"
            LogLevel=2
        })
        if ($St ) { break }
        Start-Sleep -Seconds $EX
        #Start-Sleep -Seconds 2 # DEBUG
    } ### for ($bc=1; $bc -le $Count; $bc++) {
    $Result.Status=$St
    return $result
}
#--------------------------------------------------------------
# ������ ���� ��� ������ BAD test ����� JOB
#--------------------------------------------------------------

#$logger=[logger]::new('d:\temp\123', 1)
#$logger

#$iniCFG=('D:\������\0scripts\ps\Async\test-IP-Async-job8\test-ip-job-v8.ps1.cfg'|Init-VariableCFG)
#$v=$iniCFG.cfg.var;$v.Keys.ForEach({ $s="$_ ($($v.$_.GetType()))";"$($s.PadRight(30,' ')):$($v.$_)" })

#$IPS=($iniCFG|Init-IpAddresses)

$Version=1

if ( !$FileCFG ) {
    $FileCFG = $PSCommandPath + '.cfg'
}

###########################################################################################################################
### ��� �������
# ����� ��� ������ (����������������)

#$hashCFG = Init-VariableCFG -FileIni $FileCFG

#exit

### ��� �������
###########################################################################################################################

if ( ! (Test-Path -Path $FileCFG) ) {
    Write-Host "���� �������� $($FileCFG) �� ����������. ������ ����������." -BackgroundColor Red
    Exit
}

<#
######################## DEBUG
#$r=StrInterval2Array("1-2;3:30-5:15;444;35-45;17:20-20:60;23:58-1:32;19:00-24:1;19:50-19:40;18:40-18:50;17:40-18");$r.Count;echo '----------------';$r;
$d1=[datetime]::new(1,1,1,4,58,0);
$ti = '1-2;3:30-5:15;444;35-45;17:20-20:60;23:58-1:32;19:00-24:1;19:50-19:40;18:40-18:50;17:40-18'
echo "$($d1) in $($ti) === $(TimeInStrInterval -SI $ti -DT $d1)"
$d1=Get-Date
$ti="0-23:31"
echo "$($d1) in $($ti) === $(TimeInStrInterval -SI $ti -DT $d1)"
$d1=Get-Date
$ti="24"
echo "$($d1) in $($ti) === $(TimeInStrInterval -SI $ti -DT $d1)"

#$hashCFG = Init-VariableCFG -FileIni $FileCFG
#$r=(Notify-SMS -SMSPhone '+71:Time1,82;83:Time2,+74:Time3' `
#                                    -SMSTypeModem 'ZTE' `
#                                    -SMSIPManager '192.168.0.1' `
#                                    -SendSMSReal 0 `
#       0                             -textSMS "text SMS" `
#                                    -StrInterval "0-2;6:30-8:45;11-20" `
#                                    -pHashCFG $hashCFG)#

EXIT

######################### DEBUG END
#>


if ( ($version -eq 1) -or $version -eq 0 ) {
    # �������� �� ��������� 1.
    return Test-IPALL-v1 -FileCFG $FileCFG
}
elseif ($version -eq 2) {
    # �������� �� ��������� 2.
    if ( $IPAddress ) {
        $res = Test-IPOne-v2 -FileCFG $FileCFG -ipaddress $IPAddress
    }
    else {
        $res = Test-IPALL-v2 -FileCFG $FileCFG
    }
    $res
}
else {
}







EXIT
