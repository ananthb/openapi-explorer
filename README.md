# openapi-explorer
Open API specifications are usually stored as YAML files which are hard
to read. This app will render YAML files in a legible format.

## Develop
- nodejs runtime
- yarn package manager

## Build
Install dependencies and build the Elm project.


    yarn install --dev
    yarn build
    
## Deploy
Add APIs to the explorer by copying them to the public/apis folder and 
generating an api index file.
- Each API collection must be in a separate subfolder of the **public/apis** folder.
- The API index file must be at **public/apis/index.json**.
- The API description must be at **public/apis/README.md**.

After the public/apis folder is populated, generate an APIs index using this command (replace \<title> as needed):

    pushd public; tree -J -P "*.yaml" apis | jq '{title: "<title>" , contents: .[0].contents}' > apis/index.json; popd

**Sample apis folder**

    public/apis/
    ├── content-manager
    │   ├── ingest.yaml
    │   ├── internal.yaml
    │   └── README.md
    ├── index.json
    ├── README.md
    └── screen-manager
        ├── automation.yaml
        ├── iam.yaml
        ├── media.yaml
        ├── playback.yaml
        ├── README.md
        ├── schedules.yaml
        ├── shows.yaml
        ├── storage.yaml
        └── system.yaml


[public](public) folder will now have a static website that can be deployed to any web server. 
The generated site does not depend on any external resources.

## Containers
openapi-explorer can be built and run in a container.
The /path/to/apis folder must contain valid API definitions along with a generated index.json file as described above.


    podman build -t openapi-explorer .
    podman run --rm -p 8080:8080 -v /path/to/apis:/srv/apis openapi-explorer
    
Pre-built containers are available on GitHub Container Registry:

    podman pull ghcr.io/RealImage/openapi-explorer
    
*docker can directly substitute podman in the above commands*

