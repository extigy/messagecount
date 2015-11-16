ARCHS = armv7 armv7s arm64
TARGET = iphone:clang:latest:latest
include theos/makefiles/common.mk
TWEAK_NAME = MessageCount
MessageCount_FILES = Tweak.xm
MessageCount_FRAMEWORKS = UIKit CoreFoundation
MessageCount_PRIVATE_FRAMEWORKS = ChatKit IMCore
MessageCount_LDFLAGS = -Wl,-segalign,4000

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 MobileSMS"
	install.exec "rm /var/mobile/Library/Preferences/com.teggers.messagecount.plist"
