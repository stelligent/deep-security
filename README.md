[![Build Status](https://circleci.com/gh/stelligent/deep-security.svg?style=shield)](https://circleci.com/gh/stelligent/deep-security)


# AWS Config Rules for Deep Security

A set of AWS Config Rules to help ensure that your AWS deployments are leveraging the protection of Deep Security. These rules help centralize your compliance information in one place, AWS Config.


## Table of Contents

* [Architecture](#architecture)
* [Setup](#setup)
* [Support](#support)
* [Contribute](#contribute)

## Setup

## Create a User in Deep Security

During execution, the AWS Lambda functions will query the Deep Security API. To do this, they require a Deep Security login with permissions.

You should set up a dedicated use account for API access. To configure the account with the minimum privileges (which reduces the risk if the credentials are exposed) required by this integration, follow the steps below.

1. In Deep Security, go to *Administration* > *User Manager* > *Roles*. 
1. Click **New**. Create a new role with a unique, meaningful name.
1. Under **Access Type**, select **Allow Access to web services API**.
1. Under **Access Type**, deselect **Allow Access to Deep Security Manager User Interface**.
1. On the **Computer Rights** tab, select either **All Computers** or **Selected Computers**, ensuring that only the greyed-out **View** right (under **Allow Users to**) is selected.
1. On the **Policy Rights** tab, select **Selected Policies**. Verify that no policies are selected. (The role does not grant rights for any policies.)
1. On the **User Rights** tab, select **Change own password and contact information only**.
1. On the **Other Rights** tab, verify that the default options remain, with only **View-Only** and **Hide** permissions.
1. Go to **Administration** > **User Manager** > **Users**.
1. Click **New**. Create a new user with a unique, meaningful name.
1. Select the role that you created in the previous section.


### Manage secrets

Deep Security Config rules utilize AWS SSM Parameter Store and KMS to securely manage credentials. Before deploying
Deep Security Lambda functions and Config rules, you need to create entries in Parameter Store for above created
user's username and password. Be sure to select `SecureString` as parameter type and use appropriate KMS 'Customer managed key (CMK)' 
from your account. These 2 Parameter Store keys will be added as environment variables for deployment process
described below.


### Deploy AWS Lambda and Config rules

This project is designed be deployed via several Bash scripts, but certain configuration needs to be in place fist.

Environment variables file - `deploy.config`

> - `STACK_NAME`: CloudFormation stack name for all lambda and Config rule resources
> - `LAMBDA_BUCKET`: S3 bucket name where Lambda source code is uploaded
> - `LAMBDA_PREFIX`: S3 object prefix within `LAMBDA_BUCKET`
> - `CONFIG_BUCKET`: S3 bucket name where AWS Config to store history and files
> - `CONFIG_PREFIX`: S3 object prefix within `CONFIG_BUCKET`
> - `DS_HOSTNAME`: Deep Security Manager host name
> - `DS_PORT`: (optional) Deep Security Manager host port (default: 443)
> - `DS_TENANT`: (optional) Deep Security tenant name (default: '')
> - `DS_IGNORE_SSL_VALIDATION`: (optional) Whether to validate SSL connection to Deep Security Manager (default: false)
> - `DS_USERNAME_PARAM_STORE_KEY`: SSM Parameter Store key to retrieve Deep Security username
> - `DS_PASSWORD_PARAM_STORE_KEY`: SSM Parameter Store key to retrieve Deep Security password
> - `DS_POLICY`: Policy name to check used by `DoesInstanceHavePolicy` Lambda
> - `DS_CONTROL`: Control name to check used by `IsInstanceProtectedBy` Lambda (Allowed values are
> [ anti_malware, web_reputation, firewall, intrusion_prevention, integrity_monitoring, log_inspection ])

Dependencies

- Python 3.7
- AWS SAM CLI command line tools ([instructions](https://docs.aws.amazon.com/serverless-application-model/latest/developerguide/serverless-sam-cli-install.html))
- AWS credentials correctly configured. ([instructions](https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-configure.html))

To deploy

`./deploy.sh`

To run unit tests

`pytest -s -vv`

To publish to AWS Serverless Application Repository

`./publish.sh`


## [circleci](https://circleci.com/) Configuration

This project is managed by a CircleCI CI loop. It does require some configuration be set up to do so, though.

- Create an account with `circleci` if you don't have one.
- In `circleci`, add this project (or your copy).
- In `project settings` of added project, `environment variables` section, add the following variables:
>   - `STACK_NAME`: CloudFormation stack name for all lambda and Config rule resources
>   - `LAMBDA_BUCKET`: S3 bucket name where Lambda source code is uploaded
>   - `LAMBDA_PREFIX`: S3 object prefix within `LAMBDA_BUCKET`
>   - `CONFIG_BUCKET`: S3 bucket name where AWS Config to store history and files
>   - `CONFIG_PREFIX`: S3 object prefix within `CONFIG_BUCKET`
>   - `DS_HOSTNAME`: Deep Security Manager host name
>   - `DS_PORT`: (optional) Deep Security Manager host port (default: 443)
>   - `DS_TENANT`: (optional) Deep Security tenant name (default: '')
>   - `DS_IGNORE_SSL_VALIDATION`: (optional) Whether to validate SSL connection to Deep Security Manager (default: false)
>   - `DS_USERNAME_PARAM_STORE_KEY`: SSM Parameter Store key to retrieve Deep Security username
>   - `DS_PASSWORD_PARAM_STORE_KEY`: SSM Parameter Store key to retrieve Deep Security password
>   - `DS_POLICY`: Policy name to check used by `DoesInstanceHavePolicy` Lambda
>   - `DS_CONTROL`: Control name to check used by `IsInstanceProtectedBy` Lambda (Allowed values are
>   [ anti_malware, web_reputation, firewall, intrusion_prevention, integrity_monitoring, log_inspection ])
>   - `AWS_ACCESS_KEY_ID`: Your AWS access key ID
>   - `AWS_SECRET_ACCESS_KEY`: Your AWS secret access key
>   - `AWS_SESSION_TOKEN`: (optional) Session token if you need one to access AWS
>   - `AWS_DEFAULT_REGION`: AWS region to deploy into
- Done. Now when you push into your GitHub repository, `circleci` deployment will be triggered automatically.
- **Note:** Configuration settings for `circleci` are located at `.circleci/config.yml`.

### Rules

#### IsInstanceProtectedByAntiMalware

Checks to see if the current instance is protected by Deep Security Anti-Malware controls. Anti-malware must be "on" and in "real-time" mode for the rule to be considered compliant.

Lambda handler: **dsIsInstanceProtectedByAntiMalware.aws_config_rule_handler**

##### Rule Parameters:

<table>
<tr>
  <th>Rule Parameter</th>
  <th>Expected Value Type</th>
  <th>Description</th>
</tr>
<tr>
  <td>dsUsernameKey</td>
  <td>string</td>
  <td>SSM Parameter Store key to retrive username of the Deep Security account to use for querying anti-malware status</td>
</tr>
<tr>
  <td>dsPasswordKey</td>
  <td>string</td>
  <td>SSM Parameter Store key to retrive password for the Deep Security account to use for querying anti-malware status. </td>
</tr>
<tr>
  <td>dsPasswordEncryptionContext</td>
  <td>string or URI</td>
  <td>The encryption context used to encrypt the <code>dsPassword</code>. If this parameter is given, the rule will include the encryption context information when decrypting the <code>dsPassword</code> value. Requires <code>dsPasswordKey</code> to be useful. See [Protecting Your Deep Security Manager API Password](#protecting-your-deep-security-manager-api-password) below for more details.
</tr>
<tr>
  <td>dsTenant</td>
  <td>string</td>
  <td><i>Optional as long as dsHostname is specified</i>. Indicates which tenant to sign in to within Deep Security</td>
</tr>
<tr>
  <td>dsHostname</td>
  <td>string</td>
  <td><i>Optional as long as dsTenant is specified</i>. Defaults to Deep Security as a Service. Indicates which Deep Security manager the rule should sign in to</td>
</tr>
<tr>
  <td>dsPort</td>
  <td>int</td>
  <td><i>Optional</i>. Defaults to 443. Indicates the port to connect to the Deep Security manager on</td>
</tr>
<tr>
  <td>dsIgnoreSslValidation</td>
  <td>boolean (true or false)</td>
  <td><i>Optional</i>. Use only when connecting to a Deep Security manager that is using a self-signed SSL certificate</td>
</tr>
</table>

During execution, this rule sign in to the Deep Security API. You should setup a dedicated API access account to do this. Deep Security contains a robust role-based access control (RBAC) framework which you can use to ensure that this set of credentials has the least amount of privileges to success.

This rule requires view access to one or more computers within Deep Security.

#### IsInstanceProtectedBy

Checks to see if the current instance is protected by any of Deep Security's controls. Controls must be "on" and set to their strongest setting (a/k/a "real-time" or "prevention") in order for the rule to be considered compliant.

This is the generic version of *IsInstanceProtectedByAntiMalware*.

Lambda handler: **dsIsInstanceProtectedBy.aws_config_rule_handler**

##### Rule Parameters:

<table>
<tr>
  <th>Rule Parameter</th>
  <th>Expected Value Type</th>
  <th>Description</th>
</tr>
<tr>
  <td>dsUsernameKey</td>
  <td>string</td>
  <td>SSM Parameter Store key to retrive username of the Deep Security account to use for querying anti-malware status</td>
</tr>
<tr>
  <td>dsPasswordKey</td>
  <td>string</td>
  <td>SSM Parameter Store key to retrive password for the Deep Security account to use for querying anti-malware status. </td>
</tr>
<tr>
  <td>dsPasswordEncryptionContext</td>
  <td>string or URI</td>
  <td>The encryption context used to encrypt the <code>dsPassword</code>. If this parameter is given, the rule will include the encryption context information when decrypting the <code>dsPassword</code> value. Requires <code>dsPasswordKey</code> to be useful. See [Protecting Your Deep Security Manager API Password](#protecting-your-deep-security-manager-api-password) below for more details.
</tr>
<tr>
  <td>dsTenant</td>
  <td>string</td>
  <td><i>Optional as long as dsHostname is specified</i>. Indicates which tenant to sign in to within Deep Security</td>
</tr>
<tr>
  <td>dsHostname</td>
  <td>string</td>
  <td><i>Optional as long as dsTenant is specified</i>. Defaults to Deep Security as a Service. Indicates which Deep Security manager the rule should sign in to</td>
</tr>
<tr>
  <td>dsPort</td>
  <td>int</td>
  <td><i>Optional</i>. Defaults to 443. Indicates the port to connect to the Deep Security manager on</td>
</tr>
<tr>
  <td>dsIgnoreSslValidation</td>
  <td>boolean (true or false)</td>
  <td><i>Optional</i>. Use only when connecting to a Deep Security manager that is using a self-signed SSL certificate</td>
</tr>
<tr>
  <td>dsControl</td>
  <td>string</td>
  <td>The name of the control to verify. Must be one of [ anti_malware, web_reputation, firewall, intrusion_prevention, integrity_monitoring, log_inspection ]</td>
</tr>
</table>

During execution, this rule signs in to the Deep Security API. You should setup a dedicated API access account to do this. Deep Security contains a robust role-based access control (RBAC) framework which you can use to ensure that this set of credentials has the least amount of privileges to success.

This rule requires view access to one or more computers within Deep Security.

#### DoesInstanceHavePolicy

Checks to see if the current instance is protected by a specific Deep Security policy.

Lambda handler: **dsDoesInstanceHavePolicy.aws_config_rule_handler**

##### Rule Parameters:

<table>
<tr>
  <th>Rule Parameter</th>
  <th>Expected Value Type</th>
  <th>Description</th>
</tr>
<tr>
  <td>dsUsernameKey</td>
  <td>string</td>
  <td>SSM Parameter Store key to retrive username of the Deep Security account to use for querying anti-malware status</td>
</tr>
<tr>
  <td>dsPasswordKey</td>
  <td>string</td>
  <td>SSM Parameter Store key to retrive password for the Deep Security account to use for querying anti-malware status. </td>
</tr>
<tr>
  <td>dsPasswordEncryptionContext</td>
  <td>string or URI</td>
  <td>The encryption context used to encrypt the <code>dsPassword</code>. If this parameter is given, the rule will include the encryption context information when decrypting the <code>dsPassword</code> value. Requires <code>dsPasswordKey</code> to be useful. See [Protecting Your Deep Security Manager API Password](#protecting-your-deep-security-manager-api-password) below for more details.
</tr>
<tr>
  <td>dsTenant</td>
  <td>string</td>
  <td><i>Optional as long as dsHostname is specified</i>. Indicates which tenant to sign in to within Deep Security</td>
</tr>
<tr>
  <td>dsHostname</td>
  <td>string</td>
  <td><i>Optional as long as dsTenant is specified</i>. Defaults to Deep Security as a Service. Indicates which Deep Security manager the rule should sign in to</td>
</tr>
<tr>
  <td>dsPort</td>
  <td>int</td>
  <td><i>Optional</i>. Defaults to 443. Indicates the port to connect to the Deep Security manager on</td>
</tr>
<tr>
  <td>dsIgnoreSslValidation</td>
  <td>boolean (true or false)</td>
  <td><i>Optional</i>. Use only when connecting to a Deep Security manager that is using a self-signed SSL certificate</td>
</tr>
<tr>
  <td>dsPolicy</td>
  <td>string</td>
  <td>The name of the policy to verify</td>
</tr>
</table>

During execution, this rule signs in to the Deep Security API. You should setup a dedicated API access account to do this. Deep Security contains a robust role-based access control (RBAC) framework which you can use to ensure that this set of credentials has the least amount of privileges to success.

This rule requires view access to one or more computers within Deep Security.

#### IsInstanceClear

Checks to see if the current instance is has any warnings, alerts, or errors in Deep Security. An instance is compliant if it does **not** have any warnings, alerts, or errors (a/k/a compliant, which means everything is working as expected with no active security alerts).

Lambda handler: **dsIsInstanceClear.aws_config_rule_handler**

##### Rule Parameters:

<table>
<tr>
  <th>Rule Parameter</th>
  <th>Expected Value Type</th>
  <th>Description</th>
</tr>
<tr>
  <td>dsUsernameKey</td>
  <td>string</td>
  <td>SSM Parameter Store key to retrive username of the Deep Security account to use for querying anti-malware status</td>
</tr>
<tr>
  <td>dsPasswordKey</td>
  <td>string</td>
  <td>SSM Parameter Store key to retrive password for the Deep Security account to use for querying anti-malware status. </td>
</tr>
<tr>
  <td>dsPasswordEncryptionContext</td>
  <td>string or URI</td>
  <td>The encryption context used to encrypt the <code>dsPassword</code>. If this parameter is given, the rule will include the encryption context information when decrypting the <code>dsPassword</code> value. Requires <code>dsPasswordKey</code> to be useful. See [Protecting Your Deep Security Manager API Password](#protecting-your-deep-security-manager-api-password) below for more details.
</tr>
<tr>
  <td>dsTenant</td>
  <td>string</td>
  <td><i>Optional as long as dsHostname is specified</i>. Indicates which tenant to sign in to within Deep Security</td>
</tr>
<tr>
  <td>dsHostname</td>
  <td>string</td>
  <td><i>Optional as long as dsTenant is specified</i>. Defaults to Deep Security as a Service. Indicates which Deep Security manager the rule should sign in to</td>
</tr>
<tr>
  <td>dsPort</td>
  <td>int</td>
  <td><i>Optional</i>. Defaults to 443. Indicates the port to connect to the Deep Security manager on</td>
</tr>
<tr>
  <td>dsIgnoreSslValidation</td>
  <td>boolean (true or false)</td>
  <td><i>Optional</i>. Use only when connecting to a Deep Security manager that is using a self-signed SSL certificate</td>
</tr>
</table>

During execution, this rule signs in to the Deep Security API. You should setup a dedicated API access account to do this. Deep Security contains a robust role-based access control (RBAC) framework which you can use to ensure that this set of credentials has the least amount of privileges to success.

This rule requires view access to one or more computers within Deep Security.

## Support

This is an Open Source community project. Project contributors may be able to help, 
depending on their time and availability. Please be specific about what you're 
trying to do, your system, and steps to reproduce the problem.

For bug reports or feature requests, please 
[open an issue](../issues). 
You are welcome to [contribute](#contribute).

Official support from Trend Micro is not available. Individual contributors may be 
Trend Micro employees, but are not official support.

## Contribute

We accept contributions from the community. To submit changes:

1. Fork this repository.
1. Create a new feature branch.
1. Make your changes.
1. Submit a pull request with an explanation of your changes or additions.

We will review and work with you to release the code.
