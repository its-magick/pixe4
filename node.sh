#!
# Define versions
INSTALL_NODE_VER=22
INSTALL_NVM_VER=0.40.1

# You can pass argument to this script --version 8
if [ "$1" = '--version' ]; then
	echo "==> Using specified node version - $2"
	INSTALL_NODE_VER=$2
fi

echo "==> Ensuring .bashrc exists and is writable"
touch ~/.bashrc

# Check if node is already installed
if command -v node &> /dev/null; then
	echo "==> Node.js is already installed. Skipping installation."
	node --version
	npm --version
else
	echo "==> Installing node version manager (NVM). Version $INSTALL_NVM_VER"
	# Removed if already installed
	rm -rf ~/.nvm
	# Unset exported variable
	export NVM_DIR=

	# Install nvm 
	curl -o- https://raw.githubusercontent.com/creationix/nvm/v$INSTALL_NVM_VER/install.sh | bash
	# Make nvm command available to terminal
	source ~/.nvm/nvm.sh

	echo "==> Installing node js version $INSTALL_NODE_VER"
	nvm install $INSTALL_NODE_VER

	echo "==> Make this version system default"
	nvm alias default $INSTALL_NODE_VER
	nvm use default

	echo "==> Checking for versions"
	nvm --version
	node --version
	npm --version

	echo "==> Print binary paths"
	which npm
	which node

	nvm cache clear
fi

npm install

node index.js