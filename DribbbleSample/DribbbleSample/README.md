DribbbleSample

This demo shows loading 1000 images in a collection view.

You'll need a dribbble api app setup, which provides you with a accessToken, clientId, and clientSecret.

You can create a dribbble app easily here (you'll at least need to signup):

https://dribbble.com/account/applications/

Once you have that info, update the ViewController.m line 37, 38, 39.

Then take a look at DribbbleShotCell. This has logic in it to handle images with UIImageLoader.
