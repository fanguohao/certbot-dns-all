FROM certbot/certbot

RUN pip install --upgrade pip setuptools wheel

RUN pip install \
    zope.interface \
    certbot-dns-alicloud \
    certbot-dns-dnspod \
    certbot-dns-cloudflare
