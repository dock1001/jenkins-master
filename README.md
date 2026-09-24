# jenkins-master:latest-jdk21

Docker image for the Jenkins controller, weekly release line (JDK 21). For the LTS line, see the `lts` branch.

- Docker CLI and buildx installed, using the host's Docker daemon via the mounted socket
- Plugins preinstalled from [plugins.txt](plugins.txt)
- Configured with [Jenkins Configuration as Code](https://plugins.jenkins.io/configuration-as-code/) from [casc/jenkins.yaml](casc/jenkins.yaml): 0 executors on the controller, so all builds run on agents
- Credentials are left alone by default. You can opt in to managing them with JCasC, see [Credentials](#credentials-opt-in)

## Tags

| Branch   | Image tag |
|----------|-----------|
| `master` | `latest`  |
| other    | `dev`     |

## Running

### Docker socket access

The `jenkins` user reaches the host's Docker daemon through `/var/run/docker.sock`. The container must be in the group that owns the socket on the host, so pass that group's numeric ID with `--group-add`/`group_add`:

```sh
stat -c %g /var/run/docker.sock
```

### Credentials (opt-in)

By default the image doesn't manage credentials. Credentials you add in the UI are kept across restarts.

To manage credentials with JCasC instead, mount a folder with your own JCasC files at `/var/jenkins_casc`. Jenkins loads them together with the built-in [casc/jenkins.yaml](casc/jenkins.yaml).

> **Warning:** once any mounted file has a `credentials:` section, JCasC owns the whole credential store. On every restart it replaces the store with exactly what the files declare, so **credentials added in the UI are deleted**. Declare every credential Jenkins needs.

Keep secret values out of the YAML. Write `${NAME}` and Jenkins reads the value from `/run/secrets/NAME`, falling back to an environment variable of the same name. Prefer files, since environment variables are easier to leak. Never commit secrets.

Example `casc/credentials.yaml`:

```yaml
credentials:
  system:
    domainCredentials:
      - credentials:
          - gitHubApp:
              id: github-app
              description: GitHub App
              appID: "${GITHUB_APP_ID}"
              privateKey: "${GITHUB_APP_KEY}"
          - usernamePassword:
              id: docker-hub
              scope: GLOBAL
              username: my-user
              password: "${DOCKER_HUB_TOKEN}"
```

The mounted files are merged with the built-in file, so don't set a key that [casc/jenkins.yaml](casc/jenkins.yaml) already sets (such as `jenkins.numExecutors`). JCasC stops with an error on conflicting values.

### Example: Docker Compose

```yaml
services:
  jenkins:
    image: <dockerhub-user>/jenkins-master:latest
    ports:
      - "8080:8080"    # web UI
      - "50000:50000"  # inbound agents
    group_add:
      - "999"          # output of: stat -c %g /var/run/docker.sock
    volumes:
      - jenkins_home:/var/jenkins_home
      - /var/run/docker.sock:/var/run/docker.sock
      # Opt-in credential management; leave these two out to manage credentials in the UI
      - ./casc:/var/jenkins_casc:ro                   # your JCasC files
      - ./secrets:/run/secrets:ro                     # one file per secret, readable by uid 1000

volumes:
  jenkins_home:
```

## GitHub App setup

Without a credential, Jenkins scans GitHub anonymously and is limited to 60 API requests per hour. Branch indexing then stalls with `Jenkins-Imposed API Limiter ... Sleeping until reset`. A GitHub App raises the limit to 5,000+ requests per hour.

1. Create a GitHub App on your user or organization with these repository permissions:
   - Contents: read
   - Metadata: read
   - Pull requests: read
   - Commit statuses: read and write
   - Webhooks: read and write (only if Jenkins should manage webhooks)
   - Checks: read and write (only if you use the GitHub Checks plugin)
2. Install the App on the repositories Jenkins should build.
3. Generate a private key and convert it to PKCS#8. GitHub gives you PKCS#1:
   ```sh
   openssl pkcs8 -topk8 -inform PEM -outform PEM -in github-app.pem -out GITHUB_APP_KEY -nocrypt
   ```
4. Add a **GitHub App** credential with the App ID and the converted key. Either add it in the UI, or declare it with JCasC as in the [example above](#credentials-opt-in).
5. In each multibranch job or organization folder, set **Branch Sources → GitHub → Credentials** to that credential and click **Validate**. Jobs aren't managed by JCasC, so this step is manual. Child jobs of an organization folder inherit the credential.
6. Run **Scan Repository Now** (or **Scan Organization Now**). The log should say `Connecting to https://api.github.com using ...` instead of `anonymous access`.

For faster builds with fewer API calls, add a GitHub webhook pointing at `https://<jenkins>/github-webhook/` and set the periodic scan trigger to something long, such as 1 day.

## Changing configuration

JCasC reapplies [casc/jenkins.yaml](casc/jenkins.yaml) and any files in `/var/jenkins_casc` on every startup. Any setting they manage that you change in the UI is reset on the next restart. Change the YAML instead: rebuild the image for the built-in file, or restart Jenkins for mounted files.

To add a plugin, add its ID to [plugins.txt](plugins.txt) and rebuild.
