![RibbonCMS_wide_background](https://user-images.githubusercontent.com/42331656/168180348-764a8f83-9f26-488f-a128-2b9651a1268b.png)

# GitHubIssuesCMS
GitHub Issues driven Contents M@nagement System


# The simplest Setup
1. Create a new **private** repository on Github. (Memo: repository name will be your site URL.)
1. `git clone --bare git@github.com:RibbonCMS/RibbonCMS.git ./{Your repository name}.git`  
   `cd {Your repository name}.git`  
   `git push --mirror git@github.com:<your_username>/{Your repository name}.git`
1. `cd ..`  
   `rm -rf {Your repository name}.git`
1. `git clone git@github.com:<your_username>/{Your repository name}.git`  
   `cd ./{Your repository name}`
1. `./init_settings.sh`
1. Edit `settings.config`
    1. Please make sure your name and email address are correct.
    1. Set `FRONTEND_REPOSITORY` and `SIDE_M_REPOSITORY` to the name repositories you want to use.
1. `./setup.sh`
1. `git add .`  
   `git commit -m 'exec first setup.sh'`  
   `git push origin main`
1. [Create new Labels](https://docs.github.com/ja/issues/using-labels-and-milestones-to-track-work/managing-labels#creating-a-label) on your Repository.
    1. Add `article`, `config` and `delete` labels.
    1. Add labels such as `tag/xx` or `fixed/xx` as needed.
1. Create & Edit & Close Config Issue on your Repository.
    1. New Issue & use "Config" template.
    1. Edit all values.
        1. If `{Your repository name}` is `"<your_user_name>.github.io"`, set the value of `root_url` to `https://<your user name>.github.io`.  
           Else, set the value of `root_url` to `https://<your user name>.github.io/{Your repository name}`
    1. Create & Close issue. (Rest assured that each value can be re-set at any time by re-closing.)
    1. Wait GitHub Actions end.
1. (Your Repository) Settings -> Pages -> Source branch `"build"` `"/(root)" `

## sideM
1. Create Your first post.
    1. New Issue & use "Article" template.
    1. You can add `tag/` prefix labels to the issue; it become the article tags. (named `tag/{tag_name}` issues label will be article `{tag_name}` tag.)
    1. Write Issue markdown with YAML frontmatter & Close. (Rest assured that each value can be re-set at any time by re-closing.)
    1. Wait GitHub Actions end. (If this process succeeds, the article page is updated.)

# How to manage contents
## Post Articles
1. Create issue with `Article` (or `Reserved Article`) template.
1. Fill out YAML frontmatter follow a format.
1. Fill in the body text in markdown under YAML frontmatter.
1. Close issue and wait GitHub Actions end.

## Edit Articles (or Profile)
1. Reopen the issue.
1. Edit the issue content.
1. Close the issue and wait GitHub Actions end.
