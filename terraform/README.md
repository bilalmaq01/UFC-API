# Deploying the API (Step 2)

The Lambda runs a container image, so the image must exist in ECR **before**
the Lambda resource can be created. That's why the first apply is scoped to
just the ECR repo.

> Uses `tofu` (OpenTofu). If you have HashiCorp Terraform instead, every
> command below works with `terraform` in place of `tofu`.

## One-time prerequisites

```sh
tofu -version                   # OpenTofu installed
# Docker Desktop must be installed AND running (whale icon in the menu bar)
aws sts get-caller-identity     # should print your account
```

`terraform.tfvars` is already populated with your Supabase `DATABASE_URL`.

## First deploy

```sh
cd terraform
tofu init
tofu apply -target=aws_ecr_repository.api   # 1) create ONLY the registry
```

Build and push the image (from the repo root):

```sh
cd ..
REGION=us-west-2
ACCOUNT=$(aws sts get-caller-identity --query Account --output text)
ECR="$ACCOUNT.dkr.ecr.$REGION.amazonaws.com/ufcapi-api"

aws ecr get-login-password --region $REGION \
  | docker login --username AWS --password-stdin "$ACCOUNT.dkr.ecr.$REGION.amazonaws.com"

docker build --platform linux/arm64 -t ufcapi-api .
docker tag ufcapi-api:latest "$ECR:latest"
docker push "$ECR:latest"
```

Now create everything else:

```sh
cd terraform
tofu apply                 # 2) Lambda + API Gateway + IAM
tofu output api_base_url
```

## Test it

```sh
curl "$(tofu output -raw api_base_url)/health"
# -> {"status":"ok"}
curl "$(tofu output -raw api_base_url)/fighters/search?q=jones"
```

## Redeploying after a code change

```sh
docker build --platform linux/arm64 -t ufcapi-api . && docker tag ufcapi-api:latest "$ECR:latest" && docker push "$ECR:latest"
aws lambda update-function-code --function-name ufcapi-api --image-uri "$ECR:latest" --region us-west-2
```

## Tear it all down

```sh
tofu destroy
```
