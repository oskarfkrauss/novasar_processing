"""
Created on Tue Jul 27 12:31:10 2021

@author: Oskar Fraser-Krauss
"""

#sedas needs installing

from sedas_pyapi.sedas_api import SeDASAPI 
from sedas_pyapi.bulk_download import SeDASBulkDownload
import os
# import json

from dotenv import load_dotenv

load_dotenv()

# set working directory

workdir = 'C:/Users/Oskar.Fraserkrauss/Documents/novasar_processing'

# point SeDAS API to test site

# creating the SeDASAPI object attempts to log into live. It will throw an exception if it cant. so we feed it real creds (any one using test should have a live set)
_username = os.getenv('SEDAS_USERNAME')
__password = os.getenv('SEDAS_PWD')

# Note the SeDASBulkDownload is very chatty at debug. But if you need to know what is going on enable logging.

# create the object this will connect to the test.
sedas = SeDASAPI(_username, __password)

# set the base url to point at the test instance
sedas.base_url = "https://geobrowsertest.satapps.org/api/"

# Now we need to reset a few variables that have the original base url still
sedas.sensor_url = f"{sedas.base_url}sensors"
sedas.authentication_url = f"{sedas.base_url}authentication"
sedas.search_url = f"{sedas.base_url}search" 


# Get rid of the token force the log in to happen again.
sedas._token = None  

# now we can get the users actual test password
sedas._username = os.getenv('SEDAS_USERNAME')
sedas.__password = os.getenv('SEDAS_PWD')
# and log into test
sedas.login()

# define AOI, start date, end date

wkt = "POLYGON((0.263671875 50.28933925329178," \
               "0.263671875 51.91716758909015," \
               "2.548828125 51.91716758909015," \
               "2.548828125 50.28933925329178," \
               "0.263671875 50.28933925329178))"
               
start_date = '2021-06-01T09:43:45Z'
end_date = '2021-07-01T09:43:45Z'
               
# search for relevant results and initilialise downlaod

result_sar = sedas.search_sar(wkt, start_date, end_date, source_group="NovaSAR")
# print(json.dumps(result_sar, sort_keys=True, indent=4, separators=(',', ': '))[4])

downloader = SeDASBulkDownload(sedas, '', parallel=3)

# configure working dir to save level 2(??) data into input folder 

os.chdir(workdir)

os.mkdir('input')
os.mkdir('output') # make folder to store outputs (keeps things tidy)

os.chdir(workdir + '/input')

# Add the things we want to download to the queue
downloader.add(result_sar['products'][:3])

import time
import zipfile

# Wait for the downloader to be finished..
while not downloader.is_done():
   time.sleep(5)

# clean up the background threads.
downloader.shutdown()

# unzip relevant folders
    
for item in os.listdir(os.getcwd()): # loop through items in dir
    if 'slc' not in item: # currently can't do grd or scd
        file_name = os.path.abspath(item)
        os.remove(file_name)
for item in os.listdir(os.getcwd()):
    if item.endswith('.zip'): # check for ".zip" extension
        file_name = os.path.abspath(item) # get full path of files
        zip_ref = zipfile.ZipFile(file_name) # create zipfile object
        zip_ref.extractall(os.getcwd()) # extract file to dir
        zip_ref.close() # close file
        os.remove(file_name) # delete zipped file
        
# tirkcy bit now is to configure Python --> IDL bridge, instrictions are given here:
# https://www.l3harrisgeospatial.com/docs/python.html, involves setting PATH environment 
# variables (tutorial here: https://www.youtube.com/watch?v=OdIHeg4jj2c) then running
# setup.py script (in CLI) found in IDL bridges folder (e.g. C:\Program Files\Harris\IDLxx\lib\bridges)

#%%

from idlpy import IDL
import os

workdir = 'C:/Users/Oskar.Fraserkrauss/Documents/novasar_processing'

os.chdir(workdir)

# some files don't overwrite so add something to clear all outputs before running IDL

# os.mkdir('.aux') # make folder to store auxillary files (optional step)

# run IDL script (IDLSCRIPT_TEST) first arg is working dir, second is aux dir, both required

for i in os.listdir(workdir + '/input'):

    IDL.IDLSCRIPT_TEST(i, workdir, workdir + '/.aux')

# get ais from api 
#%%

import json

import pandas as pd

js = open('ais_data.json')

data = json.load(js)

df = pd.json_normalize(data['features'])

df = df.drop(['type', 'geometry.type', 'geometry.coordinates'], 1)

df.columns = ['Message_Type', 'Repeat', 'MMSI','Longitude', 'Latitude', 'Timestamp'] 



# df.to_csv('ais.csv')


#%%

_username = os.getenv('SEDAS_USERNAME')
__password = os.getenv('SEDAS_PWD')

# Note the SeDASBulkDownload is very chatty at debug. But if you need to know what is going on enable logging.

# create the object this will connect to the test.
sedas = SeDASAPI(_username, __password)

# set the base url to point at the test instance
sedas.base_url = "https://geobrowsertest.satapps.org/api/"

# Now we need to reset a few variables that have the original base url still
sedas.sensor_url = f"{sedas.base_url}sensors"
sedas.authentication_url = f"{sedas.base_url}authentication"
sedas.search_url = f"{sedas.base_url}ais/search" 

# Get rid of the token force the log in to happen again.
sedas._token = None  

# now we can get the users actual test password
sedas._username = os.getenv('SEDAS_USERNAME')
sedas.__password = os.getenv('SEDAS_PWD')
# and log into test
sedas.login()

# define AOI, start date, end date

wkt = "POLYGON((0.263671875 50.28933925329178," \
               "0.263671875 51.91716758909015," \
               "2.548828125 51.91716758909015," \
               "2.548828125 50.28933925329178," \
               "0.263671875 50.28933925329178))"
               
start_date = '2021-06-01T09:43:45Z'
end_date = '2021-07-01T09:43:45Z'
               
results_ais = sedas.search(wkt, start_date, end_date, retry=True)

import requests

body = {
  "sourceGroup": "ALL",
  "polygon": "POLYGON((-3.2958984375 52.892748943592196,0.615234375 52.892748943592196,0.615234375 51.107402176013,-3.2958984375 51.107402176013,-3.2958984375 52.892748943592196))",
  "start": "2017-04-01T00:00:00Z",
  "stop": "2017-04-01T00:00:00Z"
  }


r = requests.post('https://geobrowsertest.satapps.org/api/ais/search', data=body)
print(r.status_code, r.reason)
