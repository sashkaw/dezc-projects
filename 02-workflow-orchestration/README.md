## Troubleshooting

### Secrets
- To use a secret from a `.env` file in Kestra, the secret must be base64 encoded and the variable must be prefixed with `SECRET_` in the `.env` file like so:

```
# .env

SECRET_MY_KEY="<base_64_encoded_value>"
```

- The Kestra docker-compose.yml file should include the `env_file` property like so:
```
kestra:
    ...
    env_file:
      - .env
    environment:
    ...
```

- You can then access the secret within Kestra as 
`"{{ secret('MY_KEY') }}"`

