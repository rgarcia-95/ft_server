FROM debian:buster

# Autor
MAINTAINER rgarcia-@student.42madrid.com

# Inicialización Debian e Instalación
RUN apt-get update && \
	apt-get upgrade -y && \
	apt-get install -y wget nginx mariadb-server php-fpm php-mysql

# Configurar NGINX
COPY srcs/nginx-config /etc/nginx/sites-available/
RUN ln -fs /etc/nginx/sites-available/nginx-config /etc/nginx/sites-enabled/default

# Configurar Wordpress
RUN wget https://es.wordpress.org/latest-es_ES.tar.gz && \
	tar xzf latest-es_ES.tar.gz -C /var/www/html/
COPY srcs/wp-config.php /var/www/html/wordpress/

# Dar permisos para usar el protocolo SSL
RUN mkdir ~/mkcert && \
	cd ~/mkcert && \
	wget https://github.com/FiloSottile/mkcert/releases/download/v1.1.2/mkcert-v1.1.2-linux-amd64 && \
	mv mkcert-v1.1.2-linux-amd64 mkcert && \
	chmod +x mkcert && \
	./mkcert -install && \
	./mkcert localhost

# Configurar MySQL
COPY srcs/wordpress.sql .
RUN service mysql start && \
	echo "CREATE DATABASE wordpress; \
	GRANT ALL PRIVILEGES ON wordpress.* TO 'root'@'localhost'; \
	FLUSH PRIVILEGES; \
	UPDATE mysql.user SET plugin = 'mysql_native_password' WHERE user = 'root';" | mysql -u root && \
	mysql wordpress -u root --password = < wordpress.sql

# Configurar phpmyadmin
RUN wget https://files.phpmyadmin.net/phpMyAdmin/4.9.2/phpMyAdmin-4.9.2-all-languages.tar.gz && \
	mkdir /var/www/html/wordpress/phpmyadmin && \
	tar xzf phpMyAdmin-4.9.2-all-languages.tar.gz --strip-components=1 -C /var/www/html/wordpress/phpmyadmin
COPY srcs/config.inc.php /var/www/html/wordpress/phpmyadmin/

# Eliminar archivos que ya no son útiles
RUN rm latest-es_ES.tar.gz phpMyAdmin-4.9.2-all-languages.tar.gz wordpress.sql

# Dar permisos al usuario para usar NGINX
RUN chown -R www-data:www-data /var/www/* && \
	chmod -R 755 /var/www/*

# Configurar el puerto que va a utilizar el contenedor
EXPOSE 80 443

# Ejecutar acciones por defecto cuando se crea el contenedor
CMD service nginx start && \
	service mysql start && \
	service php7.3-fpm start && \
	sleep infinity