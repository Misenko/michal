# MICHAL - Multi-Input Cloud Hardware Accounting Layer

MICHAL is an independent accounting solution. It is intented to be deployed as a stand-alone web application that periodically
communicates with various data sources and pulls accounting data to its own database. Accouting
data then can be viewed locally using the provided web-based GUI.

MICHAL is written using Ruby on Rails and various third party gems.

*Please, keep in mind that MICHAL is still in its early stages and doesn't provide much functionality!*

## Installation
### RVM
The use of RVM is not mandatory but it is highly recommended since MICHAL requires Ruby 1.9.3+
to function properly. More information on RVM installation and configuration can be found in
its documentation at [RVM.io](https://rvm.io/rvm/install/).

### Apache2
Install Apache2 for your distribution. Then install Phusion Passenger and configure Apache2 to load it automatically.
Detailed instructions are available at [Phusion Passenger](https://www.phusionpassenger.com/download/#open_source).

### MICHAL
Checkout the repository in the place you want your installation of MICHAL to be situated and run `bundle install` to install all necessary gems.

## Configuration
### Apache2
Here is an example configuration utilizing Krb5 and X.509 authN at the same time with an optional fallback from X.509 to Krb5:

```
<VirtualHost hostname.example.org:443>
    SSLEngine on
    SSLProtocol all
    SSLCertificateFile /etc/grid-security/hostcert.pem
    SSLCertificateKeyFile /etc/grid-security/hostkey.pem
    SSLCACertificatePath /etc/grid-security/certificates
    SSLCARevocationPath /etc/grid-security/certificates
    SSLVerifyDepth 10

    ServerName hostname.example.org
    DocumentRoot /opt/michal/public
    <Directory /opt/michal/public>
      Options FollowSymLinks
      SSLRequireSSL
      SSLVerifyClient optional
      SSLOptions +StdEnvVars +ExportCertData
      AuthType KerberosV5
      AuthName "Kerberos"
      require valid-user

      Krb5Keytab /etc/krb5.http.keytab
      KrbAuthRealms REALM
      KrbSaveCredentials Off
      KrbMethodNegotiate On
      KrbMethodK5Passwd On
      KrbServiceName HTTP
      KrbVerifyKDC On
      SSLPreauth On

      Allow from all
      Options -MultiViews
    </Directory>

    LogLevel info
</VirtualHost>
```

### MICHAL
Before starting the application you have to setup few things:

* register whenever cron jobs (`bundle exec rake whenever`)
* configure sources in [config/michal/sources/](link:config/michal/sources/)
* replace a few default values in [db/seeds.rb](link:db/seeds.rb)

## Issues
Feel free to report issues to [GH Issues](https://github.com/CESNET/michal/issues)

## Contribute
* Fork it.
* Create a branch (git checkout -b my_markup)
* Commit your changes (git commit -am "My changes")
* Push to the branch (git push origin my_markup)
* Create a Pull Request to this repository from your new branch
