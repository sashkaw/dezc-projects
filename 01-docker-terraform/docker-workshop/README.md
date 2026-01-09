## TROUBLESHOOTING

### Service account key generation
- To remove constraint blocking service account key creation, first make sure you can edit the policy:
```
gcloud organizations add-iam-policy-binding YOUR_ORG_ID --member='user:YOUR_EMAIL' --role='roles/orgpolicy.policyAdmin'
```
- Then navigate to GCP console, set policy to `Override parent's policy`, and change setting to `Not Enforced`
- NOTE: Make sure to remove both:
    - `iam.managed.disableServiceAccountKeyCreation`
    - `iam.disableServiceAccountKeyCreation`
