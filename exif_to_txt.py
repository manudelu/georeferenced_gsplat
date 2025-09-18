
import os
import exifread

INPUT_DIR = "input"               # folder with your drone images
OUTPUT_FILE = "geotags.txt"       # output file for COLMAP

def dms_to_decimal(dms, ref):
    """Convert GPS coordinates in DMS to decimal degrees."""
    degrees = float(dms[0].num) / float(dms[0].den)
    minutes = float(dms[1].num) / float(dms[1].den)
    seconds = float(dms[2].num) / float(dms[2].den)
    decimal = degrees + (minutes / 60.0) + (seconds / 3600.0)
    if ref in ["S", "W"]:
        decimal = -decimal
    return decimal

with open(OUTPUT_FILE, "w") as f_out:
    for filename in sorted(os.listdir(INPUT_DIR)):
        if not filename.lower().endswith((".jpg", ".jpeg", ".tif", ".png")):
            continue

        filepath = os.path.join(INPUT_DIR, filename)
        with open(filepath, "rb") as img_file:
            tags = exifread.process_file(img_file, details=False)
            try:
                lat = dms_to_decimal(tags["GPS GPSLatitude"].values,
                                     tags["GPS GPSLatitudeRef"].printable)
                lon = dms_to_decimal(tags["GPS GPSLongitude"].values,
                                     tags["GPS GPSLongitudeRef"].printable)
                alt = float(tags["GPS GPSAltitude"].values[0].num) / float(tags["GPS GPSAltitude"].values[0].den)

                # Write line: IMAGE_NAME LAT LON ALT
                f_out.write(f"{filename} {lat:.8f} {lon:.8f} {alt:.3f}\n")
            except KeyError:
                print(f"No GPS EXIF data found in {filename}")

print(f"Wrote geotags for COLMAP to {OUTPUT_FILE}")

