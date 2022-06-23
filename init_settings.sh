#!/bin/bash
GITHUB_USER_NAME=$(git config user.name)
GITHUB_USER_EMAIL=$(git config user.email)

if [ -e ./settings.conf ]; then
    echo './settings.conf already exists.'
    read -p "overwrite? (y/n) > " prompt;
    if [ $prompt = 'y' ]; then
        echo "#!/bin/bash" >| ./settings.conf
        echo "GITHUB_USER_NAME='$GITHUB_USER_NAME'" >> ./settings.conf
        echo "GITHUB_USER_EMAIL='$GITHUB_USER_EMAIL'" >> ./settings.conf
        echo "FRONTEND_REPOSITORY='RibbonCMS/SimpleBlogTemplate'" >> ./settings.conf
        echo "SIDE_M_REPOSITORY='RibbonCMS/RibbonCMS_sideM'" >> ./settings.conf
    fi
else
    echo "#!/bin/bash" >| ./settings.conf
    echo "GITHUB_USER_NAME='$GITHUB_USER_NAME'" >> ./settings.conf
    echo "GITHUB_USER_EMAIL='$GITHUB_USER_EMAIL'" >> ./settings.conf
    echo "FRONTEND_REPOSITORY='RibbonCMS/SimpleBlogTemplate'" >> ./settings.conf
    echo "SIDE_M_REPOSITORY='RibbonCMS/RibbonCMS_sideM'" >> ./settings.conf
fi

