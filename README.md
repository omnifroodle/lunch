# Cassandra as your first Anthos workload

# pre-work
* kill clusters
* remove clusters from Anthos
* make sure disks are cleaned up here: [Google Cloud Platform](https://console.cloud.google.com/compute/disks?project=anthos-309114)

*<spin up, then we chat>*
What’s Anthos?
* manage multiple k8 clusters as fleets
* config management -> git ops + k8s policy management
* service mesh -> IP visibility and security
* multi and hybrid cloud

What’s Cassandra?
* Distributed database designed for availability and scale (in CAP terms, C* is AP, while most distributed db’s are CP)
* the data fabric behind huge distributed systems from Apple & Netflix to FedEx and Verizon

Why are they great together?
* Anthos makes it more efficient than ever to scale your applications across the world for great uptime and responsiveness.  Cassandra is an idea database to support modern, globally-distributed app (big or small).

Fleets!


## step 1, create our first kubernetes cluster

Where?  Anywhere… we will use GCP but this could be on-premises or even on another cloud.  Anthos provides us the tools to manage hybrid and multi cloud deployments with great visibility, security, and repeatability

To set our terms:
Hybrid: on-premises -> cloud
Multi: cloud -> cloud


Lets spin up a Kubernetes cluster:
— in production we would actually split these nodes across zones in the region, Cassandra can use that when placing replicas to make the data even more durable

*<terminal>* 5 minutes
```
gcloud beta container \
	--project "anthos-309114" \
	clusters create "cen-cassandra" \
	--zone "us-central1-c" \
	--no-enable-ip-alias \
	--machine-type "e2-standard-4" \
	--num-nodes "3" \
	--network "projects/anthos-309114/global/networks/default" \
	--subnetwork "projects/anthos-309114/regions/us-central1/subnetworks/default" \
	--node-locations "us-central1-c" \
	--addons GcePersistentDiskCsiDriver
```

Or single:
```
gcloud beta container \
	--project "anthos-309114" \
	clusters create "cen-cassandra" \
	--zone "us-central1-c" \
	--no-enable-ip-alias \
	--machine-type "e2-standard-4" \
	--num-nodes "1" \
	--network "projects/anthos-309114/global/networks/default" \
	--subnetwork "projects/anthos-309114/regions/us-central1/subnetworks/default" \
	--node-locations "us-central1-c" \
	--addons GcePersistentDiskCsiDriver
```

## K8ssandra and Cassandra
Define both…

Cassandra is a NoSQL database designed for distributed deployment (think NY, LA and Tokyo).  It’s great for problems that need super high availability (no leaders, configured correctly you can loose a node, an AZ or even and entire DC/region w/o interuption)

K8ssandra is an Kubernetes operator plus a set of useful tools for daily life with Cassandra:
* medusa -> tools to manage Cassandra backups
* reaper -> long running anti-entropy data repair (not the first line of defense against data entropy in Cassandra)
* grafana -> dashboard for viewing cluster metrics, though you may want to look at integrating directly with GCP metrics tools.

Cluster is done? Let’s grab our creds for our first GKE cluster
*<terminal>*
```
gcloud container clusters get-credentials cen-cassandra --region us-central1-c --project anthos-309114
```


## Keeping secrets shared
In k8ssandra we can setup these credential with Kubernetes secrets.
*<terminal>*
```
kubectl create namespace us-central1
kubectl create secret generic cassandra-admin-secret \
	--from-literal=username=cassandra-admin \
	--from-literal=password=cassandra-admin-password \
	-n us-central1
```

If you try this at home, please don’t use this username and password!!! (And go read the Cukoo’s Egg, if you haven’t yet)

## our own spin on k8ssandra
Now to setup our config for the first K8ssandra cluster.  Check out our `gke.yaml`

```
vim gke.yaml
```

Call out 
* auth settings, and how they tie to the secret we created
* cluster name, and how it will need to match other k8ssandra installs for replication
* size, and cluster size… might be good to share a version of the config with multiple dc ’s and racks… talk about Cassandra being smart about striping the data. -> “here we are talking about keeping data close to users, but lots of C* users care about 100% uptime or greater r/w speeds and do that by adding nodes in each DC and striping them across AZ’s.  Loose a node, loose and AZ, loose a region…”
* promethious/grafana
* Cassandra version
* data volume size (and stateful sets)
* number of nodes, 3 is most common (best avialabilty both in region and distributed, consistent latency metrics). 1 is also possible, but loosing that node would take out an entire regions.

## helm it up
(You could also import your helm into Anthos config management, but we aren’t there yet…)
*<terminal>* 5 minutes
```
helm repo add k8ssandra https://helm.k8ssandra.io
helm repo update

helm install anthos-k8ssandra k8ssandra/k8ssandra -f k8ssandra/gke.triple.cen.yml -n us-central1
```

Did it go?

```
watch kubectl get pods -n us-central1
```

Problems?

```
kubectl -n us-central1 get events


kubectl -n us-central1 exec \
  -it multi-region-dc2-default-sts-0  \
  -c cassandra \
  -- nodetool -u cassandra-admin -pw cassandra-admin-password status
```

## What are all these pods?!
* reaper
* cass-operator
* grafana
* prometheus
* stargate

## wait for the Stargate…
Wait for the Stargate pod and we can proceed
```
kubectl exec -it multi-region-dc2-default-sts-0  \
	-c cassandra \
	-n us-central1 \
	-- nodetool -u cassandra-admin -pw cassandra-admin-password status 
```

`UN` is up and normal, our C* DC is ready to go!

## if you like it then you shoulda put an app on it
### config manager
In ui, register cluster to fleet
[Google Cloud Platform](https://console.cloud.google.com/anthos/clusters?project=anthos-309114)

Url: https://github.com/omnifroodle/lunch.git
Authentication: none
Branch: us-central1
Policy directory: Anthos

*<web browser>* show config management directory, call out password secret

*TODO* sneak in second cluster creation!

### no config manager
New namespace? Also needs a secret
```
kubectl create namespace frontend
kubectl create secret generic cassandra-admin-secret --from-literal=username=cassandra-admin --from-literal=password=cassandra-admin-password -n frontend
```
```
kubectl apply -f lunch-deployment.yaml -n frontend
kubectl expose deployment lunch-app --name=lunch-app-service --type=LoadBalancer --port 80 --target-port 4000 -n frontend
```
Watch for an external ip here:

```
❯ kubectl -n frontend get services                                                                                                                                                                       ─╯
NAME                                     TYPE           CLUSTER-IP      EXTERNAL-IP    PORT(S)                                                 AGE
anthos-k8ssandra-dc2-stargate-service    ClusterIP      10.112.4.177    <none>         8080/TCP,8081/TCP,8082/TCP,8084/TCP,8085/TCP,9042/TCP   95m
anthos-k8ssandra-grafana                 ClusterIP      10.112.2.251    <none>         80/TCP                                                  95m
anthos-k8ssandra-kube-prom-operator      ClusterIP      10.112.6.188    <none>         443/TCP                                                 95m
anthos-k8ssandra-kube-prom-prometheus    ClusterIP      10.112.3.101    <none>         9090/TCP                                                95m
anthos-k8ssandra-reaper-reaper-service   ClusterIP      10.112.0.216    <none>         8080/TCP                                                95m
cass-operator-metrics                    ClusterIP      10.112.2.95     <none>         8383/TCP,8686/TCP                                       95m
lunch-app-service                        LoadBalancer   10.112.12.109   35.239.42.95   80:31020/TCP                                            37m
multi-region-dc2-all-pods-service        ClusterIP      None            <none>         9042/TCP,8080/TCP,9103/TCP                              95m
multi-region-dc2-service                 ClusterIP      None            <none>         9042/TCP,9142/TCP,8080/TCP,9103/TCP,9160/TCP            95m
multi-region-seed-service                ClusterIP      None            <none>         <none>                                                  95m
prometheus-operated                      ClusterIP      None            <none>         9090/TCP                                                95m
```

## hold on, now we need some tables!

```
kubectl -n us-central1 exec -it multi-region-dc2-default-sts-0  -c cassandra -- cqlsh -u cassandra-admin -p cassandra-admin-password
```

single
```
create KEYSPACE lunch WITH replication = {'class' : 'NetworkTopologyStrategy', 'dc2' : 1};
```

```
create table lunch.lunchers ( location text, name text, time timestamp, thumbnail text, primary key(location, time, name)) WITH clustering order by (time desc);
```


```
kubectl -n frontend rollout restart deployment/lunch-app 
```


## Service mesh?
?web ui?

*Talk about it, probably not worth the time to roll out*

Security
Observability


Anthos service mesh… slow to add (maybe do this right after cluster creation?!)
```
./install_asm \
		--project_id anthos-309114 \
        --cluster_name cen-cassandra  \
        --cluster_location us-central1-c  \
        --mode install \
        --output_dir ./asm-downloads \
        --enable_all
```

TODO this can take a while, maybe Rohit can talk about Anthos more here?

```
kubectl -n istio-system get pods -l app=istiod --show-labels
kubectl label namespace us-central1 istio-injection- istio.io/rev=asm-1102-3 --overwrite
```



## Back to Hybrid/Multi
Let’s add some more cloud, apps should be everywhere… data fabric… repeatable parts… SRE, etc

## What makes a C* cluster?
To build a cluster that replicates across regions (or clouds, or on-prem) we’ll need to make sure we have a couple things in common across our k8ssandra installs:
1) cluster seeds, more on this later
2) admin credentials
3) a shared cassandra cluster name
4) network access between nodes (and K8s clusters)

First, we need seeds to ensure we know how to connect our clusters… 

Get seeds:

```
kubectl get pods -n us-central1 -o jsonpath="{.items[*].status.podIP}" --selector cassandra.datastax.com/seed-node=true
```


```
10.0.0.18
```

Set additional seeds in `gke.triple.east.yml`

We’ll need another cluster:
```
gcloud beta container \
	--project "anthos-309114" \
	clusters create "east-cassandra" \
	--zone "us-east1-b" \
	--no-enable-ip-alias \
	--machine-type "e2-standard-4" \
	--num-nodes "1" \
	--network "projects/anthos-309114/global/networks/default" \
	--subnetwork "projects/anthos-309114/regions/us-east1/subnetworks/default" \
	--node-locations "us-east1-b" \
	--addons GcePersistentDiskCsiDriver
```

Let’s grab our creds for our new GKE cluster
```
gcloud container clusters get-credentials east-cassandra --region us-east1-b --project anthos-309114
```


Add our secrets:
```
kubectl create namespace us-east1
kubectl create secret generic cassandra-admin-secret --from-literal=username=cassandra-admin --from-literal=password=cassandra-admin-password -n us-east1
```

And our helm chart:
```
helm install anthos-k8ssandra k8ssandra/k8ssandra -f k8ssandra/gke.single.east.yml -n us-east1
```


When we think pods are done:
```
kubectl -n us-east1 exec -it multi-region-dc1-default-sts-0  \
	-c cassandra \
	-- nodetool -u cassandra-admin -pw cassandra-admin-password status
```
Check our firewall


TIME HERE TO DISCUSS NETWORKING OPTIONS for multi/hybrid (adding nodes will take a few minutes)


## setup app on the second dc
Config manager here


```
kubectl -n us-east1 exec -it multi-region-dc1-default-sts-0  -c cassandra -- cqlsh -u cassandra-admin -p cassandra-admin-password
```


Switch to a us-east1 branch

```
drop keyspace lunch;
ALTER KEYSPACE system_auth WITH REPLICATION = 
{'class' : 'NetworkTopologyStrategy', 'dc2' : 1, 'dc1': 1};
```

## Closing
Cassandra and Anthos are complimentary technologies that work together to make building distributed apps easier, as well as making operating them safer and faster.

Whatever your reason for a distributed architecture, be it hybrid cloud as a way to access burstable cloud resource (or a way to begin the cloud life of on-prem assets), apps that are responsive around the world (no waiting on round trips to a database instance on the other side of the world), or apps that just can’t go down…

Anthos and Cassandra are a great choice to make them happen!

Please, reach out to us at TK
