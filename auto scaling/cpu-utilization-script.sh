#!/bin/bash

# Update the system
sudo yum update -y

# Install Python3 and pip
sudo yum install -y python3 python3-pip

# Install Flask, psutil, and Flask-Cors
sudo pip3 install flask psutil Flask-Cors

# Install stress via the EPEL repository
sudo yum install -y epel-release
sudo yum install -y stress

# Create the Flask app
cat << 'EOF' > /home/ec2-user/app.py
from flask import Flask, render_template, jsonify
from flask_cors import CORS
import psutil
import subprocess
app = Flask(__name__)
CORS(app)
stress_process = None
@app.route('/')
def index():
return render_template('index.html')
@app.route('/cpu_percentage')
def cpu_percentage():
return jsonify(cpu=psutil.cpu_percent(interval=2))
@app.route('/increase_load')
def increase_load():
global stress_process
if not stress_process:
stress_process = subprocess.Popen(['stress', '--cpu', '1'])
return jsonify(status='Load Increased')@app.route('/cancel_load')
def cancel_load():
global stress_process
if stress_process:
subprocess.run(['pkill', 'stress'])
stress_process = None
return jsonify(status='Load Cancelled')
if __name__ == "__main__":
app.run(host='0.0.0.0', port=80)
EOF

# Create the HTML template
mkdir -p /home/ec2-user/templates
cat << 'EOF' > /home/ec2-user/templates/index.html
<!DOCTYPE html>
<html>
<head>
<title>CloudFolks HUB - CPU Control</title>
<style>
body {
font-family: Arial, sans-serif;
text-align: center;
}
.branding {
color: #0077B5;
font-weight: bold;
font-size: 24px;
margin-top: 20px;
}
.meter {
height: 20px;
position: relative;
background: #555;
border-radius: 25px;
padding: 10px;
width: 70%;
margin: 0 auto;
box-shadow: inset 0 -1px 1px rgba(255, 255, 255, 0.3);
}
.meter > span {display: block;
height: 100%;
border-radius: 20px;
background-color: #33cc33;
position: relative;
overflow: hidden;
}
</style>
<script>
function updateCpuUsage() {
fetch('/cpu_percentage')
.then(response => response.json())
.then(data => {
const percentage = data.cpu;
document.getElementById('cpu-percentage-meter').style.width
= percentage + '%';
document.getElementById('cpu-text').innerText = percentage
+ '%';
});
}
function increaseLoad() {
fetch('/increase_load');
}
function cancelLoad() {
fetch('/cancel_load');
}
setInterval(updateCpuUsage, 2000);
</script>
</head>
<body onload="updateCpuUsage()">
<h2 class="branding">CloudFolks HUB</h2>
<a href="https://learn.bhaveshatara.live" target="_blank"
style="margin-bottom: 20px; display: block;">Visit our Website</a>
<div class="meter">
<span id="cpu-percentage-meter"></span>
</div>
<p id="cpu-text" style="margin-top: 20px;">Loading...</p><button onclick="increaseLoad()">Increase CPU Load</button>
<button onclick="cancelLoad()">Cancel Load</button>
<p style="margin-top: 20px;">Powered by <span
class="branding">CloudFolks HUB</span></p>
</body>
</html>
EOF

# Set the correct permissions
chown -R ec2-user:ec2-user /home/ec2-user/

# Start the Flask app and log output
nohup /usr/bin/python3 /home/ec2-user/app.py >
/home/ec2-user/flask_app.log 2>&1 &

