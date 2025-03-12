import cv2
import numpy as np
import os
import csv

import easygui

from pathlib import Path
import glob
import itertools

# PH: these are all new
import skimage.util
from skimage import filters, exposure

# EM: added this package to transform 'mage_folder' to a path string (see bottom)
from pathlib import Path

"""
This script was modified by Pieter Hovenkamp from version getmajorandminoraxis2024_4.py, received June 11 2024.
All modifications are marked by a comment starting with 'PH:'.
For details: pieter.hovenkamp@nioz.nl
"""

# PH: here we set some input parameters

# Select 'mean' to use the adaptive mean thresholding. Select 'original' to perform the original fixed thresholding (no other options are currently implemented)
threshold = 'mean'
# threshold = 'original'

# Here we can choose if we want to save the resulting plots of the original image and the image after detecting its
# contours. We can either store the plots in a separate folder (specified below as savefig_dir) if we select save_plots,
# or we can generate them within Python if we select show_plots (but note we can't save and show at the same time,
# so save_plots=True overrides show_plots)

# save_plots = True
save_plots = False
show_plots = False

# If any plots are saved or generated, it is recommended to set a maximum number of images that we process
if save_plots or show_plots:
    # If we want to generate plots we need to have matplotlib installed
    from matplotlib import pyplot as plt
    max_num = 10
else:
    max_num = None

# PH: end of input


# PH: added this function to easily show and save images - note that this function requires matplotlib to be installed
def plot_img_and_result(img, img_result, savefig_path=None, figtitle=None, title_left=None, title_right=None,
                        im_vmin=None, im_vmax=None, **fig_kwargs):
    fig, (ax1, ax2) = plt.subplots(ncols=2, **fig_kwargs)
    ax1.imshow(img, cmap='gray', vmin=im_vmin, vmax=im_vmax)
    ax1.axis('off')
    if title_left:
        ax1.set_title(title_left)

    ax2.imshow(img_result, cmap='gray', vmin=im_vmin, vmax=im_vmax)
    ax2.axis('off')
    if title_right:
        ax2.set_title(title_right)

    if figtitle:
        fig.suptitle(figtitle)

    fig.tight_layout()

    if savefig_path:
        plt.savefig(savefig_path)
    else:
        plt.show()


# PH: added this function to increase contrast
def stretch_contrast(img, p_low=2, p_up=98):
    """
    Contrast enhancement by clipping the percentiles to the min/max values of the input dtype. If
    the input image is float, then the output image is float in range [0, 1] and the image values
    span this whole interval.

    See https://scikit-image.org/docs/stable/auto_examples/color_exposure/plot_equalize.html#sphx-glr-auto-examples-color-exposure-plot-equalize-py

    :param img:
    :param p_up:
    :param p_low:
    :return:
    """
    p_low, p_up = np.percentile(img, (p_low, p_up))
    return exposure.rescale_intensity(img, in_range=(p_low, p_up))


def variance_of_laplacian(image):
    # compute the Laplacian of the image and then return the focus
    # measure, which is simply the variance of the Laplacian
    return cv2.Laplacian(image, cv2.CV_64F).var()


def image_colorfulness(image):
    # split the image into its respective RGB components
    (B, G, R) = cv2.split(image.astype("float"))
    # compute rg = R - G
    rg = np.absolute(R - G)
    # compute yb = 0.5 * (R + G) - B
    yb = np.absolute(0.5 * (R + G) - B)
    # compute the mean and standard deviation of both `rg` and `yb`
    (rbMean, rbStd) = (np.mean(rg), np.std(rg))
    (ybMean, ybStd) = (np.mean(yb), np.std(yb))
    # combine the mean and standard deviations
    stdRoot = np.sqrt((rbStd ** 2) + (ybStd ** 2))
    meanRoot = np.sqrt((rbMean ** 2) + (ybMean ** 2))
    # derive the "colorfulness" metric and return it
    return stdRoot + (0.3 * meanRoot)


#image_folder = easygui.diropenbox("Select a Folder")
image_folder = easygui.diropenbox(default='~/Desktop/selected/',title='Select the folder to process.')

# EM: this converts 'image_folder' to a string path
image_folder = Path(image_folder)

if save_plots:
    # By default any generated plots are saved in a separate folder within the directory where the images are located
    savefig_dir = image_folder.parent / "thresholding_plots" / threshold
    if not os.path.isdir(savefig_dir):
        # os.mkdir(savefig_dir)
        os.makedirs(savefig_dir, exist_ok=True) # EM addition

# Initialize an empty list to store ellipse data
ellipse_data = []

# Iterate through the image files in the folder
print(image_folder)
# iterate over files in
# that directory
images = itertools.chain(Path(image_folder).rglob('*.png'), Path(image_folder).rglob('*.jpg'))
counter = 1
for imagepath in images:
    filename = os.path.basename(imagepath)

    # PH
    if save_plots:
        savefig_path = savefig_dir / filename
    else:
        savefig_path = None

    #Read the image
    image = cv2.imread(str(imagepath))

    if image is not None:
        # Convert the image to grayscale
        gray = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)

        # calculate average gray 
        avggray = cv2.mean(gray)
        #print(avggray[0])

        # calculate average color 
        avgcolor = cv2.mean(image)
        blue = avgcolor[0]
        green = avgcolor[1]
        red = avgcolor[2]
        #print(red)

        # calculate the saturation
        img_hsv = cv2.cvtColor(image, cv2.COLOR_BGR2HSV)
        saturation = img_hsv[:, :, 1].mean()
        #print(saturation)

        # Calculate the colorfulness
        colorfulness = image_colorfulness(image)
        #print("colorfulness")
        #print(colorfulness)

        # Sharpness
        sharpness = variance_of_laplacian(gray)
        #print(sharpness) 

        # Apply thresholding to create a binary image

        # PH: added the option to use adaptive mean thresholding
        if threshold == 'original':
            # This is the original part of the code - with fixed thresholding
            _, thresh = cv2.threshold(gray, 15, 255, cv2.THRESH_BINARY)

            # Perform erosion and dilation to clean up the binary image
            kernel = np.ones((5, 5), np.uint8)
            cleaned_image = cv2.morphologyEx(thresh, cv2.MORPH_OPEN, kernel, iterations=2)
            # one additonal erosion step to compensate for dilation which makes estimates to big compared to manual measurements.
            kernel2 = np.ones((3, 3), np.uint8)
            cleaned_image = cv2.erode(cleaned_image, kernel2, iterations=4)

            # PH: we added a title for the figures that we (optionally) save
            figtitle = "Original threshold (fixed)"
        elif threshold == 'mean':
            gray = stretch_contrast(gray)

            thresh = gray > filters.threshold_mean(gray)
            thresh = skimage.util.img_as_ubyte(thresh)

            cleaned_image = thresh

            figtitle = "Adaptavive threshold (Mean)"
        else:
            raise ValueError(f"Thresholding was not defined, current value is: {threshold}")

        # Find contours in the image
        contours, _ = cv2.findContours(cleaned_image, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)
        if contours:
            # print("yes")
            # Fit an ellipse to the largest contour (assuming it's the object)
            largest_contour = max(contours, key=cv2.contourArea)
            #print(largest_contour)
            if len(largest_contour) >= 5:
                ellipse = cv2.fitEllipse(largest_contour)
                (x,y,w,h) = cv2.boundingRect(largest_contour)
                
                # print(ellipse)
                
                # Extract major and minor axes lengths from the ellipse
                major_axis = max(ellipse[1])
                minor_axis = min(ellipse[1])
                #print(str("Major"))
                #print(major_axis)
                #print(minor_axis)

                # Calculate the area of the contour
                contour_area = cv2.contourArea(largest_contour)
                contour_perimeter = cv2.arcLength(largest_contour, True)  # Perimeter of biggest contour 
                contour_circularity = 4 * np.pi * contour_area / pow(contour_perimeter,2)

                # Store image name and ellipse data
                ellipse_data.append([filename, major_axis, minor_axis, contour_area, contour_circularity, contour_perimeter, w, h, sharpness, saturation, red, green, blue, colorfulness])
                
                # Draw the contour on the original image
                image_with_contour = cv2.drawContours(image.copy(), [largest_contour], -1, (0, 255, 0), 2)
                # PH: commented this one out
                # image_with_contour = cv2.rectangle(image_with_contour, (x,y), (x+w,y+h), (255,0,0), 2)
                #cv2.imwrite(os.path.join(output_path,filename) , image_with_contour)
                
                # Display the cleaned image, pause for a second, and close the viewer
                cv2.imshow("Cleaned Image", image_with_contour)
                cv2.waitKey(5)  # Pause for 5 milliseconds
                cv2.destroyAllWindows()

                # PH: If a contour was found, we plot the original image with the drawn contour
                if save_plots or show_plots:
                    plot_img_and_result(image, image_with_contour, figtitle=figtitle, savefig_path=savefig_path,
                                        title_left=filename, title_right=f"contour length: {len(largest_contour)}")
            else:
                # PH: If only a small contour was found, we plot the original image with the binary image
                if save_plots or show_plots:
                    plot_img_and_result(image, thresh, title_left=filename, figtitle=figtitle, savefig_path=savefig_path,
                                        title_right=f"Binary image, contour length: {len(largest_contour)}")
        else:
            # PH: If no contour was found, we plot the original image with the binary image
            if save_plots or show_plots:
                plot_img_and_result(image, thresh, title_left=filename, figtitle=figtitle, savefig_path=savefig_path,
                                    title_right="Binary image, no contour was found")

    # PH: we quit the loop if we reached the set maximum number of images
    if counter == max_num:
        break
    counter += 1


# Export ellipse data to a CSV file
csv_file = "ellipse_data_" + str(os.path.basename(image_folder)) + ".csv"
csv_file = image_folder.parent / csv_file
with open(csv_file, mode='w', newline='') as file:
    writer = csv.writer(file)
    writer.writerow(["filename", "object_major", "object_minor", "object_area", "object_circularity", "object_perimeter", "object_width", "object_height", "object_sharpness", "object_saturation", "object_redness", "object_greeness", "object_blueness", "object_colorfulness"])
    writer.writerows(ellipse_data)

print("Ellipse data exported to", csv_file)
