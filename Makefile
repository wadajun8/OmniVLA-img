#--------------------------------------------------------------------
# Copyright (c) 2025 Junya Wada
# This software is released under the MIT License.
# --------------------------------------------------------------------

.PHONY: all setup run build rebuild push clean

all: run

IMAGE_NAME=wadajun8/omnivla-img:v2
CONTAINER_NAME=omnivla_container

# ==========================================================
# 1. Setup (Inference Models)
# ==========================================================
setup:
	@echo "Downloading model checkpoints..."
	# Clone into the specific directory
	git clone git@github.com:wadajun8/OmniVLA.git || true
	cd OmniVLA && git clone https://huggingface.co/NHirose/omnivla-original || true
	cd OmniVLA && git clone https://huggingface.co/NHirose/omnivla-original-balance || true
	cd OmniVLA && git clone https://huggingface.co/NHirose/omnivla-finetuned-cast || true
	@echo "Downloading training dependencies..."
	# Clone dependencies to the project root (../OmniVLA-img/)
	git clone https://github.com/NHirose/Learning-to-Drive-Anywhere-with-MBRA.git || true
	git clone https://github.com/huggingface/lerobot.git || true
	# MBRA Weights (Inside OmniVLA source dir)
	mkdir -p OmniVLA/OmniVLA_internal
	cd OmniVLA/OmniVLA_internal && git clone https://huggingface.co/NHirose/MBRA/ || true
	cd OmniVLA && ln -sf OmniVLA_internal/MBRA MBRA
	@echo "Setup Done!"

# ==========================================================
# 2. Run
# ==========================================================
run:
	docker run --gpus all -it --rm \
		--name $(CONTAINER_NAME) \
		--net=host \
		--shm-size=16g \
		-v $(CURDIR)/OmniVLA:/workspace/OmniVLA \
		-v $(CURDIR)/Learning-to-Drive-Anywhere-with-MBRA:/workspace/Learning-to-Drive-Anywhere-with-MBRA \
		-v $(CURDIR)/lerobot:/workspace/lerobot \
		$(IMAGE_NAME)

# ==========================================================
# 3. Management
# ==========================================================
build:
	docker build -t $(IMAGE_NAME) .

rebuild:
	docker build --no-cache -t $(IMAGE_NAME) .

push:
	docker push $(IMAGE_NAME)

clean:
	rm -rf __pycache__
