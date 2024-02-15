# cilium-standalone
## Steps to set up cilium in standalone
### Cloudlab profile details
four-node-lb-config profile on cloud lab used for test setup 

<img width="255" alt="image" src="https://github.com/SaumyaSachdev/cilium-standalone/assets/24439791/c8f7f4f9-b7a9-4611-aa57-79e5c73da7aa">

Four nodes. 1 lb node (2NIC) directly connected to 2 backend servers. One disconnected client node. The lb node has to be a machine with two NIC. c220g2 selected for all nodes for simplicity.


### Basic setup and packages
1. Download and install Docker on all three connected nodes using the script `docker_install.sh`. Please use root privileges by adding `sudo`.
2. Pull the `1.14.2` version of the Cilium image on Node 0 from Docker using the command below:
   ```
   sudo docker pull cilium/cilium:v1.14.2
   ```
3. Verify that BPF FS is mounted using the command below. BPF should be mounted in the directory `/sys/fs/bpf`. Follow the steps in reference [^1] if this is not the case.
   ```
   mount | grep bpf
   ```
   The result for this should include something similar to: 
   `bpf on /sys/fs/bpf type bpf (rw,nosuid,nodev,noexec,relatime,mode=700)`
   
4. Install a basic Apache server in the two nodes, Node 1 and Node 2. These are the nodes connected to the load balancer as the backends across which the load is balanced. Use the script `apache_install.sh` with `sudo` privileges. 
5. Verify that the two servers are reachable by the Load Balancer Node 0 by using `curl`.
```
   curl <Node 1 IP>:8080
   curl <Node 2 IP>:8080
```
7. Node 1 and Node 2 IPs can be found by running the `ifconfig` command. We used the private IPs internal to the network for the backend nodes. They were `10.10.1.1` and `10.10.2.1` for Node 1 and Node 2 respectively. These IPs are later used to create a service inside the cilium container as well.


### Running cilium image 
1. Use the command below to start the cilium docker image.
  ```
  sudo docker run \
    --cap-add NET_ADMIN \
    --cap-add SYS_MODULE \
    --cap-add CAP_SYS_ADMIN \
    --network host \
    --privileged \
    -v /sys/fs/bpf:/sys/fs/bpf \
    -v /lib/modules \
    --name l4lb \
    cilium/cilium:v1.14.2 cilium-agent \
    --debug=true \
    --bpf-lb-algorithm=maglev \
    --bpf-lb-mode=dsr \
    --bpf-lb-acceleration=native \
    --bpf-lb-dsr-dispatch=ipip \
    --devices=en+ \
    --datapath-mode=lb-only \
    --enable-l7-proxy=false \
    --tunnel=disabled \
    --install-iptables-rules=false \
    --enable-bandwidth-manager=false \
    --enable-local-redirect-policy=false \
    --enable-hubble=true \
    --enable-l7-proxy=false \
    --preallocate-bpf-maps=false \
    --disable-envoy-version-check=true \
    --auto-direct-node-routes=false \
    --enable-ipv4=true \
    --enable-ipv6=false
```
Notes on the command above:
   * `--network host` tells the container to use the host machine network stack and namespace. No port mapping is necessary as a result.
   * `devices` parameter includes the devices the nodes will interact with. List of devices facing cluster/external network; supports '+' as wildcard in device name, e.g. 'eth+'.
   * `enable-ipv6` is `false` and IPv6 addressing is disabled.
2. The cilium container should start in the currently running terminal. Open another terminal and verify that the container is running using `sudo docker ps -a`. It should contain a new container with the name `l4lb`.
3. To execute commands inside the container, use `sudo docker exec -it <container_id> bash`. Container ID can be retrieved from the list of running containers.


### Creating a service in the Cilium container
1. Inside the cilium container, create a service using the `cilium service update` command. The IPs for backends below depend on the private IPs for the Nodes 1 and 2.
  ```
  cilium service update --id 1 --frontend "10.200.200.1:8080" --backends "10.10.2.1:8080,10.10.1.1:8080" --k8s-node-port --debug
  ```
2. 10.200.200.1 is a VIP. To set up a VIP run following commands on both backends.
  ```
  sudo ip link add name ipip0 type ipip external
  sudo ip link add name ipip60 type ip6tnl external
  sudo ip link set up dev ipip0
  sudo ip link set up dev ipip60
  sudo ip a a 127.0.0.42/32 dev ipip0
  sudo sysctl -w net.ipv4.ip_forward=1
  sudo ip a a 10.200.200.1/32 dev lo
  ```
3. Add a route to the VIP on the client by running this command. `lp_ip` is the public-facing IP of the LB node, Node 0 here.
  ```
  //set public ip of lb
  lb_ip =128.105.145.67 
  //set route to vip to lb 
  sudo ip r add 10.200.200.1 via $lb_ip dev enp1s0f0 onlink
  ```

[^1]: https://cilium.io/blog/2022/04/12/cilium-standalone-L4LB-XDP/
















