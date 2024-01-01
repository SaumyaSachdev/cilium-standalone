# cilium-standalone
## Steps to set up cilium in standalone
// TO DO: include Cloudlab profile and hardware details
### Basic setup and packages
1. Download and install Docker on all three connected nodes using the script `docker_install.sh`.
2. Pull the stable version of the Cilium image on Node 0 from Docker using the command below:
   ```
   sudo docker pull cilium/cilium:stable
   ```
3. Verify that BPF FS is mounted using the command below. BPF should be mounted in the directory `/sys/fs/bpf`. Follow steps in reference [^1] if this is not the case.
   ```
   mount | grep bpf
   ```
   The result for this should include something similar to: 
   `bpf on /sys/fs/bpf type bpf (rw,nosuid,nodev,noexec,relatime,mode=700)`
   
4. Install a basic Apache server in the two nodes, Node 1 and Node 2. These are the nodes connected to the load balancer as the backends across which the load is balanced. Use the script `apache_install.sh`.
5. Verify that the two servers are reachable by the Load Balancer Node 0 by using `curl`.
   ```
   curl <Node 1 IP>:8080
   curl <Node 2 IP>:8080
   ```

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
    cilium/cilium:stable cilium-agent \
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
   * `devices` parameter includes the devices that the nodes will be interacting with. List of devices facing cluster/external network; supports '+' as wildcard in device name, e.g. 'eth+'.
   * `enable-ipv6` is `false` and IPv6 addressing is disabled.
2. The cilium container should start in the currently running terminal. Open another terminal and verify that the container is running using `sudo docker ps -a`. It should contain a new container with the name `l4lb`.
3. To execute commands inside the container use `sudo docker exec -it <container_id> bash`. Container ID can be retrieved from the list of running containers.


### Creating a service in the Cilium container
// TO DO: include details on how to create VIP for the cilium node
1. Inside the cilium container, create a service using the `cilium service update` command.
  ```
  cilium service update --id 1 --frontend "128.110.218.84:8080" --backends "128.110.218.86:8080" --k8s-node-port --debug
  10.10.2.1
  ```
2. // TO DO: include details on which IPs to be used for backends.


[^1]: https://cilium.io/blog/2022/04/12/cilium-standalone-L4LB-XDP/
















