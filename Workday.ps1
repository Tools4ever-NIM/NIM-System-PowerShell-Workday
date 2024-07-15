#
# Workday.ps1 - Workday Web Services API (SOAP)
#

$Log_MaskableKeys = @(
    'password',
	"proxy_password"
)

$Global:NM = New-Object System.Xml.XmlNamespaceManager -ArgumentList (New-Object System.Xml.NameTable)
$Global:NM.AddNamespace('wd','urn:com.workday/bsvc')
$Global:NM.AddNamespace('bsvc','urn:com.workday/bsvc')

$Global:WorkersCacheTime = Get-Date
$Global:Workers = [System.Collections.ArrayList]@()
$Global:WorkersEmail = [System.Collections.ArrayList]@()
$Global:WorkersDocument = [System.Collections.ArrayList]@()
$Global:WorkersNationalId = [System.Collections.ArrayList]@()
$Global:WorkersOtherId = [System.Collections.ArrayList]@()
$Global:WorkersPhone = [System.Collections.ArrayList]@()

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
                value = 'wd5-services1.myworkday.com'
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
                description = 'Username account'
                value = ''
            }
            @{
                name = 'password'
                type = 'textbox'
                password = $true
                label = 'Password'
                description = 'User account password'
                value = ''
            }
            @{
                name = 'version'
                type = 'textbox'
                label = 'Version'
                description = 'API Version'
                value = '42.1'
            },
            @{
                name = 'pagesize'
                type = 'textbox'
                label = 'Page Size'
                label_indent = $true
                description = 'Number of records per page'
                value = '250'
            }
            @{
                name = 'use_proxy'
                type = 'checkbox'
                label = 'Use Proxy Credentials'
                description = 'Use Proxy server for request'
                value = $false
            }
            @{
                name = 'proxy_address'
                type = 'textbox'
                label = 'Proxy Address'
                description = 'Address of the proxy server'
                value = 'http://127.0.0.1:8888'
                disabled = '!use_proxy'
                hidden = '!use_proxy'
            }
            @{
                name = 'use_proxy_credentials'
                type = 'checkbox'
                label = 'Use Proxy'
                description = 'Use Credentials for proxy'
                value = $false
                disabled = '!use_proxy'
                hidden = '!use_proxy'
            }
            @{
                name = 'proxy_username'
                type = 'textbox'
                label = 'Proxy Username'
                label_indent = $true
                description = 'Username account'
                value = ''
                disabled = '!use_proxy_credentials'
                hidden = '!use_proxy_credentials'
            }
            @{
                name = 'proxy_password'
                type = 'textbox'
                password = $true
                label = 'Proxy Password'
                label_indent = $true
                description = 'User account password'
                value = ''
                disabled = '!use_proxy_credentials'
                hidden = '!use_proxy_credentials'
            }
            @{
                name = 'nr_of_sessions'
                type = 'textbox'
                label = 'Max. number of simultaneous sessions'
                description = ''
                value = 1
            }
            @{
                name = 'sessions_idle_timeout'
                type = 'textbox'
                label = 'Session cleanup idle time (minutes)'
                description = ''
                value = 1
            }
        )
    }

    if ($TestConnection) {
			 $xmlRequest = '<bsvc:Get_Workers_Request bsvc:version="v30.0">
                                        <bsvc:Response_Filter>
                                            <bsvc:Page>{0}</bsvc:Page>
                                            <bsvc:Count>{1}</bsvc:Count>
                                        </bsvc:Response_Filter>
                                        <bsvc:Request_Criteria>
                                            <bsvc:Exclude_Inactive_Workers>false</bsvc:Exclude_Inactive_Workers>
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
                                    </bsvc:Get_Workers_Request>' -f 1, 1

                        $response = Invoke-WorkdayRequest -SystemParams (ConvertFrom-Json2 $ConnectionParams) -Body $xmlRequest -Namespace "Human_Resources"
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
        @{ name = 'WorkerId';                              options = @('default','update')                      }
        @{ name = 'UserId';                              options = @('default','update')                      }
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
        @{ name = 'CostCenter';                              options = @('default')                      }
        @{ name = 'HireDate';                             options = @('default') }
        @{ name = 'timeType';                             options = @('default') }
        @{ name = 'Department';                             options = @('default') }
    )
    WorkerEmail = @(
        @{ name = 'WorkerID';                              options = @('default','key')                      }
        @{ name = 'UsageType';                              options = @('default')                      }
        @{ name = 'Email';                              options = @('default')                      }
        @{ name = 'Primary';                              options = @('default')                      }
        @{ name = 'Public';                              options = @('default')                      }
    )
    WorkerDocument = @(
        @{ name = 'WorkerID';                              options = @('default','key')                      }
        @{ name = 'FileName';                              options = @('default')                      }
        @{ name = 'Category';                              options = @('default')                      }
        @{ name = 'Base64';                              options = @('default')                      }
        @{ name = 'Path';                              options = @('default')                      }
    )
    WorkerNationalId = @(
        @{ name = 'WorkerID';                              options = @('default','key')                      }
        @{ name = 'Type';                              options = @('default')                      }
        @{ name = 'ID';                              options = @('default')                      }
        @{ name = 'Descriptor';                              options = @('default')                      }
    )
    WorkerOtherId = @(
        @{ name = 'WorkerID';                              options = @('default','key')                      }
        @{ name = 'Type';                              options = @('default')                      }
        @{ name = 'ID';                              options = @('default')                      }
        @{ name = 'Descriptor';                              options = @('default')                      }
        @{ name = 'Issued_Date';                              options = @('default')                      }
        @{ name = 'Expiration_Date';                              options = @('default')                      }
    )
    WorkerPhone = @(
        @{ name = 'WorkerID';                              options = @('default','key')                      }
        @{ name = 'UsageType';                              options = @('default')                      }
        @{ name = 'DeviceType';                              options = @('default')                      }
        @{ name = 'Number';                              options = @('default')                      }
        @{ name = 'Extension';                              options = @('default')                      }
        @{ name = 'Primary';                              options = @('default')                      }
        @{ name = 'Public';                              options = @('default')                      }
    )
}



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

		$exclude_inactive_workers = if ($function_params.exclude_inactive_workers) { "true" } else { "false" }

        try { 
            if(     $Global:Workers.count -lt 1 `
                    -or ( ((Get-Date) - $Global:WorkersCacheTime) -gt (new-timespan -minutes 1) ) 
              ) {                   
                    $page = 0
                    $totalPages = 1
                    
                    while($page -lt $totalPages) {
						$page++

                        $xmlRequest = '<bsvc:Get_Workers_Request bsvc:version="v30.0">
                                        <bsvc:Response_Filter>
                                            <bsvc:Page>{0}</bsvc:Page>
                                            <bsvc:Count>{1}</bsvc:Count>
											<bsvc:As_Of_Effective_Date>{2}</bsvc:As_Of_Effective_Date>
                                        </bsvc:Response_Filter>
                                        <bsvc:Request_Criteria>
                                            <bsvc:Exclude_Inactive_Workers>{3}</bsvc:Exclude_Inactive_Workers>
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
                                    </bsvc:Get_Workers_Request>' -f $page, $system_params.pagesize, $function_params.as_of_effective_date, $exclude_inactive_workers

                    
                        $response = Invoke-WorkdayRequest -SystemParams $system_params -FunctionParams $function_params -Body $xmlRequest -Namespace "Human_Resources"
                        $totalPages = $response.Get_Workers_Response.Response_Results.Total_Pages
                        
                        LogIO info "Page $($Page) of $($totalPages) - Record Count $($response.Get_Workers_Response.Response_Data.Worker.count)"
                        Log info "Page $($Page) of $($totalPages) - Record Count $($response.Get_Workers_Response.Response_Data.Worker.count)"

                        foreach($item in ($response | ConvertFrom-WorkdayWorkerXml) ) {
                            [void]$Global:Workers.Add($item)
                        }                     
                    }   

                    $Global:WorkersCacheTime = Get-Date
                    $Global:Workers
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

function Idm-WorkersUpdate {
    param (
        # Operations
        [switch] $GetMeta,
        # Parameters
        [string] $SystemParams,
        [string] $FunctionParams
    )

    Log info "-GetMeta=$GetMeta -SystemParams='$SystemParams' -FunctionParams='$FunctionParams'"

    if ($GetMeta) {
        #
        # Get meta data
        #

        @{
            semantics = 'update'
            parameters = @(
            @{ name = ( $Global:Properties.Worker | Where-Object { $_.options.Contains('key') }).name; allowance = 'mandatory' }
            $Global:Properties.Worker | Where-Object { !$_.options.Contains('key') -and $_.options.Contains('update') } | ForEach-Object { @{ name = $_.name; allowance = 'optional' }}
            @{ name = '*'; allowance = 'prohibited' }
            )
        }
    }
    else {
        #
        # Execute function
        #
        $system_params   = ConvertFrom-Json2 $SystemParams
        $function_params = ConvertFrom-Json2 $FunctionParams

        $key = ($Global:Properties.Worker | Where-Object { $_.options.Contains('key') }).name

        try {
            LogIO info "WorkerUpdate" -In -Email $function_params.Email
		    $currentDate = Get-Date -Format "yyyy-MM-dd";
            
            $xmlRequest = '<bsvc:Workday_Account_for_Worker_Update bsvc:version="v41.2">
			<bsvc:Worker_Reference>
				<bsvc:Employee_Reference>
					<bsvc:Integration_ID_Reference>
						<bsvc:ID bsvc:System_ID="WD-EMPLID">{0}</bsvc:ID>
					</bsvc:Integration_ID_Reference>
				</bsvc:Employee_Reference>
			</bsvc:Worker_Reference>
			<bsvc:Workday_Account_for_Worker_Data>
				<bsvc:User_Name>{1}</bsvc:User_Name>
			</bsvc:Workday_Account_for_Worker_Data>
		    </bsvc:Workday_Account_for_Worker_Update>' -f $function_params.WorkerID, $function_params.UserId

                
            $response = Invoke-WorkdayRequest -SystemParams $system_params -FunctionParams $function_params -Body $xmlRequest -Namespace "Human_Resources"
            $rv = $true

            LogIO info "WorkersUpdate" -Out $rv
            Log info ($function_params | ConvertTo-Json)
        }
        catch {
            Log error "Failed: $_"
            Write-Error $_
        }
    }

    Log info "Done"
}

function Idm-WorkersEmailsRead {
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
        Check-WorkdayConnection -SystemParams $SystemParams -FunctionParams $FunctionParams
        
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

function Idm-WorkersEmailsUpdate {
    param (
        # Operations
        [switch] $GetMeta,
        # Parameters
        [string] $SystemParams,
        [string] $FunctionParams
    )

    Log info "-GetMeta=$GetMeta -SystemParams='$SystemParams' -FunctionParams='$FunctionParams'"

    if ($GetMeta) {
        #
        # Get meta data
        #

        @{
            semantics = 'update'
            parameters = @(
                $Global:Properties.WorkerEmail | ForEach-Object {
                    @{ name = $_.name; allowance = 'mandatory' }
                }    
            #@{ name = '*';                     allowance = 'mandatory'   }
            )
        }
    }
    else {
        #
        # Execute function
        #
        $system_params   = ConvertFrom-Json2 $SystemParams
        $function_params = ConvertFrom-Json2 $FunctionParams

        $key = ($Global:Properties.WorkerEmail | Where-Object { $_.options.Contains('key') }).name

        try {
            LogIO info "WorkerEmailUpdate" -In -Email $function_params.Email
		$currentDate = Get-Date -Format "yyyy-MM-dd";
            $xmlRequest = '<bsvc:Maintain_Contact_Information_for_Person_Event_Request bsvc:version="v30.0" bsvc:Add_Only="false">
                                <bsvc:Business_Process_Parameters>
                                    <bsvc:Auto_Complete>true</bsvc:Auto_Complete>
                                    <bsvc:Run_Now>true</bsvc:Run_Now>
                                    <bsvc:Comment_Data>
                                        <bsvc:Comment>Email set by NIM</bsvc:Comment>
                                    </bsvc:Comment_Data>
                                </bsvc:Business_Process_Parameters>
                                <bsvc:Maintain_Contact_Information_Data>
                                    <bsvc:Worker_Reference>
                                        <bsvc:ID bsvc:type="Employee_ID">{0}</bsvc:ID>
                                    </bsvc:Worker_Reference>
                                    <bsvc:Effective_Date>{1}</bsvc:Effective_Date>
                                    <bsvc:Worker_Contact_Information_Data>
                                        <bsvc:Email_Address_Data bsvc:Do_Not_Replace_All="true">
                                            <bsvc:Email_Address>{2}</bsvc:Email_Address>
                                            <bsvc:Usage_Data bsvc:Public="{3}">
                                                <bsvc:Type_Data bsvc:Primary="{4}">
                                                    <bsvc:Type_Reference>
                                                        <bsvc:ID bsvc:type="Communication_Usage_Type_ID">{5}</bsvc:ID>
                                                    </bsvc:Type_Reference>
                                                </bsvc:Type_Data>
                                            </bsvc:Usage_Data>
                                        </bsvc:Email_Address_Data>
                                    </bsvc:Worker_Contact_Information_Data>
                                </bsvc:Maintain_Contact_Information_Data>
                            </bsvc:Maintain_Contact_Information_for_Person_Event_Request>' -f $function_params.WorkerID, $currentDate, $function_params.Email, $function_params.Public, $function_params.Primary, $function_params.UsageType

                
            $response = Invoke-WorkdayRequest -SystemParams $system_params -FunctionParams $function_params -Body $xmlRequest -Namespace "Human_Resources"
		$rv = $true
		LogIO info "WorkersEmail" -Out $rv
		Log info ($function_params | ConvertTo-Json)
        }
        catch {
            Log error "Failed: $_"
            Write-Error $_
        }
    }

    Log info "Done"
}

function Idm-WorkersEmailsCreate {
    param (
        # Operations
        [switch] $GetMeta,
        # Parameters
        [string] $SystemParams,
        [string] $FunctionParams
    )

    Log info "-GetMeta=$GetMeta -SystemParams='$SystemParams' -FunctionParams='$FunctionParams'"

    if ($GetMeta) {
        #
        # Get meta data
        #

        @{
            semantics = 'create'
            parameters = @(
                $Global:Properties.WorkerEmail | ForEach-Object {
                    @{ name = $_.name; allowance = 'mandatory' }
                }    
            #@{ name = '*';                     allowance = 'mandatory'   }
            )
        }
    }
    else {
        #
        # Execute function
        #

        $system_params   = ConvertFrom-Json2 $SystemParams
        $function_params = ConvertFrom-Json2 $FunctionParams

        $key = ($Global:Properties.WorkerEmail | Where-Object { $_.options.Contains('key') }).name

        try {
            $currentDate = Get-Date -Format "yyyy-MM-dd";
            $xmlRequest = '<bsvc:Maintain_Contact_Information_for_Person_Event_Request bsvc:version="v30.0" bsvc:Add_Only="false">
                                <bsvc:Business_Process_Parameters>
                                    <bsvc:Auto_Complete>true</bsvc:Auto_Complete>
                                    <bsvc:Run_Now>true</bsvc:Run_Now>
                                    <bsvc:Comment_Data>
                                        <bsvc:Comment>Email set by NIM</bsvc:Comment>
                                    </bsvc:Comment_Data>
                                </bsvc:Business_Process_Parameters>
                                <bsvc:Maintain_Contact_Information_Data>
                                    <bsvc:Worker_Reference>
                                        <bsvc:ID bsvc:type="Employee_ID">{0}</bsvc:ID>
                                    </bsvc:Worker_Reference>
                                    <bsvc:Effective_Date>{1}</bsvc:Effective_Date>
                                    <bsvc:Worker_Contact_Information_Data>
                                        <bsvc:Email_Address_Data bsvc:Do_Not_Replace_All="true">
                                            <bsvc:Email_Address>{2}</bsvc:Email_Address>
                                            <bsvc:Usage_Data bsvc:Public="{3}">
                                                <bsvc:Type_Data bsvc:Primary="{4}">
                                                    <bsvc:Type_Reference>
                                                        <bsvc:ID bsvc:type="Communication_Usage_Type_ID">{5}</bsvc:ID>
                                                    </bsvc:Type_Reference>
                                                </bsvc:Type_Data>
                                            </bsvc:Usage_Data>
                                        </bsvc:Email_Address_Data>
                                    </bsvc:Worker_Contact_Information_Data>
                                </bsvc:Maintain_Contact_Information_Data>
                            </bsvc:Maintain_Contact_Information_for_Person_Event_Request>' -f $function_params.WorkerID, $currentDate, $function_params.Email, $function_params.Public, $function_params.Primary, $function_params.UsageType

                
            $response = Invoke-WorkdayRequest -SystemParams $system_params -FunctionParams $function_params -Body $xmlRequest -Namespace "Human_Resources"
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
        Check-WorkdayConnection -SystemParams $SystemParams -FunctionParams $FunctionParams
        
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
        Check-WorkdayConnection -SystemParams $SystemParams -FunctionParams $FunctionParams
        
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
        Check-WorkdayConnection -SystemParams $SystemParams -FunctionParams $FunctionParams
        
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
        Check-WorkdayConnection -SystemParams $SystemParams -FunctionParams $FunctionParams
        
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
		$splat = @{
            Method = "POST"
            Uri = $uri
            Headers = $headers
            Body = $soapEnvelope
        }

        if($SystemParams.use_proxy)
        {
                                Add-Type @"
using System.Net;
using System.Security.Cryptography.X509Certificates;
public class TrustAllCertsPolicy : ICertificatePolicy {
    public bool CheckValidationResult(
        ServicePoint srvPoint, X509Certificate certificate,
        WebRequest request, int certificateProblem) {
        return true;
    }
}
"@
[System.Net.ServicePointManager]::CertificatePolicy = New-Object TrustAllCertsPolicy

			$splat["Proxy"] = $SystemParams.proxy_address

            if($SystemParams.use_proxy_credentials)
            {
                $splat["proxyCredential"] = New-Object System.Management.Automation.PSCredential ($SystemParams.proxy_username, (ConvertTo-SecureString $SystemParams.proxy_password -AsPlainText -Force) )
            }
        }
		
		LogIO debug "Workday POST call: $($splat.Uri)"
		Log debug "Workday POST call: $($splat.Uri)"
		
		#LogIO debug "Workday POST body: $($splat.Body)"
		#Log debug "Workday POST body: $($splat.Body)"
        $response = Invoke-RestMethod @splat -ErrorAction Stop
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
                CostCenter          = $null
                HireDate  = $null
                timeType = $null
                Department = $null
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
                    $workerOrganizationData = $x.SelectSingleNode('./wd:Worker_Data/wd:Organization_Data',$Global:NM);
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
                        $o.HireDate = $workerJobData.Position_Data.Start_Date
                        $o.Location = $workerJobData.SelectNodes('./wd:Position_Data/wd:Business_Site_Summary_Data/wd:Name', $Global:NM) | Select-Object -ExpandProperty InnerText -First 1 -ErrorAction SilentlyContinue
                        $o.WorkSpace = $workerJobData.SelectNodes('./wd:Position_Data/wd:Work_Space__Reference/wd:ID[@wd:type="Location_ID"]', $Global:NM) | Select-Object -ExpandProperty InnerText -First 1 -ErrorAction SilentlyContinue
                        $o.WorkerTypeReference = $workerJobData.SelectNodes('./wd:Position_Data/wd:Worker_Type_Reference/wd:ID[@wd:type="Employee_Type_ID"]', $Global:NM) | Select-Object -ExpandProperty InnerText -First 1 -ErrorAction SilentlyContinue
                        $o.Manager_WorkerType = $manager.WorkerType
                        $o.Manager_WorkerID = $manager.WorkerID
                        $o.Department=$workerOrganizationData.SelectNodes('./wd:Worker_Organization_Data/wd:Organization_Data[wd:Organization_Type_Reference/wd:ID[@wd:type="Organization_Type_ID" and . = "Supervisory"]]', $Global:NM) | Select-Object -ExpandProperty Organization_Name -First 1 -ErrorAction SilentlyContinue
                        $o.Company = $workerJobData.SelectNodes('./wd:Position_Organizations_Data/wd:Position_Organization_Data/wd:Organization_Data[wd:Organization_Type_Reference/wd:ID[@wd:type="Organization_Type_ID" and . = "COMPANY"]]', $Global:NM) | Select-Object -ExpandProperty Organization_Name -First 1 -ErrorAction SilentlyContinue
                        $o.CostCenter = $workerJobData.SelectNodes('./wd:Position_Organizations_Data/wd:Position_Organization_Data/wd:Organization_Data[wd:Organization_Type_Reference/wd:ID[@wd:type="Organization_Type_ID" and . = "Cost_Center"]]', $Global:NM) | Select-Object -ExpandProperty Organization_Name -First 1 -ErrorAction SilentlyContinue
                        $o.BusinessUnit = $workerJobData.SelectNodes('./wd:Position_Organizations_Data/wd:Position_Organization_Data/wd:Organization_Data[wd:Organization_Type_Reference/wd:ID[@wd:type="Organization_Type_ID" and . = "BUSINESS_UNIT"]]', $Global:NM) | Select-Object -ExpandProperty Organization_Name -First 1 -ErrorAction SilentlyContinue
                        $o.Supervisory = $workerJobData.SelectNodes('./wd:Position_Organizations_Data/wd:Position_Organization_Data/wd:Organization_Data[wd:Organization_Type_Reference/wd:ID[@wd:type="Organization_Type_ID" and . = "SUPERVISORY"]]', $Global:NM) | Select-Object -ExpandProperty Organization_Name -First 1 -ErrorAction SilentlyContinue
                        $o.timeType = $workerJobData.Position_Data.Position_Time_Type_Reference.ID[1].'#text'
                    }


                    #Split Tables
                        #Email
                        foreach($item in $o.Email)
                        {
                            [void]$Global:WorkersEmail.Add(@{
                                WorkerID = $o.WorkerID
                                UsageType = $item.UsageType
                                Email = $item.Email
                                Primary = $item.Primary
                                Public = $item.Public
                            })
                        }

                        #Phone
                        foreach($item in $o.Phone)
                        {
                            [void]$Global:WorkersPhone.Add(@{
                                WorkerID = $o.WorkerID
                                UsageType = $item.UsageType
                                DeviceType = $item.DeviceType
                                Number = $item.Number
                                Extension = $item.Extension
                                Primary = $item.Primary
                                Public = $item.Public
                            })
                        }

                        #NationalId
                        foreach($item in $o.NationalId)
                        {
                            [void]$Global:WorkersNationalId.Add(@{
                                WorkerID = $o.WorkerID
                                Type = $item.Type
                                ID = $item.ID
                                Descriptor = $item.Descriptor
                            })
                        }

                        #OtherId
                        foreach($item in $o.OtherId)
                        {
                            [void]$Global:WorkersOtherId.Add(@{
                                WorkerID = $o.WorkerID
                                Type = $item.Type
                                ID = $item.ID
                                Descriptor = $item.Descriptor
                                Issued_Date = $item.Issued_Date
                                Expiration_Date = $item.Expiration_Date
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
    $out = @()
    
	if($Class -eq 'Worker') { 
		 $out += @(
			@{
				name = 'exclude_inactive_workers'
				type = 'checkbox'
				label = 'Exclude Inactive Workers'
				value = $false
			}
			@{
				name = 'as_of_effective_date'
				type = 'textbox'
				label = 'As Of Effective Date'
				value = '9999-12-31'
			}
		)
	}
	
	$out += @(
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

	$out
}

function Check-WorkdayConnection { 
    param (
        [string] $SystemParams,
		[string] $FunctionParams
    )
     Idm-WorkersRead -GetMeta $false -SystemParams $SystemParams -FunctionParams $FunctionParams | Out-Null
}