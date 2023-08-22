# Build the Docker image
docker build -t my-shiny-app -f env_spec/Dockerfile_build .

# Save the Docker image as a tarball
docker save -o my-shiny-app.tar my-shiny-app
