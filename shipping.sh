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


dnf module disable nodejs -y &>>$LOG_FILE
VALIDATE $? "Disable nodejs"

dnf module enable nodejs:20 -y &>>$LOG_FILE
VALIDATE $? "Enable nodejs"

dnf install nodejs -y &>>$LOG_FILE
VALIDATE $? "Installing Nodejs"

dnf install maven -y &>>$LOG_FILE
VALIDATE $? "Installing Maven"

id roboshop
if [ $? -ne 0 ]; then
useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop
VALIDATE $? "Creating System User"
else
    echo -e "roboshop user already exists.... $Y SKIPPING $N"
fi


mkdir -p /app 
VALIDATE $? "Creating Application Directory"

curl -L -o /tmp/shipping.zip https://roboshop-artifacts.s3.amazonaws.com/shipping-v3.zip  &>>$LOG_FILE
VALIDATE $? "Downloading Shipping Artifact"

cd /app 
VALIDATE $? "Changing Directory to /app"

rm -rf /app/* &>>$LOG_FILE
VALIDATE $? "Removing Old Application Content"

unzip /tmp/shipping.zip &>>$LOG_FILE
VALIDATE $? "Extracting Shipping Artifact"

cd /app 
VALIDATE $? "Changing Directory to /app"

mvn clean package  &>>$LOG_FILE
VALIDATE $? "Building Shipping Application"

mv target/shipping-1.0.jar shipping.jar  &>>$LOG_FILE
VALIDATE $? "Renaming Shipping Jar File"

cp $SCRIPT_DIR/shipping.service /etc/systemd/system/shipping.service &>>$LOG_FILE
VALIDATE $? "Copying Shipping Service File"

systemctl daemon-reload
VALIDATE $? "Reloading Systemd Daemon"

systemctl enable shipping 
VALIDATE $? "Enabling Shipping Service"

systemctl start shipping
VALIDATE $? "Starting Shipping Service"

dnf install mysql -y  &>>$LOG_FILE
VALIDATE $? "Installing Mysql Client"

# This command connects to the MySQL server and executes a SQL command.
mysql -h mysql.daws86s.de -uroot -pRoboshop@! -e  'use mysql' &>>$LOG_FILE
if [ $? -ne 0 ]; then
    mysql -h mysql.daws86s.de -uroot -pRoboshop@! < /app/db/schema.sql &>>$LOG_FILE
    mysql -h mysql.daws86s.de -uroot -pRoboshop@! < /app/db/app-user.sql  &>>$LOG_FILE
    mysql -h mysql.daws86s.de -uroot -pRoboshop@! < /app/db/master-data.sql &>>$LOG_FILE
else
    echo -e "Shipping DB already exists.... $Y SKIPPING $N"
fi

systemctl restart shipping  &>>$LOG_FILE
VALIDATE $? "Restarting Shipping Service"