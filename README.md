GitHub Enterprise Management Tools
==================================

ghe-tools for GitHub Enterprise Admins.

## QuickStart

* Clone the repo: `git@github.com:uzyexe/ghe-tools.git`
* Install with gem and cookbook: `rake init`

## Environment variable

You can overload and customize specific variables when running scripts.
Simply create .env with the environment variables you need, for example, OCTOKIT_API_ENDPOINT

```
# .env
OCTOKIT_API_ENDPOINT="https://<YOUR_GHE_HOSTNAME>/api/v3/"
```

This will use a OCTOKIT_API_ENDPOINT when API Request.

You can look at env.sample for other variables used by this application.

## Scripts

* user_create.rb - Add User
* users_check.rb - Difference check GHE sign-in users and LDAP user information.
* seats_check.rb - Available seats checker.
* archive_sacloud.rb - Archiving the disk for Sakura Cloud.
