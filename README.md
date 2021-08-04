# NovaSAR processing and cloud optimistation workflow

There is currently a lack of documentary on the processing of NovaSAR imagery. This repositry details a simple approach to processing and cloud optimising data from the NovaSAR-1 satellite, including the generation of a [STAC](https://github.com/radiantearth/stac-spec). The procedure (contained within the python and IDL scripts) is as follows:

1. Input AOI, start, and end dates.
2. Use the SeDAS API (hosted by SA Catapult) to download all available (level 2) data. 
3. Process the data using SARscape to generate a level 3 ship detection product, the processing steps are:  

    * Importing
    * Multilook 
    * Despeckle
    * Digital elevation model extraction
    * Geocoding and radiometric calibration
    * **Ship Detection**

4. Create a STAC of the data, saving to Catapult cloud storage.

The process_novasar.py script completes steps 1-3 using an IDL->Python bridge to deploy IDLSCRIPT_TEST.pro, which does the heavy processing.

The stac_novasar.py script creates a STAC of the processed data, saving the catalog to Catapult cloud storage.