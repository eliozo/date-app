from flask import Flask, render_template
from datetime import datetime

app = Flask(__name__)

@app.get("/")
def index():
    # Initial value rendered by the server
    now_str = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    return render_template("index.html", now_str=now_str)

if __name__ == "__main__":
    app.run(debug=True)