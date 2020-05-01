#!/bin/sh
echo -e "\e[1;31m ____  __  __  ____  __     ____     ____     __"
echo -e "\e[1;32m|  _ \|  \/  |/ ___| \ \   / /\ \   / /\ \   / /"
echo -e "\e[1;33m| |_) | |\/| | |      \ \ / /  \ \ / /  \ \ / / "
echo -e "\e[1;34m|  __/| |  | | |___    \ V /    \ V /    \ V /  "
echo -e "\e[1;35m|_|   |_|  |_|\____|    \_/      \_/      \_/   "
echo -e "\e[0m"
echo -e "\n\e[1;31mThis script will install the pmc wp environment inside of a virtual machine using vvv \e[0m"
echo -e "\n\e[1;33m@NOTES\e[0m:"
echo -e "- If re-running this script you can skip the clone/install of VVV"
echo -e "- If running this script for the first time it will download VVV and provision it for you automatically"
echo -e "- If you are on windows then you need to install wsl ( https://docs.microsoft.com/en-us/windows/wsl/install-win10 )"
echo -e "- Most answers will be 1 for yes or 2 for no"
echo -e "- Please make sure you're connected to the internet with a good connection this will take a while"
echo -e "- When prompted for a password this is to auth git repositories. Enter an app password for that step"
echo -e "\nIt looks like you're in `pwd`"
echo -e "\nYour current repo is:"
echo -e "`git remote -v`"

# Make sure vagrant is installed
if hash vagrant 2>/dev/null; then
  echo -e "✔ Vagrant installed ($(vagrant --version))"
  echo -e "If you have issues with the vagrant version please check the software requirements: https://varyingvagrantvagrants.org/docs/en-US/installation/software-requirements/"
else
  echo -e "Vagrant not found."
  echo -e "Download Vagrant at https://www.vagrantup.com/downloads.html and run again."
  exit 1
fi

echo -e "\nClone VVV or CONTINUE without cloning?"
echo -e "\n@NOTE: If it's not your first time running this script or if VVV is already cloned then navigate to VVV, re-run this script and skip this step"
select yn in "clone" "continue"; do case $yn in
  clone ) git clone https://github.com/Varying-Vagrant-Vagrants/VVV.git && cd VVV && break;;
  continue ) break;;
esac
done

echo -e "\nCopy the config.yml for VVV into config/config.yml ( this will overwrite if existing ) or continue without copying?"
select yn in "yes" "continue"; do case $yn in
  yes ) curl -o config/config.yml https://raw.githubusercontent.com/penske-media-corp/pmc-vvv/master/config.yml && break;;
  continue ) break;;
esac
done

echo -e "\nProvision vagrant machine i.e. vagrant up --provision?"
echo -e "\nIf you've already provisioned and/or there are no changes to config/config.yml then you can probably skip this step"
select yn in "yes" "no"; do case $yn in
  yes )
  vagrant up --provision
  if [ $? -eq 0 ]; then
    break;
  else
    echo "Vagrant provisioning failed or needs to run again."
    echo "Exiting now."
    exit 1
    fi;;
  no ) break;;
esac
done

# Clone the repos
echo -e "\nInstalling pmc core tech..."
git config --global credential.helper cache
git config --global credential.helper 'cache --timeout=999999'
if [ ! -d "www/phpcs/CodeSniffer/Standards/pmc-codesniffer" ]; then git clone https://bitbucket.org/penskemediacorp/pmc-codesniffer.git www/phpcs/CodeSniffer/Standards/pmc-codesniffer; fi
# Takes the current standard defined in provisioner here: https://github.com/Varying-Vagrant-Vagrants/VVV/blob/develop/provision/provision.sh#L852 and adds pmc standards
vagrant ssh -- -t "phpcs --config-show | grep installed_paths | sed 's/\://g'|sed 's/.*/\0,.\/CodeSniffer\/Standards\/pmc-codesniffer\/PmcWpVip\/,.\/CodeSniffer\/Standards\/pmc-codesniffer\/PmcLaravel\//' | xargs phpcs --config-set"
# This standard is overwritable obviously at the project level
vagrant ssh -- -t "phpcs --config-set default_standard PmcWpVip" # PmcWpVip rules inherit WP VIP standard see the repo for more information or to add a new rule by submitting a PR

echo -e "\nInstalling coretech..."
if [ ! -d "www/pmc/coretech/pmc-core" ]; then git clone https://bitbucket.org/penskemediacorp/pmc-core.git www/pmc/coretech/pmc-core; fi
if [ ! -d "www/pmc/coretech/pmc-core-2017" ]; then git clone https://bitbucket.org/penskemediacorp/pmc-core-2017.git www/pmc/coretech/pmc-core-2017; fi
if [ ! -d "www/pmc/coretech/pmc-core-v2" ]; then git clone https://bitbucket.org/penskemediacorp/pmc-core-v2.git www/pmc/coretech/pmc-core-v2; fi
if [ ! -d "www/pmc/coretech/pmc-plugins" ]; then git clone https://bitbucket.org/penskemediacorp/pmc-plugins.git www/pmc/coretech/pmc-plugins; fi

echo -e "\nInstalling go plugins... According to https://wpvip.com/documentation/vip-go/local-vip-go-development-environment/#vvv-for-vip-go-development"
if [ ! -d "www/pmc/vipgo/pmc-vip-go-plugins" ]; then git clone https://bitbucket.org/penskemediacorp/pmc-vip-go-plugins.git www/pmc/vipgo/pmc-vip-go-plugins; fi
if [ ! -d "www/pmc/vipgo/vip-go-mu-plugins-built" ]; then git clone https://github.com/automattic/vip-go-mu-plugins-built.git www/pmc/vipgo/vip-go-mu-plugins-built && git -C www/pmc/vipgo/vip-go-mu-plugins-built submodule update --init --recursive; fi

echo -e "\nInstalling wpcom plugins..."
if [ ! -d "www/pmc/wpcom/wordpress-vip-plugins" ]; then git clone https://bitbucket.org/penskemediacorp/wordpress-vip-plugins.git www/pmc/wpcom/wordpress-vip-plugins; fi
if [ ! -d "www/pmc/wpcom/vip-wpcom-mu-plugins" ]; then git clone https://github.com/automattic/vip-wpcom-mu-plugins.git www/pmc/wpcom/vip-wpcom-mu-plugins && git -C www/pmc/wpcom/vip-wpcom-mu-plugins submodule update --init --recursive; fi

echo -e "\nBuild amp for go?"
select yn in "yes" "no"; do case $yn in
  yes ) vagrant ssh -- -t 'cd /srv/www/pmc/vipgo/pmc-vip-go-plugins/amp && composer install && npm install && npm run build --force' && break;; #@NOTE: --force is needed so amp can actually build itself
  no ) break;;
esac
done

echo -e "\nBuild amp for wpcom?"
select yn in "yes" "no"; do case $yn in
  yes ) vagrant ssh -- -t 'cd /srv/www/pmc/wpcom/vip-wpcom-mu-plugins/amp-wp && composer install && npm install && npm run build --force' && break;; #@NOTE: --force is needed so amp can actually build itself
  no ) break;;
esac
done

echo -e "\nInstall dev tools into vagrant?" # @NOTE: Not all of these tools are not needed but are useful to have inside of the dev machine feel free to submit a PR if you think any new tools should be added/removed from this list
select yn in "yes" "no"; do case $yn in
  yes ) vagrant ssh -- -t "sudo npm install -g coolaj86/yaml2json && \
    sudo apt-get update && sudo apt-get install -y \
    awscli \
    git-extras \
    httpie \
    jq \
    neovim \
    ranger \
    siege \
    tig \
    vifm" && break;;
  no ) break;;
  esac
done

echo -e "\nInstall vagrant-scp plugin? ( you pretty much have to say yes if it's not already installed)"
echo "https://github.com/invernizzi/vagrant-scp"
select yn in "yes" "no"; do case $yn in
  yes ) vagrant plugin install vagrant-scp && break;;
  no ) break;;
  esac
done


echo -e "\nInstall wpcom sites?"
select yn in "yes" "no"; do case $yn in
  yes )
    # mkdirs
    vagrant ssh -- -t "mkdir -p /srv/www/wpcom/public_html/wp-content/mu-plugins /srv/www/wpcom/public_html/wp-content/themes/vip /srv/www/wpcom/public_html/wp-content/themes/vip/plugins"

    # wpcom-plugins symlink
    vagrant ssh -- -t "ln -svf /srv/www/pmc/wpcom/wordpress-vip-plugins/* /srv/www/wpcom/public_html/wp-content/themes/vip/plugins"

    # mu-plugins symlink
    vagrant ssh -- -t "ln -svf /srv/www/pmc/wpcom/vip-wpcom-mu-plugins/* /srv/www/wpcom/public_html/wp-content/mu-plugins"

    # coretech symlink
    vagrant ssh -- -t "ln -svf /srv/www/pmc/coretech/* /srv/www/wpcom/public_html/wp-content/themes/vip"
    vagrant ssh -- -t "ln -svf /srv/www/pmc/coretech/pmc-core* /srv/www/wpcom/public_html/wp-content/themes"

    vagrant scp config/config.yml :/tmp/config.yml #@NOTE: if more than one vagrant default then we may have to specify location before : in scp command

    # install primary theme
    wpcom_sites=$(vagrant ssh -- -t "yaml2json /tmp/config.yml | jq -r '.sites.wpcom.hosts[]'") # pull directly from config
    for site in $wpcom_sites
      do
        site=`echo $site | sed 's/\\r//g'` # cleanup on sting \r maybe a @TODO later into the wpcom_sites var instead
        # Clone the theme
        if [[ "wpcom" != ${site%%.*} && ! -d "www/wpcom/public_html/wp-content/themes/${site%%.*}" ]]; then git clone "https://bitbucket.org/penskemediacorp/${site%%.*}" "www/wpcom/public_html/wp-content/themes/${site%%.*}"; fi

        # create sites
        vagrant ssh -- -t "wp site create --slug=${site%%.*} --path=/srv/www/wpcom/public_html"

        # activate themes on sites
        vagrant ssh -- -t "wp theme activate ${site%%.*} --url=$site --path=/srv/www/wpcom/public_html"
    done
      # @TODO:
    # https://github.com/Varying-Vagrant-Vagrants/custom-site-template/blob/aa1680b3cb93b5f38055e56118f697a19128b78b/provision/vvv-init.sh#L61
    # install content from s3
    break;;
  no ) break;;
  esac
done

echo -e "\nInstall vipgo sites?"
select yn in "yes" "no"; do case $yn in
  yes )
    echo -e "\nDetecting PMC VIP-GO sites in www/pmc-* ..."
    for i in $(ls -d www/pmc-* | xargs -n1 basename)
      do
      # mkdirs
      vagrant ssh -- -t "mkdir -p /srv/www/$i/public_html/wp-content/mu-plugins /srv/www/$i/public_html/wp-content/themes/vip"

      # delete wordpress-importer as it's installed by provisioner and causes fatal on mu-plugins installation
      vagrant ssh -- -t "wp plugin delete wordpress-importer --path=/srv/www/$i/public_html"

      # setup default user 2fa bypass as per: https://wpvip.com/documentation/vip-go/local-vip-go-development-environment/#step-5-creating-an-admin-user-via-wp-cli
      vagrant ssh -- -t "wp user create pmcdev pmc@pmc.test --user_pass=pmcdev --role=administrator --path=/srv/www/$i/public_html"

      # vipgo-plugins symlink
      vagrant ssh -- -t "ln -svf /srv/www/pmc/vipgo/pmc-vip-go-plugins/* /srv/www/$i/public_html/wp-content/plugins"

      # mu-plugins symlink
      vagrant ssh -- -t "ln -svf /srv/www/pmc/vipgo/vip-go-mu-plugins-built/* /srv/www/$i/public_html/wp-content/mu-plugins"

      # coretech symlink
      vagrant ssh -- -t "ln -svf /srv/www/pmc/coretech/* /srv/www/$i/public_html/wp-content/themes/vip"
      vagrant ssh -- -t "ln -svf /srv/www/pmc/coretech/pmc-core* /srv/www/$i/public_html/wp-content/themes"
      vagrant ssh -- -t "ln -svf /srv/www/pmc/coretech/pmc-plugins /srv/www/$i/public_html/wp-content/plugins"

      # install primary theme
      if [ ! -d www/$i/public_html/wp-content/themes/$i ]; then git clone https://bitbucket.org/penskemediacorp/$i.git www/$i/public_html/wp-content/themes/$i; fi

      # Activate our main theme
      vagrant ssh -- -t "wp theme activate $i --path=/srv/www/$i/public_html"
      #@TODO: # https://github.com/Varying-Vagrant-Vagrants/custom-site-template/blob/aa1680b3cb93b5f38055e56118f697a19128b78b/provision/vvv-init.sh#L61 # install content from s3
    done;
    break;;
  no ) break;;
  esac
done

echo -e "\nYou should now have ALL WP PMC sites setup in VVV"
echo -e "\nNavigate To: vvv.test in your browser to see what you can do"