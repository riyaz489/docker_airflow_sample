FROM puckel/docker-airflow:1.10.2

COPY requirements.txt ./

#COPY ./airflow/airflow.cfg /usr/local/airflow
# changing user to root to create new directory
USER root
RUN mkdir /usr/local/output/
# giving ownership of output folder to airflow user
RUN chown -R airflow: /usr/local/output/
# changing user back to airflow
USER airflow

COPY ./tasks /usr/local/tasks
COPY ./library /usr/local/library
COPY ./config /usr/local/config

RUN pip install --upgrade pip --user
RUN pip install -r ./requirements.txt
WORKDIR /usr/local
ENV PYTHONPATH=/usr/local
ENV AIRFLOW_HOME=/usr/local/airflow
# setting fernet key to make sure initdb command will work
# because for password encryption required fernet key
# we have generated fernet key using this python script `from cryptography.fernet import Fernet; FERNET_KEY = Fernet.generate_key().decode(); print(FERNET_KEY)`
# docker does not support dynamic values for environment varibales
# and `RUN export` (i.e export command with RUN) is not perist
ENV FERNET_KEY='xJJkEkL2mX98VebrP-YiNHKDOHkealOTzEdXTVb59hs='
RUN airflow initdb
# uploading varibales from json file
RUN airflow variables -i /usr/local/config/Airflow_variables/variables.json
# adding google colud connection
RUN airflow connections --add --conn_id=my_gcp_conn --conn_type=google_cloud_platform --conn_extra='{ "extra__google_cloud_platform__key_path":"/usr/local/config/BigQueryProject-38532f2e6a07.json", "extra__google_cloud_platform__project": "bigquery-271708", "extra__google_cloud_platform__scope": "https://www.googleapis.com/auth/cloud-platform"}'


# other connections exmaples
#sudo docker-compose exec webserver airflow connections -a --conn_id examplessh --conn_uri ssh://user:pass@serverip --conn_extra '{"key_file":"/usr/local/airflow/id_rsa", "no_host_key_check":true}'
#sudo docker-compose exec webserver airflow connections -a --conn_id examples3 --conn_uri s3://my-test-bucket --conn_extra '{"aws_access_key_id":"AAAAAAA", "aws_secret_access_key":"bbbbbbb", "bucket_name":"mybucket"}'


# to run airflow scheduler
# sudo docker ps |grep airflow (this command will show contianer id of containers whose image name contains airflow.)
# sudo docker exec -it 'conainter-id'  airflow scheduler
