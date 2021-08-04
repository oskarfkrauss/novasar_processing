import os

import pystac

from pystac.extensions.projection import ProjectionExtension
from pystac.extensions.sar import FrequencyBand, Polarization, ObservationDirection
from pystac.extensions.sar import SarExtension

import sedas_pyapi

from sedas_pyapi.sedas_api import SeDASAPI 

# import rasterio

import numpy as np

from datetime import datetime

import json

from dotenv import load_dotenv

load_dotenv()

workdir = 'C:/Users/Oskar.Fraserkrauss/Documents/novasar_processing'

os.chdir(workdir)

scene_names = os.listdir(workdir + '/input')

# log into SeDAS

_username = os.getenv('SEDAS_USERNAME')
__password = os.getenv('SEDAS_PWD')

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

# get metadata from SeDAS API and create item

def get_geom_and_bbox(polygon):
    
    polygon = polygon.replace('POLYGON((', '')
    polygon = polygon.replace('))', '')
    
    long_1 = float(polygon.split(' ')[0])
    long_2 = float(polygon.split(' ')[1].split(',')[1])
    long_3 = float(polygon.split(' ')[2].split(',')[1])
    long_4 = float(polygon.split(' ')[3].split(',')[1])
    
    lat_1 = float(polygon.split(' ')[1].split(',')[0])
    lat_2 = float(polygon.split(' ')[2].split(',')[0])
    lat_3 = float(polygon.split(' ')[3].split(',')[0])
    lat_4 = float(polygon.split(' ')[4].split(',')[0])
   
    l_bound = min(long_1, long_2, long_3, long_4) # left
    r_bound = max(long_1, long_2, long_3, long_4) #right
    
    b_bound = min(lat_1, lat_2, lat_3, lat_4) # bottom 
    t_bound = max(lat_1, lat_2, lat_3, lat_4) # top
    
    bbox = [l_bound, 
            b_bound, 
            r_bound, 
            t_bound]
    
    footprint = [[
            [long_1, lat_1],
            [long_2, lat_2],
            [long_3, lat_3],
            [long_4, lat_4],
            [long_1, lat_1]
        ]] 
    
    return bbox, {'type': 'Polygon', 'coordinates': footprint}

def novasar_get_dt(scene_name):
    return datetime.strptime('_'.join(scene_name.split('_')[5:7]), '%y%m%d_%H%M%S')

def novasar_create_item(scene_name):
    
    singleProduct = sedas.search_product(scene_name)
    
    bbox, geom = get_geom_and_bbox(singleProduct[0]['coordinatesWKT'])
    dt = novasar_get_dt(scene_name)
    # crs
    instr = singleProduct[0]['instrumentName']

    item = pystac.Item(id=scene_name,
                      datetime=dt,
                      geometry=geom,
                      bbox=bbox,
                      properties={})
    
    SarExtension.add_to(item)

    sar_ext = SarExtension.ext(item)
    sar_ext.frequency_band = FrequencyBand('S')
    sar_ext.instrument_mode = instr
    
    return item

item = novasar_create_item(scene_names[0])

# now add assets
    