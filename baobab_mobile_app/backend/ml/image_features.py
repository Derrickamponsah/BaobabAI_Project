"""
image_features.py
-----------------
Estimate a baobab tree's morphological measurements (height, crown
diameter, trunk diameter, DBH) from a single photograph using classical
computer-vision techniques (OpenCV).

Approach
--------
1. Segment the tree from the background:
     * an HSV green mask isolates the canopy,
     * an Otsu / adaptive mask on the lower-central strip isolates the trunk,
     * the union gives the whole-tree silhouette.
2. Measure the silhouette in PIXELS:
     * tree height        = silhouette bounding-box height,
     * crown diameter     = widest run of the canopy mask,
     * trunk diameter     = median width of the trunk mask near its base.
3. Convert pixels -> metres using a scale:
     * if the caller supplies a reference object of known real height and
       its pixel height, scale = real / pixels (accurate);
     * otherwise a configurable prior tree height is assumed so that the
       RATIOS are preserved and the user can correct the absolute values.

IMPORTANT (documented honestly for the thesis): absolute measurements
from a single uncalibrated image are approximate. The mobile app therefore
returns these as EDITABLE suggestions that the user confirms or adjusts
before prediction. Providing a scale reference greatly improves accuracy.
"""
import cv2
import numpy as np

# Fallback assumption when no scale reference is given: a typical mature
# baobab silhouette height (m). Used only to set absolute scale; ratios
# are unaffected.
DEFAULT_ASSUMED_HEIGHT_M = 10.0


def _largest_contour(mask):
    cnts, _ = cv2.findContours(mask, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)
    if not cnts:
        return None
    return max(cnts, key=cv2.contourArea)


def _canopy_mask(hsv):
    # broad green range covering foliage under varied lighting
    lower = np.array([25, 30, 30]); upper = np.array([95, 255, 255])
    mask = cv2.inRange(hsv, lower, upper)
    mask = cv2.morphologyEx(mask, cv2.MORPH_OPEN, np.ones((5, 5), np.uint8))
    mask = cv2.morphologyEx(mask, cv2.MORPH_CLOSE, np.ones((9, 9), np.uint8))
    return mask


def _trunk_mask(bgr, canopy_bottom, x0, x1):
    """Segment a trunk-like structure below the canopy in the central band."""
    h, w = bgr.shape[:2]
    band = bgr[canopy_bottom:h, max(0, x0):min(w, x1)]
    if band.size == 0:
        return None, (canopy_bottom, x0)
    gray = cv2.cvtColor(band, cv2.COLOR_BGR2GRAY)
    gray = cv2.GaussianBlur(gray, (5, 5), 0)
    _, th = cv2.threshold(gray, 0, 255, cv2.THRESH_BINARY_INV + cv2.THRESH_OTSU)
    th = cv2.morphologyEx(th, cv2.MORPH_CLOSE, np.ones((7, 7), np.uint8))
    return th, (canopy_bottom, max(0, x0))


def extract_features(image_path, ref_object_height_m=None,
                     ref_object_pixel_height=None,
                     assumed_height_m=DEFAULT_ASSUMED_HEIGHT_M):
    """Return estimated morphology + a quality/confidence report.

    Returns dict:
      { estimated: {height_m, crown_diameter_m, trunk_diameter_m, dbh_mm},
        pixels:    {tree_h, crown_w, trunk_w},
        scale_m_per_px, scale_source, confidence, notes }
    """
    bgr = cv2.imread(image_path)
    if bgr is None:
        raise ValueError('Could not read image: %s' % image_path)

    # normalise size for stable thresholds
    max_side = 1024
    h0, w0 = bgr.shape[:2]
    s = max_side / max(h0, w0)
    if s < 1:
        bgr = cv2.resize(bgr, (int(w0 * s), int(h0 * s)))
    h, w = bgr.shape[:2]
    hsv = cv2.cvtColor(bgr, cv2.COLOR_BGR2HSV)

    notes = []

    # --- canopy ---
    cmask = _canopy_mask(hsv)
    canopy = _largest_contour(cmask)
    if canopy is None or cv2.contourArea(canopy) < 0.01 * h * w:
        # fallback: whole-foreground via Otsu on saturation
        notes.append('Weak canopy segmentation; used foreground fallback.')
        _, cmask = cv2.threshold(hsv[:, :, 1], 0, 255,
                                 cv2.THRESH_BINARY + cv2.THRESH_OTSU)
        canopy = _largest_contour(cmask)
    cx, cy, cw, ch = cv2.boundingRect(canopy)
    crown_w_px = cw
    canopy_bottom = cy + ch
    center_x = cx + cw // 2

    # --- trunk (central band beneath canopy) ---
    band_half = max(int(0.10 * w), cw // 6)
    tmask, (ty0, tx0) = _trunk_mask(bgr, canopy_bottom, center_x - band_half,
                                    center_x + band_half)
    trunk_w_px = None
    trunk_bottom = canopy_bottom
    if tmask is not None and tmask.sum() > 0:
        # median non-zero row width in the lower third of the band
        rows = np.where(tmask.sum(axis=1) > 0)[0]
        if len(rows):
            trunk_bottom = ty0 + int(rows.max())
            lower = tmask[int(len(tmask) * 0.5):]
            widths = [np.count_nonzero(r) for r in lower if r.any()]
            if widths:
                trunk_w_px = float(np.median(widths))
    if not trunk_w_px:
        trunk_w_px = max(4.0, 0.08 * crown_w_px)
        notes.append('Trunk not clearly detected; estimated from canopy width.')

    tree_h_px = float(trunk_bottom - cy)
    if tree_h_px < 0.3 * h:
        tree_h_px = float(ch)  # canopy only

    # --- scale ---
    if ref_object_height_m and ref_object_pixel_height:
        scale = float(ref_object_height_m) / float(ref_object_pixel_height)
        scale_source = 'reference_object'
        confidence = 'high'
    else:
        scale = float(assumed_height_m) / tree_h_px
        scale_source = 'assumed_tree_height'
        confidence = 'low'
        notes.append('No scale reference supplied; absolute sizes are '
                     'approximate — please confirm/adjust before predicting.')

    height_m = round(tree_h_px * scale, 2)
    crown_m = round(crown_w_px * scale, 2)
    trunk_m = round(trunk_w_px * scale, 3)
    dbh_mm = round(trunk_m * 1000.0, 1)  # DBH ~ trunk diameter (mm)

    return {
        'estimated': {
            'height_m': max(0.5, height_m),
            'crown_diameter_m': max(0.3, crown_m),
            'trunk_diameter_m': max(0.05, trunk_m),
            'dbh_mm': max(30.0, dbh_mm),
        },
        'pixels': {'tree_h': tree_h_px, 'crown_w': float(crown_w_px),
                   'trunk_w': float(trunk_w_px)},
        'scale_m_per_px': scale,
        'scale_source': scale_source,
        'confidence': confidence,
        'notes': notes,
    }
