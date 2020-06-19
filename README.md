# openapi-explorer
Open API specifications are usually stored as YAML files which are hard
to read. This app will render YAML files in a legible format.

## Develop
- nodejs runtime
- yarn package manager

Install project dependencies by running `yarn install`.

## Build
Add APIs to the explorer by copying them to the [public](public) folder and 
generating an api index file.

- Copy APIs - `cp -r <api-dir>/ public/`
- Generate API Index - `tree -J -P "*.yaml" public | jq '{title: "<title>" , contents: .[0].contents}' > public/apis.json`
- `yarn build`

Replace `<api-dir>` and `<title>` in the above commands as needed.

[public](public) folder will have a static website that can be deployed to any web server. 
The generated site does not depend on any external resources.

