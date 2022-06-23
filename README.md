![RibbonCMS_wide_background](https://user-images.githubusercontent.com/42331656/168180348-764a8f83-9f26-488f-a128-2b9651a1268b.png)

# GitHubIssuesCMS_sideM
GitHub Issues driven Contents M@nagement System side Manager


# Setup

## sideF
1. Fork [sideF](https://github.com/ShotaroKataoka/GitHubIssuesCMS_sideF) (Can be named arbitrarily. Repository name will be your site URL.)
1. (Forked sideF Repository) Settings -> Actions -> General -> Workflow permissions -> check "Read and write permissions"

## sideM
1. Create a new **private** repository on Github. (Memo repository name; `{Your repository name}`)
1. `git clone --bare git@github.com:ShotaroKataoka/GitHubIssuesCMS_sideM.git ./{Your repository name}.git`  
   `cd {Your repository name}.git`  
   `git push --mirror git@github.com:<your_username>/{Your repository name}.git`
1. `cd ..`  
   `rm -rf {Your repository name}.git`
1. Setting [Personal Access Token](https://docs.github.com/ja/authentication/keeping-your-account-and-data-secure/creating-a-personal-access-token#creating-a-token)
    1. (Personal) Settings -> Developper settings -> Personal access tokens
    1. Generate New token
    1. Check `public_repo`
    1. Copy Token
1. Set token to your sideM repository [secrets](https://docs.github.com/ja/actions/security-guides/encrypted-secrets#creating-encrypted-secrets-for-a-repository)
    1. (Your sideM Repository) Settings -> Secrets -> Actions
    1. New repository secret
    2. Name: `API_TOKEN_GITHUB`, Value: `{Copied Personal Access Token}`.
    3. Add secret
1. `git clone <your_username>/{Your repository name}.git`  
   `cd ./{Your repository name}`
1. Exec `./init_config.sh`
1. Edit `settings.config`
    1. Please make sure your name and email address are correct.
    1. Set `FRONTEND_REPOSITORY` to the name of your sideF repository that you just forked.
1. Exec `./setup.sh`
1. `git add .`  
   `git commit -m 'exec first setup.sh'`  
   `git push origin main`
1. [Create new Labels](https://docs.github.com/ja/issues/using-labels-and-milestones-to-track-work/managing-labels#creating-a-label) on your sideM Repository.
    1. Create `article` and `profile` labels.
1. Create&Edit&Close Profile Issue on Forked sideM Repository.
    1. New Issue & use "Profile" template.
    1. Edit all values.
        1. If `{Your sideF repository name}` is `"<your_user_name>.github.io"`, set the value of `root_url` to `https://<your user name>.github.io`.  
           Else, set the value of `root_url` to `https://<your user name>.github.io/{Your sideF repository name}`
    1. Create & Close issue. (Rest assured that each value can be re-set at any time by re-closing.)
    1. Wait sideM GitHub Actions end.

## sideF
1. Wait sideF GitHub Actions end. (This process may fail, but that is not a problem.)
1. (Your sideF Repository) Settings -> Pages -> Source branch `"build"` `"/(root)" `

## sideM
1. Create Your first post.
    1. New Issue & use "Article" template.
    1. You can add `tag/` prefix labels to the issue; it become the article tags. (named `tag/{tag_name}` issues label will be article `{tag_name}` tag.)
    1. Write Issue markdown with YAML frontmatter & Close. (Rest assured that each value can be re-set at any time by re-closing.)
    1. Wait sideM & sideF GitHub Actions end. (If this process succeeds, the article page is updated.)

# How to manage contents
## Post Articles
1. Create issue on sideM with `Article` (or `Reserved Article`) template.
1. Fill out YAML frontmatter follow a format.
1. Fill in the body text in markdown under YAML.
1. Clone issue and wait sideM & sideF GitHub Actions end.

## Edit Articles (or Profile)
1. Reopen the issue.
1. Edit the issue content.
1. Close the issue and wait sideM & sideF GitHub Actions end.
