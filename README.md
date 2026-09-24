# jenkins-master:lts-jdk21

Docker image for the Jenkins LTS controller (JDK 21).

- Docker CLI and buildx installed, using the host's Docker daemon via the mounted socket
- Plugins preinstalled from [plugins.txt](plugins.txt)
- Configured with [Jenkins Configuration as Code](https://plugins.jenkins.io/configuration-as-code/) from [casc/jenkins.yaml](casc/jenkins.yaml):
  - 0 executors on the controller, so all builds run on agents
  - A GitHub App credential (`github-app`) for GitHub API access

## Tags

| Branch | Image tag |
|--------|-----------|
| `lts`  | `lts`     |
| other  | `dev-lts` |

## Running

### Docker socket access

The `jenkins` user reaches the host's Docker daemon through `/var/run/docker.sock`. The container must be in the group that owns the socket on the host, so pass that group's numeric ID with `--group-add`/`group_add`:

```sh
stat -c %g /var/run/docker.sock
```

### GitHub App secrets

The `github-app` credential is built at startup from two values:

| Name             | Value                                        |
|------------------|----------------------------------------------|
| `GITHUB_APP_ID`  | The App ID from the GitHub App settings page |
| `GITHUB_APP_KEY` | The App's private key, in PKCS#8 format      |

Jenkins reads each value from `/run/secrets/<name>`, falling back to an environment variable of the same name. Prefer files, since environment variables are easier to leak. Never commit the key.

GitHub gives you the key in PKCS#1 format. Convert it before use:

```sh
openssl pkcs8 -topk8 -inform PEM -outform PEM -in github-app.pem -out GITHUB_APP_KEY -nocrypt
```

### Example: Docker Compose

```yaml
services:
  jenkins:
    image: <dockerhub-user>/jenkins-master:lts
    ports:
      - "8080:8080"    # web UI
      - "50000:50000"  # inbound agents
    group_add:
      - "999"          # output of: stat -c %g /var/run/docker.sock
    volumes:
      - jenkins_home:/var/jenkins_home
      - /var/run/docker.sock:/var/run/docker.sock
    secrets:
      - GITHUB_APP_ID
      - GITHUB_APP_KEY

secrets:
  GITHUB_APP_ID:
    file: ./secrets/GITHUB_APP_ID
  GITHUB_APP_KEY:
    file: ./secrets/GITHUB_APP_KEY

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
3. Generate a private key, convert it to PKCS#8 (see above) and provide both secrets.
4. In each multibranch job or organization folder, set **Branch Sources → GitHub → Credentials** to `github-app` and click **Validate**. Jobs aren't managed by JCasC, so this step is manual. Child jobs of an organization folder inherit the credential.
5. Run **Scan Repository Now** (or **Scan Organization Now**). The log should say `Connecting to https://api.github.com using ...` instead of `anonymous access`.

For faster builds with fewer API calls, add a GitHub webhook pointing at `https://<jenkins>/github-webhook/` and set the periodic scan trigger to something long, such as 1 day.

## Changing configuration

JCasC reapplies [casc/jenkins.yaml](casc/jenkins.yaml) on every startup. Any setting it manages that you change in the UI is reset on the next restart. Change the YAML and rebuild the image instead.

To add a plugin, add its ID to [plugins.txt](plugins.txt) and rebuild.
