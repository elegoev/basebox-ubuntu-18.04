# create git tag

# create git tag
git add --all
git commit -m "new basebox version $env:IMAGE_VERSION"
git tag $env:IMAGE_VERSION
git push --tags





