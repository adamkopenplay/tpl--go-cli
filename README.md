# GO CLI template

Use init.sh to configure this repo.

You can delete the init.sh script after completion, and remove this content from this README.

```
Usage: ./init.sh [OPTS]
```

## Options

| OPTION | Type | Default | Required | Description | 
| ------ | ---- | ------- | -------- | ----------- |
| --name=* | `string` | - | Y | Repository name. This will also be used for the name of the tool. |
| --org=* | `string` | - | Y | The git organisation the repository is in. |
| --image=* | `string` | - | Y | The name of the image we should push to, including the org name. |
| --git-host=* | `string` | `github.com` | N | The URL of the git histing server. |
| --go-version=* | `string` | `1.20` | N | The go version to use. |
| --registry=* | `string` | `docker.io` | N | The docker registry that the image should be pushed to. |
| --no-init | `bool` | `false` | N | Will prevent initialising the go app (i.e. prevents `go mod init`) |
