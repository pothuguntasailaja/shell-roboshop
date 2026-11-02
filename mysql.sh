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


dnf install mysql-server -y &>>$LOG_FILE
VALIDATE $? "Installing MySQL Server"


systemctl enable mysqld &>>$LOG_FILE
VALIDATE $? "Enable MySQL Service"

systemctl start mysqld  &>>$LOG_FILE
VALIDATE $? "Start MySQL Service"

mysql_secure_installation --set-root-pass RoboShop@1 &>>$LOG_FILE
VALIDATE $? "Setting MySQL Root Password"

END_TIME=$(date +%s)
TOTAL_TIME=$(($END_TIME - $START_TIME))
echo "Total execution time: $TOTAL_TIME seconds" 