Android signing placeholder

1. Copy keystore.properties.example to keystore.properties.
2. Put the upload keystore at this folder or configure an absolute path.
3. Inject passwords from CI secrets; do not commit keystore.properties or *.jks.
4. Release signing should be wired into android/app/build.gradle by the platform owner.
