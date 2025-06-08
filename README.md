# LibreChat Cloudron package

Source: https://github.com/danny-avila/LibreChat

NOTE: This app is not currently officially packaged or supported by the Cloudron team.

## Installing

Install a docker registry app (e.g. docker.yourregistry.com in the example below), or use a public registry.

```
docker build . -t docker.yourregistry.com/librechat:latest --platform linux/amd64
docker push docker.yourregistry.com/librechat:latest
# Make sure you are first logged in to your cloudron instance, e.g. `cloudron login`
cloudron install --image docker.yourregistry.com/librechat:latest -l talk
```

If your cloudron instance domain is at `my.cloudroninstance.com` then the above `install` command will install it at `talk.cloudroninstance.com`.

## Todo

- add RAG API for file upload and interraction

## Credits

- LibreChat team
- Vaxelico, who started packaging LibreChat
  https://gitlab.com/vlebert/librechat-cloudron
