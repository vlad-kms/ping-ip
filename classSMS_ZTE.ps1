Class SMS_ZTE {
    [string]$Server
    [string]$Referer
    [string]$Host
    [string]$Origin

    [hashtable]$Headers
    [string]$GetForm
    [string]$SetForm
    [int32]$NumberSendAtATime


    SMS_ZTE([string]$Server) {
        $this.Server = $Server
        $this.Referer = "http://$Server/index.html"
        $this.Host = "$Server"
        $this.Origin = "http://$Server"
        $this.GetForm="/goform/goform_get_cmd_process"
        $this.SetForm="/goform/goform_set_cmd_process"
        $this.Headers=@{}
        $this.Headers.Add('Referer', "$($this.Referer)")
        $this.Headers.Add('Origin', "$($this.Origin)")
        $this.Headers.Add("Accept-Encoding","gzip, deflate")
        $this.Headers.Add("Accept-Language", "ru-RU,ru;q=0.9,en-US;q=0.8,en;q=0.7")
        $this.Headers.Add('Content-Type', 'application/x-www-form-urlencoded; charset=UTF-8')
        $this.Headers.Add("Accept", "application/json, text/javascript, */*; q=0.01")
        $this.Headers.Add("X-Requested-With", "XMLHttpRequest")
        $this.NumberSendAtATime=5
    }

    [string]ConvertTextToSMS ([string]$msg) {
        $encTo = [System.Text.Encoding]::GetEncoding('unicode')
        $bytes = $encTo.GetBytes($msg)
        $result=''
        for ($i=0; $i -lt [int32]($bytes.Count/2);$i++) {
            $ce=$bytes[$i*2]
            $result += ('{0:x2}' -f [int]$bytes[$i*2+1])
            $result += ('{0:x2}' -f [int]$bytes[$i*2])
        }
        return $result
    }

    [string]ConvertListSMSToString([object[]]$ListSMS, [string]$FieldName) {
        $Result = ""
        $ListSMS.ForEach({
            $Result+=([string]$_.$FieldName+';')
        })
        return $Result
    }

    [string[]]ConvertPhonesStrToArray([string]$Phones, [boolean]$Test) {
        $Result = [string[]]@()
        $Phones.foreach({
            #$Result+=$_.Split(',;').foreach({ [regex]::replace(([regex]::replace($_.trim(), '\s', '')), '-', '')  })
            $Result+=$_.Split(',;').foreach({ [regex]::replace($_.trim(), '[\s,-]', '')  })
        })
        if ($Test) {
            $tmpArr=[string[]]@()
            try {
                foreach ($el in $Result) {
                    if ( [regex]::IsMatch($el, '[^\d-+]') ) {
                      $IsAdd=$False
                      Continue
                    }
                    $IsAdd=$True
                    switch ($el.Length) {
                        10 {
                            if ( [regex]::IsMatch($el, '[+]') ) {
                                $IsAdd=$False
                                Continue
                            }
                            $fc = $el.Substring(0,1)
                            if ( $fc -eq '8' ) {
                                $IsAdd=$False
                                Continue
                            }
                            $el='+7'+$el
                        }
                        11 {
                            if ( [regex]::IsMatch($el, '[+]') ) {
                                $IsAdd=$False
                                Continue
                            }
                            $fc = $el.Substring(0,1)
                            if ( ($fc -eq '8') -or ($fc -eq '7') ) {
                                $el = '+7'+ $el.Substring(1, 10)
                            } else {
                                $IsAdd=$False
                            }
                        }
                        12 {
                            if ( ($el.Substring(0,2)) -ne '+7' ) {
                                $IsAdd=$False
                            }
                        }
                        Default {
                            $IsAdd=$False
                        }
                    }
                    if ($IsAdd) {
                        $tmpArr += $el
                    }
                } ### foreach ($el in $Result) {
                $result = $tmpArr
            }
            catch {
                $Result = [string[]]@()
            }
        }
        return $Result
    }

    [object[]]GetListSMS () {
        $r=Invoke-WebRequest -Uri "$($this.Origin)$($this.GetForm)?isTest=false&cmd=sms_data_total&page=0&data_per_page=500&mem_store=1&tags=10&order_by=order+by+id+desc" -Headers $this.Headers
        $s=$r.Content.Replace("{""messages"":[{","")
        $s=($s.SubString(0, $s.Length-3)) -split "},{"
        $arrRet=@()
        $s.ForEach({
            $e=$_ -split ',', 3
            $hs=( (($e[0] -replace """", '') -replace ':', '=')|ConvertFrom-StringData )+( (($e[1] -replace """", '') -replace ':', '=')|ConvertFrom-StringData )
            $arrRet+=$hs
        })
        return $arrRet
    }

    [string]GetIdListSMS ([object[]]$ArraySMS) {
        $Result = ""
        $ArraySMS.ForEach({
            $Result+=("$([string]$_.ID);")
        })
        return $Result
    }

    [object[]]sendSMS ([string]$textSMS, [string]$Phones) {
       <#
        $Phones - строка телефонов разделенных ',' или ';'
        #>
        [object[]]$Result=@()
        $textSMS=$this.ConvertTextToSMS($textSMS)
        $arrPhones=$this.ConvertPhonesStrToArray($Phones, $True)
        #$plus=('%'+$this.ConvertTextToSMS("+").Substring(2,2)).ToUpper()
        #$ps=[regex]::Replace($ps, '\+', $plus)
        $url=$this.Origin+$this.SetForm
        $bd=@{
            isTest=$false
            goformId='SEND_SMS'
            notCallback=$true
            Number=""
            sms_time=""
            MessageBody=$textSMS
            ID=-1
            encode_type='UNICODE'
        }

        $ps=""
        for ($i=0; $i -lt $arrPhones.Count; $i++) {
            if ( ($i -gt 0) -and (($i % ($this.NumberSendAtATime)) -eq 0) ) {
                $dt=Get-Date
                $dt =
                    ([string]($dt.Year-2000)).PadLeft(2, '0') + ';' +
                    ([string]($dt.Month)).PadLeft(2, '0') + ';' +
                    ([string]($dt.Day)).PadLeft(2, '0') + ';' +
                    ([string]($dt.Hour)).PadLeft(2, '0') + ';' +
                    ([string]($dt.Minute)).PadLeft(2, '0') + ';' +
                    ([string]($dt.Second)).PadLeft(2, '0') + ';+' +
                    #([string]($dt.Millisecond)).PadLeft(2, '0')
                    '10'
                $bd.sms_time="$dt"
                $bd.Number="$ps"
                $ps=""
                $Result+=Invoke-WebRequest $url -Method Post -Body $bd -Headers $this.Headers
            } 
            $ps+="$($arrPhones[$i]);"

        } ### for ($i=0; $i -lt $arrPhones.Count; $i++) {
        if ($ps) {
            $dt=Get-Date
            $dt =
                ([string]($dt.Year-2000)).PadLeft(2, '0') + ';' +
                ([string]($dt.Month)).PadLeft(2, '0') + ';' +
                ([string]($dt.Day)).PadLeft(2, '0') + ';' +
                ([string]($dt.Hour)).PadLeft(2, '0') + ';' +
                ([string]($dt.Minute)).PadLeft(2, '0') + ';' +
                ([string]($dt.Second)).PadLeft(2, '0') + ';+' +
                #([string]($dt.Millisecond)).PadLeft(2, '0')
                '10'
            $bd.sms_time="$dt"
            $bd.Number="$ps"
            $Result+=Invoke-WebRequest $url -Method Post -Body $bd -Headers $this.Headers
        }
        return $Result
    }

    [object]DeleteSMS([string]$ListIDSMS){
        $Result=[object]::new()
        if ( !$ListIDSMS) {
            return $Result
        }
        $b=@{
            'isTest'=$false
            'goformId'="DELETE_SMS"
            'msg_id'=$ListIDSMS
            'notCallback'=$true
        }
        $Result = Invoke-WebRequest -Uri "$($this.Origin)$($this.SetForm)" -Method "POST" -Headers $this.Headers -Body $b
        return $Result
    } ### [object]DeleteSMS([string]$ListIDSMS){

    [object]ClearSMS(){
        return ($this.DeleteSMS(
                $this.GetIdListSMS($this.GetListSMS())
            ))
    }

}
<#
$s=[SMS_ZTE]::new('192.168.0.1');
'%'+$s.ConvertTextToSMS("+").Substring(2,2)
$a="просто"
$a
"==================================="
$s.ConvertTextToSMS($a)
"==================================="
$a
$lsms=$s.GetListSMS()
#$s.NumberSendAtATime=2
#$s.sendSMS($a, '91417782-36;9141851182;91441474-06')
#$s.sendSMS($a, '91417782-01;91441474-02;91441474-03,91441474-04,91441474-05,91441474-06,')
#>
