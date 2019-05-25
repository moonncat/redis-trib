
$ports=@("7001","7002","7003")

if(!(Test-Path .\redis-server.exe )){
    throw "redis-server is not found"
}
if(!(Test-Path .\redis-cli.exe )){
    throw "redis-server is not found"
}

# build config file 
$cofigTemplate="port {0}
cluster-enabled yes
cluster-config-file node_{0}.conf
cluster-node-timeout 5000
appendonly yes"

if(!(Test-Path .\nodes)){
    New-Item .\nodes -ItemType dir
}

# create config file for each node
$ports|ForEach-Object{
    $p=$_
    $cofigContent= [System.String]::Format($cofigTemplate,$p)
    $cofigContent|Out-File ".\nodes\redis_node_$p.conf" -Encoding ascii
}


# service-install
$ports|ForEach-Object{
    $p=$_

	# Stop service
    .\redis-server --service-stop --service-name "Redis$p"
	
    # unintall
    .\redis-server --service-uninstall --service-name "Redis$p"

    # intall
    .\redis-server --service-install ".\nodes\redis_node_$p.conf" --service-name "Redis$p" --port "$p"
}


# service-start
$ports|ForEach-Object{
    $p=$_
    .\redis-server --service-start --service-name "Redis$p"
}


# config-cluster
$ports|ForEach-Object{
    $p=$_
    if($p -ne $ports[0]){
        .\redis-cli -c -h 127.0.0.1 -p $ports[0] cluster meet 127.0.0.1 $p
    }
}

# set Hash-Slot, assign all slot to primary node
$sb={param($rrd,$slotFrom,$slotTo,$masterPort)
    for ($slot=$slotFrom;$slot -le $slotTo;$slot++) { 
        & $rrd\redis-cli.exe -h 127.0.0.1 -p $masterPort CLUSTER ADDSLOTS $slot 
    }
}

$redisRoot=(dir .)[0].Parent.FullName
Start-Job -ScriptBlock $sb -ArgumentList @($redisRoot,0,1638,$ports[0])
Start-Job -ScriptBlock $sb -ArgumentList @($redisRoot,1639,3278,$ports[0])
Start-Job -ScriptBlock $sb -ArgumentList @($redisRoot,3279,4917,$ports[0])
Start-Job -ScriptBlock $sb -ArgumentList @($redisRoot,4918,6556,$ports[0])
Start-Job -ScriptBlock $sb -ArgumentList @($redisRoot,6557,8195,$ports[0])
Start-Job -ScriptBlock $sb -ArgumentList @($redisRoot,8196,9834,$ports[0])
Start-Job -ScriptBlock $sb -ArgumentList @($redisRoot,9835,11473,$ports[0])
Start-Job -ScriptBlock $sb -ArgumentList @($redisRoot,11474,13112,$ports[0])
Start-Job -ScriptBlock $sb -ArgumentList @($redisRoot,13113,14751,$ports[0])
Start-Job -ScriptBlock $sb -ArgumentList @($redisRoot,14752,16383,$ports[0])

Get-Job|Wait-Job

# check-nodes
.\redis-cli -c -h 127.0.0.1 -p $ports[0] cluster nodes


Write-Host "done"