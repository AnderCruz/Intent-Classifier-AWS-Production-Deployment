#!/bin/bash

# Directory
# update packages
# Git clone - Download
# Python Virtual Env
# Install the Python Dependencies
# Run Model
# WSGI -> Linux systemd service
# Nginx -> Linux systemd service
# Enable services

#!/bin/bash
set -e

# =========================
# CONFIG
# =========================
APP_DIR=/opt/intent-app
REPO_URL="https://github.com/iam-veeramalla/Intent-classifier-model.git"

# =========================
# UPDATE SYSTEM
# =========================
apt update -y
apt install -y git python3 python3-venv python3-pip nginx

# =========================
# PREP APP DIRECTORY
# =========================
rm -rf $APP_DIR
mkdir -p $APP_DIR

# clone cleanly
git clone $REPO_URL $APP_DIR

cd $APP_DIR

# =========================
# PYTHON ENV
# =========================
python3 -m venv .venv
source .venv/bin/activate

pip install --upgrade pip

# install dependencies
pip install -r requirements.txt

# ensure gunicorn exists
pip install gunicorn

# =========================
# (OPTIONAL) TRAIN MODEL
# =========================
if [ -f "model/train.py" ]; then
    python model/train.py
fi

# =========================
# SYSTEMD SERVICE
# =========================
cat >/etc/systemd/system/intent_gunicorn.service <<EOF
[Unit]
Description=Intent Classifier API (Gunicorn)
After=network.target

[Service]
User=root
WorkingDirectory=$APP_DIR
ExecStart=$APP_DIR/.venv/bin/python -m gunicorn \
    --workers 3 \
    --bind 127.0.0.1:6000 \
    wsgi:application

Restart=always

[Install]
WantedBy=multi-user.target
EOF

# =========================
# NGINX CONFIG
# =========================
cat >/etc/nginx/sites-available/intent_app <<EOF
server {
    listen 80;
    server_name _;

    location / {
        proxy_pass http://127.0.0.1:6000;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    }
}
EOF

# enable nginx site
ln -sf /etc/nginx/sites-available/intent_app /etc/nginx/sites-enabled/intent_app

# remove default site to avoid conflict
rm -f /etc/nginx/sites-enabled/default || true

# =========================
# START SERVICES
# =========================
systemctl daemon-reload
systemctl enable intent_gunicorn
systemctl restart intent_gunicorn

systemctl enable nginx
systemctl restart nginx

echo "Deployment completed successfully!"
echo "API running on port 80 (Nginx) -> 6000 (Gunicorn)"