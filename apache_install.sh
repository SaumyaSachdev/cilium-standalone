#!/bin/bash

# Create a directory for the HTML file
mkdir -p apache_html
echo "<html><body><h1>Hello, Docker Apache Server!</h1></body></html>" > apache_html/index.html

# Create a Dockerfile to configure the Apache server
echo "FROM httpd:latest" > Dockerfile
echo "COPY ./apache_html/ /usr/local/apache2/htdocs/" >> Dockerfile

# Build the Docker image
docker build -t my-apache-image .

# Run the Docker container
docker run -d -p 8080:80 --name my-apache-container my-apache-image

echo "Apache server is running on http://localhost:8080/"
