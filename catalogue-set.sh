#!/bin/bash

set -euo pipefail

trap 'echo "There is an error in $LINENO, Command is: $BASH_COMMAND"' ERR

USER_ID=$(id -u) # get the user id of the current user
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

LOGS_FOLDER="/var/log/shell-roboshop"
SCRIPT_NAME=$(echo $0 | cut -d "." -f1)
LOG_FILE="$LOGS_FOLDER/$SCRIPT_NAME.log"
MONGODB_HOST=mongodb.daws86s.de
SCRIPT_DIR=$PWD


mkdir -p $LOGS_FOLDER
echo "Logs will be stored in $LOG_FILE" | tee -a $LOG_FILE
echo "Script started execution at $(date)" | tee -a $LOG_FILE

if [ $USER_ID -ne 0 ]; then 
    echo "please run this script as root privilege"
    exit 1 # failure exit status
fi


VALIDATE(){
    if [ $1 -ne 0 ]; then  # check the exit status of the last command
        echo -e "$2 installation is $R FAILURE.... $N" | tee -a $LOG_FILE
        exit 1
    else
        echo -e "$2 installation is $G SUCCESS.... $N" | tee -a $LOG_FILE
    fi
}


dnf module disable nodejs -y &>>$LOG_FILE
VALIDATE $? "Disable nodejs"

dnf module enable nodejs:20 -y &>>$LOG_FILE
VALIDATE $? "Enable nodejs"

dnf install nodejs -y &>>$LOG_FILE
VALIDATE $? "Installing Nodejs"


id roboshop
if [ $? -ne 0 ]; then
useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop

else
    echo -e "roboshop user already exists.... $Y SKIPPING $N"
fi


mkdir -p /app &>>$LOG_FILE



curl -o /tmp/catalogue.zip https://roboshop-artifacts.s3.amazonaws.com/catalogue-v3.zip  &>$LOG_FILE


cd /app  &>>$LOG_FILE


rm -rf /app/* &>>$LOG_FILE


unzip /tmp/catalogue.zip &>>$LOG_FILE 



cd /app  &>>$LOG_FILE


npm install &>>$LOG_FILE



cp $SCRIPT_DIR/catalogue.service /etc/systemd/system/catalogue.service &>>$LOG_FILE



systemctl daemon-reload &>>$LOG_FILE



systemctl enable catalogue &>>$LOG_FILE


systemctl start catalogue &>>$LOG_FILE


cp $SCRIPT_DIR/mongo.repo  /etc/yum.repos.d/mongo.repo &>>$LOG_FILE



dnf install mongodb-mongosh -y &>>$LOG_FILE



# "MongoDB Server and MongoDB Shell are different. MongoDB Server stores all the catalogue product information.
# MongoDB Shell is a command-line tool used to connect to the MongoDB Server and execute commands.
# We use mongosh to execute the master-data.js file and load product data into MongoDB."

INDEX=$(mongosh mongodb.daws86s.de --quiet --eval "db.getMongo().getDBNames().indexOf('catalogue')")
if [ $INDEX -le 0 ]; then
     mongosh --host $MONGODB_HOST </app/db/master-data.js &>>$LOG_FILE
  
else
    echo -e "Catalogue Products already Loaded.... $Y SKIPPING $N"
fi

systemctl restart catalogue &>>$LOG_FILE
