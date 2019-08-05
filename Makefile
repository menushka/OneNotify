include $(THEOS)/makefiles/common.mk

TWEAK_NAME = OneNotify
OneNotify_FILES = Tweak.xm
OneNotify_EXTRA_FRAMEWORKS += Cephei

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 SpringBoard"
SUBPROJECTS += onenotifypreferences
include $(THEOS_MAKE_PATH)/aggregate.mk
