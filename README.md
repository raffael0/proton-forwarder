# Proton-Forwarder
This repo is my attempt to forward emails from ProtonMail to a 3rd-party mail provider like FastMail. To accomplish this I'm stringing together multiple applications - specifically Hydroxide, fetchmail and postfix.

Please note that these instructions are a work in progress. While I managed to get it to work locally, I ultimately failed at creating a docker container which works. More on that in [#Docker](#Docker)

I listed all inputs needed for each application in the respective section.

The hydroxide portion of this projects docker files is adapted from Harley Lang's [hydroxide-docker](https://github.com/harleylang/hydroxide-docker)

# Hydroxide:
[Hydroxide](https://github.com/emersion/hydroxide/)
 is used to connect to the ProtonMail servers via standard email protocols such as IMAP/SMTP/POP3. 


inputs:
- proton_username
- proton_password

## install hydroxide:
```bash
git clone https://github.com/emersion/hydroxide.git
go build ./cmd/hydroxide
```
## Generate bridge password:

generate pass with proton username and password

```bash
hydroxide auth <username>
```
store it in as an env variable:
```bash
HYDROXIDE_BRIDGE_PASS = pass
```

## Run the IMAP server

```bash
hydroxide imap
```

# Fetchmail:
Fetchmail connects to the local IMAP server(from Hydroxide) and gets all new emails and sends them Postfix.


Inputs:
- proton_username
- hydroxide_bridge_pass
- receiver_email_address

## Install Fetchmail

```bash
sudo apt install fetchmail
```

## Configure Fetchmail
Copy the following config to ~/.fetchmailrc
```bash
set bouncemail
set no spambounce
set softbounce
set properties ""
set invisible
set syslog
set daemon 5
poll localhost with proto IMAP service 1143 auth password
       user '$PROTON_USERNAME' there with password '$HYDROXIDE_BRIDGE_PASS' is '$RECEIVER_EMAIL_ADDRESS' here no sslcertck
       smtpaddress '$RECEIVER_EMAIL_ADDRESS'

```

## Run Fetchmail

```bash
fetchmail -d
```

# Postfix

Postfix does the actual forwarding. Each message received from fetchmail gets sent to the defined email address. Please note that you may have to change the Postfix config when you're using a different email provider.


inputs:
- fastmail_email
- fastmail_app_password
- proton_email

## Install postfix

```bash
sudo apt install postfix
```

## Create config
/etc/postfix/main.cf:
```bash
relayhost=smtp.fastmail.com:587

smtp_sasl_auth_enable = yes
smtp_sasl_password_maps = hash:/etc/postfix/sasl_passwd
smtp_sasl_security_options = noanonymous
smtp_sasl_mechanism_filter = PLAIN, LOGIN
smtp_use_tls = yes
smtp_tls_security_level = encrypt
smtp_tls_mandatory_ciphers = high
smtp_tls_verify_cert_match = nexthop
smtp_sasl_tls_security_options = noanonymous

virtual_alias_maps = hash:/etc/postfix/virtual
```

## Add the sasl_passwd file

you need to replace the @ in the mail with #
/etc/postfix/sasl_passwd:
```postfix
smtp.fastmail.com:587 $fastmail_email:$fastmail_app_password
```

## Add the virtual file

/etc/postfix/virtual
```bash
$proton_email   $fastmail_email
```

## Generate Hash Database:

```bash
postmap /etc/postfix/sasl_passwd
postmap /etc/postfix/virtual
```

## Start postfix

```bash
sudo systemctl enable postfix
sudo systemctl start postfix
```


# Docker
My attempt at dockerizing the project lives in `/docker`. Sadly I couldn't get it to work since Protonmail seems to reject block mosts[1] requests made from Hydroxide in the container. Multiple Upstream fixes were suggested like a [cookie yar](https://github.com/emersion/hydroxide/issues/218) or various [http header modifications](https://github.com/emersion/hydroxide/issues/235). Until a solution is presented I don't think it's feasible to create a docker container. Please let me know if anyone finds a solution... 

[1] One or two runs of the script seem to work when starting up but when debugging the problem I get immediately rate-limited which makes development incredibly annoying

<details>
<summary>The error message</summary>
```bash
2023/09/03 19:43:13 request failed: POST https://mail.proton.me/api/auth: [9001] For security reasons, please complete CAPTCHA. If you can't pass it, please try updating your app or contact us here: https://proton.me/support/abuse
```
</details>

## Variables
These are the variables that need to be set including defaults

**FASTMAIL_SMTP**: The receiving smtp server + port

default:
```
smtp.fastmail.com:587
```
**FASTMAIL_EMAIL**: The receiving email
```
mail@example.com
```

**PROTON_EMAIL**: The Protonmail address

```
mail@protonmail.com
```
**PROTON_PASSWORD**: The Protonmail password

```
passw
```
**POSTFIX_CONFIG**: The postfix config

default:
```bash
relayhost=$FASTMAIL_SMTP
smtp_sasl_auth_enable = yes
smtp_sasl_password_maps = hash:/etc/postfix/sasl_passwd
smtp_sasl_security_options = noanonymous
smtp_sasl_mechanism_filter = PLAIN, LOGIN
smtp_use_tls = yes
smtp_tls_security_level = encrypt
smtp_tls_mandatory_ciphers = high
smtp_tls_verify_cert_match = nexthop
smtp_sasl_tls_security_options = noanonymous
virtual_alias_maps = hash:/etc/postfix/virtual
```

**FETCHMAIL_CONFIG**
default:
```bash
set bouncemail
set no spambounce
set softbounce
set properties ""
set invisible
set syslog
set daemon 5
poll localhost with proto IMAP service 1143 auth password
       user '$PROTON_USERNAME' there with password '$HYDROXIDE_BRIDGE_PASS' is '$RECEIVER_EMAIL_ADDRESS' here no sslcertck
       smtpaddress '$RECEIVER_EMAIL_ADDRESS'
```

"
