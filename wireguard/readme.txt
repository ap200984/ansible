WireGuard - клиент-серверное приложение, работающее по UDP. Номер порат можно задавать.
Для установленя соединения достаочно одной из сторон иметь Белый адрес.

1. На сервере нужно добавить нового клиента
    wireguard-install.sh
    создается файл с настройками:
        cat /home/user/wg0-client-temp.conf
[Interface]
PrivateKey = eFqvTTN3lCv+PUmQ3cWpnSElq0XvbK/d/j4n7YxlO2Y=
Address = 10.66.66.8/32,fd42:42:42::8/128
DNS = 1.1.1.1,1.0.0.1

[Peer]
PublicKey = v2z1skxkx4HI6BCbrbxscOZpvHEGak1AkSpWrHe3+jQ=
PresharedKey = JMppS4CDS4YQobcnZZ6PIrNlK2FYOnTUEyza6+gTMS8=
Endpoint = 69.30.237.130:56685
AllowedIPs = 0.0.0.0/0,::/0


2. На стороне Микротика (клиента) нужно
    - создать интерфейс wg_client_vds4
        - все поля оставить пустыми, при нажатии OK ему будет сгенерирована пара ключей
            - открытый
            - закрытый
    - создать peer wg_client_vds4
        - имя: wg_client_vds4 (можно такое же как у интерфейса)
        - Public Key: взять из сгенерированного конфига для этого клиента
            (он же есть на сервере из значения SERVER_PUB_KEY в файле /etc/wireguard/params)
        - Private Key: оставить пустым
        - Endpoint: взять из сгенерированного конфига для этого клиента (только IP без :)
        - Endpoint Port: взять из сгенерированного конфига для этого клиента (только номер порта после :)
        - Allowed Address: 0.0.0.0/0
        - Preshared Key: взять из сгенерированного конфига для этого клиента
        - Persistent Keepalive: поставил 25 с, нодумаю, не обязательно
    - добавить IP адрес на интерфейсе wg_client_vds4, указанный в сгенерированном конфиге (Address)

3. На стороне сервера
    - открытй ключ необходимо прописать в конфигурации сервера (vds4)
        - файл /etc/wireguard/wg0.conf добавить
### Client temp
[Peer]
PublicKey = ZVp4hWCC6XRI9j2Mj8zAV70XYiFxUXRjttg1LjetVAo= (взят из интерфейса микротика при повторогом входе в него после создания)
PresharedKey = JMppS4CDS4YQobcnZZ6PIrNlK2FYOnTUEyza6+gTMS8= (сгенеррован изначально)
AllowedIPs = 10.66.66.8/32,fd42:42:42::8/128 (IP адрес, который нужно назначить этому клиенту)

    - перезапустить службу wg
        - sudo service wg-quick@wg0 restart


Ошибка в логах микротика:
    wg_client_vds4: [wg_client_vds4] v2z1skxkx4HI6BCbrbxscOZpvHEGak1AkSpWrHe3+jQ=: Handshake for peer did not complete after 5 seconds, retrying (try 2)




Соединенение двух Linux серверов:
vds4 # wg genkey > private
vds4 # wg pubkey < private
vds4 # ip link add wg0 type wireguard
vds4 # ip addr add 10.250.0.1/24 dev wg0
vds4 # wg set wg0 private-key ./private
vds4 # ip link set wg0 up
vds4 # wg
vds4 # wg set wg0 peer [public key from vsd5] allowed-ips 10.250.0.2/32 endpoint 217.144.189.206:56685
vds4 # wg



vds5 # wg genkey > private
vds5 # wg pubkey < private
vds5 # ip link add wg0 type wireguard
vds5 # ip addr add 10.250.0.2/24 dev wg0
vds5 # wg set wg0 private-key ./private
vds5 # ip link set wg0 up
vds5 # wg set wg0 peer [public key from vsd4] allowed-ips 10.250.0.1/32 endpoint 69.30.237.130:56685
vds5 # wg

