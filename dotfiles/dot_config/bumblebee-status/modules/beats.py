# Use code snippet from https://stackoverflow.com/questions/51721018/swatch-internet-time-in-python.

import core.module
import core.widget

from datetime import datetime
from dateutil import tz

def itime():
    """Calculate and return Swatch Internet Time

    :returns: No. of beats (Swatch Internet Time)
    :rtype: float
    """
    from_zone = tz.gettz('UTC')
    to_zone = tz.gettz('Europe/Zurich')
    time = datetime.utcnow()
    utc_time = time.replace(tzinfo=from_zone)
    zurich_time = utc_time.astimezone(to_zone)

    h, m, s = zurich_time.timetuple()[3:6]

    beats = ((h * 3600) + (m * 60) + s) / 86.4

    if beats > 1000:
        beats -= 1000
    elif beats < 0:
        beats += 1000

    return beats

class Module(core.module.Module):
    def __init__(self, config, theme):
        super().__init__(config, theme, core.widget.Widget(self.full_text))

    def full_text(self, widgets):
        return f"@{itime():03.4}"
