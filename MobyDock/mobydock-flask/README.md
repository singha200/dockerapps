**Flask -- Building the app**
**Build and run everything in 1 command**
docker-compose up --build
**Visit the database seed route in your browser**
http://localhost:8000/seed
Using the Docker Toolbox? Goto http://192.168.99.100:8000 instead
**Feed MobyDock until you get bored**
<Keep reloading your browser>
**Stop everything**
docker-compose stop
**Show the Docker Compose help menu**
docker-compose --help
**Build everything again**
docker-compose build
**Up everything again**
docker-compose up
**Show a list of Docker images**
docker images
**List running Docker containers**
docker ps
docker container ls
**Exec into the running mobydock container**
docker-compose exec mobydock bash
**List running Docker containers for this project**
docker-compose ps
**List Docker networks**
docker network ls
**List Docker volumes**
docker volume ls
**Stop and remove everything**
docker-compose down -v
Install git
sudo apt-get install git
Configure git
git config --global user.email"you@example.com"
git config --global user.name "Your Name"
**Customize the text in blue with whatever you want.**
Create a git repo out of the project and commit everything
git init && git add -A && git commit -m "Initial commit"
