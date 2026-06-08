#!/bin/sh

source /koolshare/scripts/base.sh
eval `dbus export cfddns`
alias echo_date='echo 【$(TZ=UTC-8 date -R +%Y年%m月%d日\ %X)】:'
CONFIG_FILE="/tmp/cfddns_status.json"
LOG_FILE="/tmp/upload/cfddns_log.txt"
LOGTIME=$(TZ=UTC-8 date -R "+%Y-%m-%d %H:%M:%S")

# 默认值设置
[ "$cfddns_method" = "" ] && cfddns_method="auto"
[ "$cfddns_ttl" = "" ] && cfddns_ttl="1"
[ "$cfddns_retry" = "" ] && cfddns_retry="3"
get_type="A"

if [ "$cfddns_name" = "@" ];then
	cfddns_name_domain=$cfddns_domain
else
	cfddns_name_domain=$cfddns_name.$cfddns_domain
fi

get_bol() {
	case "$cfddns_proxied" in
		1)
			echo "true"
		;;
		0|*)
			echo "false"
		;;
	esac
}

get_record_response() {
	curl -kLs --connect-timeout 10 --max-time 15 \
	-X GET "https://api.cloudflare.com/client/v4/zones/$cfddns_zid/dns_records?type=$get_type&name=${cfddns_name_domain}&order=type&direction=desc&match=all" \
	-H "X-Auth-Email: $cfddns_email" \
	-H "X-Auth-Key: $cfddns_akey" \
	-H "Content-type: application/json" 2>/dev/null
}

update_record() {
	curl -kLs --connect-timeout 10 --max-time 15 \
	-X PUT "https://api.cloudflare.com/client/v4/zones/$cfddns_zid/dns_records/$cfddns_id" \
	-H "X-Auth-Email: $cfddns_email" \
	-H "X-Auth-Key: $cfddns_akey" \
	-H "Content-Type: application/json" \
	--data '{"type":"'$get_type'","name":"'${cfddns_name_domain}'","content":"'$update_to_ip'","ttl":'$cfddns_ttl',"proxied":'$(get_bol)'}' 2>/dev/null
}

# 改进的本地IP获取函数 - 使用临时文件避免子进程问题
get_local_ip() {
	local ip=""
	local method_used=""
	local temp_file="/tmp/cfddns_ip_temp.txt"
	
	# 清空临时文件
	> $temp_file
	
	# 定义测试函数 - 直接赋值全局变量
	try_method() {
		local cmd="$1"
		local result=""
		
		result=$(eval "$cmd" 2>/dev/null | head -n1 | grep -oE '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' | head -n1)
		
		if [ -n "$result" ]; then
			# 排除内网IP
			case "$result" in
				10.*|172.1[6-9].*|172.2[0-9].*|172.3[0-1].*|192.168.*|127.*)
					return 1
					;;
			esac
			echo "$result|$cmd" > $temp_file
			return 0
		fi
		return 1
	}
	
	# 如果用户指定了自定义方法且不是auto
	if [ "$cfddns_method" != "auto" ] && [ -n "$cfddns_method" ]; then
		# 清理用户命令中的换行和多余空格
		clean_cmd=$(echo "$cfddns_method" | tr -d '\n\r' | sed 's/[[:space:]]\+/ /g')
		try_method "$clean_cmd"
		if [ $? -eq 0 ] && [ -s $temp_file ]; then
			read line < $temp_file
			echo "$line"
			rm -f $temp_file
			return 0
		fi
	fi
	
	# 自动模式：依次尝试多种方法
	local methods="
curl -s --connect-timeout 5 --max-time 10 ifconfig.me
curl -s --connect-timeout 5 --max-time 10 icanhazip.com
curl -s --connect-timeout 5 --max-time 10 ipinfo.io/ip
curl -s --connect-timeout 5 --max-time 10 api.ipify.org
curl -s --connect-timeout 5 --max-time 10 checkip.amazonaws.com
curl -s --connect-timeout 5 --max-time 10 ip.3322.net
wget -q -O - --timeout=10 ipv4.icanhazip.com
"
	
	echo "$methods" | while IFS= read -r cmd; do
		[ -z "$cmd" ] && continue
		try_method "$cmd"
		if [ $? -eq 0 ] && [ -s $temp_file ]; then
			return 0
		fi
		sleep 1
	done
	
	# 尝试从ppp接口获取
	for iface in ppp0 ppp1 ppp1.2 ppp0.2; do
		ip=$(ifconfig $iface 2>/dev/null | grep -oE 'inet addr:[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' | grep -v '127.0.0.1' | head -n1 | cut -d':' -f2)
		if [ -n "$ip" ]; then
			case "$ip" in
				10.*|172.1[6-9].*|172.2[0-9].*|172.3[0-1].*|192.168.*|127.*)
					continue
					;;
			esac
			echo "$ip|interface $iface" > $temp_file
			break
		fi
	done
	
	if [ -s $temp_file ]; then
		read line < $temp_file
		echo "$line"
		rm -f $temp_file
		return 0
	fi
	
	rm -f $temp_file
	return 1
}

# JSON解析函数
parse_json_id() {
	local json="$1"
	echo "$json" | sed 's/},{/\n/g' | grep '"type":"A"' | sed 's/.*"id":"\([^"]*\)".*/\1/' | head -n1
}

parse_json_content() {
	local json="$1"
	echo "$json" | sed 's/},{/\n/g' | grep '"type":"A"' | sed 's/.*"content":"\([^"]*\)".*/\1/' | head -n1
}

get_info(){
	local retry_count=0
	local max_retry=3
	
	while [ $retry_count -lt $max_retry ]; do
		get_type="A"
		cfddns_result=$(get_record_response)
		
		if echo "$cfddns_result" | grep -q '"success":true'; then
			cfddns_id=$(parse_json_id "$cfddns_result")
			current_ip=$(parse_json_content "$cfddns_result")
			
			if [ -n "$current_ip" ] && [ -n "$cfddns_id" ]; then
				echo_date "CloudFlare IP为 $current_ip"
				break
			fi
		fi
		
		retry_count=$((retry_count + 1))
		if [ $retry_count -lt $max_retry ]; then
			echo_date "获取CloudFlare记录失败，${retry_count}秒后重试..."
			sleep $retry_count
		fi
	done
	
	if [ -z "$current_ip" ]; then
		dbus set cfddns_status="【$LOGTIME】：获取IPV4解析记录错误！"
		echo_date "错误：无法获取CloudFlare记录"
		return 1
	fi
	
	# 获取本地IP
	retry_count=0
	localip=""
	local method_info=""
	
	while [ $retry_count -lt $cfddns_retry ]; do
		localip_result=$(get_local_ip)
		if [ $? -eq 0 ] && [ -n "$localip_result" ]; then
			localip=$(echo "$localip_result" | cut -d'|' -f1)
			method_info=$(echo "$localip_result" | cut -d'|' -f2-)
			# 验证IP格式正确
			if echo "$localip" | grep -qE '^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$'; then
				echo_date "本地IP为 $localip (来源: $method_info)"
				break
			else
				echo_date "获取到无效IP格式: $localip"
				localip=""
			fi
		fi
		
		retry_count=$((retry_count + 1))
		if [ $retry_count -lt $cfddns_retry ]; then
			echo_date "获取本地IP失败，${retry_count}秒后重试..."
			sleep $retry_count
		fi
	done
	
	if [ -z "$localip" ]; then
		dbus set cfddns_status="【$LOGTIME】：获取本地IP错误！"
		echo_date "错误：无法获取本地公网IP"
		return 1
	fi
	
	return 0
}

get_local_ipv6(){
	local ipv6=""
	
	# 尝试多个IPv6服务
	for url in "ipv6.icanhazip.com" "v6.ident.me" "api64.ipify.org"; do
		ipv6=$(curl -s --connect-timeout 5 --max-time 10 "http://$url" 2>/dev/null | grep -oE '^([a-fA-F0-9:]+)$' | head -n1)
		if [ -n "$ipv6" ]; then
			# 排除链路本地地址
			case "$ipv6" in
				fe80:*|::1)
					continue
					;;
			esac
			localipv6="$ipv6"
			return 0
		fi
	done
	
	# 尝试从本地接口获取
	ipv6=$(ifconfig 2>/dev/null | grep -oE 'inet6 addr: [a-fA-F0-9:]+' | grep -v 'fe80:' | head -n1 | cut -d' ' -f3)
	if [ -n "$ipv6" ]; then
		localipv6="$ipv6"
		return 0
	fi
	
	return 1
}

get_info_ipv6(){
	if ! get_local_ipv6; then
		echo_date "没有IPV6地址！"
		return 1
	fi
	
	echo_date "本地IPV6为 $localipv6"
	
	get_type="AAAA"
	cfddns_result=$(get_record_response)
	
	if echo "$cfddns_result" | grep -q '"success":true'; then
		cfddns_id=$(echo "$cfddns_result" | sed 's/},{/\n/g' | grep '"type":"AAAA"' | sed 's/.*"id":"\([^"]*\)".*/\1/' | head -n1)
		current_ipv6=$(echo "$cfddns_result" | sed 's/},{/\n/g' | grep '"type":"AAAA"' | sed 's/.*"content":"\([^"]*\)".*/\1/' | head -n1)
		
		if [ -n "$current_ipv6" ]; then
			echo_date "CloudFlare IPV6为 $current_ipv6"
			return 0
		fi
	fi
	
	dbus set cfddns_status="【$LOGTIME】：获取IPV6解析记录错误！"
	return 1
}

update_ip(){
	local retry_count=0
	local max_retry=3
	
	while [ $retry_count -lt $max_retry ]; do
		update_result=$(update_record)
		
		if echo "$update_result" | grep -q '"success":true'; then
			echo_date "更新成功！"
			return 0
		else
			echo_date "更新失败，尝试第 $((retry_count + 1)) 次..."
			err_msg=$(echo "$update_result" | grep -o '"message":"[^"]*"' | head -c 200)
			[ -n "$err_msg" ] && echo_date "错误详情: $err_msg"
		fi
		
		retry_count=$((retry_count + 1))
		if [ $retry_count -lt $max_retry ]; then
			sleep $((retry_count * 2))
		fi
	done
	
	echo_date "更新失败！请检查设置！"
	return 1
}

check_update(){
	echo_date "======================================"
	echo_date "CloudFlare DDNS更新启动!"
	
	# 检查必要参数
	if [ -z "$cfddns_email" ] || [ -z "$cfddns_akey" ] || [ -z "$cfddns_zid" ] || [ -z "$cfddns_domain" ]; then
		echo_date "错误：请填写完整的CloudFlare账号信息！"
		dbus set cfddns_status="【$LOGTIME】：配置信息不完整！"
		return 1
	fi
	
	# IPv4更新
	if get_info; then
		if [ "$localip" = "$current_ip" ]; then
			echo_date "两个IP相同，跳过更新！"
			dbus set cfddns_status="【$LOGTIME】：IP地址：$localip 未发生变化，跳过！"
		else
			update_to_ip=$localip
			echo_date "两个IP不相同，开始更新！"
			if update_ip; then
				dbus set cfddns_status="【$LOGTIME】：IP地址：$localip 更新成功！"
			else
				dbus set cfddns_status="【$LOGTIME】：IP地址更新失败！"
			fi
		fi
	fi
	
	# IPv6更新（如启用）
	if [ "$cfddns_ipv6" = "1" ]; then
		echo_date "--------------------------------------"
		if get_info_ipv6; then
			if [ "$localipv6" = "$current_ipv6" ]; then
				echo_date "两个IPV6相同，跳过更新！"
			else
				update_to_ip=$localipv6
				echo_date "两个IPV6不相同，开始更新！"
				update_ip
			fi
		fi
	fi
	
	echo_date "======================================"
}

# ====================================used by init or cru====================================
case $1 in
start)
	if [ "$cfddns_enable" == "1" ]; then
		logger "[软件中心]: 启动CloudFlare DDNS！"
		
		# 等待网络就绪
		sleep 5
		
		echo_date "======================================" >> $LOG_FILE
		echo_date "检测到网络拨号..." >> $LOG_FILE
		check_update >> $LOG_FILE
	else
		logger "[软件中心]: CloudFlare DDNS未设置开机启动，跳过！"
	fi
	;;
update)
	check_update >> $LOG_FILE
	;;
esac

# ====================================submit by web====================================
case $2 in
1)
	echo "" > $LOG_FILE
	http_response "$1"
	
	# 创建设备启动链接
	if [ "$cfddns_enable" == "1" ]; then
		[ ! -L "/koolshare/init.d/S99cfddns.sh" ] && ln -sf /koolshare/scripts/cfddns_config.sh /koolshare/init.d/S99cfddns.sh
		
		# 添加定时任务
		if [ -n "$cfddns_refresh_time" ] && [ "$cfddns_refresh_time" -gt 0 ] 2>/dev/null; then
			sed -i '/cfddns/d' /var/spool/cron/crontabs/* >/dev/null 2>&1
			cru a cfddns "0 */$cfddns_refresh_time * * * /koolshare/scripts/cfddns_config.sh update"
		fi
		
		echo_date "======================================" >> $LOG_FILE
		check_update >> $LOG_FILE
	else
		echo_date "关闭CloudFlare DDNS!" >> $LOG_FILE
		sed -i '/cfddns/d' /var/spool/cron/crontabs/* >/dev/null 2>&1
	fi
	echo XU6J03M6 >> $LOG_FILE
	;;
esac