# CI/CD with Kubernetes

This guide explains the basic workflow of how Kubernetes can be integrated with the CI/CD pipelines for deployment of an application in a simplified way.

## What is CI?

CI stands for Continuous Integration. In CI, when people work on a project together, code changes are integrated into a shared repository on a regular basis. This is typically done multiple times a day.  Then, automated tests run to check if everything is okay with the new code. This helps catch problems early in the development cycle. If these tests say "Everything is ok!" then the code is allowed to move to the next steps in the pipeline.
There are a lot of tools that help in achieving CI/CD, like Jenkins, AWS CodePipeline, etc. 

## What is CD?

CD stands for both, Continuous Delivery and Continuous Deployment. Continuous Deployment extends CI by automating the deployment process. Once the code passes CI stage in the pipeline, it's automatically deployed to a staging environment for further testing. If everything works well in the staging environment, the code is then automatically promoted to the production environment, making the release process more efficient and reducing the risk of manual errors. However, Continuous Delivery means that your code changes are automatically tested and built as part of the CI stage. If everything looks good, the application is all set to be deployed. However, you decide when to actually release it to the end users.

## Role of Kubernetes in CI/CD

Kubernetes is like a super helper in the process of getting the application ready and out to end users. It helps put the application on different places in the same way every time. This helps make sure everything works well, no matter where it goes. 

Let us understand this through a simple workflow of a CI/CD pipeline for a containerized application.

1. **Committing Code**: Developers commit their code changes to a version control system like Git. 
2. **Build**: An automated build is triggered in a CI/CD tool like Jenkins to build a Docker image from the application code.
3. **Run Tests**: Automated tests are run on the Docker image to ensure it meets the set functionality/standards.
4. **Push Artifacts**: Once the testing stage is completed, the image is pushed to an Artifact Management System like Artifactory/Dockerhub/Docker Trusted Registry. 
5. **Deployment using Kubernetes**: In this stage, we leverage the power of Kubernetes to streamline and automate the deployment process of the application. Let's get into the process by breaking it down into various essential steps.

* **Deployment Manifest File**:
 A Kubernetes deployment script, deployment YAML file, holds the critical configuration instructions that Kubernetes requires to manage and deploy the application. Within this YAML file, we define the application's name, specify the container image to be used, determine the desired number of instances (replicas), and include other essential configurations. This YAML file acts as a comprehensive guide for Kubernetes, detailing how to create, maintain, and update the application's environment.
 The deployment YAML file is stored in the same repository as the application code. This allows for easy collaboration, versioning, and synchronization between the application code and its deployment configuration.

* **Deployment in Staging Environment**:
 After generating a new image for the application through CI, the next step is to deploy it to a staging environment within the Kubernetes cluster. This staging environment, often known as "Staging" or "Pre-Prod", closely resembles the production setup but operates in isolation for testing.

* **Testing in Staging Environment**:
 Automated testing and validation are performed in the staging environment to ensure the new version of the application image works as expected. 

* **Production Deployment**:
 Once the testing in the staging environment passes successfully, the new version of the application can be deployed to the production environment using the same deployment YAML script that guided the staging deployment. This ensures consistent setup in the production environment and the transition from staging to production is seamless.


<img width="1147" alt="Screenshot 2023-08-21 at 4 16 35 PM" src="https://github.com/bwarikoo/kubestarter/assets/32089999/086c90df-b741-4cac-8f5e-b7904d03d989">


## Conclusion

By automating the above-mentioned steps and using Kubernetes, the CI/CD process becomes more efficient, reliable, and repeatable. It helps development teams release new features faster while maintaining stability! Happy Learning!
