#!/bin/bash

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

dnf module disable nginx -y &>>$LOG_FILE
VALIDATE $? "Disable nginx"

dnf module enable nginx:1.24 -y &>>$LOG_FILE
VALIDATE $? "Enable nginx"

dnf install nginx -y &>>$LOG_FILE
VALIDATE $? "Install nginx"

dnf module enable nginx:1.24 -y &>>$LOG_FILE
VALIDATE $? "Enable nginx"

dnf install nginx -y &>>$LOG_FILE
VALIDATE $? "Install nginx"

systemctl enable nginx
VALIDATE $? "Enable nginx Service"

systemctl start nginx 
VALIDATE $? "Start nginx Service"

rm -rf /usr/share/nginx/html/* &>>$LOG_FILE
VALIDATE $? "Removing Default Nginx Content"

curl -o /tmp/frontend.zip https://roboshop-artifacts.s3.amazonaws.com/frontend-v3.zip  &>>$LOG_FILE
VALIDATE $? "Downloading Frontend Artifact"

cd /usr/share/nginx/html &>>$LOG_FILE
VALIDATE $? "Changing Directory to /usr/share/nginx/html"

unzip /tmp/frontend.zip &>>$LOG_FILE
VALIDATE $? "Extracting Frontend Artifact"

cp $SCRIPT_DIR/localhost.conf /etc/nginx/nginx.conf &>>$LOG_FILE
VALIDATE $? "Copying Nginx Configuration File"

systemctl restart nginx
VALIDATE $? "Restarting Nginx Service"