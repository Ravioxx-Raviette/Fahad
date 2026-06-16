from flask import Flask, request, jsonify
import torch
import torch.nn as nn
from torchvision import transforms, models
from PIL import Image
import io

app = Flask(__name__)

model = models.efficientnet_b0(pretrained=False)
num_features = model.classifier[1].in_features
model.classifier[1] = nn.Linear(num_features, 2)

state_dict = torch.load("models/deepfake_model.pt", map_location=torch.device('cpu'))
model.load_state_dict(state_dict)
model.eval()

transform = transforms.Compose([
    transforms.Resize((224, 224)),
    transforms.ToTensor(),
])

@app.route("/predict", methods=["POST"])
def predict():
    file = request.files["file"]
    img_bytes = file.read()
    image = Image.open(io.BytesIO(img_bytes)).convert("RGB")
    image = transform(image).unsqueeze(0)

    with torch.no_grad():
        outputs = model(image)
        _, predicted = torch.max(outputs, 1)
        label = "Real" if predicted.item() == 0 else "Fake"

    return jsonify({"result": label})

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000, debug=True)