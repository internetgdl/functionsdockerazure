# Azure Functions with Docker support in Linux, using a storage queue as trigger


Azure functions are powerful serverless resources, we can create and debug locally, upload to cloud, monitor usage, exceptions and pay only for usage 

 
 ![](https://github.com/internetgdl/functionsdockerazure/blob/master/images/logo.png?raw=true)


In this example, I will show you how to create Azure Function in Microsoft Azure on a Docker Container in Azure Container Registry. 


For this example, we will need Visual Studio Code, Azure CLI, Azure Functions CLI, our Azure account and Docker installed on our computer and .Net Core 3.1 SDK 


We can download the Azure cli from: https://docs.microsoft.com/en-us/cli/azure/install-azure-cli?view=azure-cli-latest 


I recommend you use brew, if it is the case, use the follow lines to install Azure Tools 

    brew update && brew install azure-cli 

To install The Azure Functions Tools the page is: https://github.com/Azure/azure-functions-core-tools 

Using Brew, the lines to the version 3 of Azure Functions is 

    brew tap azure/functions 
    brew install azure-functions-core-tools@3 



In Windows you can install with npm or choco, in the last page you'll get more information about this. 


For Docker we can download from: https://www.docker.com/get-started 


Once Docker are already installed, we can validate the installation using out terminal and typing  

    docker ---version 


For the .Net Core SDK 3.1 the URL to download it is: 



https://dotnet.microsoft.com/download/dotnet-core/thank-you/sdk-3.1.201-windows-x64-installer 



Ok, I assume that you are ready with the installations. 


We going to create the resources locally. 


1.- Create a folder on your computer in this case with PowerShell 

    mkdir function  
    cd function  

Now let's create the Azure Functions with the Azure Functions Tools 

write: 

    func init LocalFunction --worker-runtime dotnet --docker 

![](https://github.com/internetgdl/functionsdockerazure/blob/master/images/1.png?raw=true)

With the Argument --docker, creates the Dockerfile, that it contains the definition of the resources that we'll need for the imagen that will uploaded to Azure Container Registry 


Now let's create the function using a queue as trigger 


    func new --name QueueFunction --template "Queue trigger" 


the argument template defines the type of trigger in this case "Queue Trigger" 

The function was created.

![](https://github.com/internetgdl/functionsdockerazure/blob/master/images/3.png?raw=true)

To run the function use: 

    func start --build 

![](https://github.com/internetgdl/functionsdockerazure/blob/master/images/4.png?raw=true)

Then in the terminal you 'll see how the function is starting up locally in the localhost under the 7071 port
![](https://github.com/internetgdl/functionsdockerazure/blob/master/images/5.png?raw=true)
To emulate a new queue you can send the params by POST with curl by example: 


    curl --request POST -H "Content-Type:application/json" --data '{"input":"sample queue data"}' http://localhost:7071/admin/functions/QueueTrigger




In the image you can see how send the message as data on the function called QueueFunction with a simple response 
![](https://github.com/internetgdl/functionsdockerazure/blob/master/images/6.png?raw=true)



In the files, the file with the name of the function have the logic of business We'll change the message. 



![](https://github.com/internetgdl/functionsdockerazure/blob/master/images/9.png?raw=true)

Let's create resources in your Azure Account. 

First make login to our Azure Account with: 

    az login 

It will prompt a window in our predetermined browser to make login in out Azure Account 

![](https://github.com/internetgdl/functionsdockerazure/blob/master/images/10.png?raw=true)

![](https://github.com/internetgdl/functionsdockerazure/blob/master/images/11.png?raw=true)


Create the resource Group 

	$nameEnvironment = "examplefunc" 
	$nameGrp = "group" 
	$nameGrp = $nameEnvironment+"-" + $nameGrp 
	$location = "westus" 
	az group create --name $namegrp --location $location 


![](https://github.com/internetgdl/functionsdockerazure/blob/master/images/12.png?raw=true)


Create Storage 


	$storageAccountName = "examplestorage127262" 
	$skuName = "Standard_LRS" 
	az storage account create --name $storageAccountName -g $namegrp --sku $skuName 

![](https://github.com/internetgdl/functionsdockerazure/blob/master/images/13.png?raw=true)


Get keys 

	$key=$(az storage account keys list --account-name $storageAccountName --query [0].value -o tsv) 


Create the Queue 

	$queueName = "examplequeue" 
	az storage queue create --name $queueName --account-key $key --account-name $storageAccountName 
![](https://github.com/internetgdl/functionsdockerazure/blob/master/images/14.png?raw=true)


Create container service for Docker Images 

    $acr = "examplecontainer127262" 
    $acrsku = "Basic" 
    az acr create --name $acr --resource-group $nameGrp --sku $acrsku 
    az acr update --name $acr --admin-enabled true 
    $acrusername = az acr credential show -n $acr --query username 
    $acrpassword = az acr credential show -n $acr --query passwords[0].value 
![](https://github.com/internetgdl/functionsdockerazure/blob/master/images/15.png?raw=true)

The next line 'll do Handshake between your computer and Azure Container Registry ACR to make push of the image  


	az acr login --name $acr --username $acrusername --password $acrpassword 
![](https://github.com/internetgdl/functionsdockerazure/blob/master/images/16.png?raw=true)


We can see all the resources on Azure Portal 

![](https://github.com/internetgdl/functionsdockerazure/blob/master/images/17.png?raw=true)


Now we'll build the Docker Image, let's define the connection string of the storage in that we had create the queue 

in Azure CLI we can access to the connection string and save it to a var with: 


    $connectionstring = az storage account show-connection-string --resource-group $nameGrp --name
	$storageName --query connectionString --output tsv 
    $connectionstring 

![](https://github.com/internetgdl/functionsdockerazure/blob/master/images/30.png?raw=true)

and set the connection string to our localsettings.json file in the project. 

![](https://github.com/internetgdl/functionsdockerazure/blob/master/images/23.png?raw=true)

Set the correct name of your queue and the variable assigned to connection.

![](https://github.com/internetgdl/functionsdockerazure/blob/master/images/22.png?raw=true)

Now we'll create the image with the name and version, in this case, "latest" 



    $dockerimage = "exampleimage" 
    $dockerimageversion = $dockerimage+":v0.0.0" 
    docker build ./ --tag $dockerimageversion 


![](https://github.com/internetgdl/functionsdockerazure/blob/master/images/18.png?raw=true)


The image was created, and we can list with 

    docker images 

![](https://github.com/internetgdl/functionsdockerazure/blob/master/images/20.png?raw=true)

Run with 

	docker run $dockerimage+":latest" 


![](https://github.com/internetgdl/functionsdockerazure/blob/master/images/24.png?raw=true)

Once that we have a Docker Image, we must make push and create a tag with the URL of container, that is the name of the container with azurecr.io 


	$acrlogin = $acr+".azurecr.io" 
	docker tag $dockerimageversion $acrlogin/$dockerimageversion 
	docker push $acrlogin/$dockerimageversion 


![](https://github.com/internetgdl/functionsdockerazure/blob/master/images/25.png?raw=true)

List all repositories 

    az acr repository list --name $acrlogin/$dockerimage 


or we can see through the Azure Portal 


![](https://github.com/internetgdl/functionsdockerazure/blob/master/images/26.png?raw=true)


Create Function Plan in Azure Account, it must be on demand  


    $appplansku = "B1" 
    $linux = "--is-linux" 
    $functionplanname = "examplefunctionplan" 
    $numworkers = 1 
    $appfunction = "examplefunction127262" 
	$webhookname = "examplewebhook" 
	az functionapp plan create --resource-group $nameGrp --name $functionplanname --location $location --number-of-workers $numworkers --sku $appplansku $linux 

![](https://github.com/internetgdl/functionsdockerazure/blob/master/images/28.png?raw=true)


Create Linux Function 

	az functionapp create --name $appfunction --storage-account $storageAccountName --resource-group $nameGrp --plan $functionplanname --deployment-container-image-name $acrlogin/$dockerimagename # --app-insights $appinsightskey 


![](https://github.com/internetgdl/functionsdockerazure/blob/master/images/29.png?raw=true)


Attach the connection string to the configuration of function. 

	az functionapp config appsettings set --name $appfunction --resource-group $nameGrp --settings AzureWebJobsStorage=$connectionstring 


![](https://github.com/internetgdl/functionsdockerazure/blob/master/images/31.png?raw=true)


Enable continuous integration and get the Hook URL 


	$hookurl = az functionapp deployment container config --enable-cd --query CI_CD_URL --output tsv --name $appfunction --resource-group $nameGrp 

Create webhook to the container registry making push for all versions 

	$dockerimageallversion = $dockerimage+":*" 
	az acr webhook create -n $webhookname -r $acr --uri $hookurl --scope $dockerimageallversion --actions push delete 



The image was created we can validate over the Azure Portal 

![](https://github.com/internetgdl/functionsdockerazure/blob/master/images/32.png?raw=true)

And the Continuous Integration was created with the webhook 

We can see the publish of this in the function in portal 

![](https://github.com/internetgdl/functionsdockerazure/blob/master/images/34.png?raw=true)

The function in Azure Portal

![](https://github.com/internetgdl/functionsdockerazure/blob/master/images/36.png?raw=true)

To view the function working we can open the Queue and send a message to the message's queues. 

![](https://github.com/internetgdl/functionsdockerazure/blob/master/images/38.png?raw=true)

In other windows we can see the function monitor.

![](https://github.com/internetgdl/functionsdockerazure/blob/master/images/42.png?raw=true)

In this example, we saw how to create an Azure function using the Azure function tools in the terminal of our computer with Docker support, modifying the project with Visual Studio Code to connect the function with our queue and create all the resources in our Azure account. 

We create the Docker image on our computer, perform a test emulating a queue, and then push to the Azure Container Registry. 


After creating a Linux Azure function, we create a Webhook to pull the image from the container and send a sample message. 


So if you have any questions please feel free to contact me. 


Email: eduardo@eduardo.mx 

Web: [eduardo.mx](http://eduardo.mx "eduardo.mx")

Twitter: [internetgdl](https://twitter.com/internetgdl "internetgdl")

LinkedIn:  [https://www.linkedin.com/in/luis-eduardo-estrada/ ](https://www.linkedin.com/in/luis-eduardo-estrada/  "https://www.linkedin.com/in/luis-eduardo-estrada/ ")

GitHub: [internetgdl](https://github.com/internetgdl "internetgdl")
 

Notes: for reference the complete script is in this project under the file: [initProject.ps1](https://github.com/internetgdl/functionsdockerazure/blob/master/initProject.ps1 "initProject.ps1")

 
