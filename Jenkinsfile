
pipeline {
    agent {
        label 'taskforge-agent'
    }

    options {
        timestamps()
        skipDefaultCheckout(true)
        preserveStashes(buildCount: 5)
    }

    stages {
        stage('Checkout') {
            steps {
                git branch: 'main',
                    url: 'https://github.com/XO-Edson/TaskForge.git'

                stash name: 'taskforge-source',
                    includes: '**',
                    excludes: '**/node_modules/**,**/dist/**'
            }
        }

        stage('Verify Toolchain') {
            steps {
                sh '''
                    set -eu

                    node --version
                    npm --version
                    git --version
                    docker --version
                    docker info --format 'Docker server: {{.ServerVersion}}'

                    docker run --rm aquasec/trivy:latest --version
                '''
            }
        }

        
    stage('Verify AWS Credentials') {
        steps {
            withCredentials([
                usernamePassword(
                    credentialsId: 'aws-ecr-credentials',
                    usernameVariable: 'AWS_ACCESS_KEY_ID',
                    passwordVariable: 'AWS_SECRET_ACCESS_KEY'
                )
            ]) {
                sh '''
                    set -eu

                    echo "=== Verify AWS identity ==="
                    docker run --rm \
                        -e AWS_ACCESS_KEY_ID \
                        -e AWS_SECRET_ACCESS_KEY \
                        -e AWS_DEFAULT_REGION=eu-central-1 \
                        amazon/aws-cli:latest \
                        sts get-caller-identity

                    echo "=== Verify ECR authentication permission ==="
                    docker run --rm \
                        -e AWS_ACCESS_KEY_ID \
                        -e AWS_SECRET_ACCESS_KEY \
                        -e AWS_DEFAULT_REGION=eu-central-1 \
                        amazon/aws-cli:latest \
                        ecr get-login-password \
                        --region eu-central-1 > /dev/null

                    echo "AWS credentials and ECR authentication verified."
                '''
            }
        }
    }


        stage('Build Frontend') {
            steps {
                retry(2) {
                    dir('frontend') {
                        sh '''
                            set -eu
                            npm ci
                            npm run build
                        '''
                    }
                }
            }
        }

        stage('Validate Backend') {
            steps {
                retry(2) {
                    dir('backend') {
                        sh '''
                            set -eu
                            npm ci
                            node --check src/server.js
                        '''
                    }
                }
            }
        }

        stage('Run Available Tests') {
            steps {
                script {
                    for (String app : ['frontend', 'backend']) {
                        dir(app) {
                            sh '''
                                set -eu

                                if node -e "process.exit(require('./package.json').scripts?.test ? 0 : 1)"
                                then
                                    npm test
                                else
                                    echo "No test script configured; skipping."
                                fi
                            '''
                        }
                    }
                }
            }
        }

        stage('Build Frontend Image') {
            steps {
                retry(2) {
                    sh '''
                        set -eu

                        IMAGE_TAG=$(git rev-parse --short=12 HEAD)
                        FRONTEND_IMAGE="taskforge-frontend:${IMAGE_TAG}"

                        docker build --pull \
                            --label "org.opencontainers.image.revision=$(git rev-parse HEAD)" \
                            -t "$FRONTEND_IMAGE" \
                            ./frontend

                        docker image inspect "$FRONTEND_IMAGE" \
                            --format '{{.Id}}'
                    '''
                }
            }
        }

        stage('Build Backend Image') {
            steps {
                retry(2) {
                    sh '''
                        set -eu

                        IMAGE_TAG=$(git rev-parse --short=12 HEAD)
                        BACKEND_IMAGE="taskforge-backend:${IMAGE_TAG}"

                        docker build --pull \
                            --label "org.opencontainers.image.revision=$(git rev-parse HEAD)" \
                            -t "$BACKEND_IMAGE" \
                            ./backend

                        docker image inspect "$BACKEND_IMAGE" \
                            --format '{{.Id}}'
                    '''
                }
            }
        }

        stage('Scan Frontend') {
            steps {
                retry(2) {
                    sh '''
                        set -eu

                        IMAGE_TAG=$(git rev-parse --short=12 HEAD)
                        FRONTEND_IMAGE="taskforge-frontend:${IMAGE_TAG}"

                        docker run --rm \
                            -v /var/run/docker.sock:/var/run/docker.sock \
                            -v taskforge-trivy-cache:/root/.cache/ \
                            aquasec/trivy:latest \
                            image \
                            --image-src docker \
                            --docker-host unix:///var/run/docker.sock \
                            --timeout 15m \
                            --scanners vuln \
                            --severity HIGH,CRITICAL \
                            --exit-code 1 \
                            "$FRONTEND_IMAGE"
                    '''
                }
            }
        }

        stage('Scan Backend') {
            steps {
                retry(2) {
                    sh '''
                        set -eu

                        IMAGE_TAG=$(git rev-parse --short=12 HEAD)
                        BACKEND_IMAGE="taskforge-backend:${IMAGE_TAG}"

                        docker run --rm \
                            -v /var/run/docker.sock:/var/run/docker.sock \
                            -v taskforge-trivy-cache:/root/.cache/ \
                            aquasec/trivy:latest \
                            image \
                            --image-src docker \
                            --docker-host unix:///var/run/docker.sock \
                            --timeout 15m \
                            --scanners vuln \
                            --severity HIGH,CRITICAL \
                            --exit-code 1 \
                            "$BACKEND_IMAGE"
                    '''
                }
            }
        }
    }

    post {
        success {
            echo 'TaskForge CI and security scans completed successfully.'
        }

        failure {
            echo 'TaskForge pipeline failed. Restart from the failed stage where appropriate.'
        }

        always {
            echo 'Pipeline execution finished.'
        }
    }
}

