pipeline {
    agent any

    environment {
        APP_NAME = 'portal-a'
        REGISTRY = credentials('docker-registry-url')
        GITOPS_REPO_URL = 'github.com/bunnywkwk/aeron-gitops.git'
    }

    stages {
        stage('Determine Tags') {
            steps {
                script {
                    if (env.TAG_NAME) {
                        // Production Release (Git Tag v1.0.x)
                        env.IS_PROD = 'true'
                        env.IMAGE_TAG = "${env.TAG_NAME}"
                        env.TARGET_FOLDER = "environments/production"
                        echo "Production Release Build. Tag: ${env.IMAGE_TAG}"
                    } else if (env.BRANCH_NAME == 'main') {
                        // Staging Build (ONLY ON MAIN BRANCH!)
                        env.IS_STAGING = 'true'
                        env.IMAGE_TAG = "staging-v${env.BUILD_NUMBER}"
                        env.TARGET_FOLDER = "environments/staging"
                        echo "Staging Build on main. Tag: ${env.IMAGE_TAG}"
                    } else {
                        // Feature Branch (e.g. new-branch, feature/*)
                        env.IS_FEATURE = 'true'
                        echo "Feature Branch (${env.BRANCH_NAME}) detected. Automated testing stage only."
                    }
                }
            }
        }

        stage('Build & Push') {
            when {
                anyOf {
                    environment name: 'IS_STAGING', value: 'true'
                    environment name: 'IS_PROD', value: 'true'
                }
            }
            steps {
                sh """
                    echo "Building ${REGISTRY}/${APP_NAME}:${IMAGE_TAG}"
                    docker build -t ${REGISTRY}/${APP_NAME}:${IMAGE_TAG} .
                    docker push ${REGISTRY}/${APP_NAME}:${IMAGE_TAG}
                """
            }
        }

        stage('Update GitOps') {
            when {
                anyOf {
                    environment name: 'IS_STAGING', value: 'true'
                    environment name: 'IS_PROD', value: 'true'
                }
            }
            steps {
                withCredentials([usernamePassword(credentialsId: 'github-credentials', usernameVariable: 'GITHUB_USER', passwordVariable: 'GITHUB_TOKEN')]) {
                    sh """
                        rm -rf aeron-gitops
                        git clone https://${GITHUB_USER}:${GITHUB_TOKEN}@${GITOPS_REPO_URL} aeron-gitops
                        cd aeron-gitops
                        
                        # 1. Update image tag
                        sed -i "s|image: ${REGISTRY}/portal-a:.*|image: ${REGISTRY}/portal-a:${IMAGE_TAG}|g" ${TARGET_FOLDER}/deployment.yaml

                        # 2. Update APP_VERSION
                        sed -i "/name: APP_VERSION/{n;s|value: .*|value: \"${IMAGE_TAG}\"|}" ${TARGET_FOLDER}/deployment.yaml

                        git config user.email "aeron@jenkins-automation"
                        git config user.name "Aeron"
                        git add .
                        git commit -m "ci: update ${APP_NAME} to ${IMAGE_TAG}" || echo "No changes"
                        git push origin main
                    """
                }
            }
        }
    }
}
