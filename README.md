# Image Organizer

A tool for consolidating disorganized image libraries and organizing them by the date the photos were taken.

## Installing

### GNU/Linux

    # apt-get install libimage-exiftool-perl
    $ bundle install

### Mac OS X

    $ brew install exiftool
    $ bundle install

## Usage

    $ ruby organize.rb source_directory destination_directory

## Folder Structure

If the image's EXIF data contains a `date_time_original_civil`, then the image will be moved into a folder based on the date the image was taken.

    destination_directory/YYYY/MM/DD/

If the image's EXIF data does not contain a `date_time_original_civil`, the image will be moved to

    destination_directory/Unsorted

## Duplicate Files

If two images with the same `date_time_original_civil` and the same filename are found, the MD5 hashes of the first 1MB of each file are compared. If they are identical, the duplicate file is discarded. If the hashes differ, then the dimensions of each image are compared, and the image with the largest size is kept.

