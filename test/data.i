   #[1]FreeBSD Handbook [2]Chapter30.Firewalls [3]30.3.PF
   [4]30.5.IPFILTER (IPF) [5]Copyright

                 30.4. IPFW
   [6]Prev  Chapter 30. Firewalls  [7]Next
     __________________________________________________________________

30.4. IPFW

   IPFW is a stateful firewall written for FreeBSD which supports both
   IPv4 and IPv6. It is comprised of several components: the kernel
   firewall filter rule processor and its integrated packet accounting
   facility, the logging facility, NAT, the [8]dummynet(4) traffic shaper,
   a forward facility, a bridge facility, and an ipstealth facility.

   FreeBSD provides a sample ruleset in /etc/rc.firewall which defines
   several firewall types for common scenarios to assist novice users in
   generating an appropriate ruleset. IPFW provides a powerful syntax
   which advanced users can use to craft customized rulesets that meet the
   security requirements of a given environment.

   This section describes how to enable IPFW, provides an overview of its
   rule syntax, and demonstrates several rulesets for common configuration
   scenarios.

30.4.1. Enabling IPFW

   IPFW is included in the basic FreeBSD install as a kernel loadable
   module, meaning that a custom kernel is not needed in order to enable
   IPFW.

   For those users who wish to statically compile IPFW support into a
   custom kernel, refer to the instructions in [9]Chapter 9, Configuring
   the FreeBSD Kernel. The following options are available for the custom
   kernel configuration file:
options    IPFIREWALL                   # enables IPFW
options    IPFIREWALL_VERBOSE           # enables logging for rules with log key
word
options    IPFIREWALL_VERBOSE_LIMIT=5   # limits number of logged packets per-en
try
options    IPFIREWALL_DEFAULT_TO_ACCEPT # sets default policy to pass what is no
t explicitly denied
options    IPDIVERT                     # enables NAT

   To configure the system to enable IPFW at boot time, add the following
   entry to /etc/rc.conf:
firewall_enable="YES"

   To use one of the default firewall types provided by FreeBSD, add
   another line which specifies the type:
firewall_type="open"

   The available types are:
     * open: passes all traffic.
     * client: protects only this machine.
     * simple: protects the whole network.
     * closed: entirely disables IP traffic except for the loopback
       interface.
     * workstation: protects only this machine using stateful rules.
     * UNKNOWN: disables the loading of firewall rules.
     * filename: full path of the file containing the firewall ruleset.

   If firewall_type is set to either client or simple, modify the default
   rules found in /etc/rc.firewall to fit the configuration of the system.

   Note that the filename type is used to load a custom ruleset.

   An alternate way to load a custom ruleset is to set the firewall_script
   variable to the absolute path of an executable script that includes
   IPFW commands. The examples used in this section assume that the
   firewall_script is set to /etc/ipfw.rules:
firewall_script="/etc/ipfw.rules"

   To enable logging, include this line:
firewall_logging="YES"

   There is no /etc/rc.conf variable to set logging limits. To limit the
   number of times a rule is logged per connection attempt, specify the
   number using this line in /etc/sysctl.conf:
net.inet.ip.fw.verbose_limit=5

   After saving the needed edits, start the firewall. To enable logging
   limits now, also set the sysctl value specified above:
# service ipfw start
# sysctl net.inet.ip.fw.verbose_limit=5

30.4.2. IPFW Rule Syntax

   When a packet enters the IPFW firewall, it is compared against the
   first rule in the ruleset and progresses one rule at a time, moving
   from top to bottom in sequence. When the packet matches the selection
   parameters of a rule, the rule's action is executed and the search of
   the ruleset terminates for that packet. This is referred to as "first
   match wins". If the packet does not match any of the rules, it gets
   caught by the mandatory IPFW default rule number 65535, which denies
   all packets and silently discards them. However, if the packet matches
   a rule that contains the count, skipto, or tee keywords, the search
   continues. Refer to [10]ipfw(8) for details on how these keywords
   affect rule processing.

   When creating an IPFW rule, keywords must be written in the following
   order. Some keywords are mandatory while other keywords are optional.
   The words shown in uppercase represent a variable and the words shown
   in lowercase must precede the variable that follows it. The # symbol is
   used to mark the start of a comment and may appear at the end of a rule
   or on its own line. Blank lines are ignored.

   CMD RULE_NUMBER set SET_NUMBER ACTION log LOG_AMOUNT PROTO from SRC
   SRC_PORT to DST DST_PORT OPTIONS

   This section provides an overview of these keywords and their options.
   It is not an exhaustive list of every possible option. Refer to
   [11]ipfw(8) for a complete description of the rule syntax that can be
   used when creating IPFW rules.

   CMD
          Every rule must start with ipfw add.

   RULE_NUMBER
          Each rule is associated with a number from 1 to 65534. The
          number is used to indicate the order of rule processing.
          Multiple rules can have the same number, in which case they are
          applied according to the order in which they have been added.

   SET_NUMBER
          Each rule is associated with a set number from 0 to 31. Sets can
          be individually disabled or enabled, making it possible to
          quickly add or delete a set of rules. If a SET_NUMBER is not
          specified, the rule will be added to set 0.

   ACTION
          A rule can be associated with one of the following actions. The
          specified action will be executed when the packet matches the
          selection criterion of the rule.

          allow | accept | pass | permit: these keywords are equivalent
          and allow packets that match the rule.

          check-state: checks the packet against the dynamic state table.
          If a match is found, execute the action associated with the rule
          which generated this dynamic rule, otherwise move to the next
          rule. A check-state rule does not have selection criterion. If
          no check-state rule is present in the ruleset, the dynamic rules
          table is checked at the first keep-state or limit rule.

          count: updates counters for all packets that match the rule. The
          search continues with the next rule.

          deny | drop: either word silently discards packets that match
          this rule.

          Additional actions are available. Refer to [12]ipfw(8) for
          details.

   LOG_AMOUNT
          When a packet matches a rule with the log keyword, a message
          will be logged to [13]syslogd(8) with a facility name of
          SECURITY. Logging only occurs if the number of packets logged
          for that particular rule does not exceed a specified LOG_AMOUNT.
          If no LOG_AMOUNT is specified, the limit is taken from the value
          of net.inet.ip.fw.verbose_limit. A value of zero removes the
          logging limit. Once the limit is reached, logging can be
          re-enabled by clearing the logging counter or the packet counter
          for that rule, using ipfw reset log.

Note:

          Logging is done after all other packet matching conditions have
          been met, and before performing the final action on the packet.
          The administrator decides which rules to enable logging on.

   PROTO
          This optional value can be used to specify any protocol name or
          number found in /etc/protocols.

   SRC
          The from keyword must be followed by the source address or a
          keyword that represents the source address. An address can be
          represented by any, me (any address configured on an interface
          on this system), me6, (any IPv6 address configured on an
          interface on this system), or table followed by the number of a
          lookup table which contains a list of addresses. When specifying
          an IP address, it can be optionally followed by its CIDR mask or
          subnet mask. For example, 1.2.3.4/25 or 1.2.3.4:255.255.255.128.

   SRC_PORT
          An optional source port can be specified using the port number
          or name from /etc/services.

   DST
          The to keyword must be followed by the destination address or a
          keyword that represents the destination address. The same
          keywords and addresses described in the SRC section can be used
          to describe the destination.

   DST_PORT
          An optional destination port can be specified using the port
          number or name from /etc/services.

   OPTIONS
          Several keywords can follow the source and destination. As the
          name suggests, OPTIONS are optional. Commonly used options
          include in or out, which specify the direction of packet flow,
          icmptypes followed by the type of ICMP message, and keep-state.

          When a keep-state rule is matched, the firewall will create a
          dynamic rule which matches bidirectional traffic between the
          source and destination addresses and ports using the same
          protocol.

          The dynamic rules facility is vulnerable to resource depletion
          from a SYN-flood attack which would open a huge number of
          dynamic rules. To counter this type of attack with IPFW, use
          limit. This option limits the number of simultaneous sessions by
          checking the open dynamic rules, counting the number of times
          this rule and IP address combination occurred. If this count is
          greater than the value specified by limit, the packet is
          discarded.

          Dozens of OPTIONS are available. Refer to [14]ipfw(8) for a
          description of each available option.

30.4.3. Example Ruleset

   This section demonstrates how to create an example stateful firewall
   ruleset script named /etc/ipfw.rules. In this example, all connection
   rules use in or out to clarify the direction. They also use via
   interface-name to specify the interface the packet is traveling over.

Note:

   When first creating or testing a firewall ruleset, consider temporarily
   setting this tunable:
net.inet.ip.fw.default_to_accept="1"

   This sets the default policy of [15]ipfw(8) to be more permissive than
   the default deny ip from any to any, making it slightly more difficult
   to get locked out of the system right after a reboot.

   The firewall script begins by indicating that it is a Bourne shell
   script and flushes any existing rules. It then creates the cmd variable
   so that ipfw add does not have to be typed at the beginning of every
   rule. It also defines the pif variable which represents the name of the
   interface that is attached to the Internet.
#!/bin/sh
# Flush out the list before we begin.
ipfw -q -f flush

# Set rules command prefix
cmd="ipfw -q add"
pif="dc0"     # interface name of NIC attached to Internet

   The first two rules allow all traffic on the trusted internal interface
   and on the loopback interface:
# Change xl0 to LAN NIC interface name
$cmd 00005 allow all from any to any via xl0

# No restrictions on Loopback Interface
$cmd 00010 allow all from any to any via lo0

   The next rule allows the packet through if it matches an existing entry
   in the dynamic rules table:
$cmd 00101 check-state

   The next set of rules defines which stateful connections internal
   systems can create to hosts on the Internet:
# Allow access to public DNS
# Replace x.x.x.x with the IP address of a public DNS server
# and repeat for each DNS server in /etc/resolv.conf
$cmd 00110 allow tcp from any to x.x.x.x 53 out via $pif setup keep-state
$cmd 00111 allow udp from any to x.x.x.x 53 out via $pif keep-state

# Allow access to ISP's DHCP server for cable/DSL configurations.
# Use the first rule and check log for IP address.
# Then, uncomment the second rule, input the IP address, and delete the first ru
le
$cmd 00120 allow log udp from any to any 67 out via $pif keep-state
#$cmd 00120 allow udp from any to x.x.x.x 67 out via $pif keep-state

# Allow outbound HTTP and HTTPS connections
$cmd 00200 allow tcp from any to any 80 out via $pif setup keep-state
$cmd 00220 allow tcp from any to any 443 out via $pif setup keep-state

# Allow outbound email connections
$cmd 00230 allow tcp from any to any 25 out via $pif setup keep-state
$cmd 00231 allow tcp from any to any 110 out via $pif setup keep-state

# Allow outbound ping
$cmd 00250 allow icmp from any to any out via $pif keep-state

# Allow outbound NTP
$cmd 00260 allow tcp from any to any 37 out via $pif setup keep-state

# Allow outbound SSH
$cmd 00280 allow tcp from any to any 22 out via $pif setup keep-state

# deny and log all other outbound connections
$cmd 00299 deny log all from any to any out via $pif

   The next set of rules controls connections from Internet hosts to the
   internal network. It starts by denying packets typically associated
   with attacks and then explicitly allows specific types of connections.
   All the authorized services that originate from the Internet use limit
   to prevent flooding.
# Deny all inbound traffic from non-routable reserved address spaces
$cmd 00300 deny all from 192.168.0.0/16 to any in via $pif     #RFC 1918 private
 IP
$cmd 00301 deny all from 172.16.0.0/12 to any in via $pif      #RFC 1918 private
 IP
$cmd 00302 deny all from 10.0.0.0/8 to any in via $pif         #RFC 1918 private
 IP
$cmd 00303 deny all from 127.0.0.0/8 to any in via $pif        #loopback
$cmd 00304 deny all from 0.0.0.0/8 to any in via $pif          #loopback
$cmd 00305 deny all from 169.254.0.0/16 to any in via $pif     #DHCP auto-config
$cmd 00306 deny all from 192.0.2.0/24 to any in via $pif       #reserved for doc
s
$cmd 00307 deny all from 204.152.64.0/23 to any in via $pif    #Sun cluster inte
rconnect
$cmd 00308 deny all from 224.0.0.0/3 to any in via $pif        #Class D & E mult
icast

# Deny public pings
$cmd 00310 deny icmp from any to any in via $pif

# Deny ident
$cmd 00315 deny tcp from any to any 113 in via $pif

# Deny all Netbios services.
$cmd 00320 deny tcp from any to any 137 in via $pif
$cmd 00321 deny tcp from any to any 138 in via $pif
$cmd 00322 deny tcp from any to any 139 in via $pif
$cmd 00323 deny tcp from any to any 81 in via $pif

# Deny fragments
$cmd 00330 deny all from any to any frag in via $pif

# Deny ACK packets that did not match the dynamic rule table
$cmd 00332 deny tcp from any to any established in via $pif

# Allow traffic from ISP's DHCP server.
# Replace x.x.x.x with the same IP address used in rule 00120.
#$cmd 00360 allow udp from any to x.x.x.x 67 in via $pif keep-state

# Allow HTTP connections to internal web server
$cmd 00400 allow tcp from any to me 80 in via $pif setup limit src-addr 2

# Allow inbound SSH connections
$cmd 00410 allow tcp from any to me 22 in via $pif setup limit src-addr 2

# Reject and log all other incoming connections
$cmd 00499 deny log all from any to any in via $pif

   The last rule logs all packets that do not match any of the rules in
   the ruleset:
# Everything else is denied and logged
$cmd 00999 deny log all from any to any

30.4.4. Configuring NAT

   Contributed by Chern Lee.

   FreeBSD's built-in NAT daemon, [16]natd(8), works in conjunction with
   IPFW to provide network address translation. This can be used to
   provide an Internet Connection Sharing solution so that several
   internal computers can connect to the Internet using a single IP
   address.

   To do this, the FreeBSD machine connected to the Internet must act as a
   gateway. This system must have two NICs, where one is connected to the
   Internet and the other is connected to the internal LAN. Each machine
   connected to the LAN should be assigned an IP address in the private
   network space, as defined by [17]RFC 1918, and have the default gateway
   set to the [18]natd(8) system's internal IP address.

   Some additional configuration is needed in order to activate the NAT
   function of IPFW. If the system has a custom kernel, the kernel
   configuration file needs to include option IPDIVERT along with the
   other IPFIREWALL options described in [19]Section 30.4.1, "Enabling
   IPFW".

   To enable NAT support at boot time, the following must be in
   /etc/rc.conf:
gateway_enable="YES"            # enables the gateway
natd_enable="YES"               # enables NAT
natd_interface="rl0"            # specify interface name of NIC attached to Inte
rnet
natd_flags="-dynamic -m"        # -m = preserve port numbers; additional options
 are listed in [20]natd(8)

Note:

   It is also possible to specify a configuration file which contains the
   options to pass to [21]natd(8):
natd_flags="-f /etc/natd.conf"

   The specified file must contain a list of configuration options, one
   per line. For example:
redirect_port tcp 192.168.0.2:6667 6667
redirect_port tcp 192.168.0.3:80 80

   For more information about this configuration file, consult
   [22]natd(8).

   Next, add the NAT rules to the firewall ruleset. When the rulest
   contains stateful rules, the positioning of the NAT rules is critical
   and the skipto action is used. The skipto action requires a rule number
   so that it knows which rule to jump to.

   The following example builds upon the firewall ruleset shown in the
   previous section. It adds some additional entries and modifies some
   existing rules in order to configure the firewall for NAT. It starts by
   adding some additional variables which represent the rule number to
   skip to, the keep-state option, and a list of TCP ports which will be
   used to reduce the number of rules:
#!/bin/sh
ipfw -q -f flush
cmd="ipfw -q add"
skip="skipto 500"
pif=dc0
ks="keep-state"
good_tcpo="22,25,37,53,80,443,110"

   The inbound NAT rule is inserted after the two rules which allow all
   traffic on the trusted internal interface and on the loopback interface
   and before the check-state rule. It is important that the rule number
   selected for this NAT rule, in this example 100, is higher than the
   first two rules and lower than the check-state rule:
$cmd 005 allow all from any to any via xl0  # exclude LAN traffic
$cmd 010 allow all from any to any via lo0  # exclude loopback traffic
$cmd 100 divert natd ip from any to any in via $pif # NAT any inbound packets
# Allow the packet through if it has an existing entry in the dynamic rules tabl
e
$cmd 101 check-state

   The outbound rules are modified to replace the allow action with the
   $skip variable, indicating that rule processing will continue at rule
   500. The seven tcp rules have been replaced by rule 125 as the
   $good_tcpo variable contains the seven allowed outbound ports.
# Authorized outbound packets
$cmd 120 $skip udp from any to x.x.x.x 53 out via $pif $ks
$cmd 121 $skip udp from any to x.x.x.x 67 out via $pif $ks
$cmd 125 $skip tcp from any to any $good_tcpo out via $pif setup $ks
$cmd 130 $skip icmp from any to any out via $pif $ks

   The inbound rules remain the same, except for the very last rule which
   removes the via $pif in order to catch both inbound and outbound rules.
   The NAT rule must follow this last outbound rule, must have a higher
   number than that last rule, and the rule number must be referenced by
   the skipto action. In this ruleset, rule number 500 diverts all packets
   which match the outbound rules to [23]natd(8) for NAT processing. The
   next rule allows any packet which has undergone NAT processing to pass.
$cmd 499 deny log all from any to any
$cmd 500 divert natd ip from any to any out via $pif # skipto location for outbo
und stateful rules
$cmd 510 allow ip from any to any

   In this example, rules 100, 101, 125, 500, and 510 control the address
   translation of the outbound and inbound packets so that the entries in
   the dynamic state table always register the private LAN IP address.

   Consider an internal web browser which initializes a new outbound HTTP
   session over port 80. When the first outbound packet enters the
   firewall, it does not match rule 100 because it is headed out rather
   than in. It passes rule 101 because this is the first packet and it has
   not been posted to the dynamic state table yet. The packet finally
   matches rule 125 as it is outbound on an allowed port and has a source
   IP address from the internal LAN. On matching this rule, two actions
   take place. First, the keep-state action adds an entry to the dynamic
   state table and the specified action, skipto rule 500, is executed.
   Next, the packet undergoes NAT and is sent out to the Internet. This
   packet makes its way to the destination web server, where a response
   packet is generated and sent back. This new packet enters the top of
   the ruleset. It matches rule 100 and has its destination IP address
   mapped back to the original internal address. It then is processed by
   the check-state rule, is found in the table as an existing session, and
   is released to the LAN.

   On the inbound side, the ruleset has to deny bad packets and allow only
   authorized services. A packet which matches an inbound rule is posted
   to the dynamic state table and the packet is released to the LAN. The
   packet generated as a response is recognized by the check-state rule as
   belonging to an existing session. It is then sent to rule 500 to
   undergo NAT before being released to the outbound interface.

30.4.4.1. Port Redirection

   The drawback with [24]natd(8) is that the LAN clients are not
   accessible from the Internet. Clients on the LAN can make outgoing
   connections to the world but cannot receive incoming ones. This
   presents a problem if trying to run Internet services on one of the LAN
   client machines. A simple way around this is to redirect selected
   Internet ports on the [25]natd(8) machine to a LAN client.

   For example, an IRC server runs on client A and a web server runs on
   client B. For this to work properly, connections received on ports 6667
   (IRC) and 80 (HTTP) must be redirected to the respective machines.

   The syntax for -redirect_port is as follows:
     -redirect_port proto targetIP:targetPORT[-targetPORT]
                 [aliasIP:]aliasPORT[-aliasPORT]
                 [remoteIP[:remotePORT[-remotePORT]]]

   In the above example, the argument should be:
    -redirect_port tcp 192.168.0.2:6667 6667
    -redirect_port tcp 192.168.0.3:80 80

   This redirects the proper TCP ports to the LAN client machines.

   Port ranges over individual ports can be indicated with -redirect_port.
   For example, tcp 192.168.0.2:2000-3000 2000-3000 would redirect all
   connections received on ports 2000 to 3000 to ports 2000 to 3000 on
   client A.

   These options can be used when directly running [26]natd(8), placed
   within the natd_flags="" option in /etc/rc.conf, or passed via a
   configuration file.

   For further configuration options, consult [27]natd(8)

30.4.4.2. Address Redirection

   Address redirection is useful if more than one IP address is available.
   Each LAN client can be assigned its own external IP address by
   [28]natd(8), which will then rewrite outgoing packets from the LAN
   clients with the proper external IP address and redirects all traffic
   incoming on that particular IP address back to the specific LAN client.
   This is also known as static NAT. For example, if IP addresses
   128.1.1.1, 128.1.1.2, and 128.1.1.3 are available, 128.1.1.1 can be
   used as the [29]natd(8) machine's external IP address, while 128.1.1.2
   and 128.1.1.3 are forwarded back to LAN clients A and B.

   The -redirect_address syntax is as follows:
-redirect_address localIP publicIP

   localIP  The internal IP address of the LAN client.
   publicIP The external IP address corresponding to the LAN client.

   In the example, this argument would read:
-redirect_address 192.168.0.2 128.1.1.2
-redirect_address 192.168.0.3 128.1.1.3

   Like -redirect_port, these arguments are placed within the
   natd_flags="" option of /etc/rc.conf, or passed via a configuration
   file. With address redirection, there is no need for port redirection
   since all data received on a particular IP address is redirected.

   The external IP addresses on the [30]natd(8) machine must be active and
   aliased to the external interface. Refer to [31]rc.conf(5) for details.

30.4.5. The IPFW Command

   ipfw can be used to make manual, single rule additions or deletions to
   the active firewall while it is running. The problem with using this
   method is that all the changes are lost when the system reboots. It is
   recommended to instead write all the rules in a file and to use that
   file to load the rules at boot time and to replace the currently
   running firewall rules whenever that file changes.

   ipfw is a useful way to display the running firewall rules to the
   console screen. The IPFW accounting facility dynamically creates a
   counter for each rule that counts each packet that matches the rule.
   During the process of testing a rule, listing the rule with its counter
   is one way to determine if the rule is functioning as expected.

   To list all the running rules in sequence:
# ipfw list

   To list all the running rules with a time stamp of when the last time
   the rule was matched:
# ipfw -t list

   The next example lists accounting information and the packet count for
   matched rules along with the rules themselves. The first column is the
   rule number, followed by the number of matched packets and bytes,
   followed by the rule itself.
# ipfw -a list

   To list dynamic rules in addition to static rules:
# ipfw -d list

   To also show the expired dynamic rules:
# ipfw -d -e list

   To zero the counters:
# ipfw zero

   To zero the counters for just the rule with number NUM:
# ipfw zero NUM

30.4.5.1. Logging Firewall Messages

   Even with the logging facility enabled, IPFW will not generate any rule
   logging on its own. The firewall administrator decides which rules in
   the ruleset will be logged, and adds the log keyword to those rules.
   Normally only deny rules are logged. It is customary to duplicate the
   "ipfw default deny everything" rule with the log keyword included as
   the last rule in the ruleset. This way, it is possible to see all the
   packets that did not match any of the rules in the ruleset.

   Logging is a two edged sword. If one is not careful, an over abundance
   of log data or a DoS attack can fill the disk with log files. Log
   messages are not only written to syslogd, but also are displayed on the
   root console screen and soon become annoying.

   The IPFIREWALL_VERBOSE_LIMIT=5 kernel option limits the number of
   consecutive messages sent to [32]syslogd(8), concerning the packet
   matching of a given rule. When this option is enabled in the kernel,
   the number of consecutive messages concerning a particular rule is
   capped at the number specified. There is nothing to be gained from 200
   identical log messages. With this option set to five, five consecutive
   messages concerning a particular rule would be logged to syslogd and
   the remainder identical consecutive messages would be counted and
   posted to syslogd with a phrase like the following:
last message repeated 45 times

   All logged packets messages are written by default to
   /var/log/security, which is defined in /etc/syslog.conf.

30.4.5.2. Building a Rule Script

   Most experienced IPFW users create a file containing the rules and code
   them in a manner compatible with running them as a script. The major
   benefit of doing this is the firewall rules can be refreshed in mass
   without the need of rebooting the system to activate them. This method
   is convenient in testing new rules as the procedure can be executed as
   many times as needed. Being a script, symbolic substitution can be used
   for frequently used values to be substituted into multiple rules.

   This example script is compatible with the syntax used by the
   [33]sh(1), [34]csh(1), and [35]tcsh(1) shells. Symbolic substitution
   fields are prefixed with a dollar sign ($). Symbolic fields do not have
   the $ prefix. The value to populate the symbolic field must be enclosed
   in double quotes ("").

   Start the rules file like this:
############### start of example ipfw rules script #############
#
ipfw -q -f flush       # Delete all rules
# Set defaults
oif="tun0"             # out interface
odns="192.0.2.11"      # ISP's DNS server IP address
cmd="ipfw -q add "     # build rule prefix
ks="keep-state"        # just too lazy to key this each time
$cmd 00500 check-state
$cmd 00502 deny all from any to any frag
$cmd 00501 deny tcp from any to any established
$cmd 00600 allow tcp from any to any 80 out via $oif setup $ks
$cmd 00610 allow tcp from any to $odns 53 out via $oif setup $ks
$cmd 00611 allow udp from any to $odns 53 out via $oif $ks
################### End of example ipfw rules script ############

   The rules are not important as the focus of this example is how the
   symbolic substitution fields are populated.

   If the above example was in /etc/ipfw.rules, the rules could be
   reloaded by the following command:
# sh /etc/ipfw.rules

   /etc/ipfw.rules can be located anywhere and the file can have any name.

   The same thing could be accomplished by running these commands by hand:
# ipfw -q -f flush
# ipfw -q add check-state
# ipfw -q add deny all from any to any frag
# ipfw -q add deny tcp from any to any established
# ipfw -q add allow tcp from any to any 80 out via tun0 setup keep-state
# ipfw -q add allow tcp from any to 192.0.2.11 53 out via tun0 setup keep-state
# ipfw -q add 00611 allow udp from any to 192.0.2.11 53 out via tun0 keep-state
     __________________________________________________________________

   [36]Prev   [37]Up               [38]Next
   30.3. PF  [39]Home  30.5. IPFILTER (IPF)

             All FreeBSD documents are available for download at
                 [40]http://ftp.FreeBSD.org/pub/FreeBSD/doc/

   Questions that are not answered by the [41]documentation may be sent to
                    <[42]freebsd-questions@FreeBSD.org>.
    Send questions about this document to <[43]freebsd-doc@FreeBSD.org>.

References

   1. https://www.freebsd.org/doc/handbook/index.html
   2. https://www.freebsd.org/doc/handbook/firewalls.html
   3. https://www.freebsd.org/doc/handbook/firewalls-pf.html
   4. https://www.freebsd.org/doc/handbook/firewalls-ipf.html
   5. https://www.freebsd.org/doc/handbook/legalnotice.html
   6. https://www.freebsd.org/doc/handbook/firewalls-pf.html
   7. https://www.freebsd.org/doc/handbook/firewalls-ipf.html
   8. http://www.FreeBSD.org/cgi/man.cgi?query=dummynet&sektion=4
   9. https://www.freebsd.org/doc/handbook/kernelconfig.html
  10. http://www.FreeBSD.org/cgi/man.cgi?query=ipfw&sektion=8
  11. http://www.FreeBSD.org/cgi/man.cgi?query=ipfw&sektion=8
  12. http://www.FreeBSD.org/cgi/man.cgi?query=ipfw&sektion=8
  13. http://www.FreeBSD.org/cgi/man.cgi?query=syslogd&sektion=8
  14. http://www.FreeBSD.org/cgi/man.cgi?query=ipfw&sektion=8
  15. http://www.FreeBSD.org/cgi/man.cgi?query=ipfw&sektion=8
  16. http://www.FreeBSD.org/cgi/man.cgi?query=natd&sektion=8
  17. ftp://ftp.isi.edu/in-notes/rfc1918.txt
  18. http://www.FreeBSD.org/cgi/man.cgi?query=natd&sektion=8
  19. https://www.freebsd.org/doc/handbook/firewalls-ipfw.html#firewalls-ipfw-enable
  20. http://www.FreeBSD.org/cgi/man.cgi?query=natd&sektion=8
  21. http://www.FreeBSD.org/cgi/man.cgi?query=natd&sektion=8
  22. http://www.FreeBSD.org/cgi/man.cgi?query=natd&sektion=8
  23. http://www.FreeBSD.org/cgi/man.cgi?query=natd&sektion=8
  24. http://www.FreeBSD.org/cgi/man.cgi?query=natd&sektion=8
  25. http://www.FreeBSD.org/cgi/man.cgi?query=natd&sektion=8
  26. http://www.FreeBSD.org/cgi/man.cgi?query=natd&sektion=8
  27. http://www.FreeBSD.org/cgi/man.cgi?query=natd&sektion=8
  28. http://www.FreeBSD.org/cgi/man.cgi?query=natd&sektion=8
  29. http://www.FreeBSD.org/cgi/man.cgi?query=natd&sektion=8
  30. http://www.FreeBSD.org/cgi/man.cgi?query=natd&sektion=8
  31. http://www.FreeBSD.org/cgi/man.cgi?query=rc.conf&sektion=5
  32. http://www.FreeBSD.org/cgi/man.cgi?query=syslogd&sektion=8
  33. http://www.FreeBSD.org/cgi/man.cgi?query=sh&sektion=1
  34. http://www.FreeBSD.org/cgi/man.cgi?query=csh&sektion=1
  35. http://www.FreeBSD.org/cgi/man.cgi?query=tcsh&sektion=1
  36. https://www.freebsd.org/doc/handbook/firewalls-pf.html
  37. https://www.freebsd.org/doc/handbook/firewalls.html
  38. https://www.freebsd.org/doc/handbook/firewalls-ipf.html
  39. https://www.freebsd.org/doc/handbook/index.html
  40. http://ftp.FreeBSD.org/pub/FreeBSD/doc/
  41. http://www.FreeBSD.org/docs.html
  42. mailto:freebsd-questions@FreeBSD.org
  43. mailto:freebsd-doc@FreeBSD.org
