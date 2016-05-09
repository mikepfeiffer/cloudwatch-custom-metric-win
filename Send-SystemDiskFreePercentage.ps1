[CmdletBinding()]
param(
    [Parameter(ValueFromPipelineByPropertyName=$true, Mandatory=$false)]
    [String]
    $ComputerName = $env:COMPUTERNAME,

    [switch]
    $ViewOnly,

    [Parameter(Mandatory=$false)]
    [ValidateSet('eu-west-1','ap-southeast-1','ap-southeast-2','eu-central-1','ap-northeast-2','ap-northeast-1','us-east-1','sa-east-1','us-west-1','us-west-2')]
    [String]
    $Region = 'us-west-2'
)
  
process {
    Write-Verbose "Gathering performance monitor data"
    $free = Get-Counter "\LogicalDisk(c:)\% Free Space" -comp $ComputerName

    $result = $free.CounterSamples | ?{$_.InstanceName -match ":"} | 
        select @{n="Server";e={$ComputerName}},
               @{n="Drive";e={$_.InstanceName}},
	           @{n="PercentFree";e={[Math]::Round($_.CookedValue,2)}}
    
    if($ViewOnly) {
        Write-Verbose "ViewOnly switch used...outputting results"
        Write-Output $result
    }
    else {
        Write-Verbose "Retrieving instance id from EC2 instance meta-data"
        $instanceId = Invoke-RestMethod http://169.254.169.254/latest/meta-data/instance-id

        $dimensions = "Name=InstanceId,Value=$instanceId"

        Write-Verbose "Publishing disk free space percentage via put-metric-data"
        aws cloudwatch put-metric-data --metric-name RootVolPercentFree `
        --namespace Windows `
        --dimensions $dimensions `
        --value $result.PercentFree `
        --region $Region
    }
}