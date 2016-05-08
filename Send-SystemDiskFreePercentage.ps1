[CmdletBinding()]
param(
    [Parameter(Position=0, ValueFromPipelineByPropertyName=$true, Mandatory=$false)]
    [String]
    $Name = $env:COMPUTERNAME,

    [switch]
    $ViewOnly
)
  
process {
    Write-Verbose "Gathering performance monitor data"
    $free = Get-Counter "\LogicalDisk(c:)\% Free Space" -comp $Name

    $result = $free.CounterSamples | ?{$_.InstanceName -match ":"} | 
        select @{n="Server";e={$Name}},
               @{n="Drive";e={$_.InstanceName}},
	           @{n="PercentFree";e={[Math]::Round($_.CookedValue,2)}}
    
    if($ViewOnly) {
        Write-Verbose "ViewOnly switch used...outputting results"
        Write-Output $result
    }
    else {
        Write-Output "Retrieving instance id from EC2 instance meta-data"
        $instanceId = Invoke-RestMethod http://169.254.169.254/latest/meta-data/instance-id

        $dimensions = "Name=InstanceId,Value=$instanceId"

        Write-Verbose "Publishing disk free space percentage via put-metric-data"
        aws cloudwatch put-metric-data --metric-name RootVolPercentFree `
        --namespace Windows `
        --dimensions $dimensions `
        --value $result.PercentFree
    }
}