# Local CI/CD Pipeline on a Windows Laptop using WSL, KIND, GitLab Runner, Docker, AWS ECR, Snyk and Argo CD

**Recommended Project to see before this project:** https://github.com/bhavukm/devops-cicd-production.git

**YouTube Video:** https://youtu.be/eG9hJ1E1GbI

Reference project used: https://gitlab.com/bhavukm/springboot-app.git

This README documents the complete local CI/CD setup built during this
project.

The final design runs GitLab CI jobs on a self-hosted GitLab Runner
installed inside WSL on a Windows laptop. The runner uses the Shell
executor and can directly access the local Docker daemon, the local KIND
Kubernetes cluster, and the locally exposed Argo CD server.

The pipeline builds a Spring Boot application, pushes the container
image to Amazon ECR, scans the image with Snyk, updates a separate
GitOps repository with the exact image tag, and lets Argo CD synchronize
that Git change into the local KIND cluster.

------------------------------------------------------------------------
# Final Architecture

<img width="206" height="677" alt="image" src="https://github.com/user-attachments/assets/bde3798b-0eb2-42ac-988b-b764045be1c8" />

     Prerequisites

The laptop needs:

-   Windows
-   WSL
-   Ubuntu or another Linux distribution inside WSL
-   Docker available from WSL
-   KIND
-   kubectl
-   Git
-   AWS CLI
-   GitLab Runner
-   Argo CD
-   Argo CD CLI
-   An AWS account
-   An Amazon ECR repository
-   A GitLab project containing the Spring Boot application
-   A second GitLab repository for GitOps
-   A Snyk account/token if scanning is enabled

**Step 1: Open WSL**

Open your Ubuntu/WSL terminal:

**Step 2: Update packages**

sudo apt update

sudo apt upgrade -y

**Step 3: Install required tools**

sudo apt install -y curl ca-certificates git

Verify:

curl --version

git --version

**Step 4: Add the official GitLab Runner repository**

curl -L "https://packages.gitlab.com/install/repositories/runner/gitlab-runner/script.deb.sh" -o /tmp/gitlab-runner-repo.sh

Then run it:

sudo bash /tmp/gitlab-runner-repo.sh

This configures the official GitLab Runner package repository.

**Step 5: Install GitLab Runner**

sudo apt install -y gitlab-runner

**Step 6: Verify installation**

gitlab-runner --version

You should get something similar to:
Version:      19.x.x
Git revision: ...
GO version:   ...
OS/Arch:      linux/amd64

**Step 7: Verify where Runner is installed**

which gitlab-runner

Expected:

/usr/bin/gitlab-runner

Then:
ls -l /usr/bin/gitlab-runner

**Step 8: Check Runner status**

First check:
gitlab-runner status

For your lab, I would make the second one deliberately obvious:

Existing: bhavuk-wsl-kind-runner

New: bhavuk-wsl-kind-runner-2

Same WSL machine

Same GitLab project: bhavukm/springboot-app

Same shell executor

Different tag: kind-local-2

**1. Create the second runner in GitLab**

Go to:

GitLab → springboot-app → Settings → CI/CD → Runners

Click:

Create project runner

Configure it approximately like this:

Setting	Value

Runner description	bhavuk-wsl-kind-runner-2

Platform	Linux

Tags	kind-local-2

Run untagged jobs	OFF

Protected	OFF for this lab

Then click Create runner.

GitLab will show you a temporary runner authentication token. Keep that page open. The current GitLab workflow uses runner authentication tokens, which normally start with glrt-.

**2. Register the second runner in your WSL**

Open your WSL terminal.

Run:

gitlab-runner register

You will get:

Enter the GitLab instance URL:

Enter:

https://gitlab.com/

Then:

Enter an authentication token:

Paste the new runner's token from GitLab.

Then:

Enter a name for the runner:

Enter:

bhavuk-wsl-kind-runner-2

Then:

Enter an executor:

Enter:

shell

You should eventually see:

Runner registered successfully.

The important point for your video is that you don't install another GitLab Runner application.

You are registering another runner configuration with the existing GitLab Runner installation. 

GitLab Runner supports multiple [[runners]] entries in the same configuration file.

**3. Verify that you now have TWO runners**

Run:

gitlab-runner list

You should see something similar to:

bhavuk-wsl-kind-runner

bhavuk-wsl-kind-runner-2

You can also run:

gitlab-runner verify

Expected:

Verifying runner... is valid

Verifying runner... is valid

And:

cat ~/.gitlab-runner/config.toml

You should now have two [[runners]] sections.

Something conceptually like:

[[runners]]

  name = "bhavuk-wsl-kind-runner"
  
  url = "https://gitlab.com/"
  
  token = "glrt-XXXXXXXX"
  
  executor = "shell"


[[runners]]

  name = "bhavuk-wsl-kind-runner-2"
  
  url = "https://gitlab.com/"
  
  token = "glrt-YYYYYYYY"
  
  executor = "shell"

Do not show the tokens in your YouTube recording.

**4. Start the runner**

Because you are using user-mode GitLab Runner, run:

gitlab-runner run

If your existing runner is already running in another terminal, you need to make sure the Runner process reloads the updated configuration.

You can check:

ps aux | grep gitlab-runner

For your lab, the simplest approach is to stop the existing process and start it again:

pkill gitlab-runner

Then:

gitlab-runner run

You should see both runners being loaded from:

/home/bhavuk/.gitlab-runner/config.toml

**5. Make sure the second runner has the correct tag**

This is important.

Your current .gitlab-ci.yml has:

test-local-runner:

  stage: test
  
  tags:
  
    - kind-local

That job will therefore go to:

bhavuk-wsl-kind-runner

because that runner has:

kind-local

For the second runner, use:

kind-local-2

**6. Add a test job for the second runner**

For your YouTube demonstration, I recommend temporarily adding this to .gitlab-ci.yml:

runner-2-demo:

  stage: test

  tags:
  
    - kind-local-2

  script:
  
    - echo "========================================="
    
    - echo "       SECOND RUNNER DEMONSTRATION"
    
    - echo "========================================="

    - echo "Runner:"
    
    - echo "$CI_RUNNER_DESCRIPTION"

    - echo "Runner ID:"
    
    - echo "$CI_RUNNER_ID"

    - echo "Runner tags:"
    
    - echo "$CI_RUNNER_TAGS"

    - echo "User:"
    - whoami

    - echo "Hostname:"
    
    - hostname

    - echo "Kubernetes context:"
    
    - kubectl config current-context

    - echo "Kubernetes nodes:"
    
    - kubectl get nodes

    - echo "========================================="
    
    - echo "Second runner is working!"
    
    - echo "========================================="

Now push the change.

**7. What you should see in GitLab**

The pipeline should contain:

test-local-runner

runner-2-demo

The first job:

tags:

  - kind-local

goes to:

bhavuk-wsl-kind-runner

The second:

tags:
  - kind-local-2

goes to:

bhavuk-wsl-kind-runner-2

Both are actually executing on the same Windows laptop → WSL environment.
