DB_URL=postgresql://root:123456@localhost:20000/simple_bank?sslmode=disable

postgres:
docker run -it -d --name psql -e POSTGRES_USER=root -e POSTGRES_DB=simple_bank -e POSTGRES_PASSWORD=123456 -p 20000:5432 postgres
