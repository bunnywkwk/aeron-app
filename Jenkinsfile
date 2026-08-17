pipeline {
    agent any

    environment {
        APP_NAME = 'portal-a'
        REGISTRY = credentials('docker-registry-url')
        GITOPS_REPO_URL = 'github.com/bunnywkwk/aeron-gitops.git'
        GIT_SHORT_SHA = "${sh(script: 'git rev-parse --short HEAD || echo dev', returnStdout: true).trim()}"
    }

    stages {
        stage('Determine Tags') {
            steps {
                script {
                    if (env.TAG_NAME) {
                        env.IMAGE_TAG = "${env.TAG_NAME}"
                        env.TARGET_FOLDER = "environments/production"
                    } else {
                        env.IMAGE_TAG = "staging-${env.GIT_SHORT_SHA}"
                        env.TARGET_FOLDER = "environments/staging"
                    }
                }
            }
        }

        stage('Build & Push') {
            steps {
                sh """
                    echo "Building ${REGISTRY}/${APP_NAME}:${IMAGE_TAG}"
                    docker build -t ${REGISTRY}/${APP_NAME}:${IMAGE_TAG} .
                    docker push ${REGISTRY}/${APP_NAME}:${IMAGE_TAG}
                """
            }
        }

        stage('Update GitOps') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'github-credentials', usernameVariable: 'GITHUB_USER', passwordVariable: 'GITHUB_TOKEN')]) {
                    sh """
                        rm -rf aeron-gitops
                        git clone https://${GITHUB_USER}:${GITHUB_TOKEN}@${GITOPS_REPO_URL} aeron-gitops
                        cd aeron-gitops
                        
                        sed -i "s|image: ${REGISTRY}/${APP_NAME}:.*|image: ${REGISTRY}/${APP_NAME}:${IMAGE_TAG}|g" ${TARGET_FOLDER}/deployment.yaml
                        
                        git config user.email "jenkins@aeron-automation"
                        git config user.name "Jenkins Engine"
                        git add .
                        git commit -m "ci: update ${APP_NAME} to ${IMAGE_TAG}" || echo "No changes"
                        git push origin main
                    """
                }
            }
        }
    }
}
