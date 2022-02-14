#!/usr/bin/env bash
# Installing brew
echo "Downloading Brew..."
/usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"

echo "Updating Brew..."
brew update

# Adding brew to the path
echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
eval "$(/opt/homebrew/bin/brew shellenv)"

# install node-js and nvm
echo "Installing Node and NVM..."
brew install node
brew install nvm

# Adding nvm to path
export NVM_DIR="$HOME/.nvm"
[ -s "/usr/local/opt/nvm/nvm.sh" ] && . "/usr/local/opt/nvm/nvm.sh"
[ -s "/usr/local/opt/nvm/etc/bash_completion.d/nvm" ] && . "/usr/local/opt/nvm/etc/bash_completion.d/nvm"

# use node 16
nvm install 16
nvm use 16

# installing package dependencies
echo "Refreshing package dependencies..."
npm install

echo "Ready to Develop!"