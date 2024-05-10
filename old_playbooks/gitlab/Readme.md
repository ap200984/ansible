# Default login: root
# Пароль можно узнать после установки
 sudo docker exec -it gitlab bash -c "grep Password /etc/gitlab/initial_root_password"

# либо задать через переменну GITLAB_ROOT_PASSWORD