# This isn't gonna be the actual script. Just putting stuff here ti remind myself
# how to use ports.

port = Port.open({:spawn, "python scripts/predict.py"}, [:binary])

Port.command(port, "priv/static/uploads/live_view_upload-1622126802-545213873721679-6.jpeg\n")
