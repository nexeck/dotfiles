#!/usr/bin/env sh

# if the privilegesCLI (SAP Privileges.app) is available, request admin rights
command -v privilegesCLI >/dev/null 2>&1 && privilegesCLI --add

exit 0
