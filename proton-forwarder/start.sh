#!/bin/bash



PROTON_USERNAME="${PROTON_EMAIL%%@*}"


mkdir /json
export HYDROXIDEKEYRAW=$(echo $PROTON_PASSWORD | su - root -c "hydroxide auth $PROTON_USERNAME")
IFS=":" read -ra HYDROXIDEKEYDELIMIT <<< "$HYDROXIDEKEYRAW"
export HYDROXIDEKEY="${HYDROXIDEKEYDELIMIT[2]:1}"
echo -e "{\x22user\x22: \x22$PROTON_USERNAME\x22, \x22hash\x22: \x22$HYDROXIDEKEY\x22}" > /data/info.json



DEFAULT_FETCHMAIL_CONFIG="set bouncemail\nset no spambounce\nset softbounce\nset properties \"\"\nset invisible\nset syslog\nset daemon 5\npoll localhost with proto IMAP service 1143 auth password\n       user '$PROTON_USERNAME' there with password '$HYDROXIDEKEY' is '$RECEIVER_EMAIL_ADDRESS' here no sslcertck\n       smtpaddress '$RECEIVER_EMAIL_ADDRESS'"

hydroxide imap | logger -t hydroxide &

echo ${FETCHMAIL_CONFIG-$DEFAULT_FETCHMAIL_CONFIG}> /root/.fetchmailrc

fetchmail -f /root/.fetchmailrc -d &

DEFAULT_POSTFIX_CONFIG="relayhost=$FASTMAIL_SMTP\nsmtp_sasl_auth_enable = yes\nsmtp_sasl_password_maps = hash:/etc/postfix/sasl_passwd\nsmtp_sasl_security_options = noanonymous\nsmtp_sasl_mechanism_filter = PLAIN, LOGIN\nsmtp_use_tls = yes\nsmtp_tls_security_level = encrypt\nsmtp_tls_mandatory_ciphers = high\nsmtp_tls_verify_cert_match = nexthop\nsmtp_sasl_tls_security_options = noanonymous\nvirtual_alias_maps = hash:/etc/postfix/virtual"
echo "$POSTFIX_CONFIG-$DEFAULT_POSTFIX_CONFIG" > /etc/postfix/main.cf
echo "${FASTMAIL_SMTP-"smtp.fastmail.com:587"} ${FASTMAIL_EMAIL/@/#}:$FASTMAIL_APP_PASSWORD" > /etc/postfix/sasl_passwd
echo "$PROTON_EMAIL $FASTMAIL_EMAIL" > /etc/postfix/virtual
postmap /etc/postfix/sasl_passwd
postmap /etc/postfix/virtual

postfix start-fg | logger -t postfix &


tail -f /dev/null