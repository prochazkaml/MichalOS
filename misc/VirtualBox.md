# Running MichalOS in VirtualBox

If you aren't familiar with DOSBox (or don't have a Linux system available to build the project), this is your next best option.
However, there is one big issue with using MichalOS on VirtualBox:

**Sound doesn't work at all.**

MichalOS uses old primitive PC sound technologies (PC speaker, AdLib FM Synthesizer), which aren't supported under VirtualBox.

Anyhow, here's the guide:

## Step 1: Get VirtualBox

[Here](https://www.virtualbox.org/wiki/Downloads)'s the link to the VirtualBox's Downloads page.

## Step 2: Create a new virtual machine

Open VirtualBox, and you should be greeted by this window:

![fresh_vbox](https://user-images.githubusercontent.com/41787099/126858589-9d62b502-e966-4644-8f6c-ada33a4305d8.png)

Click on the blue "New" button. This should pop up:

![name](https://user-images.githubusercontent.com/41787099/126858600-7c11c63e-3a38-4610-ae6e-d49a82a728a4.png)

Fill it in so that your settings match the ones on the picture (except the "Machine folder"), so:

- Name: "MichalOS"
- Type: "Other"
- Version: "Other/Unknown"

Next it will ask you how much RAM you want. Keep in mind that MichalOS can only use 640 kB of RAM, so just set it to the minimum:

![memory](https://user-images.githubusercontent.com/41787099/126858650-fe752fec-448d-4c46-ac7a-9bf6f9311da4.png)

Finally, it will ask you whether you want a hard disk. We don't, MichalOS doesn't support it, so select the "Do not add a virtual hard disk" option:

![hdd](https://user-images.githubusercontent.com/41787099/126858656-88df62f9-723a-4816-bf94-21297bf02581.png)

It will nag you for not adding a hard disk, however, we know what we're doing, so just click "Continue":

![nag](https://user-images.githubusercontent.com/41787099/126858688-e09bc725-ebc9-442f-9673-cf62daee9eaa.png)

## Step 3: Attach a floppy disk image to the virtual machine

After you've created your new virtual machine, highlight it and click on the orange "Settings" button:

![vm_created](https://user-images.githubusercontent.com/41787099/126858793-6760335a-6cec-46f1-8bef-c29becdda64a.png)

A new window will pop up. From the panel on the left, select "Storage". Your window will now look like this:

![settings](https://user-images.githubusercontent.com/41787099/126858818-23d2de66-01f9-44be-81c9-b0ac17392b85.png)

On the bottom, there is a little button with an icon of a weird tilted green square and a plus icon (it's the one on the left). Click on it and select "I82078 (Floppy)":

![floppy](https://user-images.githubusercontent.com/41787099/126858851-5ca2fdfd-d3ff-4085-bee4-8b4b2e5635d5.png)

This will create a new floppy controller.

![floppycontroller](https://user-images.githubusercontent.com/41787099/126858889-0cd59498-6ef0-41ad-88b4-431a524f2c0b.png)

Highlight it, and next to it will appear a little "floppy add" icon. Click on it, and it will take you to the Floppy Disk Selector:

![floppyadddialog](https://user-images.githubusercontent.com/41787099/126858917-7052d622-c74b-4d24-9960-fa8c1639e95c.png)

Click on the "Add" button. From there, navigate to the directory where you have extracted MichalOS and find "michalos.flp" (it will be either in the "build" or "build/images" directory):

![michalosflp](https://user-images.githubusercontent.com/41787099/126858963-1241cee7-576f-464f-b462-edf260a1bc05.png)

Click on "Open". That will take you back to the Floppy Disk Selector.

![yesiwantthatfloppy](https://user-images.githubusercontent.com/41787099/126859008-413c16fb-720a-400d-884c-02db57a7a20d.png)

Select "michalos.flp" in the list and click "Choose". That will take you back to the settings dialog. Press "OK".

## Step 4: Run!

Select "MichalOS" from the virtual machine list and press Start.
