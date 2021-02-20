resource "aws_s3_bucket" "codepipeline_bucket" {
  bucket = "${var.company_name}-ecs-codepipeline-${var.env}"
  acl    = "private"
}

resource "aws_iam_role" "codepipeline_role" {
  name = "${var.project_name}-ecs-codepipeline-${var.env}"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "codepipeline.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "codepipeline_policy" {
  name = "${var.project_name}-ecs-codepipeline-${var.env}"
  role = aws_iam_role.codepipeline_role.id

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect":"Allow",
      "Action": [
        "s3:*"
      ],
      "Resource": [
        "${aws_s3_bucket.codepipeline_bucket.arn}",
        "${aws_s3_bucket.codepipeline_bucket.arn}/*"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "codebuild:BatchGetBuilds",
        "codebuild:StartBuild"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "ecr:*"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "codedeploy:*"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": "iam:PassRole",
      "Resource": "*"
    }
  ]
}
EOF
}

resource "aws_codepipeline" "codepipeline" {
  name     = "${var.project_name}-ecs-codepipeline-${var.env}"
  role_arn = aws_iam_role.codepipeline_role.arn

  artifact_store {
    location = aws_s3_bucket.codepipeline_bucket.bucket
    type     = "S3"
  }

  stage {
    name = "Source"

    action {
      name             = "Source"
      category         = "Source"
      owner            = "ThirdParty"
      provider         = "GitHub"
      version          = "1"
      output_artifacts = ["source_output"]

      configuration = {
        Owner      = var.github_organization
        Repo       = "ecs-terraform-example"
        Branch     = "master"
        OAuthToken = var.github_oauth_token
      }
    }
  }

  stage {
    name = "Build"

    action {
      name             = "Build"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      input_artifacts  = ["source_output"]
      output_artifacts = ["build_output"]
      version          = "1"

      configuration = {
        ProjectName = aws_codebuild_project.main.name
      }
    }
  }
}

resource "aws_codepipeline" "codepipeline-ecr" {
  name     = "${var.project_name}-ecs-codepipeline-ecr-${var.env}"
  role_arn = aws_iam_role.codepipeline_role.arn

  artifact_store {
    location = aws_s3_bucket.codepipeline_bucket.bucket
    type     = "S3"
  }

  stage {
    name = "Source"

    action {
      name             = "Source1"
      category         = "Source"
      owner            = "AWS"
      provider         = "ECR"
      version          = "1"
      output_artifacts = ["build_output1"]

      configuration = {
        ImageTag       = "latest"
        RepositoryName = "task1"
      }
    }
    action {
      name             = "Source2"
      category         = "Source"
      owner            = "AWS"
      provider         = "ECR"
      version          = "1"
      output_artifacts = ["build_output2"]

      configuration = {
        ImageTag       = "latest"
        RepositoryName = "task2"
      }
    }
    action {
      name             = "Source3"
      category         = "Source"
      owner            = "ThirdParty"
      provider         = "GitHub"
      version          = "1"
      output_artifacts = ["source_output"]

      configuration = {
        Owner      = var.github_organization
        Repo       = "ecs-terraform-example"
        Branch     = "master"
        OAuthToken = var.github_oauth_token
      }
    }
  }

  stage {
    name = "Deploy"

    action {
      name            = "Deploy1"
      category        = "Deploy"
      owner           = "AWS"
      provider        = "CodeDeployToECS"
      input_artifacts = ["build_output1", "source_output"]
      version         = "1"

      configuration = {
        ApplicationName                = aws_codedeploy_app.task1.name
        DeploymentGroupName            = aws_codedeploy_deployment_group.task1.deployment_group_name
        Image1ArtifactName             = "build_output1"
        Image1ContainerName            = "IMAGE1_NAME"
        AppSpecTemplatePath            = "appspec1.yaml"
        AppSpecTemplateArtifact        = "source_output"
        TaskDefinitionTemplateArtifact = "source_output"
        TaskDefinitionTemplatePath     = "task-definition-template-1.json"
      }
    }

    action {
      name            = "Deploy2"
      category        = "Deploy"
      owner           = "AWS"
      provider        = "CodeDeployToECS"
      input_artifacts = ["build_output2", "source_output"]
      version         = "1"

      configuration = {
        ApplicationName                = aws_codedeploy_app.task2.name
        DeploymentGroupName            = aws_codedeploy_deployment_group.task2.deployment_group_name
        Image1ArtifactName             = "build_output2"
        Image1ContainerName            = "IMAGE1_NAME"
        AppSpecTemplatePath            = "appspec1.yaml"
        AppSpecTemplateArtifact        = "source_output"
        TaskDefinitionTemplateArtifact = "source_output"
        TaskDefinitionTemplatePath     = "task-definition-template-2.json"
      }
    }
  }
}

resource "aws_codepipeline_webhook" "main" {
  name            = "${var.project_name}-ecs-codepipeline-${var.env}"
  authentication  = "GITHUB_HMAC"
  target_action   = "Source"
  target_pipeline = aws_codepipeline.codepipeline.name

  authentication_configuration {
    secret_token = var.github_webhook_secret
  }

  filter {
    json_path    = "$.ref"
    match_equals = "refs/heads/master"
  }
}

# Wire the CodePipeline webhook into a GitHub repository.
resource "github_repository_webhook" "main" {
  repository = "ecs-terraform-example"

  configuration {
    url          = aws_codepipeline_webhook.main.url
    content_type = "form"
    insecure_ssl = true
    secret       = var.github_webhook_secret
  }

  events = ["push"]
}
