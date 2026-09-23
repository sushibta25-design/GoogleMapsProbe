ARCHS = arm64 arm64e
TARGET = iphone:clang:16.5:15.0
THEOS_PACKAGE_SCHEME = rootless

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = GoogleMapsProbe
GoogleMapsProbe_FILES = Tweak.xm
GoogleMapsProbe_FRAMEWORKS = Foundation UIKit
GoogleMapsProbe_CFLAGS = -fobjc-arc

include $(THEOS_MAKE_PATH)/tweak.mk
