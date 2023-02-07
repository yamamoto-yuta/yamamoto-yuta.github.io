#!/bin/bash
if [ "$1" = "-h" -o "$1" = "--help" ]; then
  echo 'usage: ./tie.sh [--side-f SIDE_F_REPO] [--side-m SIDE_M_REPO] user_name repo_name'
  echo ''
  echo 'positional arguments:'
  echo '  user_name             GitHub user name'
  echo '  repo_name             GitHub repository name'
  echo ''
  echo 'optional arguments:'
  echo '  -h, --help            show this help message and exit'
  echo '  --side-f SIDE_F_REPO  GitHub repository name of the side-f'
  echo '                        Format: <user_name>/<repo_name> (default: RibbonCMS/SimpleBlogTemplate)'
  echo '  --side-m SIDE_M_REPO  GitHub repository name of the side-m'
  echo '                        Format: <user_name>/<repo_name> (default: RibbonCMS/RibbonCMS_sideM)'
else
  # Pattern: Missing arguments
  if [ $# -lt 2 ]; then
    echo '[ERROR] Missing arguments!: user_name repo_name'
    exit 1
  # Pattern: --side-f SIDE_F_REPO --side-m SIDE_M_REPO user_name repo_name
  elif [ "$1" = "--side-f" ] && [ "$3" = "--side-m" ]; then
    SIDE_F_REPO=$2
    SIDE_M_REPO=$4
    USER_NAME=$5
    REPO_NAME=$6
  # Pattern: --side-m SIDE_M_REPO --side-f SIDE_F_REPO user_name repo_name
  elif [ "$1" = "--side-m" ] && [ "$3" = "--side-f" ]; then
    SIDE_F_REPO=$4
    SIDE_M_REPO=$2
    USER_NAME=$5
    REPO_NAME=$6
  # Pattern: --side-f SIDE_F_REPO user_name repo_name
  elif [ "$1" = "--side-f" ]; then
    SIDE_F_REPO=$2
    SIDE_M_REPO=RibbonCMS/RibbonCMS_sideM
    USER_NAME=$3
    REPO_NAME=$4
  # Pattern: --side-m SIDE_M_REPO user_name repo_name
  elif [ "$1" = "--side-m" ]; then
    SIDE_F_REPO=RibbonCMS/SimpleBlogTemplate
    SIDE_M_REPO=$2
    USER_NAME=$3
    REPO_NAME=$4
  # Pattern: user_name repo_name
  else
    SIDE_F_REPO=RibbonCMS/SimpleBlogTemplate
    SIDE_M_REPO=RibbonCMS/RibbonCMS_sideM
    USER_NAME=$1
    REPO_NAME=$2
  fi

  git clone --bare git@github.com:RibbonCMS/RibbonCMS.git ./$REPO_NAME.git
  cd ./$REPO_NAME.git
  git push --mirror git@github.com:$USER_NAME/$REPO_NAME.git

  cd ..
  rm -rf ./$REPO_NAME.git

  git clone git@github.com:$USER_NAME/$REPO_NAME.git
  cd ./$REPO_NAME
  GITHUB_USER_NAME=$(git config user.name)
  GITHUB_USER_EMAIL=$(git config user.email)
  echo "#!/bin/bash" >| ./settings.conf
  echo "GITHUB_USER_NAME='$GITHUB_USER_NAME'" >> ./settings.conf
  echo "GITHUB_USER_EMAIL='$GITHUB_USER_EMAIL'" >> ./settings.conf
  echo "FRONTEND_REPOSITORY='$SIDE_F_REPO'" >> ./settings.conf
  echo "SIDE_M_REPOSITORY='$SIDE_M_REPO'" >> ./settings.conf

  ./setup.sh

  git add .
  git commit -m 'exec first setup.sh'
  git push origin main

  echo '[INFO] Done.'
fi
