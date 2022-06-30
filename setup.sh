#!/bin/bash
source ./settings.conf

issue_builder='./templates/workflows/issue_builder.yml'
workflow=$(cat $issue_builder)
workflow=$(echo "$workflow" | sed -e "s|T_GITHUB_USER_NAME|${GITHUB_USER_NAME}|g")
workflow=$(echo "$workflow" | sed -e "s|T_GITHUB_USER_EMAIL|${GITHUB_USER_EMAIL}|g")
workflow=$(echo "$workflow" | sed -e "s|T_FRONTEND_REPOSITORY|${FRONTEND_REPOSITORY}|g")
workflow=$(echo "$workflow" | sed -e "s|T_SIDE_M_REPOSITORY|${SIDE_M_REPOSITORY}|g")
if [ ! -d ./.github/workflows ]; then
    mkdir -p ./.github/workflows
fi
if [ -e ./.github/workflows/issue_builder.yml ]; then
    read -p "cp: overwrite './.github/workflows/issue_builder.yml'? " prompt;
    if [ $prompt = 'y' ]; then
        echo "$workflow" >| ./.github/workflows/issue_builder.yml
    fi
else
    echo "$workflow" >| ./.github/workflows/issue_builder.yml
fi

git clone git@github.com:${FRONTEND_REPOSITORY}.git ./front
# copy
if [ ! -d ./.github/ISSUE_TEMPLATE ]; then
    mkdir -p ./.github/ISSUE_TEMPLATE
fi
cp ./front/templates/issues/* ./.github/ISSUE_TEMPLATE/

if [ -f ./.github/ISSUE_TEMPLATE/feature_request.md ]; then
    rm ./.github/ISSUE_TEMPLATE/feature_request.md
fi
if [ -f ./.github/ISSUE_TEMPLATE/bug_report.md ]; then
    rm ./.github/ISSUE_TEMPLATE/bug_report.md
fi
if [ -d ./front ]; then
    rm -rf ./front
fi


