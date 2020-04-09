using System;
using Microsoft.Azure.WebJobs;
using Microsoft.Azure.WebJobs.Host;
using Microsoft.Extensions.Logging;

namespace LocalFunction
{
    public static class QueueFunction
    {
        [FunctionName("QueueFunction")]
        public static void Run([QueueTrigger("myqueue-items", Connection = "AzureWebJobsStorage")]string myQueueItem, ILogger log)
        {
            log.LogInformation($"Thank you for your request: {myQueueItem}");
        }
    }
}
