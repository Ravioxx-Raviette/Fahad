# train.py
import os
import argparse
from datasets import load_dataset, concatenate_datasets
from torch.utils.data import Dataset, DataLoader, random_split
from torchvision import transforms, models
from PIL import Image
import torch
from torch import nn
from tqdm import tqdm
import random
import numpy as np

# ------------------------------
# Dataset Wrapper
# ------------------------------
class HFImageDataset(Dataset):
    def __init__(self, hf_ds, transform=None):
        self.ds = hf_ds
        self.transform = transform

    def __len__(self):
        return len(self.ds)

    def _get_label(self, item):
        for key in ("label", "labels", "class_label", "target", "is_fake"):
            if key in item:
                return item[key]
        for key in item.keys():
            if key.lower().find("label") != -1:
                return item[key]
        if "metadata" in item and isinstance(item["metadata"], dict):
            for k in ("label", "is_fake", "class"):
                if k in item["metadata"]:
                    return item["metadata"][k]
        raise KeyError("No label field found in dataset item.")

    def __getitem__(self, idx):
        item = self.ds[idx]
        img = item.get("image", None)
        if img is None:
            for k in item.keys():
                if isinstance(item[k], Image.Image):
                    img = item[k]
                    break
        if img is None and "image_path" in item:
            img = Image.open(item["image_path"]).convert("RGB")
        if img is None:
            raise RuntimeError("No image found in dataset item.")

        label = self._normalize_label(self._get_label(item))
        if self.transform:
            img = self.transform(img)
        return img, label

    @staticmethod
    def _normalize_label(l):
        if isinstance(l, dict):
            if "is_fake" in l:
                return 1 if l["is_fake"] else 0
            if "label" in l:
                return HFImageDataset._normalize_label(l["label"])
        if isinstance(l, (int, float)):
            return int(l)
        if isinstance(l, str):
            s = l.strip().lower()
            if s in ("real", "genuine", "0"):
                return 0
            if s in ("fake", "synthetic", "ai", "1"):
                return 1
            try:
                return int(s)
            except:
                pass
        raise ValueError(f"Unknown label value: {l}")

# ------------------------------
# Model Loader
# ------------------------------
def get_model_by_name(name="resnet50", num_classes=2, pretrained=False):
    if name == "resnet50":
        m = models.resnet50(pretrained=pretrained)
        m.fc = nn.Linear(m.fc.in_features, num_classes)
        return m
    if name == "efficientnet_v2_s":
        m = models.efficientnet_v2_s(weights=None)
        m.classifier[1] = nn.Linear(m.classifier[1].in_features, num_classes)
        return m
    if name == "mobilenet_v3_large":
        m = models.mobilenet_v3_large(pretrained=pretrained)
        m.classifier[3] = nn.Linear(m.classifier[3].in_features, num_classes)
        return m
    raise ValueError("Unknown model name: " + name)

def try_load_existing_state(model, path):
    if not os.path.exists(path):
        print(f"[load] file not found: {path}")
        return False
    try:
        state = torch.load(path, map_location="cpu")
        if isinstance(state, dict):
            for k in ("model_state_dict", "state_dict", "model_state"):
                if k in state:
                    model.load_state_dict(state[k], strict=False)
                    print(f"[load] loaded nested '{k}' with strict=False")
                    return True
        model.load_state_dict(state, strict=False)
        print("[load] loaded state_dict (strict=False)")
        return True
    except Exception as e:
        print("[load] error:", e)
        return False

# ------------------------------
# Training Loop
# ------------------------------
def train_loop(model, train_loader, val_loader, device, epochs, lr, out_path):
    model.to(device)
    optimizer = torch.optim.Adam(model.parameters(), lr=lr)
    criterion = nn.CrossEntropyLoss()
    best_val = -1.0

    for epoch in range(1, epochs + 1):
        model.train()
        running_loss, correct, total = 0.0, 0, 0
        pbar = tqdm(train_loader, desc=f"Train Epoch {epoch}/{epochs}")
        for imgs, labels in pbar:
            imgs, labels = imgs.to(device), labels.to(device)
            optimizer.zero_grad()
            outs = model(imgs)
            if isinstance(outs, (tuple, list)):
                outs = outs[0]
            loss = criterion(outs, labels)
            loss.backward()
            optimizer.step()

            running_loss += loss.item() * imgs.size(0)
            preds = torch.argmax(outs, dim=1)
            correct += (preds == labels).sum().item()
            total += labels.size(0)
            pbar.set_postfix({"loss": running_loss / total, "acc": correct / total})

        train_acc = correct / total if total else 0
        model.eval()
        v_correct, v_total, v_loss = 0, 0, 0.0
        with torch.no_grad():
            for imgs, labels in val_loader:
                imgs, labels = imgs.to(device), labels.to(device)
                outs = model(imgs)
                if isinstance(outs, (tuple, list)):
                    outs = outs[0]
                loss = criterion(outs, labels)
                v_loss += loss.item() * imgs.size(0)
                preds = torch.argmax(outs, dim=1)
                v_correct += (preds == labels).sum().item()
                v_total += labels.size(0)
        val_acc = v_correct / v_total if v_total else 0
        print(f"Epoch {epoch}: val_acc={val_acc:.4f}")

        if val_acc > best_val:
            best_val = val_acc
            os.makedirs(os.path.dirname(out_path) or ".", exist_ok=True)
            torch.save(model.state_dict(), out_path)
            print(f"[saved] best model -> {out_path} (val_acc={val_acc:.4f})")

    print("Training finished. Best val acc:", best_val)

# ------------------------------
# Main
# ------------------------------
def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--existing-model", type=str, default="deepfake_model.pt")
    parser.add_argument("--output", type=str, default="models/deepfake_model_finetuned.pt")
    parser.add_argument("--epochs", type=int, default=5)
    parser.add_argument("--batch-size", type=int, default=16)
    parser.add_argument("--lr", type=float, default=1e-4)
    parser.add_argument("--device", type=str, default="cuda" if torch.cuda.is_available() else "cpu")
    parser.add_argument("--from-scratch", action="store_true")
    parser.add_argument("--model-arch", type=str, default="resnet50")
    parser.add_argument("--seed", type=int, default=42)
    args = parser.parse_args()

    torch.manual_seed(args.seed)
    random.seed(args.seed)
    np.random.seed(args.seed)
    device = torch.device(args.device)

    # ✅ Use environment variable for safe cache
    cache_dir = os.environ.get("HF_DATASETS_CACHE", None)
    print(f"[cache] Using: {cache_dir}")

    print("[dataset] loading date3k2/raw_real_fake_images ...")
    ds1 = load_dataset("date3k2/raw_real_fake_images", split="train", cache_dir=cache_dir)
    print("[dataset] loading InfImagine/FakeImageDataset ...")
    ds2 = load_dataset("InfImagine/FakeImageDataset", split="train", cache_dir=cache_dir)

    combined = concatenate_datasets([ds1, ds2])
    combined = combined.shuffle(seed=args.seed)
    print(f"[dataset] combined size before limit: {len(combined)}")

    # ✅ Limit dataset size to prevent overload
    max_samples = 5000
    if len(combined) > max_samples:
        combined = combined.select(range(max_samples))
    print(f"[dataset] combined size after limit: {len(combined)}")

    val_frac = 0.1
    val_size = int(len(combined) * val_frac)
    train_size = len(combined) - val_size
    train_hf, val_hf = random_split(combined, [train_size, val_size], generator=torch.Generator().manual_seed(args.seed))

    transform = transforms.Compose([
        transforms.Resize((224, 224)),
        transforms.CenterCrop((224, 224)),
        transforms.ToTensor(),
        transforms.Normalize(mean=[0.485, 0.456, 0.406], std=[0.229, 0.224, 0.225])
    ])
    train_ds = HFImageDataset(train_hf, transform)
    val_ds = HFImageDataset(val_hf, transform)

    train_loader = DataLoader(train_ds, batch_size=args.batch_size, shuffle=True, num_workers=2)
    val_loader = DataLoader(val_ds, batch_size=args.batch_size, shuffle=False, num_workers=2)

    print(f"[model] using arch: {args.model_arch}")
    model = get_model_by_name(args.model_arch, num_classes=2, pretrained=False)

    if not args.from_scratch and args.existing_model:
        if not try_load_existing_state(model, args.existing_model):
            print("[model] failed to load existing weights; starting fresh")

    train_loop(model, train_loader, val_loader, device, args.epochs, args.lr, args.output)

if __name__ == "__main__":
    main()
