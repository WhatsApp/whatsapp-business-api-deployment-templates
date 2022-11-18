# WhatsApp Business API (On-Premises) Deployment Templates

This repository contains Infra-as-Code templates that create cloud services hosting WhatsApp Business API (On-Premises) with desired throughput on various public cloud platforms, including AWS, Azure & GCP.

For more details related to WhatsApp Business API (On-Premises), please visit the documentation at: https://developers.facebook.com/docs/whatsapp/on-premises.

## Features
* **Tailored to different messaging needs**: The templates support selections of different message throughputs and message types.
* **Easy to get started**: The templates automatically provision resources based on the combination of message throughput and message type, so that users don’t need to worry about the setup and configuration details.
* **Highly configurable**: The templates offer configuration parameters that can be adjusted to fit your environment.

## Benchmark Results
We have used the [Outbound Load Testing](https://developers.facebook.com/docs/whatsapp/guides/high-throughput#evaluating-performance) method to measure the maximum throughput of each template under different message type options in different cloud environments.

| Platform | API Version | Max Throughput |
|----------|-------------|----------------|
| AWS      | v2.41.3     | 350            |
| Azure    | v2.41.3     | 200            |

*Disclaimer: Although higher throughput has been achieved with certain templates under the specific conditions, Meta does not commit to technical support for throughput that is > 250 MPS. Please use at your own discretion.*

## Technologies
### AWS:
* Infra definition: [CloudFormation](https://docs.aws.amazon.com/cloudformation/index.html)
* Database: [Amazon Aurora](https://aws.amazon.com/rds/aurora/)
* Container management: [Amazon Elastic Container Service (Amazon ECS)](https://aws.amazon.com/ecs/)
### Azure:
* Infra definition: [Terraform](https://www.terraform.io/)
* Database: MySQL in VM
* Container management: [Kubernetes](https://kubernetes.io/)

## Get Started
1. Clone or download files based on your cloud platform from the `src` directory.
2. Follow the step-by-step guide below to deploy the templates based on your desired throughput and message type:
  * AWS: https://developers.facebook.com/docs/whatsapp/on-premises/get-started/installation/aws
  * Azure: https://developers.facebook.com/docs/whatsapp/on-premises/get-started/installation/azure
  * GCP (coming soon H2 2022)

## Support
We highly recommend you to deploy the templates in a testing environment first before deploying in production. We have verified the templates under the conditions documented in the [Benchmark Results](#benchmark-results) section, however, we are unable to guarantee the maximum throughput if alterations are made to the templates.

If you have any feedback on how to improve the templates, please kindly file an issue or a pull request in this repository. We will follow up on them in our best efforts.

For any other types of issues, please contact Direct Support.

## License
WhatsApp Business API (On-Premises) Deployment Templates is [MIT licensed](./LICENSE).
