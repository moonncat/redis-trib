
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

    # unintall
    #.\redis-server --service-uninstall --service-name "Redis$p"

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
for ($slot=0;$slot -le 16383;$slot++) { .\redis-cli.exe -h 127.0.0.1 -p $ports[0] CLUSTER ADDSLOTS $slot }

# check-nodes
.\redis-cli -c -h 127.0.0.1 -p $ports[0] cluster nodes