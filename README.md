# docker-github-self-hosted-runner-win

## Run

```
docker run -it --name "github-runner-win" --dns 8.8.8.8 -e ACCESS_TOKEN="<<YOUR ACCESS_TOKEN>>" -e RUNNER_SCOPE="org" -e ORG_NAME="<<YOUR ORG_NAME>>" -e ADDITIONAL_PACKAGES="vim" alescim/github-runner-win
```