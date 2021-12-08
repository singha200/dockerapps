**Flask -- Building the app** <br />
**Build and run everything in 1 command** <br />
docker-compose up --build
**Visit the database seed route in your browser**<br />
http://localhost:8000/seed
Using the Docker Toolbox? Goto http://192.168.99.100:8000 instead
**Feed MobyDock until you get bored** <br />
<Keep reloading your browser>
****Stop everything****<br />
docker-compose stop
****Show the Docker Compose help menu****<br />
docker-compose --help
****Build everything again****<br />
docker-compose build
****Up everything again****<br />
docker-compose up
****Show a list of Docker images****<br />
docker images
****List running Docker containers****<br />
docker ps
docker container ls
****Exec into the running mobydock container****<br />
docker-compose exec mobydock bash
****List running Docker containers for this project****<br />
docker-compose ps
****List Docker networks****<br />
docker network ls
****List Docker volumes****<br />
docker volume ls
****Stop and remove everything****<br />
docker-compose down -v
Install git
sudo apt-get install git
Configure git
git config --global user.email"you@example.com"
git config --global user.name "Your Name"
****Customize the text in blue with whatever you want.****<br />
Create a git repo out of the project and commit everything
git init && git add -A && git commit -m "Initial commit"
