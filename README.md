# Validate Certificates

This step will validate that installed certificates are not going to expire any time soon. By default this step will fail if any certificates will expire in the next 182 days.

## How to use this Step

Can be run directly with the [bitrise CLI](https://github.com/bitrise-io/bitrise),
just `git clone` this repository, `cd` into it's folder in your Terminal/Command Line
and call `bitrise run test`.

* **Important:** When used in a workflow this step must come after the Bitrise step [steps-certificate-and-profile-installer](https://github.com/bitrise-io/steps-certificate-and-profile-installer).
* Input `validate_certificate_error_days`: This step will fail if a certificate has less days remaining then this value (default 182) 
* Output `VALIDATE_CERTIFICATES_ERRORS`: This step sets this value to the number of certificates that will expire before `validate_certificate_error_days`
* *More inputs and outputs can be found when this step is viewed in Bitrises step editor, or in [step.yml](step.yml)*

## Example Workflow
The following can be added to your bitrise.yml to create a workflow that can be scheduled to alert a slack channel about the state of the certificates.

*Remember to set `slack_webhook_url` and `slack_channel` in your secret/env vars.*

```
  check-certs:
    steps:
    - certificate-and-profile-installer@1.10.1: {}
    - git::https://github.com/InVisionApp/bitrise-step-validate-certificates.git: {}
    - slack@3.1.0:
        inputs:
        - channel: "$slack_channel"
        - text: ''
        - pretext: "*Certificates are up to date!*"
        - fields: |-
            App|${BITRISE_APP_TITLE}
            Workflow|${BITRISE_TRIGGERED_WORKFLOW_ID}
            Success|${VALIDATE_CERTIFICATES_SUCCESS}
            Ignored|${VALIDATE_CERTIFICATES_IGNORED}
            Errors|${VALIDATE_CERTIFICATES_ERRORS}
            Warnings|${VALIDATE_CERTIFICATES_WARNINGS}
        - buttons: |-
            View App|${BITRISE_APP_URL}
            View Build|${BITRISE_BUILD_URL}
        - channel_on_error: "$slack_channel"
        - text_on_error: ''
        - pretext_on_error: "*@here $VALIDATE_CERTIFICATES_ERRORS certificates
            are not up to date.*"
        - webhook_url: "$slack_webhook_url"
```
