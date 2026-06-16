# backend_server.py
import os
import io
import sys
import json
from collections import OrderedDict

from flask import Flask, request, jsonify
from flask_cors import CORS
from PIL import Image
import numpy as np
import torch
from torch import nn
from torchvision import transforms, models
import onnxruntime as ort

# ========== CONFIG ==========
BASE_DIR = os.path.dirname(os.path.abspath(__file__))
MODELS_DIR = os.path.join(BASE_DIR, "models")
PT_MODEL_NAME = "deepfake_model.pt"   # <- put your file here
ONNX_MODEL_NAME = "deepfake_model.onnx"
PT_MODEL_PATH = os.path.join(MODELS_DIR, PT_MODEL_NAME)
ONNX_MODEL_PATH = os.path.join(MODELS_DIR, ONNX_MODEL_NAME)

# If your model used a different arch, set it here e.g. "efficientnet_v2_s" or "resnet50"
DEFAULT_ARCH = "efficientnet_v2_s"
NUM_CLASSES = 2  # real/fake

# ========== UTILITIES ==========
def is_state_dict(obj):
    if not isinstance(obj, dict):
        return False
    # Heuristic: keys are strings and values are tensors/ndarrays
    for k, v in list(obj.items())[:10]:
        if not isinstance(k, str):
            return False
    return True

def strip_prefix_if_present(state_dict, prefix="model."):
    keys = list(state_dict.keys())
    if any(k.startswith(prefix) for k in keys):
        new = OrderedDict()
        for k, v in state_dict.items():
            if k.startswith(prefix):
                new[k[len(prefix):]] = v
            else:
                new[k] = v
        return new
    return state_dict

def try_build_default_model(num_classes=2):
    # Build a default torchvision model to load the state_dict into.
    # You can change this to the architecture you used.
    if DEFAULT_ARCH == "efficientnet_v2_s":
        model = models.efficientnet_v2_s(weights=None)
        # adjust classifier if needed (EffNet v2 classifier layout may differ by torchvision version)
        try:
            model.classifier[1] = nn.Linear(model.classifier[1].in_features, num_classes)
        except Exception:
            # fallback: replace whole classifier
            model.classifier = nn.Sequential(nn.AdaptiveAvgPool2d(1), nn.Flatten(), nn.Linear(model.classifier[1].in_features, num_classes))
    elif DEFAULT_ARCH == "resnet50":
        model = models.resnet50(weights=None)
        model.fc = nn.Linear(model.fc.in_features, num_classes)
    else:
        raise ValueError(f"DEFAULT_ARCH {DEFAULT_ARCH} not handled. Edit the script to add it.")
    return model

# ========== LOAD / PREPARE MODEL ==========
def load_pt_model(pt_path):
    if not os.path.exists(pt_path):
        raise FileNotFoundError(f"PyTorch file not found: {pt_path}")

    print("Loading:", pt_path)
    obj = torch.load(pt_path, map_location=torch.device("cpu"))

    # Case A: full model object was saved (torch.save(model))
    if hasattr(obj, "eval") and isinstance(obj, nn.Module):
        print("Detected: full PyTorch model object.")
        model = obj
        model.eval()
        return model

    # Case B: a dict saved
    if isinstance(obj, dict):
        # Common pattern: {'state_dict': {...}} or direct state_dict
        if "state_dict" in obj and isinstance(obj["state_dict"], dict):
            state_dict = obj["state_dict"]
            print("Found nested 'state_dict' inside .pt file.")
        else:
            state_dict = obj

        if not is_state_dict(state_dict):
            raise RuntimeError("Loaded dict doesn't look like a state_dict.")

        # Fix common prefixes
        state_dict = strip_prefix_if_present(state_dict, prefix="module.")
        state_dict = strip_prefix_if_present(state_dict, prefix="model.")

        # Try to build default model and load
        try:
            model = try_build_default_model(num_classes=NUM_CLASSES)
            model.load_state_dict(state_dict, strict=False)
            model.eval()
            print("State dict loaded into default architecture (strict=False).")
            return model
        except Exception as e:
            print("Failed to load state_dict into default architecture:", e)
            # As fallback, try strict=False with strict mapping after attempts
            model = try_build_default_model(num_classes=NUM_CLASSES)
            model.load_state_dict(state_dict, strict=False)
            model.eval()
            return model

    raise RuntimeError("Unrecognized .pt format. Please tell me how you saved the model (full model or state_dict).")

# Convert to ONNX
def export_to_onnx(model, onnx_path, opset=18):
    print("Exporting model to ONNX:", onnx_path)
    dummy = torch.randn(1, 3, 224, 224)
    os.makedirs(os.path.dirname(onnx_path), exist_ok=True)
    torch.onnx.export(
        model,
        dummy,
        onnx_path,
        input_names=["input"],
        output_names=["output"],
        dynamic_axes={"input": {0: "batch_size"}, "output": {0: "batch_size"}},
        opset_version=opset,
    )
    print("ONNX saved.")

# ========== PREPROCESS ==========
preprocess_transform = transforms.Compose([
    transforms.Resize((224, 224)),
    transforms.ToTensor(),
    transforms.Normalize([0.485,0.456,0.406],[0.229,0.224,0.225])
])

def preprocess_image_bytes(image_bytes):
    img = Image.open(io.BytesIO(image_bytes)).convert("RGB")
    t = preprocess_transform(img).unsqueeze(0).numpy().astype(np.float32)
    return t

# ========== SERVER SETUP ==========
app = Flask(__name__)
CORS(app)

# Ensure models dir exists
os.makedirs(MODELS_DIR, exist_ok=True)

# Load model (try to reuse ONNX if present)
model = None
ort_session = None

if os.path.exists(ONNX_MODEL_PATH):
    print("ONNX model found, loading ONNX Runtime session.")
    ort_session = ort.InferenceSession(ONNX_MODEL_PATH)
else:
    # try to load .pt and export to ONNX
    if not os.path.exists(PT_MODEL_PATH):
        raise FileNotFoundError(f"Need either {ONNX_MODEL_PATH} or {PT_MODEL_PATH}. Place your .pt in {MODELS_DIR}.")
    model = load_pt_model(PT_MODEL_PATH)
    # Export to ONNX for faster inference with minimal deps
    try:
        export_to_onnx(model, ONNX_MODEL_PATH)
        ort_session = ort.InferenceSession(ONNX_MODEL_PATH)
    except Exception as e:
        print("ONNX export failed; will use PyTorch for inference. Error:", e)
        ort_session = None

@app.route("/predict", methods=["POST"])
def predict():
    if 'file' not in request.files:
        return jsonify({"error": "No image provided"}), 400
    file = request.files['file']
    try:
        input_tensor = preprocess_image_bytes(file.read())  # shape (1,3,224,224), np.float32

        if ort_session is not None:
            outputs = ort_session.run(None, {"input": input_tensor})
            logits = np.array(outputs[0])[0]
            probs = np.exp(logits) / np.sum(np.exp(logits))
            real_p, fake_p = float(probs[0]), float(probs[1])
        else:
            # Use PyTorch model directly
            x = torch.from_numpy(input_tensor)
            with torch.no_grad():
                out = model(x)
                logits = out.detach().cpu().numpy()[0]
                probs = np.exp(logits) / np.sum(np.exp(logits))
                real_p, fake_p = float(probs[0]), float(probs[1])

        return jsonify({
            "real": round(real_p * 100, 2),
            "fake": round(fake_p * 100, 2)
        })
    except Exception as e:
        return jsonify({"error": str(e)}), 500

if __name__ == "__main__":
    print("Starting server. Models dir:", MODELS_DIR)
    print("PT path:", PT_MODEL_PATH)
    print("ONNX path:", ONNX_MODEL_PATH)
    app.run(host="0.0.0.0", port=5000, debug=True)
