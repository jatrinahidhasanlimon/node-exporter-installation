### Crafted a Bash script for effortlessly installing Node Exporter, simplifying the process. Just run `````sudo ./node_exporter_installer.sh````` 
and boom! 


##### Here are the steps that are needed to follow to install node exporter efficiently with basic auth! but with this bash following commands should not be run manually.

** In the following text all **arm64** will be replaced by amd64 if your system architecture is **amd64** . you can find your system architecture by running   `````jdpkg --print-architecture`````

## Step 1: Download and Install
````
Wget https://github.com/prometheus/node_exporter/releases/download/v1.6.1/node_exporter-1.6.1.linux-arm64.tar.gz
tar xvfz node_exporter-*.*-arm64.tar.gz
````


## Step 2 # move into bin for systemctl daemon service
````
cd node_exporter-*.*-arm64
sudo touch config.yml
sudo mkdir /etc/node_exporterch
sudo mv node_exporter-1.6.1.linux-arm64/node_exporter /usr/local/bin
mv node_exporter.* /etc/node_exporter 
````

## Step 3 # User add 
````
sudo useradd -rs /bin/false node_exporter
````

## Step 4 # Write config file 

Create your own hash password there are number of tools that can help you to job done 
Such as apache2 utils

#
### Step 4.1. # Generate the password hash
````

apt update
apt install apache2-utils -y
htpasswd -nBC 10 "" | tr -d ':\n'; echo
````


### Step 4.2 # write into config
````
sudo nano /etc/node_exporter/config.yml 
````
````
basic_auth_users:
  prometheus: ###our-hashed-password###

````
### step 4.2 # Give permission to user 
````
chown -R node_exporter:node_exporter /etc/node_exporter
````
## Step 5 # Create a node_exporter service file under systemd.
````
sudo nano /etc/systemd/system/node_exporter.service
````

````
[Unit]
Description=Node Exporter
After=network.target
 
[Service]
User=node_exporter
Group=node_exporter
Type=simple
 ExecStart=/usr/local/bin/node_exporter --web.config.file=/etc/node_exporter/config.yml
 
[Install]
WantedBy=multi-user.target

````


## Step 6 # Daemon reload and reactivate on reboot
````
sudo systemctl daemon-reload
sudo systemctl enable node_exporter
sudo systemctl start node_exporter
sudo systemctl status node_exporter
````

## Reference

* https://drive.google.com/file/d/1zIWA8qxFfD_uaVbc_eKr2r-4LwZ6qFiG/view?usp=drive_link
* https://www.dbi-services.com/blog/how-to-keep-your-prometheus-ecosystem-secure/
* https://developer.couchbase.com/tutorial-node-exporter-setup

