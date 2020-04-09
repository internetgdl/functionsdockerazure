Azure Functions with Docker using a Storage Queue

The Azure functions are really powerfull serverless resources, we can create and debug locally, upload yo cloud, monitor the use, the excepcions and pay only for the use

In this example I going to show you how to create an Azure Function on Microsoft Azure Cloud but, in a Docker Container on Azure Container Registry.

To this example we'll need Azure Cli, Azure Functions Cli, our Azure Account and Docker installed in our computer and .Net Core 3.1 SDK


We can donwload the Azure cli from: https://docs.microsoft.com/en-us/cli/azure/install-azure-cli?view=azure-cli-latest

I recomend you using brew, if it is the case the follow lines intall azure tools

brew update && brew install azure-cli

To install The Azure Functions Tools the page is: https://github.com/Azure/azure-functions-core-tools

Using brew the lines to the version 3 of azure functions is

brew tap azure/functions
brew install azure-functions-core-tools@3

in windows you can install with npm or choco, in the last page you'll get more informacion abut this.

For Docker we can download from: https://www.docker.com/get-started

Once Docker are already installed we can validate the instalation using out terminal and typing 

docker ---version

For the .Net Core SDK 3.1 the url to download it is:

https://dotnet.microsoft.com/download/dotnet-core/thank-you/sdk-3.1.201-windows-x64-installer

Ok, I assume that you are ready with the installations.

Firts one.

We goint to create the resurces locally.

1.- create a folder on your computer when you'll place the function

mkdir function 
cd function 

Now with the terminal using the azure functions tools

write:

func init LocalFunction --worker-runtime dotnet --docker

With the Argument --docker it creates the Dockerfile, that it contains the definition of the resources that we'll need for the imagen that be'll uploaded to Azure Container Registry

Now lets create the function using a queue as trigger

func new --name QueueFunction --template "Queue trigger"

the argument template defines the type of trigger

The function was created.

To run the function use:

func start --build

Then in the terminal you 'll see how h function is starting up locally in the locslhost under the 7071 port

To emulate a new queue yo can send the params by POST with curl by example:

curl --request POST -H "Content-Type:application/json" --data '{"input":"sample queue data"}' http://localhost:7071/admin/functions/QueueTrigger

in the image you can see how send the message as data on the function called QueueFunction with a simple response

In the files, the file with the name of the fuction have the logic of the data,  ll change the message

<image>

Lets create resources in our Azure Account

Login to out Azure Account
az login

It will prompt a windows of out predeterminated browser to make login in out azure account

<image>

<image>



Create the resource Group
$nameEnvironment = "examplefunc"
$nameGrp = "group"
$nameGrp = $nameEnvironment+"-" + $nameGrp
$location = "westus"
az group create --name $namegrp --location $location

<image>
##CREATE STORAGES

Create the storage

$storageAccountName = "examplestorage127262"
$skuName = "Standard_LRS"
az storage account  create --name $storageAccountName -g $namegrp --sku $skuName
<image>
Get keys
$key=$(az storage account keys list --account-name $storageAccountName --query [0].value -o tsv)

Create the Queue
$queueName = "examplequeue"
az storage queue create --name $queueName --account-key $key --account-name $storageAccountName


Create container service for docker images
$acr = "examplecontainer127262"
$acrsku = "Basic"
az acr create --name $acr --resource-group $nameGrp --sku $acrsku
az acr update --name $acr --admin-enabled true
$acrusername = az acr credential show -n $acr --query username
$acrpassword = az acr credential show -n $acr --query passwords[0].value

#handshake between our computer and azure container registry
az acr login --name $acr --username $acrusername  --password $acrpassword

We can see all the resources on azure portal
<image>

Before that we'll build the Docker , lets define the connection string of the storage in that we had create the queue
in azure cli we can acces to the connection string with az storage account keys list

az storage account keys list -g $namegrp -n $storageAccountName
<image>

and set the connectionstring to the key of our Function in the project in conectionstring format

DefaultEndpointsProtocol=https;AccountName=<FunctionName>;AccountKey=<keyString>;EndpointSuffix=core.windows.net

<image>

And set the correct name of your queue

<image>

Now we'll create the image with the name and version in this case, latest
$dockerimage = "exampleimage"
$dockerimageversion = $dockerimage+":v0.0.0"
docker build ./ --tag $dockerimageversion

<image>

The image was created and we can list with

docker images
<image>

And run with

docker run $dockerimage+":latest"

once that we have a docker image we have to make push 

We have to tag the image with the url container, that is the name of the container with azurecr.io

$acrlogin = $acr+".azurecr.io"
docker tag $dockerimageversion $acrlogin/$dockerimageversion


docker push $acrlogin/$dockerimageversion


List all repositories
az acr repository list --name $acrlogin/$dockerimage



CREATE FUNCTION
create function plan because it must to be on demand 

$appplansku = "B1"

$linux = "--is-linux"
$functionplanname = "examplefunctionplan"
$numworkers = 1
$appfunction = "examplefunction"

$webhookname = "examplewebhook"

az functionapp plan create --resource-group $nameGrp --name $functionplanname --location $location --number-of-workers $numworkers --sku $appplansku $linux
#create function and attach to docker
az functionapp create --name $appfunction --storage-account $storageAccountName --resource-group $nameGrp --plan $functionplanname --deployment-container-image-name $acrlogin/$dockerimagename # --app-insights $appinsightskey
#Get connection string of the storage
$connectionstring = az storage account show-connection-string --resource-group $nameGrp --name $storageName --query connectionString --output tsv
#attach the connection string to the configuration of function
az functionapp config appsettings set --name $appfunction --resource-group $nameGrp --settings AzureWebJobsStorage=$connectionstring
#enable continous integration and get the hook url
$hookurl = az functionapp deployment container config --enable-cd --query CI_CD_URL --output tsv --name $appfunction --resource-group $nameGrp
#create webhook to the container  registry making push for all versions
$dockerimageallversion = $dockerimage+":*"
az acr webhook create -n $webhookname -r $acr --uri $hookurl --scope $dockerimageallversion --actions push delete




Notes: for reference the complete script is in this project initProject.ps1