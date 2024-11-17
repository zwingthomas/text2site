### Welcome! 

Start with the other repository. That repository will set up the CICD pipeline infastructure. After you have a running Jenkins properly set up. Then come here.

If you haven't already, create an account and get a phone number from twilio. Specify this number in  this repository at textanything/terraform/variables.tf

This code automatically deploys when merged or pushed to main when using the Jenkins server set up in the other repository: jenkins. Follow the steps to set up the Jenkins server and then code naturally.

Note: Verification is expected to fail in the pipeline till Route 53 DNS is set up.


### To the reviewers:
I learned a decent amount about aws with this exercise. Especially when it comes to Route 53 which still has my certificates pending at the time I write this. I truly enjoyed this activity and now I have a great personal project (that isn't in a private repo for the fun side thing me and a friend do) to showcase my skills with Terraform, Ansible, and Jenkins. I really appreciate the inspiration. 

Sincerely, thank you. 
I hope you had a great weekend!

p.s. I opted for ecs since k8s seems overkill (ecs is more cost effective as well in this case) and I wanted to show off container skills still.
