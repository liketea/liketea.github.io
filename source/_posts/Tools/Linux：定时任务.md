---
title: Linux：定时任务
date: 2020-06-16 17:01:09
tags:
    - "Linux"
categories:
    - "Linux"
---

![](https://likeitea-1257692904.cos.ap-guangzhou.myqcloud.com/liketea_blog/20200616144400.png)

在 Linux 里配置定时任务主要是通过 `cron` 和 `crontab` 两个程序来控制:

1. `cron`：是定期执行指定命令的守护程序，负责配置的解析和处理；
2. `crontab`：是用户维护定时任务配置文件的命令；

## Cron

```sh
$ man cron
NAME
       cron - daemon to execute scheduled commands

SYNOPSIS
       cron [-n | -p | -s | -m<mailcommand>]
       cron -x [ext,sch,proc,pars,load,misc,test,bit]

DESCRIPTION
       Cron should be started from /etc/rc.d/init.d or /etc/init.d
... ...
```

### 启动 Cron
`Cron` 可以通过 `/etc/rc.d/init.d` 或 `/etc/init.d` 路径下的 `crond` 脚本随系统开机自动启动，也可以通过以下方式手动启动：

```
# 如果系统有 service 命令
/sbin/service crond start    # 启动服务
/sbin/service crond stop     # 关闭服务
/sbin/service crond restart  # 重启服务
/sbin/service crond reload   # 重新载入配置

# 如果系统没有 service 命令
$sudo /etc/init.d/cron start
$sudo /etc/init.d/cron stop
$sudo /etc/init.d/cron restart
```

查看服务是否已经在运行：

```sh
$ ps -ax | grep cron 
13651 ?        Ss     5:50 /usr/sbin/crond -n
48218 pts/17   S+     0:00 grep --color=auto cron
```

### 配置文件
`Cron` 平时处于休眠状态，每分钟醒来一次，检查以下路径中配置文件的最新修改时间，并重新加载已改变的内容，所以即使修改了 crontab 文件也没有必要重新启动 cron 守护程序：

- `/var/spool/cron/user`：用户调度的配置文件，不同用户可以拥有独立的 `crontab` 配置文件，每个文件以对应用户名命名，事实上，当用户通过 `crontab` 命令修改定时任务配置时，修改的就是这里的文件；

```sh
[root@100-117-147-160 /etc/rc.d/init.d]# cd /var/spool/cron
[root@100-117-147-160 /var/spool/cron]# ll
总用量 12
-rw------- 1 root root    0  7月  4 2017 adm
-rw------- 1 root root    0  7月  4 2017 arpwatch
-rw------- 1 root root    0  7月  4 2017 bin
-rw------- 1 root root    0  7月  4 2017 daemon
-rw------- 1 root root    0  7月  4 2017 dbus
-rw------- 1 root root    0  7月  4 2017 ftp
-rw------- 1 root root    0  7月  4 2017 games
-rw------- 1 root root    0  7月  4 2017 gopher
-rw------- 1 root root    0  7月  4 2017 haldaemon
-rw------- 1 root root    0  7月  4 2017 halt
-rw------- 1 root root    0  7月  4 2017 lp
-rw------- 1 root root    0  7月  4 2017 mail
-rw------- 1 mqq  mqq  6711  6月 16 13:19 mqq

[root@100-117-147-160 /var/spool/cron]# cat mqq
#wsd script manage add by hansli
# add by tafServer, mon_taf_node.sh 
* * * * *  (cd /usr/local/app/taf/tafnode/util/ && ./mon_taf_node.sh >> /usr/local/app/taf/app_log/taf/tafnode/mon_taf_node.log) >/dev/null 2>&1
... ...
```

- `/etc/crontab`：系统调度的配置文件，

```sh
# 配置crond任务运行的环境变量
## SHELL变量指定了系统要使用哪个shell
SHELL=/bin/bash
## PATH变量指定了系统执行命令的路径
PATH=/sbin:/bin:/usr/sbin:/usr/bin
## MAILTO变量指定了crond的任务执行信息将通过电子邮件发送给root用户，如果MAILTO变量的值为空，则表示不发送任务执行信息给用户
MAILTO=root
## HOME变量指定了在执行命令或者脚本时使用的主目录
HOME=/

# run-parts 遍历文件夹内的所有配置文件
51 * * * * root run-parts /etc/cron.hourly
24 7 * * * root run-parts /etc/cron.daily
22 4 * * 0 root run-parts /etc/cron.weekly
42 4 1 * * root run-parts /etc/cron.monthly
```

- `/etc/cron.daily`：作为系统管理员，定时任务模式大都是每小时触发、每日触发、每周触发等，这时可以不用配置 cron 项，只需要把需要定时执行的脚本放在对应的 `/etc/cron.daily`、`/etc/cron.hourly` 之类的文件下就行了，事实上很多系统自身需要的定时任务就是这么做的；
- `/etc/cron.d/`：有时，某些处理特定任务的进程也希望能够创建定时任务，比如编写或安装的第三方任务，这些任务不希望依附于某一个用户，而希望拥有独立的配置文件，方便修改和卸载。这时就可以新建一个 cron 配置文件，放置于`/etc/cron.d/` 目录下，进行统一管理，像 csf，lfd 这类进程就是这样做的。


## Crontab
### Crontab 命令格式
命令格式：

```sh
$ man crontab
NAME：为不同用户维护 crontab 文件
    crontab - maintain crontab files for individual users

SYNOPSIS
    crontab [-u user] file 表示将 file 做为crontab 的任务列表文件并载入 crontab。如果在命令行中没有指定这个文件，crontab命令将接受标准输入（键盘）上键入的命令，并将它们载入crontab。会用 file 中的内容覆盖当前配置文件，不推荐

    crontab [-u user] [-l | -r | -e | -s] [-i]
    default operation is replace
    -u, --user   用来设定某个用户的crontab服务
    edit some other user's crontab
    -l, --list   显示某个用户的crontab文件内容，如果不指定用户，则表示显示当前用户的crontab文件内容
    list user's crontab
    -r, --remove 从/var/spool/cron目录中删除某个用户的crontab文件，如果不指定用户，则默认删除当前用户的crontab文件，千万别乱运行crontab -r。它从Crontab目录（/var/spool/cron）中删除用户的Crontab文件。删除了该用户的所有crontab都没了。
    delete user's crontab
    -e, --edit   编辑某个用户的crontab文件内容。如果不指定用户，则表示编辑当前用户的crontab文件
    edit user's crontab
    -s, --show   显示有 crontab 任务的所有用户
    show all user who have a crontab
    -i, --ask    在删除用户的crontab文件时给确认提示
    prompt before deleting user's crontab

DESCRIPTION
    Crontab 是一个程序，用于让用户以传统 cron 格式安装、卸载或列出定时作业
    Crontab is the program used to let users install, deinstall or list recurrent jobs in the legacy cron format.
    每个用户都可以有自己的 crontab文件，尽管这些是 /var/spool/cron/crontab` 中的文件，但通常不会直接编辑它们
    Each user can have their own crontab, and though these are files in /var/spool/cron/crontabs, they are not intended to be edited directly.
    These jobs are then automatically translated in systemd Timers & Units by systemd-crontab-generator.

    FILES：Crontab 通过 /etc/cron.allow 和 /etc/cron.deny 来控制用户权限，只有在白名单里的用户才能使用 crontab 命令，在黑名单里的用户无法使用 crontab 命令，原则上两个文件不能同时存在，如果同时存在，只有白名单会生效，如果两个文件都不存在，根据 linux 版本不同，有的默认所有用户都有权限，有的默认只有 root 用户才有权限
    /var/spool/cron/crontabs
    Directory for users crontabs.
    /etc/cron.allow
    list of users that can use crontab
    /etc/cron.deny
    list of users that aren't allowed to use crontab
    (by default, only root can use crontab)
    
```

示例：

```sh
[running]mqq@100.117.147.160:/etc/cron.d$ crontab -l
#wsd script manage add by hansli
# add by tafServer, mon_taf_node.sh 
* * * * *  (cd /usr/local/app/taf/tafnode/util/ && ./mon_taf_node.sh >> /usr/local/app/taf/app_log/taf/tafnode/mon_taf_node.log) >/dev/null 2>&1


# added by hangruan for wenzhen_union_test
# 10 03 * * * (python /usr/local/app/dataanalysis/daf_proj/DafFramework.py --module=IhInqueryMessageChart --jobs=union --dest=test --source=test >/dev/null 2>&1)
* * * * * sleep 10; sh /data/jaysonding/address/port_monitor.sh >> /tmp/port_monitor.log 2>&1

[running]mqq@100.117.147.160:/etc/cron.d$ crontab -e
打开 vim 编辑器
```

### crontab 文件格式
用户所建立的crontab文件中，每一行都代表一项任务，每行的每个字段代表一项设置，它的格式共分为六个字段，前五段是时间设定段，第六段是要执行的命令段，格式如下：

![](https://likeitea-1257692904.cos.ap-guangzhou.myqcloud.com/liketea_blog/20200616144728.png)

在以上各个字段中，还可以使用以下特殊字符：

1. "*"代表所有的取值范围内的数字，如月份字段为*，则表示1到12个月；
2. "/"代表每一定时间间隔的意思，如分钟字段为*/10，表示每10分钟执行1次。
3. "-"代表从某个区间范围，是闭区间。如“2-5”表示“2,3,4,5”，小时字段中0-23/2表示在0~23点范围内每2个小时执行一次。
4. ","分散的数字（不一定连续），如1,2,3,4,7,9。

示例：

```
# 每分钟执行一次 myCommand
* * * * * myCommand

# 每隔两天的上午8点到11点的第3和第15分钟执行
3,15 8-11 */2  *  * myCommand

# 每周六、周日的1 : 10重启smb
10 1 * * 6,0 /etc/init.d/smb restart

# 晚上11点到早上7点之间，每隔一小时重启smb
0 23-7 * * * /etc/init.d/smb restart
```

说明：可以通过[Crontab表达式执行时间验证](http://www.atool9.com/crontab.php)来验证写好的Crontab表达式的实际执行效果

![](https://likeitea-1257692904.cos.ap-guangzhou.myqcloud.com/liketea_blog/20200616200641.png)

### 其他问题

#### 执行结果重定向
每条任务调度执行完毕，系统都会将任务输出信息通过电子邮件的形式发送给当前系统用户，这样日积月累，日志信息会非常大，可能会影响系统的正常运行，因此，将每条任务进行重定向处理非常重要。 例如，可以在crontab文件中设置如下形式，忽略日志输出:

```
# 忽略日志输出 2>&1 代表执行结果及错误信息
0 */3 * * * /usr/local/apache2/apachectl restart >/dev/null 2>&1
# 也可重定向到指定文件
0 */3 * * * /usr/local/apache2/apachectl restart >/dev/my.log 2>&1
```
#### 环境变量问题
有时我们创建了一个crontab，但是这个任务却无法自动执行，而手动执行这个任务却没有问题，这种情况一般是由于在crontab文件中没有配置环境变量引起的。

在crontab文件中定义多个调度任务时，需要特别注环境变量的设置，因为我们手动执行某个任务时，是在当前shell环境下进行的，程序当然能找到环境变量，而系统自动执行任务调度时，是不会加载任何环境变量的，因此，就需要在crontab文件中指定任务运行所需的所有环境变量，这样，系统执行任务调度时就没有问题了。

不要假定cron知道所需要的特殊环境，它其实并不知道。所以你要保证在shelll脚本中提供所有必要的路径和环境变量，除了一些自动设置的全局变量。所以注意如下3点：

（1）脚本中涉及文件路径时写全局路径；

（2）脚本执行要用到java或其他环境变量时，通过source命令引入环境变量，如:

```sh
cat start_cbp.sh
!/bin/sh
source /etc/profile
export RUN_CONF=/home/d139/conf/platform/cbp/cbp_jboss.conf
/usr/local/jboss-4.0.5/bin/run.sh -c mev &
```

（3）当手动执行脚本OK，但是crontab死活不执行时,很可能是环境变量惹的祸，可尝试在crontab中直接引入环境变量解决问题。如:

```sh
0 * * * * . /etc/profile;/bin/sh /var/www/java/audit_no_count/bin/restart_audit.sh
```

#### 系统级任务调度与用户级任务调度
系统级任务调度主要完成系统的一些维护操作，用户级任务调度主要完成用户自定义的一些任务，可以将用户级任务调度放到系统级任务调度来完成（不建议这么做），但是反过来却不行，root用户的任务调度操作可以通过”crontab –uroot –e”来设置，也可以将调度任务直接写入/etc/crontab文件，需要注意的是，如果要定义一个定时重启系统的任务，就必须将任务放到/etc/crontab文件，即使在root用户下创建一个定时重启系统的任务也是无效的。

#### 杂项
1. 在crontab中%是有特殊含义的，表示换行的意思。如果要用的话必须进行转义%，如经常用的date ‘+%Y%m%d’在crontab里是不会执行的，应该换成date ‘+%Y%m%d’；
2. 新创建的cron job，不会马上执行，至少要过2分钟才执行。如果重启cron则马上执行；
3. 当crontab失效时，可以尝试/etc/init.d/crond restart解决问题。或者查看日志看某个job有没有执行/报错tail -f /var/log/cron；
4. 千万别乱运行crontab -r。它从Crontab目录（/var/spool/cron）中删除用户的Crontab文件。删除了该用户的所有crontab都没了；
5. 更新系统时间时区后需要重启cron；


## 参考

- [Linux 下定时任务配置深入理解](https://blog.mythsman.com/post/5d2d4b62a2005d74040ef7d3/)
- [Linux 命令搜索](https://wangchujiang.com/linux-command/c/crontab.html)
- [Crontab表达式执行时间验证](http://www.atool9.com/crontab.php)
- [Linux Tools Quick Tutorial](https://linuxtools-rst.readthedocs.io/zh_CN/latest/tool/crontab.html)