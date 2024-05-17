# Kong Plugin - Inflate GZIP

Transparently inflates/deflates GZIP HTTP body(s), when a client is using it but the backend only accepts plaintext payloads.

## Configuration

There is only one config option:

* `config.deflate_response`

and it is set `FALSE` to send the plaintext response body to the client, or set `TRUE` to once again compress the response body
before returning it to the client.