FROM python:3.7.4-slim-stretch

MAINTAINER nicor88

COPY requirements.txt .
RUN pip install -r requirements.txt

COPY config/profiles.dist.yml /root/.dbt/profiles.yml

WORKDIR /dbt

COPY macros /dbt/macros
COPY models /dbt/models
COPY tests /dbt/tests
COPY dbt_project.yml /dbt/dbt_project.yml
