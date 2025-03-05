### Welcome! 

Start with the other repository. That repository will set up the CICD pipeline infastructure. After you have a running Jenkins properly set up. Then come here.

If you haven't already, create an account and get a phone number from twilio. Specify this number in  this repository at textanything/terraform/variables.tf

This code automatically deploys when merged or pushed to main when using the Jenkins server set up in the other repository: jenkins. Follow the steps to set up the Jenkins server and then code naturally.

Note: Verification is expected to fail in the pipeline till Route 53 DNS is set up.


### To the viewers:
After standing this up please run the following to confirm it is up on all 3 infrastructures:

```
while true; do
  IP=$(host -t A zwingers.us 8.8.8.8 | awk '/has address/ { print $4 }' | head -n 1)
  curl -s http://$IP | sed -n 's/.*<h1>\(.*\)<\/h1>.*/\1/p'
  sleep 2
done
```
