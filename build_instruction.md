```
docker build --platform linux/amd64 -t valex/librechat:0.7.5 .
docker tag valex/librechat:0.7.5 docker.srv2.digi-stud.io/valex/librechat:0.7.5
cloudron install --image docker.srv2.digi-stud.io/valex/librechat:0.7.5 -l librechat.srv2.digi-stud.io;
```
