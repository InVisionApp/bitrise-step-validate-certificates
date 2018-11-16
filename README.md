# Validate Certificates

This step will validate that installed certificates are not going to expire any time soon. By default this step will fail if any certificates will expire in the next 182 days.

## How to use this Step

Can be run directly with the [bitrise CLI](https://github.com/bitrise-io/bitrise),
just `git clone` this repository, `cd` into it's folder in your Terminal/Command Line
and call `bitrise run test`.

When used in a workflow this step must come after the Bitrise step [steps-certificate-and-profile-installer](https://github.com/bitrise-io/steps-certificate-and-profile-installer).

* Input `validate_certificate_error_days`: This step will fail if a certificate has less days remaining then this value (default 182) 
* Output `VALIDATE_CERTIFICATES_ERRORS`: This step sets this value to the number of certificates that will expire before `validate_certificate_error_days`

*More inputs and outputs can be found in [step.yml](step.yml)*
