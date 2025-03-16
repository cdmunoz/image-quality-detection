# image_quality_detector

This project focus on use a set of algorithms and libraries to detect wheter an image has a good or bad quality based on blur, borders and shadows.
This is part of a spike that could be used later in the drivers-app for scanning quality validations.

## What To Know About

We are using `google_mlkit_document_scanner`, `google_mlkit_image_labeling` and `google_mlkit_text_recognition` to scan an image, validate that it is a document, then verify its blurring and borders quality. Also, we have implemented a couple of algorithms (Laplacian, Sobel, Shadows) to verify as well if the scanned document has a good quality based on the blur, pixels quality and shadows. 
The heuristics goes as follow: once we have the bytes array of the scanned document, we apply the MLKit logic to calculate a score that says if the image has or not a good quality based on the parameters above. If we have uncertainty about the result, then we proceed to do a hybrid check with the local algorithms. 
To take into consideration, we probably should change, depending on how strict we will be with the results, the value of the threshold in the algorithms.

