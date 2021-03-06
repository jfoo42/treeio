#!/bin/sh

sudo mkdir /opt/treeio
sudo chown $USER /opt/treeio
cd /opt/treeio

sudo apt-get install python-virtualenv python-pip python-dev unzip nginx libmemcached-dev memcached -y
# libs for pillow
sudo apt-get install libtiff5-dev libjpeg8-dev zlib1g-dev libfreetype6-dev liblcms2-dev libwebp-dev tcl8.6-dev tk8.6-dev python-tk -y
# ubuntu 12.04 see https://github.com/python-pillow/Pillow/blob/master/docs/installation.rst
# sudo apt-get install libtiff4-dev libjpeg8-dev zlib1g-dev libfreetype6-dev liblcms2-dev libwebp-dev tcl8.5-dev tk8.5-dev python-tk -y

virtualenv env
source env/bin/activate
pip install -U setuptools pip
pip install uwsgi pylibmc

wget https://github.com/treeio/treeio/archive/2.0.zip
unzip 2.0.zip
rsync -a treeio-2.0/ treeio
rm -rf treeio-2.0
rm 2.0.zip

pip install -r treeio/requirements.txt

# see http://www.postgresql.org/download/linux/ubuntu/
# this should work for lucid (10.04), precise (12.04), trusty (14.04) and utopic (14.10)
echo "deb http://apt.postgresql.org/pub/repos/apt/ "$(lsb_release -a | grep Codename | awk -F' ' '{print $2}')"-pgdg main" | sudo tee /etc/apt/sources.list.d/pgdg.list
wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -
sudo apt-get update
sudo apt-get install postgresql-9.4 libpq-dev -y
sudo -u postgres createuser --pwprompt treeio
sudo -u postgres createdb treeio --owner=treeio
pip install psycopg2
cd treeio
python manage.py collectstatic --noinput
python manage.py installdb

#add uwsgi to upstart
sudo ln -s /opt/treeio/treeio/install/upstart.conf  /etc/init/treeio.conf
sudo initctl reload-configuration
sudo start treeio
sudo ln -s /opt/treeio/treeio/install/nginx.conf  /etc/nginx/sites-enabled/treeio
sudo rm  /etc/nginx/sites-enabled/default
sudo nginx -s reload