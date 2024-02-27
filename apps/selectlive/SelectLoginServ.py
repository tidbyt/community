from flask import Flask, request, jsonify
import requests
import logging
import os
from OpenSSL import SSL

# a very simple HTTPS server for obtaining a session cookie
# from select.live, to work around this issue:
#   https://github.com/tidbyt/pixlet/pull/1008
# intended to be hosted by replit -- rename as main.py before deploying

app = Flask('app')

# configure Flask's logger to output to stderr
logHandler = logging.StreamHandler()
logHandler.setLevel(logging.INFO)
app.logger.addHandler(logHandler)

# during development, it's nice to use the simple password "knockknock"
# and substitute it for the real password of an actual system  
DEFAULT_PWD = '<ACTUAL USER PASSWORD>'

@app.route('/')
def index():
  return 'to login, post to /login with `email` and `pwd`'


@app.route('/login', methods=['POST'])
def login():
  email = request.form.get('email')
  pwd = request.form.get('pwd')

  # check for missing credentials
  if not email or not pwd:
    app.logger.error("missing auth info")
    return jsonify({"error": "Authorization error"}), 401

  # temporary
  if pwd == "knockknock":
    pwd = DEFAULT_PWD

  # POST the request to select.live/login
  response = requests.post('https://select.live/login',
                           data={
                               'email': email,
                               'pwd': pwd
                           })

  # check for a cookie
  cookies = response.cookies.get_dict()
  if cookies:
    # include the cookie in the response to the client
    reply = jsonify({"message": "success"})
    reply.headers.set(
        'Set-Cookie',
        '; '.join([f"{key}={value}" for key, value in cookies.items()]))
    return reply

  app.logger.error(f'login failed. user \'{email}\'')
  return jsonify({"error": "Login failed"}), 401


if __name__ == "__main__":
  app.run(host='0.0.0.0', port=8080)
