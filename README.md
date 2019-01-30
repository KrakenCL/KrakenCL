# KrakenCL
Continuous learning, integration and deployment server for Machine Learning.

## Instalation
As config storage *KrakenCL* is using SQLite library.


### macOS

You can install SQLite, libgit2, libssh2 with [Homebrew](https://brew.sh/):

```
$ brew install sqlite libgit2 libssh2
```

### Linux
```
$ sudo apt-get install sqlite3 libsqlite3-dev libgit2
```

## Ubuntu service
There is a great tutorial about how to [setup upstart script](https://crunchify.com/systemd-upstart-respawn-process-linux-os/) and respawn process, I'll just make a quick walkthrough about what you should do. First, simply create a new file under `/lib/systemd/system/krakeb-cl.service with the following contents.

```
[Unit]
Description=Kraken-CL server daemon

[Service]
User=ubuntu
Group=ubuntu
ExecStart=/usr/local/bin/kraken-cl 8080
Restart=always

[Install]
WantedBy=multi-user.target
```

Of course provide your own configuration (path, user, group and exec command). When you finish you have to reload systemctl configs, and you are ready to go.

```
chmod +x /lib/systemd/system/kraken-cl.service
systemctl daemon-reload
systemctl enable kraken-cl.service
systemctl start kraken-cl
systemctl status kraken-cl
```

From now on you can simply sudo service todo start|stop|restart your backend application server, which is actually very convenient! 


## Hosting through a web server
### nginx
Nginx is a web server and even more. You can simply install it by running the sudo apt-get install nginx command. Maybe the hardest part is to setup a proper nginx configuration for your application server with HTTP2 and SSL support. A very basic HTTP nginx configuration should look something like this.

```
server {
    listen 80;
    server_name mytododomain.com;
    
    location / {
        proxy_pass              http://localhost:8080;
        proxy_set_header        Host $host;
        proxy_set_header        X-Real-IP $remote_addr;
        proxy_set_header        X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header        X-Forwarded-Proto $scheme;
        proxy_read_timeout      90;
    }
}
```

This setup (somewhere inside `/etc/nginx/sites-available/domain.com`) simply proxies the incoming traffic from the domain to the local port through pure HTTP without the S-ecurity. Don't forget to symlink the file into the sites-enabled folder and sudo service reload nginx. If you messed up someting you can always sudo nginx -t.

### Letsencrypt
In order to support secure HTTP connections, first you'll need an SSL certificate. Letsencrypt will help you get one for FREE. You just have to install certbot.

```
sudo apt-get update
sudo apt-get install software-properties-common
sudo add-apt-repository ppa:certbot/certbot
sudo apt-get update
sudo apt-get install python-certbot-nginx 
```

You can request a new certificate and setup SSL automatically for your nginx configuration, by running the following command.

```
sudo certbot --nginx
```

You just have to follow the instructions and enjoy the brand new secure API service written in Swift language. Ah, don't forget to set up a cron job to renew your certificate periodically. 

```
sudo certbot renew --dry-run
```