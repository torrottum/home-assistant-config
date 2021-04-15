# Borrowed some code from
# https://github.com/basnijholt/home-assistant-config/blob/master/pyscript/wake_up_light.py
# My lights are not RGB, so I just do linear interpolation on the color_temp

def lerp(x, y, a):
    return x * (1 - a) + y * a


DEFAULT_DURATION = 1800
MIN_TIME_STEP = 2


@service
def wakeup_light(entity_id=None, duration=DEFAULT_DURATION, **kwargs):
    """yaml
name: Wake up light
description: Emulates sunrise
fields:
  entity_id:
     description: Light to fade in
     example: light.bedroom
     required: true
     selector:
       entity:
         domain: light
  duration:
     description: The duration of the effect in seconds
     example: 1800
     default: 1800
     required: true
     selector:
       number:
         min: 0
         unit_of_measurement: seconds
  start_temp:
     description: Start temperature, defaults to max_mireds of the light
     example: 454
     selector:
       number:
         min: 0
         unit_of_measurement: mireds
  end_temp:
     description: End temperature, defaults to min_mireds of the light
     example: 153
     selector:
       number:
         min: 0
         unit_of_measurement: mireds
"""
    task.unique(f"wakeup_light.{entity_id}")

    start_temp = kwargs.get("start_temp",
                            state.getattr(entity_id)["max_mireds"])
    end_temp = kwargs.get("end_temp",
                          state.getattr(entity_id)["min_mireds"])

    steps = min(duration // 2, 255)
    transition = duration / steps

    first_run = True
    for i in range(steps + 1):
        if first_run:
            state.set(entity_id, 'on')
        elif state.get(entity_id) == 'off' and not first_run:
            break
        brightness = lerp(1, 255, i / steps)
        color_temp = lerp(start_temp, end_temp, i / steps)
        light.turn_on(
            entity_id=entity_id,
            brightness=brightness,
            color_temp=color_temp,
            transition=transition
        )
        task.sleep(transition)
        first_run = False
