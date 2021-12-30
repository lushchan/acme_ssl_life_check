# acme_ssl_life_check

`-h - вызов справки`

`-w - указывается количество дней до истечения срока валидности сертификата, при котором будет приходить уведомление WARNING. Обязательный параметр.`

`-с - указывается количество дней до истечения срока валидности сертификата, при котором будет приходить уведомление CRITICAL. Обязательный параметр.`

```# /usr/lib64/nagios/plugins/check_acme -h
Help
Options:
-h - help
-w - set warning threshold in days
-c - set critical threshold in days
If you wanna check non-acme certs, place domains in /usr/lib64/nagios/plugins/external
