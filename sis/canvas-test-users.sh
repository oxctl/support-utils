#!/bin/bash
#
# Generates some Canvas test users.

curl -s https://randomuser.me/api/?results=500 |\
  jq -r '
  ["user_id", "login_id", "first_name", "last_name", "email", "status"],
  (.results[] | [.login.uuid, .login.username, .name.first, .name.last, .email, "active"])
  | @csv'
