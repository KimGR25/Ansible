#!/bin/bash

clear
cat << EOF

#################################################
    일반 DNS 서버 삭제
    0) work 변수 설정  
    1) inventory 파일 설정
    2) root dns삭제시 group_vars/root.yml 백업!
    3) remove_dns.sh 실행
#################################################

EOF

WORK=example

echo -n "삭제할 DNS서버 도메인을 입력해 주십시오(ex: example) : "
read domainname
echo
echo -n "삭제할 DNS서버 IP를 입력해 주십시오(ex: 192.168.10.11) : "
read dns_ip

while true
do
echo
echo "DomainName : $domainname.com "
echo "IP Address: $dns_ip "
echo -n '다음 정보가 맞습니까? (y|n) : '
read choice
case $choice in
    y) break ;;
    n) continue ;;
    *) echo "[ WARN ] 잘못 입력하셨습니다. " ;;
esac
done

# 1. templates/com.zone.j2 내용 삭제
sed -i "/$domainname/d" templates/com.zone.j2
# 2. templates/com.rev.j2 내용 삭제
sed -i "/$domainname/d" templates/com.rev.j2
# 3. group_vars/domain.yml 삭제
rm -f ~/dns/group_vars/$domainname.yml
# 4. restore_playbook.yml 파일 편집
cat << EOF > restore_playbook.yml
---
- name: DNS 서버 복원 작업
  hosts: $WORK
  tasks:
    - name: 복원 작업
      include_tasks: tasks/remove_dns.yml

    - name: 복원 작업 - net
      include_tasks: tasks/restore_net.yml

EOF
# 5. restore_playbook 실행
ansible-playbook restore_playbook.yml
