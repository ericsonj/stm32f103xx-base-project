## Local functions
define logger-compile
	@printf "%6s\t%-30s\n" $(1) $(2)
endef	

## Test FLAGS
ifndef PROJECT
$(error PROJECT flag is not set)
endif

ifndef PROJECTS_DIR
$(error PROJECTS_DIR flag is not set)
endif

## ARM NONE EABI
ARM_PREFIX	?= arm-none-eabi
CC			:= $(ARM_PREFIX)-gcc
CXX			:= $(ARM_PREFIX)-g++
LD			:= $(ARM_PREFIX)-gcc
AR			:= $(ARM_PREFIX)-ar
AS			:= $(ARM_PREFIX)-as
OBJCOPY		:= $(ARM_PREFIX)-objcopy
SIZE		:= $(ARM_PREFIX)-size
OBJDUMP		:= $(ARM_PREFIX)-objdump
GDB			:= $(ARM_PREFIX)-gdb

## Definitions
STFLASH		= $(shell which st-flash)

LIBS_DIR = libs
HAL_LIBRARY = $(LIBS_DIR)/STM32F1xx_HAL_Driver
FREERTOS_DIR = $(LIBS_DIR)/FreeRTOS/Source
LDSCRIPT = LinkerScript.ld

HAL_LIBRARY_SRC = $(HAL_LIBRARY)/*/
FREERTOS_CMSIS = $(FREERTOS_DIR)/CMSIS_RTOS
FREERTOS_SRC = $(FREERTOS_DIR)
FREERTOS_PORT_SRC = $(FREERTOS_DIR)/portable/GCC/ARM_CM3/port.c
FREERTOS_MEMMANG_SRC = $(FREERTOS_DIR)/portable/MemMang/heap_4.c
FREERTOS_INC = $(FREERTOS_DIR)/include
FREERTOS_CMSIS_INC = $(FREERTOS_DIR)/CMSIS_RTOS
FREERTOS_PORT_INC = $(FREERTOS_DIR)/portable/GCC/ARM_CM3/

CMSIS_INC = $(LIBS_DIR)/CMSIS/Include
CMSIS_DEVICE_INC = $(LIBS_DIR)/CMSIS/Device/ST/STM32F1xx/Include
HAL_LIBRARY_INC = $(HAL_LIBRARY)/Inc
HAL_LEGACY_INC = $(HAL_LIBRARY)/Inc/Legacy

PROJECT_OUT = $(PROJECTS_DIR)/$(PROJECT)/out
PROJECT_SRC = $(PROJECTS_DIR)/$(PROJECT)/src
PROJECT_INC = $(PROJECTS_DIR)/$(PROJECT)/inc
PROJECT_STARTUP = $(PROJECTS_DIR)/$(PROJECT)/startup

TARGET = $(PROJECT_OUT)/$(PROJECT).elf
TARGET_BIN = $(PROJECT_OUT)/$(PROJECT).bin
TARGET_MAP = $(PROJECT_OUT)/$(PROJECT).map

## SOURCES C CXX AS
CSRC := $(wildcard $(PROJECT_SRC)/*.c)
CSRC += $(wildcard $(HAL_LIBRARY_SRC)*.c)

ifeq ($(FREERTOS),y)
	CSRC += $(wildcard $(FREERTOS_CMSIS)/*.c)
	CSRC += $(wildcard $(FREERTOS_SRC)/*.c)
	CSRC += $(FREERTOS_PORT_SRC)
	CSRC += $(FREERTOS_MEMMANG_SRC)
endif

CXXSRC := $(wildcard $(PROJECT_SRC)/*.cpp)
ASSRC := $(wildcard $(PROJECT_STARTUP)/*.s)
ASSRC += $(wildcard $(PROJECT_SRC)/*.s)
PASSRC += $(wildcard $(PROJECT_SRC)/*.S) 

## INCLUDE
INCLUDE_FLAGS = -I$(CMSIS_INC) -I$(CMSIS_DEVICE_INC) -I$(HAL_LIBRARY_INC) -I$(HAL_LEGACY_INC) -I$(PROJECT_INC)

ifeq ($(FREERTOS),y)
	INCLUDE_FLAGS += -I$(FREERTOS_INC) -I$(FREERTOS_CMSIS_INC) -I$(FREERTOS_PORT_INC)
endif

## OBJECTS
OBJECTS = $(CSRC:%.c=$(PROJECT_OUT)/%.o) $(CXXSRC:%.cpp=$(PROJECT_OUT)/%.o) $(ASSRC:%.s=$(PROJECT_OUT)/%.o) $(PASSRC:%.S=$(PROJECT_OUT)/%.o)

## CFLAGS
OPT				:= -O0 -g3 -Wall -fmessage-length=0 -ffunction-sections
CSTD			?= -std=c99
FP_FLAGS		?= -mfloat-abi=soft
ARCH_FLAGS		= -mthumb -mcpu=cortex-m3 $(FP_FLAGS)
FREERTOS_USE	= -DUSE_RTOS_SYSTICK

CFLAGS += $(OPT)
CFLAGS += $(ARCH_FLAGS)
CFLAGS += -DSTM32 -DSTM32F1 -DSTM32F103C8Tx -DDEBUG -DUSE_HAL_DRIVER -DSTM32F103xB

ifeq ($(FREERTOS),y)
	CFLAGS += $(FREERTOS_USE)
endif

CFLAGS += $(INCLUDE_FLAGS)

## LINKED
LDFLAGS	+= -mcpu=cortex-m3 -mthumb -mfloat-abi=soft
LDFLAGS	+= -T$(LDSCRIPT)

$(PROJECT_OUT)/%.o: %.c
	$(call logger-compile,"CC",$(notdir $<))
	@mkdir -p $(dir $@)
	$(CC) -MMD -MP $(CFLAGS) -o $@ -c $<

$(PROJECT_OUT)/%.o: %.cpp
	$(call logger-compile,"CXX",$(notdir $<))
	@mkdir -p $(dir $@)
	@touch $@

$(PROJECT_OUT)/%.o: %.s
	$(call logger-compile,"AS",$(notdir $<))
	@mkdir -p $(dir $@)
	$(CC) -MMD $(CFLAGS) -o $@ -c $<

$(PROJECT_OUT)/%.o: %.S
	$(call logger-compile,"AS",$(notdir $<))
	@mkdir -p $(dir $@)
	$(CC) -MMD $(CFLAGS) -o $@ -c $<

$(TARGET): $(OBJECTS) $(LDSCRIPT)
	$(call logger-compile,"LD",$@)
	$(LD) $(LDFLAGS) -Wl,-Map=$(TARGET_MAP) -Wl,--gc-sections -fno-exceptions -fno-rtti $(OBJECTS) -o $@ -lm
	$(SIZE) $@

$(TARGET_BIN): $(TARGET)
	$(OBJCOPY) -v -O binary $< $@

all: $(TARGET)

clean:
	@rm -rf $(PROJECT_OUT)
	@echo "CLEAN OK"

download: $(TARGET_BIN)
	$(STFLASH) write $(TARGET_BIN) 0x8000000

.PHONY: clean download
