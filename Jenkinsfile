pipeline {
    agent {
        label 'docker'
    }
    
    environment {
        DOCKER_REGISTRY = 'kartikeyadhub'
        DOCKER_CREDENTIALS = 'dockerhub'
        APP_NAME = 'micro'
        GIT_REPO = 'https://github.com/ksrepo9/github.git'
        GIT_BRANCH = 'main'
        K8S_MANIFESTS_DIR = 'k8s'
        DEPLOYMENT_FILE = 'app-deployment.yaml'
    }
    
    stages {
        stage('Checkout Code') {
            steps {
                git branch: 'main', credentialsId: 'github', url: 'https://github.com/ksrepo9/github.git'
            }
        }
        
        stage('Docker Compose Build') {
            steps {
                sh 'docker compose build'
            }
        }
        
        stage('Tag') {
            steps {
                script {
                    echo "=== Current Docker Images ==="
                    sh 'docker images'
                    
                    echo "=== Tagging built image ==="
                    sh """
                        docker tag pro-ci-spring-app ${DOCKER_REGISTRY}/${APP_NAME}:${BUILD_NUMBER}
                        docker tag pro-ci-spring-app ${DOCKER_REGISTRY}/${APP_NAME}:latest
                    """
                    
                    echo "=== Verifying tags ==="
                    sh "docker images | grep \"${DOCKER_REGISTRY}/${APP_NAME}\""
                    
                    // Set variables for downstream jobs
                    env.DOCKER_IMAGE_LATEST = "${DOCKER_REGISTRY}/${APP_NAME}:latest"
                    env.DOCKER_IMAGE_BUILD = "${DOCKER_REGISTRY}/${APP_NAME}:${BUILD_NUMBER}"
                }
            }
        }
        
        stage('Push') {
            steps {
                script {
                    withCredentials([usernamePassword(
                        credentialsId: 'dockerhub',
                        usernameVariable: 'DOCKER_USER',
                        passwordVariable: 'DOCKER_PASS'
                    )]) {
                        sh """
                            # Login to Docker Hub
                            echo "\$DOCKER_PASS" | docker login --username \$DOCKER_USER --password-stdin
                            
                            # Push images
                            docker push ${DOCKER_REGISTRY}/${APP_NAME}:${BUILD_NUMBER}
                            docker push ${DOCKER_REGISTRY}/${APP_NAME}:latest
                            
                            # Logout
                            docker logout
                            
                            echo "✅ Images pushed successfully to ${DOCKER_REGISTRY}/${APP_NAME}"
                        """
                    }
                }
            }
        }
        
        stage('Update Kubernetes Manifest') {
            steps {
                script {
                    echo "=== Updating Kubernetes Deployment Manifest ==="
                    
                    // Create and execute the update script
                    def updateScript = """
#!/bin/bash
set -e

echo "🔍 Finding deployment file..."
DEPLOYMENT_FILE_PATH="${K8S_MANIFESTS_DIR}/${DEPLOYMENT_FILE}"
NEW_IMAGE="${DOCKER_REGISTRY}/${APP_NAME}:${BUILD_NUMBER}"

echo "📝 Updating deployment file: \$DEPLOYMENT_FILE_PATH"
echo "🆕 New image: \$NEW_IMAGE"

# Check if deployment file exists
if [ ! -f "\$DEPLOYMENT_FILE_PATH" ]; then
    echo "❌ ERROR: Deployment file \$DEPLOYMENT_FILE_PATH not found!"
    echo "Current directory: \$(pwd)"
    echo "Files in k8s directory:"
    ls -la ${K8S_MANIFESTS_DIR} 2>/dev/null || echo "k8s directory not found"
    exit 1
fi

# Backup the original file
cp "\$DEPLOYMENT_FILE_PATH" "\$DEPLOYMENT_FILE_PATH.backup"

# Update the image in deployment file
if grep -q "image:" "\$DEPLOYMENT_FILE_PATH"; then
    # Method 1: Using sed (works for most YAML files)
    sed -i "s|image:.*${APP_NAME}.*|image: \$NEW_IMAGE|g" "\$DEPLOYMENT_FILE_PATH"
    echo "✅ Image updated using sed"
else
    echo "⚠️ No image field found in deployment file"
fi

# Verify the update
echo "=== Updated deployment file ==="
grep -A 2 -B 2 "image:" "\$DEPLOYMENT_FILE_PATH" || echo "No image found in file"

echo "🔍 Comparing changes:"
diff -u "\$DEPLOYMENT_FILE_PATH.backup" "\$DEPLOYMENT_FILE_PATH" || true

echo "✅ Kubernetes manifest updated successfully!"
"""

                    // Write and execute the script
                    writeFile file: 'update-k8s-manifest.sh', text: updateScript
                    sh 'chmod +x update-k8s-manifest.sh && ./update-k8s-manifest.sh'
                }
            }
        }
        
        stage('Commit and Push to GitHub') {
            steps {
                script {
                    echo "=== Committing and Pushing Changes to GitHub ==="
                    
                    withCredentials([usernamePassword(
                        credentialsId: 'github',
                        usernameVariable: 'GIT_USERNAME',
                        passwordVariable: 'GIT_PASSWORD'
                    )]) {
                        sh """
                            # Configure git
                            git config user.name "Jenkins"
                            git config user.email "jenkins@example.com"
                            
                            # Add changes
                            git add ${K8S_MANIFESTS_DIR}/${DEPLOYMENT_FILE}
                            
                            # Check if there are changes to commit
                            if git diff --staged --quiet; then
                                echo "⚠️ No changes to commit"
                            else
                                # Commit changes
                                git commit -m "CI: Update ${APP_NAME} image to ${BUILD_NUMBER} [Jenkins Build #${BUILD_NUMBER}]"
                                
                                # Push to GitHub
                                git push https://\${GIT_USERNAME}:\${GIT_PASSWORD}@github.com/ksrepo9/github.git HEAD:${GIT_BRANCH}
                                
                                echo "✅ Changes committed and pushed to GitHub"
                                echo "📝 Commit message: Update ${APP_NAME} image to ${BUILD_NUMBER}"
                            fi
                        """
                    }
                }
            }
        }
        
        stage('Trigger ArgoCD Sync') {
            steps {
                script {
                    echo "=== ArgoCD Auto-Sync Triggered ==="
                    echo "📦 New Image: ${DOCKER_REGISTRY}/${APP_NAME}:${BUILD_NUMBER}"
                    echo "🔗 ArgoCD will automatically detect the Git changes and sync"
                    echo "⏰ Sync should happen within ArgoCD's configured sync period"
                    
                    // Optional: If you want to manually trigger ArgoCD sync via API
                    // Uncomment and configure the following if needed:
                    /*
                    withCredentials([string(credentialsId: 'argocd-token', variable: 'ARGOCD_TOKEN')]) {
                        sh """
                            curl -X POST \
                                 -H "Authorization: Bearer \$ARGOCD_TOKEN" \
                                 https://argocd.your-domain.com/api/v1/applications/${APP_NAME}/sync
                        """
                    }
                    */
                }
            }
        }
        
        stage('Export Variables') {
            steps {
                script {
                    // Create environment file for downstream jobs
                    sh """
                        echo "DOCKER_IMAGE_LATEST=${DOCKER_REGISTRY}/${APP_NAME}:latest" > docker-vars.env
                        echo "DOCKER_IMAGE_BUILD=${DOCKER_REGISTRY}/${APP_NAME}:${BUILD_NUMBER}" >> docker-vars.env
                        echo "DOCKER_IMAGE_NAME=${DOCKER_REGISTRY}/${APP_NAME}" >> docker-vars.env
                        echo "DOCKER_IMAGE_TAG=${BUILD_NUMBER}" >> docker-vars.env
                        echo "GIT_COMMIT_MESSAGE=CI: Update ${APP_NAME} image to ${BUILD_NUMBER}" >> docker-vars.env
                        echo "ARGOCD_APP_NAME=${APP_NAME}" >> docker-vars.env
                    """
                    
                    // Archive the file
                    archiveArtifacts artifacts: 'docker-vars.env'
                    
                    echo "📦 Image Variables Exported:"
                    echo "Latest: ${DOCKER_REGISTRY}/${APP_NAME}:latest"
                    echo "Build: ${DOCKER_REGISTRY}/${APP_NAME}:${BUILD_NUMBER}"
                }
            }
        }
    }
    
    post {
        always {
            echo "Cleaning up Docker resources..."
            sh 'docker system prune -f'
            sh 'rm -f update-k8s-manifest.sh docker-vars.env 2>/dev/null || true'
        }
        success {
            echo "🎉 Pipeline completed successfully!"
            echo "📊 Build Number: ${BUILD_NUMBER}"
            echo "🐳 Image: ${DOCKER_REGISTRY}/${APP_NAME}:latest"
            echo "📝 Git Commit: Updated deployment.yaml with new image"
            echo "🚀 ArgoCD: Changes pushed to Git - Auto-sync triggered"
        }
        failure {
            echo "❌ Pipeline failed!"
        }
    }
}