#!/bin/bash

clear
cat << EOF

############################################
    일반 DNS 서버 설정 (ex: example.com)  
    0) work 변수 설정  
    1) inventory 파일 설정
    2) installdns.sh 실행
############################################

EOF
############################################
work=soldesk
############################################
while true
do
echo -n '설정하고 싶은 도메인을 입력하십시오 (ex: example) : '
read split_domain 

echo -n '설정하고 싶은 DNS서버 IP를 입력하십시오 (ex: 192.168.10.10) : '
read ip

echo
echo "DomainName : $split_domain.com "
echo "IP Address: $ip "
echo -n '다음 정보가 맞습니까? (y|n) : '
read choice
case $choice in
    y) break ;;
    n) continue ;;
    *) echo "[ WARN ] 잘못 입력하셨습니다. " ;;
esac
done

# 1. templates/com.zone.j2 내용 추가
short_domain=$split_domain

cat << EOF >> templates/com.zone.j2
$short_domain         IN  NS  ns1.$short_domain
ns1.$short_domain     IN  A   $ip
EOF

# 2. templates/com.rev.j2 내용 추가
last_ip=$(echo $ip | awk -F. '{print $4}')
cat << EOF >> templates/com.rev.j2
$last_ip              IN  PTR         ns1.$short_domain.com. 
EOF

# 3. group_vars/domain.yml
cat << EOF > group_vars/$short_domain.yml
---
domain_dns_revers_num: $last_ip
domain: $short_domain.com
split_domain: $short_domain

EOF

# 4. playbook_domain.yml 파일 편집

cat << EOF > playbook_domain.yml
---
- name: DNS 서버 설정 - {{ domain }}
  hosts: $work
  gather_facts: no
  tasks:
    - name: DNS 초기 설정
      include_tasks: tasks/dns_init_configuration.yml

    - name: DNS 확장 설정
      include_tasks: tasks/dns_domain_configuration.yml

    - name: DNS Client 설정
      include_tasks: tasks/dns_client_configuration.yml

  handlers:
    - name: restart named
      service:
        name: named
        state: restarted

EOF

# 5. playbook
ansible-playbook playbook.yml