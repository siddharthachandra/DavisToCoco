# DavisToCoco

This is a script to convert the davis video dataset to the coco format.

The code can be modified to convert any segmentation dataset (with images, png segmentation mask annotations) to the coco format.

The coco-format dataset involves a json object (dictionary) with a list of images, and polygon segmentations.

The only dependency for this code is [jsonlab](https://www.mathworks.com/matlabcentral/fileexchange/33381-jsonlab--a-toolbox-to-encode-decode-json-files)
(a toolbox allowing writing of json files in matlab).
