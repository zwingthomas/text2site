# Dockerfile

FROM python:3.8-slim-buster 

ARG APP_ENV
ENV APP_ENV=${APP_ENV}

WORKDIR /app

COPY requirements.txt requirements.txt
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

EXPOSE 80

CMD ["gunicorn", "--bind", "0.0.0.0:80", "app:app"]
