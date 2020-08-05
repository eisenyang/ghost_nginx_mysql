init(){
    GHOST_USER='ghostcms'
    GHOST_DIR='/var/www/ghost'
    GHOST_URL="http://localhost:8088"
    DB_HOST="localhost"
    DB_PASSWD=$(print_random_string 20)
}

print_random_string()
{
  # $1 = new tring length
  date +%s | sha256sum | base64 |head -c $1;echo
}

cook-ghost_user_and_dir(){
    adduser $GHOST_USER --gecos 'none'
    usermod -aG sudo  $GHOST_USER

    mkdir -p $GHOST_DIR
    chown $GHOST_USER:$GHOST_USER $GHOST_DIR
    chmod 775 $GHOST_DIR
}

install-begin(){
    apt update -y 
    apt upgrade -y 

    apt install -y curl nginx 
    ufw allow 'Nginx Full'

    apt install -y mysql-server
    mysql -e "ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY '$DB_PASSWD';flush privileges;"

    curl -sL https://deb.nodesource.com/setup_12.x | sudo -E bash
    apt install -y nodejs

    npm install ghost-cli@latest -g
}

install-end(){
    [ -n "$GHOST_DIR" ] && rm $GHOST_DIR/* -rf
    [ -s $GHOST_DIR/.ghost-cli ] && rm $GHOST_DIR/.ghost-cli
    
    local code="ghost install \
        --dir $GHOST_DIR \
        --url $GHOST_URL \
        --db mysql \
        --dbhost $DB_HOST \
        --dbuser 'root' \
        --dbpass $DB_PASSWD \
        --ip 0.0.0.0 \
        --auto"
    echo $code > /tmp/install.sh
    chown $GHOST_USER:$GHOST_USER /tmp/install.sh && chmod +x /tmp/install.sh
    su $GHOST_USER -s "/tmp/install.sh"
}

# --------- main
echo ---------[ Install ghost + nginx + mysql ]
init
cook-ghost_user_and_dir
install-begin
install-end
echo ---------[ Done ]
echo ---------[ mysql root password: $DB_PASSWD ]
