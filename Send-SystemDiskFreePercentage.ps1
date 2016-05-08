param(
    [Parameter(Position=0, ValueFromPipelineByPropertyName=$true, Mandatory=$false)]
    [String]
    $Name = $env:COMPUTERNAME,

    [switch]
    $ViewOnly
)
  
process {
    $free = Get-Counter "\LogicalDisk(c:)\% Free Space" -comp $Name

    $result = $free.CounterSamples | ?{$_.InstanceName -match ":"} | 
        select @{n="Server";e={$Name}},
               @{n="Drive";e={$_.InstanceName}},
	           @{n="PercentFree";e={[Math]::Round($_.CookedValue,2)}}
    
    if($ViewOnly) {
        Write-Output $result
    }
    else {
        $instanceId = Invoke-RestMethod http://169.254.169.254/latest/meta-data/instance-id
        $dimensions = "Name=InstanceId,Value=$instanceId"

        aws cloudwatch put-metric-data --metric-name RootVolPercentFree `
        --namespace Windows `
        --dimensions $dimensions `
        --value $result.PercentFree    
    }
}