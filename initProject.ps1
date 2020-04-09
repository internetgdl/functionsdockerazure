#Create resources locally
mkdir function 
cd function 

func init LocalFunction --worker-runtime dotnet --docker

func new --name QueueFunction --template "Queue trigger"



#Create Resources on Azure

$nameEnvironment = "gral"
$nameGrp = "group"

# Ubicación de los recursos
$location = "westus"
#All vars
$namegrp = $nameEnvironment+"-" + $nameGrp
$storageAccountName = "examplestorage127262"
$skuName = "Standard_LRS"
$queueName = "examplequeue"

$appplansku = "B1"


$acr = "examplecontainer127262"
$acrlogin = $acr+".azurecr.io"
$acrsku = "Basic"
$linux = "--is-linux"
$functionplanname = "examplefunctionplan"
$numworkers = 1
$appfunction = "examplefunction"
$dockerimage = "exampleimage"
$dockerimageversion = $dockerimage+":v0.0.0"
$webhookname = "examplewebhook"


#Create all resources

# Grupo de Recursos
az group create --name $namegrp --location $location
##CREATE STORAGES

# Storage
az storage account  create --name $storageAccountName -g $namegrp --sku $skuName

#GetKeys
$key=$(az storage account keys list --account-name $storageAccountName --query [0].value -o tsv)

#Create Queue
az storage queue create --name $queueName --account-key $key --account-name $storageAccountName


# create container service for docker images
az acr create --name $acr --resource-group $nameGrp --sku $acrsku
az acr update --name $acr --admin-enabled true
$acrusername = az acr credential show -n $acr --query username
$acrpassword = az acr credential show -n $acr --query passwords[0].value

#handshake between our computer and azure container registry
az acr login --name $acr --username $acrusername  --password $acrpassword

# Now we'll create the image 
 
docker build ./ --tag $dockerimageversion
docker tag $dockerimageversion $acrlogin/$dockerimageversion


# once that we have a docker image we have to make push 



docker push $acrlogin/$dockerimageversion
docker rmi $acrlogin/$dockerimageversion

#list all repositories
az acr repository list --name $acrlogin/$dockerimagename


## CREATE FUNCTION
# create function plan because it must to be on demand 
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

