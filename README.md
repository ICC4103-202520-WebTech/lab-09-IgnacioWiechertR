# Lab 10 — Deploying the Recipe Book Application with Kamal on DigitalOcean

## Objective
Deploy your Recipe Book application to a live server using **Kamal** and **DigitalOcean**.  
By the end of this lab, you should have your application running online, accessible through a temporary DigitalOcean IP (no domain required).

This lab consolidates your knowledge of:
- Preparing a Rails app for production.
- Using **Kamal** for simple and reproducible deployments.
- Working with **DigitalOcean droplets**.
- Managing environment variables and secrets in production.

## Instructions
1. **Prepare Your Application for Production**
   - Make sure your application runs correctly in development.
   - Commit all recent changes to your Git repository.
   - Check that your database configuration supports the `production` environment.
   - Ensure all required environment variables are defined (`RAILS_MASTER_KEY`, `DATABASE_URL`, etc.).

2. **Set Up DigitalOcean**
   - Create a new **droplet** (you can use the referral link provided by your instructor to get free credits).
   - Configure SSH access so Kamal can deploy to the droplet.
   - You do **not** need a custom domain — the server’s IP address will be enough.

3. **Install and Configure Kamal**
   - Add Kamal to your project and initialize the configuration.
   - Set up your `kamal.yml` file with:
     - The server IP address.
     - The image name and repository (if you use Docker Hub or GitHub Container Registry).
     - Environment variables for production.

4. **Deploy the Application**
   - Use Kamal to build and deploy your app to the droplet.
   - Verify that the application is accessible via the droplet’s public IP.

5. **Post-Deployment Verification**
   - Visit the IP in your browser and confirm that:
     - The home page loads.
     - You can sign up and log in.
     - Recipes can be created and displayed correctly.
   - Check that logs and containers are running as expected on the server.

## Deliverables
- Recipe Book application successfully deployed to DigitalOcean using Kamal.
- A short write-up (in Markdown or PDF) explaining:
  - The steps you followed.
  - Any issues encountered and how you solved them.
  - The IP address where the app can be accessed.
- Clean repository ready for evaluation.
