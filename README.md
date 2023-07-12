# campaign-site-docker-API
Docker for monerofund.org fundraising campaigns API

## Building

Before building the Docker with `docker build -t monerofundapi .`, a file named `.env` must be placed in this repository with the API keys, Store ID, and URL, with this format:

```txt
BTCPAY_API_KEY=<key>
BTCPAY_URL=https://<domain>/api/v1/
BTCPAY_STORE_ID=<id>
STRIPE_SECRET_KEY=<key>
```
