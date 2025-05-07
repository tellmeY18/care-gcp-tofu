Retrieve the Service Account Key from **Google Cloud Platform (GCP)**, store it securely, and set its file path as the value of the `GOOGLE_APPLICATION_CREDENTIALS` environment variable:

```bash
export GOOGLE_APPLICATION_CREDENTIALS="/path/to/your/service-account-key.json"
```

Next, install **OpenTofu**, a tool for managing infrastructure as code. To do this, visit the official OpenTofu installation page and follow the instructions for your operating system: [OpenTofu Installation Guide](https://opentofu.org/docs/intro/install/).

After installing OpenTofu, manually create a **Google Cloud Storage (GCS) bucket**. During the execution of `make init`, provide the name of the bucket when prompted:

```bash
make init
# Enter the GCS bucket name when prompted
```
