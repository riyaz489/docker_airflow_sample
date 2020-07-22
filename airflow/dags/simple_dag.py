import datetime as dt
from datetime import timedelta
from airflow import DAG
from airflow.operators.bash_operator import BashOperator
from airflow.operators.python_operator import PythonOperator
import os
PATH = '/'


def greet(r_date):
    print('Writing in file')
    dirpath = os.getcwd()
    print(dirpath)
    output_path = os.path.join(dirpath, 'output', 'greet.txt')
    print(output_path)
    with open(output_path, 'a+', encoding='utf8') as f:
        f.write(str(r_date) + '\n')
    return 'Greeted'


def respond():
    return 'Greet Responded Again'

default_args = {
    'owner': 'airflow',
    'start_date': dt.datetime(2020, 6, 1, 10, 00, 00),
    'concurrency': 1,
    'depends_on_past': True,
    'email_on_failure': False,
    'email_on_retry': False,
    #'schedule_interval': '@daily',
    'retries': 1,
    'retry_delay': timedelta(seconds=5),

}

with DAG('simple_dag', default_args=default_args, schedule_interval='* * * * *')as dag:
    opr_hello = BashOperator(task_id='say_hi',
                             bash_command='echo Hi !!')
    opr_greet = PythonOperator(task_id='greet',
                               python_callable=greet,
                               # execution_date is airflow variable which returns current execution date in python format
                               op_kwargs={'r_date':'{{ (execution_date - macros.timedelta(days=5)).strftime("%Y-%m-%d") }} '})
    opr_sleep = BashOperator(task_id='sleep_me',
                             bash_command='sleep 2')
    opr_respond = PythonOperator(task_id='respond',
                                 python_callable=respond)

    opr_hello.set_downstream(opr_greet)
    opr_greet.set_downstream(opr_sleep)
    opr_sleep.set_downstream(opr_respond)
    # or we can specify flow like this
    # opr_hello >> opr_greet >> opr_sleep >> opr_respond