#
# Workday.ps1 - Workday Web Services API (SOAP)
#


$Log_MaskableKeys = @(
    # Put a comma-separated list of attribute names here, whose value should be masked before 
    'Password'
)

#
# System functions
#
function Idm-SystemInfo {
    param (
        # Operations
        [switch] $Connection,
        [switch] $TestConnection,
        [switch] $Configuration,
        # Parameters
        [string] $ConnectionParams
    )

    Log info "-Connection=$Connection -TestConnection=$TestConnection -Configuration=$Configuration -ConnectionParams='$ConnectionParams'"
    
    if ($Connection) {
        @(
            @{
                name = 'Hostname'
                type = 'textbox'
                label = 'Hostname'
                description = 'Hostname for Web Services'
                value = 'wd2-impl-services1.workday.com'
            }
            @{
                name = 'tenantid'
                type = 'textbox'
                label = 'Tenant Id'
                description = 'Name of Tenant'
                value = ''
            }
            @{
                name = 'username'
                type = 'textbox'
                label = 'Username'
                label_indent = $true
                description = 'Username account'
                value = ''
            }
            @{
                name = 'password'
                type = 'textbox'
                password = $true
                label = 'Password'
                label_indent = $true
                description = 'User account password'
                value = ''
            }
            @{
                name = 'version'
                type = 'textbox'
                label = 'Version'
                label_indent = $true
                description = 'AXL API Version'
                value = '39.2'
            }
            @{
                name = 'nr_of_sessions'
                type = 'textbox'
                label = 'Max. number of simultaneous sessions'
                description = ''
                value = 5
            }
            @{
                name = 'sessions_idle_timeout'
                type = 'textbox'
                label = 'Session cleanup idle time (minutes)'
                description = ''
                value = 30
            }
        )
    }

    if ($TestConnection) {
        
    }

    if ($Configuration) {
        @()
    }

    Log info "Done"
}

function Idm-OnUnload {
}


#
# Object CRUD functions
#
$Properties = @{
    Worker = @(
        @{ name = 'WorkerWid';                              options = @('default','key')                      }
        @{ name = 'Active';                              options = @('default')                      }
        @{ name = 'WorkerDescriptor';                              options = @('default')                      }
        @{ name = 'PreferredName';                              options = @('default')                      }
        @{ name = 'FirstName';                              options = @('default')                      }
        @{ name = 'LastName';                              options = @('default')                      }
        @{ name = 'WorkerType';                              options = @('default')                      }
        @{ name = 'WorkerId';                              options = @('default')                      }
        @{ name = 'UserId';                              options = @('default')                      }
        @{ name = 'NationalId';                              options = @('default')                      }
        @{ name = 'OtherId';                              options = @('default')                      }
        @{ name = 'Phone';                              options = @('default')                      }
        @{ name = 'Email';                              options = @('default')                      }
        @{ name = 'BusinessTitle';                              options = @('default')                      }
        @{ name = 'JobProfileName';                              options = @('default')                      }
        @{ name = 'Location';                              options = @('default')                      }
        @{ name = 'WorkSpace';                              options = @('default')                      }
        @{ name = 'WorkerTypeReference';                              options = @('default')                      }
        @{ name = 'Manager_WorkerID';                              options = @('default')                      }
        @{ name = 'Manager_WorkerType';                              options = @('default')                      }
        @{ name = 'Company';                              options = @('default')                      }
        @{ name = 'BusinessUnit';                              options = @('default')                      }
        @{ name = 'Supervisory';                              options = @('default')                      }
    )
    WorkerEmail = @(
        @{ name = 'WorkerWid';                              options = @('default','key')                      }
        @{ name = 'UsageType';                              options = @('default')                      }
        @{ name = 'Email';                              options = @('default')                      }
        @{ name = 'Primary';                              options = @('default')                      }
        @{ name = 'Public';                              options = @('default')                      }
    )
    WorkerDocument = @(
        @{ name = 'WorkerWid';                              options = @('default','key')                      }
        @{ name = 'FileName';                              options = @('default')                      }
        @{ name = 'Category';                              options = @('default')                      }
        @{ name = 'Base64';                              options = @('default')                      }
        @{ name = 'Path';                              options = @('default')                      }
    )
    WorkerNationalId = @(
        @{ name = 'WorkerWid';                              options = @('default','key')                      }
        @{ name = 'Type';                              options = @('default')                      }
        @{ name = 'ID';                              options = @('default')                      }
        @{ name = 'Descriptor';                              options = @('default')                      }
    )
    WorkerOtherId = @(
        @{ name = 'WorkerWid';                              options = @('default','key')                      }
        @{ name = 'Type';                              options = @('default')                      }
        @{ name = 'ID';                              options = @('default')                      }
        @{ name = 'Descriptor';                              options = @('default')                      }
        @{ name = 'Issued_Date';                              options = @('default')                      }
        @{ name = 'Expiration_Date';                              options = @('default')                      }
    )
    WorkerPhone = @(
        @{ name = 'WorkerWid';                              options = @('default','key')                      }
        @{ name = 'UsageType';                              options = @('default')                      }
        @{ name = 'DeviceType';                              options = @('default')                      }
        @{ name = 'Number';                              options = @('default')                      }
        @{ name = 'Extension';                              options = @('default')                      }
        @{ name = 'Primary';                              options = @('default')                      }
        @{ name = 'Public';                              options = @('default')                      }
    )
}

$Global:NM = New-Object System.Xml.XmlNamespaceManager -ArgumentList (New-Object System.Xml.NameTable)
$Global:NM.AddNamespace('wd','urn:com.workday/bsvc')
$Global:NM.AddNamespace('bsvc','urn:com.workday/bsvc')

$Global:WorkersInitialized = $false
$Global:Workers = [System.Collections.ArrayList]@()
$Global:WorkersEmail = [System.Collections.ArrayList]@()
$Global:WorkersDocument = [System.Collections.ArrayList]@()
$Global:WorkersNationalId = [System.Collections.ArrayList]@()
$Global:WorkersOtherId = [System.Collections.ArrayList]@()
$Global:WorkersPhone = [System.Collections.ArrayList]@()

function Idm-WorkersRead {
    param (
        [switch] $GetMeta,
        [string] $SystemParams,
        [string] $FunctionParams
    )
    $Class = "Worker"
    Log info "-GetMeta=$GetMeta -SystemParams='$SystemParams' -FunctionParams='$FunctionParams'"

    if ($GetMeta) {

        Get-ClassMetaData -SystemParams $SystemParams -Class $Class
    }
    else {
        
        $system_params   = ConvertFrom-Json2 $SystemParams
        $function_params = ConvertFrom-Json2 $FunctionParams

        $properties = $function_params.properties

        if ($properties.length -eq 0) {
            $properties = ($Global:Properties.$Class | Where-Object { $_.options.Contains('default') }).name
        }

        # Assure key is the first column
        $key = ($Global:Properties.$Class | Where-Object { $_.options.Contains('key') }).name
        $properties = @($key) + @($properties | Where-Object { $_ -ne $key })

        try { 
                
                if($Global:WorkersInitialized -eq $false) {
                    $xmlRequest = '<bsvc:Get_Workers_Request bsvc:version="v30.0">
                                    <bsvc:Response_Filter>
                                        <bsvc:Page>1</bsvc:Page>
                                    </bsvc:Response_Filter>
                                    <bsvc:Request_Criteria>
                                        <bsvc:Exclude_Inactive_Workers>true</bsvc:Exclude_Inactive_Workers>
                                    </bsvc:Request_Criteria>
                                    <bsvc:Response_Group>
                                        <bsvc:Include_Reference>true</bsvc:Include_Reference>
                                        <bsvc:Include_Personal_Information>true</bsvc:Include_Personal_Information>
                                        <bsvc:Include_Employment_Information>true</bsvc:Include_Employment_Information>
                                        <bsvc:Include_Compensation>true</bsvc:Include_Compensation>
                                        <bsvc:Include_Organizations>true</bsvc:Include_Organizations>
                                        <bsvc:Include_Roles>true</bsvc:Include_Roles>
                                        <bsvc:Include_Worker_Documents>true</bsvc:Include_Worker_Documents>
                                    </bsvc:Response_Group>
                                </bsvc:Get_Workers_Request>'

                
                    $response = Invoke-WorkdayRequest -SystemParams $system_params -FunctionParams $function_params -Body $xmlRequest -Namespace "Human_Resources"
                    
                    foreach($item in ($response | ConvertFrom-WorkdayWorkerXml) ) {
                        [void]$Global:Workers.Add($item)
                    }
                    
                    $Global:WorkersInitialized = $true
                } else {
                    $Global:Workers
                }
                
                
            }
            catch {
                Log error "Failed: $_"
                Write-Error $_
            }
    }

    Log info "Done"
}

function Idm-WorkersEmailRead {
    param (
        [switch] $GetMeta,
        [string] $SystemParams,
        [string] $FunctionParams
    )
    $Class = "WorkerEmail"
    Log info "-GetMeta=$GetMeta -SystemParams='$SystemParams' -FunctionParams='$FunctionParams'"

    if ($GetMeta) {

        Get-ClassMetaData -SystemParams $SystemParams -Class $Class
    }
    else {
        if($Global:WorkersInitialized -eq $false)
        {
            Log info "Worker data not yet collected, collecting now"
            Idm-WorkersRead -FunctionParams $FunctionParams -SystemParams $SystemParams > $null
        }
        
        $system_params   = ConvertFrom-Json2 $SystemParams
        $function_params = ConvertFrom-Json2 $FunctionParams

        $properties = $function_params.properties

        if ($properties.length -eq 0) {
            $properties = ($Global:Properties.$Class | Where-Object { $_.options.Contains('default') }).name
        }

        # Assure key is the first column
        $key = ($Global:Properties.$Class | Where-Object { $_.options.Contains('key') }).name
        $properties = @($key) + @($properties | Where-Object { $_ -ne $key })

        try { 
                foreach($item in $Global:WorkersEmail) {
                    [PSCustomObject]$item
                }
                
            }
            catch {
                Log error "Failed: $_"
                Write-Error $_
            }
    }

    Log info "Done"
}

function Idm-WorkersDocumentRead {
    param (
        [switch] $GetMeta,
        [string] $SystemParams,
        [string] $FunctionParams
    )
    $Class = "WorkerDocument"
    Log info "-GetMeta=$GetMeta -SystemParams='$SystemParams' -FunctionParams='$FunctionParams'"

    if ($GetMeta) {

        Get-ClassMetaData -SystemParams $SystemParams -Class $Class
    }
    else {
        if($Global:WorkersInitialized -eq $false)
        {
            Log info "Worker data not yet collected, collecting now"
            Idm-WorkersRead -FunctionParams $FunctionParams -SystemParams $SystemParams > $null
        }
        
        $system_params   = ConvertFrom-Json2 $SystemParams
        $function_params = ConvertFrom-Json2 $FunctionParams

        $properties = $function_params.properties

        if ($properties.length -eq 0) {
            $properties = ($Global:Properties.$Class | Where-Object { $_.options.Contains('default') }).name
        }

        # Assure key is the first column
        $key = ($Global:Properties.$Class | Where-Object { $_.options.Contains('key') }).name
        $properties = @($key) + @($properties | Where-Object { $_ -ne $key })

        try { 
                foreach($item in $Global:WorkersDocument) {
                    [PSCustomObject]$item
                }
                
            }
            catch {
                Log error "Failed: $_"
                Write-Error $_
            }
    }

    Log info "Done"
}

function Idm-WorkersNationalIdRead {
    param (
        [switch] $GetMeta,
        [string] $SystemParams,
        [string] $FunctionParams
    )
    $Class = "WorkerNationalId"
    Log info "-GetMeta=$GetMeta -SystemParams='$SystemParams' -FunctionParams='$FunctionParams'"

    if ($GetMeta) {

        Get-ClassMetaData -SystemParams $SystemParams -Class $Class
    }
    else {
        if($Global:WorkersInitialized -eq $false)
        {
            Log info "Worker data not yet collected, collecting now"
            Idm-WorkersRead -FunctionParams $FunctionParams -SystemParams $SystemParams > $null
        }
        
        $system_params   = ConvertFrom-Json2 $SystemParams
        $function_params = ConvertFrom-Json2 $FunctionParams

        $properties = $function_params.properties

        if ($properties.length -eq 0) {
            $properties = ($Global:Properties.$Class | Where-Object { $_.options.Contains('default') }).name
        }

        # Assure key is the first column
        $key = ($Global:Properties.$Class | Where-Object { $_.options.Contains('key') }).name
        $properties = @($key) + @($properties | Where-Object { $_ -ne $key })

        try { 
                foreach($item in $Global:WorkersNationalId) {
                    [PSCustomObject]$item
                }
                
            }
            catch {
                Log error "Failed: $_"
                Write-Error $_
            }
    }

    Log info "Done"
}

function Idm-WorkersOtherIdRead {
    param (
        [switch] $GetMeta,
        [string] $SystemParams,
        [string] $FunctionParams
    )
    $Class = "WorkerOtherId"
    Log info "-GetMeta=$GetMeta -SystemParams='$SystemParams' -FunctionParams='$FunctionParams'"

    if ($GetMeta) {

        Get-ClassMetaData -SystemParams $SystemParams -Class $Class
    }
    else {
        if($Global:WorkersInitialized -eq $false)
        {
            Log info "Worker data not yet collected, collecting now"
            Idm-WorkersRead -FunctionParams $FunctionParams -SystemParams $SystemParams > $null
        }
        
        $system_params   = ConvertFrom-Json2 $SystemParams
        $function_params = ConvertFrom-Json2 $FunctionParams

        $properties = $function_params.properties

        if ($properties.length -eq 0) {
            $properties = ($Global:Properties.$Class | Where-Object { $_.options.Contains('default') }).name
        }

        # Assure key is the first column
        $key = ($Global:Properties.$Class | Where-Object { $_.options.Contains('key') }).name
        $properties = @($key) + @($properties | Where-Object { $_ -ne $key })

        try { 
                foreach($item in $Global:WorkersOtherId) {
                    [PSCustomObject]$item
                }
                
            }
            catch {
                Log error "Failed: $_"
                Write-Error $_
            }
    }

    Log info "Done"
}

function Idm-WorkersPhoneRead {
    param (
        [switch] $GetMeta,
        [string] $SystemParams,
        [string] $FunctionParams
    )
    $Class = "WorkerPhone"
    Log info "-GetMeta=$GetMeta -SystemParams='$SystemParams' -FunctionParams='$FunctionParams'"

    if ($GetMeta) {

        Get-ClassMetaData -SystemParams $SystemParams -Class $Class
    }
    else {
        if($Global:WorkersInitialized -eq $false)
        {
            Log info "Worker data not yet collected, collecting now"
            Idm-WorkersRead -FunctionParams $FunctionParams -SystemParams $SystemParams > $null
        }
        
        $system_params   = ConvertFrom-Json2 $SystemParams
        $function_params = ConvertFrom-Json2 $FunctionParams

        $properties = $function_params.properties

        if ($properties.length -eq 0) {
            $properties = ($Global:Properties.$Class | Where-Object { $_.options.Contains('default') }).name
        }

        # Assure key is the first column
        $key = ($Global:Properties.$Class | Where-Object { $_.options.Contains('key') }).name
        $properties = @($key) + @($properties | Where-Object { $_ -ne $key })

        try { 
                foreach($item in $Global:WorkersPhone) {
                    [PSCustomObject]$item
                }
                
            }
            catch {
                Log error "Failed: $_"
                Write-Error $_
            }
    }

    Log info "Done"
}

function Invoke-WorkdayRequest {
    param (
        [hashtable] $SystemParams,
        [hashtable] $FunctionParams,
        [string] $Namespace,
        [string] $Body

    )
    $uri = "https://{0}/ccx/service/{1}/{2}/v{3}" -f $SystemParams.hostname, $SystemParams.tenantId, $Namespace, $SystemParams.version

    $SoapEnvelope = [xml] @'
<soapenv:Envelope xmlns:bsvc="urn:com.workday/bsvc" xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/">
    <soapenv:Header>
        <wsse:Security soapenv:mustUnderstand="1" xmlns:wsse="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd" xmlns:wsu="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-utility-1.0.xsd">
            <wsse:UsernameToken>
                <wsse:Username>IntegrationUser@Tenant</wsse:Username>
                <wsse:Password Type="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-username-token-profile-1.0#PasswordText">Password</wsse:Password>
            </wsse:UsernameToken>
        </wsse:Security>
    </soapenv:Header>
    <soapenv:Body>
         <bsvc:RequestNode xmlns:bsvc="urn:com.workday/bsvc" />
    </soapenv:Body>
</soapenv:Envelope>
'@

	$soapEnvelope.Envelope.Header.Security.UsernameToken.Username = "{0}@{1}" -f $SystemParams.username, $SystemParams.tenantId
	$soapEnvelope.Envelope.Header.Security.UsernameToken.Password.InnerText = $SystemParams.Password
	$soapEnvelope.Envelope.Body.InnerXml = $Body
    
    $headers= @{
		'Content-Type' = 'text/xml;charset=UTF-8'
	}

    try {
		$response = Invoke-RestMethod -Method Post -Uri $uri -Headers $headers -Body $soapEnvelope -ErrorAction Stop
        $result = [xml]$response.Envelope.Body.InnerXml
	}
	catch [System.Net.WebException] {
       
        try {
            $reader = New-Object System.IO.StreamReader -ArgumentList $_.Exception.Response.GetResponseStream()
            $response = $reader.ReadToEnd()
            $reader.Close()

            $result = ([xml]$response).Envelope.Body.InnerXml

            # Log the first Workday Exception
            if ($result.InnerXml.StartsWith('<SOAP-ENV:Fault ')) {
                $message = "Error : $($o.Xml.Fault.faultcode): $($o.Xml.Fault.faultstring)"
                Log error $message
                Write-Error $message
            }
        }
        catch {}
        
        $message = "Error : $($_)"
        Log error $message
        Write-Error $_
	}
    catch {
        $message = "Error : $($_)"
        Log error $message
        Write-Error $_
    }
    finally {
        $result | Out-File "C:\\data\\test.xml"
        Write-Output $result
    }
}

function ConvertFrom-WorkdayWorkerXml {
    <#
    .Synopsis
       Converts Workday Worker XML into a custom object.
    #>
        [CmdletBinding()]
        [OutputType([pscustomobject])]
        Param (
            [Parameter(Mandatory=$true,
                ValueFromPipeline=$true,
                ValueFromPipelineByPropertyName=$true,
                Position=0)]
            [xml[]]$Xml
        )
    
        Begin {
            $WorkerObjectTemplate = [pscustomobject][ordered]@{
                WorkerWid             = $null
                Active                = $null
                WorkerDescriptor      = $null
                PreferredName         = $null
                FirstName             = $null
                LastName              = $null
                WorkerType            = $null
                WorkerId              = $null
                UserId                = $null
                NationalId            = $null
                OtherId               = $null
                Phone                 = $null
                Email                 = $null
                BusinessTitle         = $null
                JobProfileName        = $null
                Location              = $null
                WorkSpace             = $null
                WorkerTypeReference   = $null
                Manager_WorkerID      = $null
                Manager_WorkerType      = $null
                Company               = $null
                BusinessUnit          = $null
                Supervisory           = $null
            }
            $WorkerObjectTemplate.PsObject.TypeNames.Insert(0, "Workday.Worker")
        }
    
        Process {
            foreach ($elements in $Xml) {
                foreach ($x in $elements.SelectNodes('//wd:Worker', $Global:NM)) {
                    $o = $WorkerObjectTemplate.PsObject.Copy()
    
                    $referenceId = $x.Worker_Reference.ID | Where-Object {$_.type -ne 'WID'}
    
                    $o.WorkerWid        = $x.Worker_Reference.ID | Where-Object {$_.type -eq 'WID'} | Select-Object -ExpandProperty '#text'
                    $o.WorkerDescriptor = $x.Worker_Descriptor
                    $o.PreferredName    = $x.Worker_Data.Personal_Data.Name_Data.Preferred_Name_Data.Name_Detail_Data.Formatted_Name
                    $o.FirstName        = $x.Worker_Data.Personal_Data.Name_Data.Preferred_Name_Data.Name_Detail_Data.First_Name
                    $o.LastName         = $x.Worker_Data.Personal_Data.Name_Data.Preferred_Name_Data.Name_Detail_Data.Last_Name
                    $o.WorkerType       = $referenceId.type
                    $o.WorkerId         = $referenceId.'#text'
                    $o.Phone      = @(Get-WorkdayWorkerPhone -WorkerXml $x.OuterXml)
                    $o.Email      = @(Get-WorkdayWorkerEmail -WorkerXml $x.OuterXml)
                    $o.NationalId = @(Get-WorkdayWorkerNationalId -WorkerXml $x.OuterXml)
                    $o.OtherId    = @(Get-WorkdayWorkerOtherId -WorkerXml $x.OuterXml)
                    $o.UserId     = $x.Worker_Data.User_ID
                    
                    # The methods SelectNodes and SelectSingleNode have access to the entire XML document and require anchoring with "./" to work as expected.
                    $workerEmploymentData = $x.SelectSingleNode('./wd:Worker_Data/wd:Employment_Data', $Global:NM)
                    if ($null -ne $workerEmploymentData) {
                        $o.Active = $workerEmploymentData.Worker_Status_Data.Active -eq '1'
                    }
                    
                    $workerJobData = $x.SelectSingleNode('./wd:Worker_Data/wd:Employment_Data/wd:Worker_Job_Data', $Global:NM)
                    if ($null -ne $workerJobData) {

                        $manager = $workerJobData.Position_Data.Manager_as_of_last_detected_manager_change_Reference.ID |
                        Where-Object {$_.type -ne 'WID'} |
                            Select-Object @{Name='WorkerType';Expression={$_.type}}, @{Name='WorkerID';Expression={$_.'#text'}}

                        $o.BusinessTitle = $workerJobData.Position_Data.Business_Title
                        $o.JobProfileName = $workerJobData.Position_Data.Job_Profile_Summary_Data.Job_Profile_Name
                        $o.Location = $workerJobData.SelectNodes('./wd:Position_Data/wd:Business_Site_Summary_Data/wd:Name', $Global:NM) | Select-Object -ExpandProperty InnerText -First 1 -ErrorAction SilentlyContinue
                        $o.WorkSpace = $workerJobData.SelectNodes('./wd:Position_Data/wd:Work_Space__Reference/wd:ID[@wd:type="Location_ID"]', $Global:NM) | Select-Object -ExpandProperty InnerText -First 1 -ErrorAction SilentlyContinue
                        $o.WorkerTypeReference = $workerJobData.SelectNodes('./wd:Position_Data/wd:Worker_Type_Reference/wd:ID[@wd:type="Employee_Type_ID"]', $Global:NM) | Select-Object -ExpandProperty InnerText -First 1 -ErrorAction SilentlyContinue
                        $o.Manager_WorkerType = $manager.WorkerType
                        $o.Manager_WorkerID = $manager.WorkerID
                        $o.Company = $workerJobData.SelectNodes('./wd:Position_Organizations_Data/wd:Position_Organization_Data/wd:Organization_Data[wd:Organization_Type_Reference/wd:ID[@wd:type="Organization_Type_ID" and . = "COMPANY"]]', $Global:NM) | Select-Object -ExpandProperty Organization_Name -First 1 -ErrorAction SilentlyContinue
                        $o.BusinessUnit = $workerJobData.SelectNodes('./wd:Position_Organizations_Data/wd:Position_Organization_Data/wd:Organization_Data[wd:Organization_Type_Reference/wd:ID[@wd:type="Organization_Type_ID" and . = "BUSINESS_UNIT"]]', $Global:NM) | Select-Object -ExpandProperty Organization_Name -First 1 -ErrorAction SilentlyContinue
                        $o.Supervisory = $workerJobData.SelectNodes('./wd:Position_Organizations_Data/wd:Position_Organization_Data/wd:Organization_Data[wd:Organization_Type_Reference/wd:ID[@wd:type="Organization_Type_ID" and . = "SUPERVISORY"]]', $Global:NM) | Select-Object -ExpandProperty Organization_Name -First 1 -ErrorAction SilentlyContinue
                    }


                    #Split Tables
                    foreach($item in $o.Email)
                    {
                        [void]$Global:WorkersEmail.Add(@{
                            WorkerID = $o.WorkerWid 
                            UsageType = $item.UsageType
                            Email = $item.Email
                            Primary = $item.Primary
                            Public = $item.Public
                        })
                    }

                    Write-Output $o
                }
            }
        }
    }

function Get-WorkdayWorkerDocument {
    [OutputType([PSCustomObject])]
    param (
        [Parameter(ParameterSetName="NoSearch")]
        [xml]$DocumentXml,
        [string]$Path
    )

    if ($null -eq $DocumentXml) {
        Write-Warning 'Unable to find Document information.'
        return
    }

    $fileTemplate = [pscustomobject][ordered]@{
        FileName      = $null
        Category      = $null
        Base64        = $null
        Path          = $null
    }

    Add-Member -InputObject $fileTemplate -MemberType ScriptMethod -Name SaveAs -Value {
        param ( [string]$Path )
        [system.io.file]::WriteAllBytes( $Path, [System.Convert]::FromBase64String( $this.Base64 ) )
    }

    if (-not ([string]::IsNullOrEmpty($Path)) -and -not (Test-Path -Path $Path)) {
        New-Item -Path $Path -ItemType Directory | Out-Null
    }

    foreach ($doc in $DocumentXml.GetElementsByTagName('wd:Worker_Document_Detail_Data')) {
        $o = $fileTemplate.PsObject.Copy()
        $categoryXml = $doc.Document_Category_Reference.ID | Where-Object {$_.type -match 'Document_Category__Workday_Owned__ID|Document_Category_ID'}
        $o.Category = '{0}/{1}' -f $categoryXml.type, $categoryXml.'#text'
        $o.FileName = $doc.Filename
        $o.Base64 = $doc.File
    
        if (-not ([string]::IsNullOrEmpty($Path))) {
            $filePath = Join-Path $Path $o.FileName
            $o.Path = $filePath
            $o.SaveAs($filePath)
        }

        Write-Output $o
    }
}

function Get-WorkdayWorkerEmail {
    [OutputType([PSCustomObject])]
    param (
        [Parameter(ParameterSetName="NoSearch")]
        [xml]$WorkerXml

    )

    if ($WorkerXml -eq $null) {
        
        Log info 'Unable to get Email information, Worker not found.'
        return
    }

    $numberTemplate = [pscustomobject][ordered]@{
        UsageType        = $null
        Email            = $null
        Primary          = $null
        Public           = $null
    }
    
    $WorkerXml.GetElementsByTagName('wd:Email_Address_Data') | ForEach-Object {
        $o = $numberTemplate.PsObject.Copy()
        $o.UsageType = $_.SelectSingleNode('wd:Usage_Data/wd:Type_Data/wd:Type_Reference/wd:ID[@wd:type="Communication_Usage_Type_ID"]', $Global:NM).InnerText
        $o.Email = $_.Email_Address
        $o.Primary = [System.Xml.XmlConvert]::ToBoolean( $_.Usage_Data.Type_Data.Primary )
        $o.Public = [System.Xml.XmlConvert]::ToBoolean( $_.Usage_Data.Public )
        Write-Output $o
    }
}

function Get-WorkdayWorkerNationalId {
    [OutputType([PSCustomObject])]
    param (
        [xml]$WorkerXml
    )
    if ($WorkerXml -eq $null) {
        Write-Warning 'Unable to get National Id information, Worker not found.'
        return
    }

    $numberTemplate = [pscustomobject][ordered]@{
        Type       = $null
        Id         = $null
        Descriptor = $null
        WID = $null
    }

    $WorkerXml.GetElementsByTagName('wd:National_ID') | ForEach-Object {
        $o = $numberTemplate.PsObject.Copy()
        $typeXml = $_.National_ID_Data.ID_Type_Reference.ID | Where-Object {$_.type -eq 'National_ID_Type_Code'}
        $o.Type = $typeXml.'#text'
        $o.Id = $_.National_ID_Data.ID
        $o.Descriptor = $_.National_ID_Reference.Descriptor
        $o.WID = $_.National_ID_Reference.ID | Where-Object {$_.type -eq 'WID'} | Select-Object -ExpandProperty '#text'
        Write-Output $o
    }
    
}

function Get-WorkdayWorkerOtherId {
    [OutputType([PSCustomObject])]
    param (
        [xml]$WorkerXml
    )

    if ($WorkerXml -eq $null) {
        Write-Warning 'Unable to get Other Id information, Worker not found.'
        return
    }

    $numberTemplate = [pscustomobject][ordered]@{
        Type       = $null
        Id         = $null
        Descriptor = $null
        Issued_Date = $null
        Expiration_Date = $null
        WID = $null
    }

    $WorkerXml.GetElementsByTagName('wd:Custom_ID') | ForEach-Object {
        $o = $numberTemplate.PsObject.Copy()
        $typeXml = $_.Custom_ID_Data.ID_Type_Reference.ID | Where-Object {$_.type -eq 'Custom_ID_Type_ID'}
        $o.Type = '{0}' -f $typeXml.'#text'
        $o.Id = $_.Custom_ID_Data.ID
        $o.Descriptor = $_.Custom_ID_Data.ID_Type_Reference.Descriptor
        $o.Issued_Date = try { Get-Date $_.Custom_ID_Data.Issued_Date -ErrorAction Stop } catch {}
        $o.Expiration_Date = try { Get-Date $_.Custom_ID_Data.Expiration_Date -ErrorAction Stop } catch {}
        $o.WID = $_.Custom_ID_Shared_Reference.ID | Where-Object {$_.type -eq 'WID'} | Select-Object -ExpandProperty '#text'
        Write-Output $o
    }

}

function Get-WorkdayWorkerPhone {
    [OutputType([PSCustomObject])]
    param (
        [xml]$WorkerXml
    )
    if ($WorkerXml -eq $null) {
        Log debug 'Worker not found.'
        return
    }

    $numberTemplate = [pscustomobject][ordered]@{
        UsageType = $null
        DeviceType = $null
        Number  = $null
        Extension = $null
        Primary = $null
        Public  = $null
    }

    $WorkerXml.GetElementsByTagName('wd:Phone_Data') | ForEach-Object {
        $o = $numberTemplate.PsObject.Copy()
        $o.UsageType = $_.SelectSingleNode('wd:Usage_Data/wd:Type_Data/wd:Type_Reference/wd:ID[@wd:type="Communication_Usage_Type_ID"]', $Global:NM).InnerText
        $o.DeviceType = $_.SelectSingleNode('wd:Phone_Device_Type_Reference/wd:ID[@wd:type="Phone_Device_Type_ID"]', $Global:NM).InnerText
        $international = $_ | Select-Object -ExpandProperty 'International_Phone_Code' -ErrorAction SilentlyContinue
        $areaCode = $_ | Select-Object -ExpandProperty 'Area_Code' -ErrorAction SilentlyContinue
        $phoneNumber = $_ | Select-Object -ExpandProperty 'Phone_Number' -ErrorAction SilentlyContinue

        $o.Number = '{0} ({1}) {2}' -f $international, $areaCode, $phoneNumber
        $o.Extension = $_ | Select-Object -ExpandProperty 'Phone_Extension' -ErrorAction SilentlyContinue
        $o.Primary = [System.Xml.XmlConvert]::ToBoolean( $_.Usage_Data.Type_Data.Primary )
        $o.Public = [System.Xml.XmlConvert]::ToBoolean( $_.Usage_Data.Public )
        Write-Output $o
    }
}

function Get-WorkdayWorkerPhoto {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param (
        [Parameter(Mandatory=$true,
                    Position=0,
                    ValueFromPipelineByPropertyName=$true,
                    ParameterSetName='IndividualWorker')]
        [ValidatePattern ('^$|^[a-fA-F0-9\-]{1,32}$')]
        [string]$WorkerId,
        [Parameter(Position=1,
                    ValueFromPipelineByPropertyName=$true,
                    ParameterSetName='IndividualWorker')]
        [ValidateSet('WID', 'Contingent_Worker_ID', 'Employee_ID')]
        [string]$WorkerType = 'Employee_ID',
        [string]$Path,
        [switch]$Passthru,
        [string]$Human_ResourcesUri,
        [string]$Username,
        [string]$Password,
        [DateTime]$AsOfEntryDateTime = (Get-Date)
    )

    begin {
        if ([string]::IsNullOrWhiteSpace($Human_ResourcesUri)) { $Human_ResourcesUri = Get-WorkdayEndpoint 'Human_Resources' }
    }

    process {
        $request = [xml]@'
<bsvc:Get_Worker_Photos_Request bsvc:version="v30.0" xmlns:bsvc="urn:com.workday/bsvc">
    <bsvc:Request_References bsvc:Skip_Non_Existing_Instances="false">
    <bsvc:Worker_Reference>
        <bsvc:ID bsvc:type="Employee_ID">?EmployeeId?</bsvc:ID>
    </bsvc:Worker_Reference>
    </bsvc:Request_References>
    <bsvc:Response_Filter>
    <bsvc:As_Of_Entry_DateTime>?DateTime?</bsvc:As_Of_Entry_DateTime>
    </bsvc:Response_Filter>
</bsvc:Get_Worker_Photos_Request>
'@

        $request.Get_Worker_Photos_Request.Response_Filter.As_Of_Entry_DateTime = $AsOfEntryDateTime.ToString('o')

        $request.Get_Worker_Photos_Request.Request_References.Worker_Reference.ID.InnerText = $WorkerId
        if ($WorkerType -eq 'Contingent_Worker_ID') {
            $request.Get_Worker_Photos_Request.Request_References.Worker_Reference.ID.type = 'Contingent_Worker_ID'
        } elseif ($WorkerType -eq 'WID') {
            $request.Get_Worker_Photos_Request.Request_References.Worker_Reference.ID.type = 'WID'
        }
        $response = Invoke-WorkdayRequest -Request $request -Uri $Human_ResourcesUri -Username:$Username -Password:$Password

        if ($Passthru) {
            Write-Output $response
        }
        elseif ($response.Success) {
            $filename = $response.Xml.Get_Worker_Photos_Response.Response_Data.Worker_Photo.Worker_Photo_Data.Filename
            $base64 = $response.Xml.Get_Worker_Photos_Response.Response_Data.Worker_Photo.Worker_Photo_Data.File
            $bytes = [System.Convert]::FromBase64String($base64)

            if ([string]::IsNullOrEmpty($Path)) {
                $output = [PsCustomObject][Ordered]@{
                    Filename = $filename
                    Bytes    = $bytes
                }
                Write-Output $output
            }
            else {
                if (Test-Path -Path $Path -PathType Container) {
                    $Path = Join-Path $Path $filename
                }
                $bytes | Set-Content -Path $Path -Encoding Byte
            }
        }
        else {
            throw "Error calling Get_Worker_Photos_Request: $($response.Message)"
        }
    }
}

function Get-ClassMetaData {
    param (
        [string] $SystemParams,
        [string] $Class
    )
    
    @(
        @{
            name = 'properties'
            type = 'grid'
            label = 'Properties'
            description = 'Selected properties'
            table = @{
                rows = @( $Global:Properties.$Class | ForEach-Object {
                    @{
                        name = $_.name
                        usage_hint = @( @(
                            foreach ($opt in $_.options) {
                                if ($opt -notin @('default', 'idm', 'key')) { continue }

                                if ($opt -eq 'idm') {
                                    $opt.Toupper()
                                }
                                else {
                                    $opt.Substring(0,1).Toupper() + $opt.Substring(1)
                                }
                            }
                        ) | Sort-Object) -join ' | '
                    }
                })
                settings_grid = @{
                    selection = 'multiple'
                    key_column = 'name'
                    checkbox = $true
                    filter = $true
                    columns = @(
                        @{
                            name = 'name'
                            display_name = 'Name'
                        }
                        @{
                            name = 'usage_hint'
                            display_name = 'Usage hint'
                        }
                    )
                }
            }
            value = ($Global:Properties.$Class | Where-Object { $_.options.Contains('default') }).name
        }
    )
}
