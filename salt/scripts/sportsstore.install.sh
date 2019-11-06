#!/bin/sh

# Setting up variables
red='\e[31m'
green='\e[32m'
orange='\e[33m'
yellow='\e[93m'
blue='\e[34m'
magenta='\e[35m'
nc='\e[39m'

appName=SportsStore

instDir="/var/${appName}"
srcDir="/src"
srcAppDir="${srcDir}/${appName}"
liveDir="${srcAppDir}/dist"
serviceFile="/etc/systemd/system/${appName}.service"

useColor="true"

overrideDatabase=0
rebuildApp=0
installApp=0
uninstallApp=0
checkForUpdates=1
help=0
unknown=0

#creating functions
output() {
    if [ "$useColor" = "true" ];
    then
        echo "$2$1${nc}"
    else
        echo "$1"
    fi
}

# Checking if the sportsstore is present
installApp() {
    getApp
    output "Installing ${appName} on ${instDir}" $blue
    if [ ! -d "$instDir" ];
    then
        mkdir $instDir;
        mkdir $instDir/dist
    fi
    if [ $rebuildApp -eq 1 ];
    then
        output "Building ${appName}" $magenta
        cd $srcAppDir
        export NG_CLI_ANALYTICS=ci
        npm install -g @angular/cli -s -f -y
        npm install -s -f -y
        ng build
    fi
    cp -Rf $liveDir/$appName $instDir/dist/
    cp -f $srcAppDir/authMiddleware.js $instDir
    cp -Rf $srcAppDir/ssl $instDir
    if [ $overrideDatabase -eq 1 ]; 
    then 
        installDatabase
    fi
    cp -f $srcAppDir/server.js $instDir
    cp -f $srcAppDir/deploy-package.json $instDir/package.json

    cd $instDir
    output "Restoring ${appName} npm packages" $magenta
    npm install -s -f -y 
    generateAppService
}

installDatabase() {
    if [ $overrideDatabase -eq 1 ]; 
    then 
        if [ -f $srcAppDir/serverData.json ];
        then
            output "Starting to copy the application database" $blue
            cp -f $srcAppDir/serverData.json $instDir
            output "Finished copying the application database" $green
        fi
    fi
}

checkForApp() {
    if [ ! -d "$liveDir" ];
    then
        output "${appName} live folder was not found, trying to reinstall" $yellow
        installApp
    fi
    if [ ! -f "${serviceFile}" ];
    then
        generateAppService
    fi
}

checkForAppUpdate() {
    if [ ! -d $srcAppDir ];
    then
        getApp
    fi

    cd $srcAppDir
    pullOutput=$(git pull)
    pullResult=$(echo ${pullOutput} | grep "Already up to date.")
    if [ -z "$pullResult" ]; 
    then 
        output "There is an update for ${appName}, running the instalation without replacing the data" $blue
        installApp
        output "Sports Store has been updated" $green
    else
        output "Started checking healt of ${appName}" $blue
        checkForApp
        output "Finished checking healt of ${appName}" $green
    fi

    if [ $overrideDatabase -eq 1 ];
    then
        installDatabase
    fi
}

generateAppService() {
    if [ -f "${serviceFile}" ];
    then
        if [ "$1" = "true" ];
        then
            sudo rm -f $serviceFile
        fi
    fi

    if [ ! -f "${serviceFile}" ];
    then
        sudo echo "[Unit]" > $serviceFile
        sudo echo "Description=Sports Store Service" >> $serviceFile
        sudo echo "[Service]" >> $serviceFile
        sudo echo "" >> $serviceFile
        sudo echo "WorkingDirectory=${instDir}" >> $serviceFile
        sudo echo "ExecStart=node server.js" >> $serviceFile
        sudo echo "ExecStop=pkill -f nodejs" >> $serviceFile
        sudo echo "Restart=always" >> $serviceFile
        sudo echo "RestartSec=10" >> $serviceFile
        sudo echo "SyslogIdentifier=sysadmin" >> $serviceFile
        sudo echo "User=root" >> $serviceFile
        sudo echo "Environment=ASPNETCORE_ENVIRONMENT=Development" >> $serviceFile
        sudo echo "" >> $serviceFile
        sudo echo "[Install]" >> $serviceFile
        sudo echo "WantedBy=multi-user.target" >> $serviceFile
        sudo systemctl enable $appName
        sudo systemctl daemon-reload
        sudo systemctl restart $appName       
    fi
}

removeApp() {
    if [ -f "${serviceFile}" ];
    then
        output "Removing ${appName} service..." $blue
        sudo systemctl stop $appName 
        sudo systemctl disable $appName
        sudo rm -f $serviceFile
        sudo systemctl daemon-reload
        output "Service removed..." $blue
    fi

    if [ -d "${instDir}" ];
    then
        output "Removing ${appName} install folder..." $blue
        sudo rm -Rf $instDir
        output "Install folder removed..." $blue
    fi

    if [ -d "${srcAppDir}" ];
    then
        output "Removing ${appName} source folder..." $blue
        sudo rm -Rf $srcAppDir
        output "Source folder removed..." $blue
    fi
    output "${appName} removed..." $green
}

getApp() {
    if [ ! -d "$srcAppDir" ];
    then
        output "${appName} source is not present, cloning it from github.." $yellow
        if [ ! -d "${srcDir}" ];
        then 
            sudo mkdir $srcDir 
        fi
        sudo mkdir $srcAppDir
        cd $srcAppDir
        git clone https://github.com/cjlapao/angular-SportsStore.git $srcAppDir
        output "Cloning is complete"
    fi
}

showHelp() {
    echo "Help for Salt Install App Script"
}

# Getting the options from the command line
while [ $# -gt 0 ]
do
    case "$1" in
        -o) overrideDatabase=1 shift ;;
        --override) overrideDatabase=1 shift ;;
        -u) uninstallApp=1 shift ;;
        --unistall) uninstallApp=1 shift ;;
        -r) rebuildApp=1 shift ;;
        --rebuild) rebuildApp=1 shift ;;
        -i) installApp=1 shift ;;
        --install) installApp=1 shift ;;
        -c) checkForUpdates=1  shift ;;
        --update) checkForUpdates=1 shift ;;
        -h) help=1 shift ;;
        --help) help=1 shift ;;
        *) unknown=1 shift ;;
    esac
done

if [ $unknown -eq 1 ]
then
    echo "Invalid option, please use -h to see available options"
    exit 0
fi

if [ $uninstallApp -eq 1 ];
then
    removeApp
elif [ $installApp -eq 1 ];
then
    rebuildApp=1
    overrideDatabase=1
    installApp
elif [ $rebuildApp -eq 1 ];
then
    installApp
elif [ $checkForUpdates -eq 1 ];
then
    checkForAppUpdate
elif [ $overrideDatabase -eq 1 ];
then
    installDatabase
elif [ $help -eq 1 ];
then
    showHelp
else
    output "Checking if ${appName} is present" $blue
    if [ ! -d "$srcAppDir" ];
    then
        installApp
    else
        checkForAppUpdate
    fi
fi
