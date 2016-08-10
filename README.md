Master: [![Build Status](https://travis-ci.org/diegovalle/hoyodesmog.svg?branch=master)](https://travis-ci.org/diegovalle/hoyodesmog)
Develop: [![Build Status](https://travis-ci.org/diegovalle/hoyodesmog.svg?branch=develop)](https://travis-ci.org/diegovalle/hoyodesmog)
# HoyoDeSmog

Web site for hoyodesmog.diegovalle.net

It is recommended to use the ansible playbook in the ansible directory
to install. You'll need to create a secrets.yml (it's encrypted in
this repo) file with the following structure:

```yml
      # Structure of secrets.yml
      EMAIL_ADDRESS:
      SENDGRID_USER:
      SENDGRID_PASS:
      ## created with:
      ## mkpasswd --method=SHA-512
      DEPLOY_PASSWORD:
      ROOT_PASSWORD:
      HEATMAP_HEALTHCHECK_URL:
      RUNALL_HEALTHCHECK_URL:
```

The *_HEALTHCHECK variables are for [deadmansnitch] like services

To manually install, copy the files to /var/www/hoyodesmog.diegovalle.net, add
the nginx.conf file to the sites-available directory under nginx, and add the following lines to cron in a
system with R already installed.

```{sh}
1-25,30,40,50 * * * * /var/www/hoyodesmog.diegovalle.net/R/run-all.sh >> /var/www/hoyodesmog.diegovalle.net/R/log-all.txt
1-25,30,40,50 * * * * /var/www/hoyodesmog.diegovalle.net/R/run-heatmap.sh >> /var/www/hoyodesmog.diegovalle.net/R/log-heatmap.txt
```

If you have a sendgrid account you can set the EMAIL_ADDRESS,
SENDGRID_USER and SENDGRID_PASS to have the program send you and email
when 140 IMECAS are reached

#License

The template used by the website is not free software.

License: pixelarity.com/license

Every else is under an MIT License
