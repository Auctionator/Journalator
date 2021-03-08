#!/bin/bash

curl  -i \
      -H "X-Api-Token: $3" \
      -X POST -H "Content-Type: multipart/form-data"  \
      -F \
"""metadata={
  changelog: \"\",
  displayName: \"$1\",
  gameVersions: [8157],
  releaseType: \"release\",
  relations: {
    projects: [{
      slug: \"auctionator\",
      type: \"requiredDependency\"
    }]
  }
}"""\
      -F "file=@$2" \
    "https://wow.curseforge.com/api/projects/453921/upload-file/"
