# Jenkins → EKS End-to-End Demo

A minimal Node.js/Express API, built and deployed to an existing EKS cluster
via an existing Jenkins server. Docker images are pushed to Docker Hub.

## Project layout

```
.
├── app/
│   ├── server.js         # Express API (/, /health)
│   ├── server.test.js    # Jest + Supertest tests
│   └── package.json
├── Dockerfile             # multi-stage build, non-root runtime user
├── .dockerignore
├── Jenkinsfile             # declarative pipeline: test → build → push → deploy
└── k8s/
    ├── namespace.yaml
    ├── deployment.yaml    # image tag is templated at deploy time
    └── service.yaml       # LoadBalancer service (creates an AWS ELB)
```

## One-time setup on your Jenkins server

1. **Plugins**: `Pipeline`, `Docker Pipeline`, `Credentials Binding`,
   `Amazon Web Services SDK :: All` (or `pipeline-aws`).
2. **Tools on the Jenkins agent**: `docker`, `node`/`npm`, `kubectl`, `aws` CLI
   all need to be installed and on `PATH`. The agent's Docker daemon must be
   reachable by the Jenkins user (e.g. it's in the `docker` group).
3. **Credentials** (Manage Jenkins → Credentials):
   - `dockerhub-creds` — Username/Password credential with your Docker Hub
     username + an access token (not your account password).
   - `aws-eks-creds` — AWS credentials (access key/secret, or better, an IAM
     role) for an IAM principal that has `eks:DescribeCluster` and is mapped
     in the cluster's `aws-auth` ConfigMap (or EKS access entries) with
     permissions to deploy into the `demo` namespace.
4. Edit the `TODO` values at the top of `Jenkinsfile`:
   - `DOCKERHUB_USER`
   - `EKS_CLUSTER_NAME`
   - `AWS_REGION`
5. Create a **Multibranch Pipeline** or **Pipeline** job in Jenkins pointing
   at this repo — Jenkins will auto-discover the `Jenkinsfile`.

## What the pipeline does

1. **Checkout** — pulls this repo.
2. **Install Dependencies / Test** — `npm ci` + `npm test` (Jest).
3. **Docker Build** — builds `<dockerhub-user>/jenkins-eks-demo:<build-number>`
   and `:latest`.
4. **Docker Push** — logs in to Docker Hub using the `dockerhub-creds`
   credential and pushes both tags.
5. **Configure kubectl** — runs `aws eks update-kubeconfig` so `kubectl`
   points at your cluster.
6. **Deploy to EKS** — applies the namespace/service, substitutes the new
   image tag into `deployment.yaml`, applies it, and waits on
   `kubectl rollout status` so the build fails if the rollout doesn't
   succeed.

## Running locally (optional sanity check before wiring up Jenkins)

```bash
cd app
npm install
npm test
npm start          # serves on http://localhost:3000

# in another terminal
docker build -t jenkins-eks-demo:local .
docker run -p 3000:3000 jenkins-eks-demo:local
```

## Verifying the deployment

```bash
kubectl get pods -n demo
kubectl get svc jenkins-eks-demo -n demo   # note the EXTERNAL-IP (ELB hostname)
curl http://<EXTERNAL-IP>/health
```

## Notes / things to adapt for a real environment

- The Service uses `type: LoadBalancer`, which provisions a classic ELB on
  EKS. Swap in an Ingress + AWS Load Balancer Controller if you want an ALB,
  path routing, or TLS termination.
- For production, prefer OIDC/IRSA or a Jenkins IAM instance role over static
  AWS access keys in `aws-eks-creds`.
- Consider pinning image digests instead of mutable tags, and adding a
  `imagePullPolicy: IfNotPresent` / `Always` depending on your tagging
  strategy.
- Add a `HorizontalPodAutoscaler` and `NetworkPolicy` if this is meant to be
  more than a demo.
# EKS-Demo
