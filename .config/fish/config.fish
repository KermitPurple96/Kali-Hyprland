# ~/.config/fish/config.fish

set -g fish_term_features 1

# Colors
set -g endcolor "\033[0m\e[0m"
set -g green "\e[0;32m\033[1m"
set -g red "\e[0;31m\033[1m"
set -g blue "\e[0;34m\033[1m"
set -g yellow "\e[0;33m\033[1m"
set -g purple "\e[0;35m\033[1m"
set -g turquoise "\e[0;36m\033[1m"
set -g gray "\e[0;37m\033[1m"
set -g negro "\e[0;30m\033{1m"
set -g fondonegro "\e[0;40m\033[1m"
set -g fondoverde "\e[0;42m\033[1m"
set -g fondoamarillo "\e[0;43m\033[1m"
set -g fondoazul "\e[0;44m\033[1m"
set -g fondopurple "\e[0;46m\033[1m"
set -g fondogris "\e[0;47m\033[1m"


#echo -ne "\t   __                    __                   __            
#\t _/ /________  __       / /__________________/ /_________
#\t/  __/ ___/ / / /      / __  / __  / ___/ __  / _  / ___/
#\t/ /_/ /  / /_/ /      / / / / /_/ / /  / /_/ /  __/ /
#\t\__/_/  _\__  /      /_/ /_/\__,_/_/  /_____/\___/_/   
#\t       /_____/ \n" | lolcat
#echo


# Export PATH
set -g PATH $PATH $HOME/.local/bin /usr/bin/ /usr/share/responder /usr/share/ghidra /usr/share/hydra /usr/share/libreoffice /snap/bin /usr/sandbox /usr/local/bin /usr/local/go/bin /bin /usr/local/games /usr/games /usr/share/games /usr/local/sbin /usr/sbin /sbin /usr/local/bin /bin /usr/local/games /usr/games $HOME/.fzf/bin /opt/exploitdb $HOME/.local/bin /usr/share/metasploit-framework/tools/exploit /usr/bin/arsenal /usr/bin/gtfo $HOME/.fzf/bin /usr/share/Wordpresscan $HOME/.local/pipx/shared/bin $HOME/go/bin /usr/bin/pwsh $HOME/kitty.app/bin /home/kermit/dev/python /home/kermit/dev/bash /home/kermit/OSCP-PythonSupportTools $HOME/.cargo/bin /usr/local/bin/lua-language-server/bin /home/kermit/thc-ipv6

set _OLD_VIRTUAL_PATH "$PATH"

# Set other environment variables
set -gx ip (cat /home/kermit/.config/bin/target.txt)
set -gx name (cat /home/kermit/.config/bin/target_sys.txt)
set -gx _JAVA_AWT_WM_NONREPARENTING 1
set -gx wpscan (cat /home/kermit/wpscan_key)
set -gx wpscan (cat /home/kermit/shodan_key)
set -gx PDCP_API_KEY (cat /home/kermit/CVEmap_key)




alias venv='python3 -m venv .venv'
alias vens='source .venv/bin/activate.fish'

alias ars='source /usr/bin/arsenal/ars/bin/activate.fish' 

# ~/.config/fish/config.fish
#alias montar='sudo vmhgfs-fuse .host:/D /mnt/hgfs/ -o allow_other -o uid=1000'
alias montar='sudo vmhgfs-fuse .host:/ /mnt/hgfs/ -o allow_other -o uid=1000'
alias hash='cd /mnt/hgfs/share/hashcat-6.2.6/hashcat-6.2.6'

# Alias
alias dockerrmc='docker rm (docker ps -a -q) --force'
alias dockerrmi='docker rmi (docker images -q)'
alias dockerrmv='docker volume rm (docker volume ls -q)'

alias sp="searchsploit"
#alias share='impacket-smbserver share (pwd) -smb2support'
alias sd="sudo su"
alias fz='nvim (fzf --preview="cat {}")'
#alias serve='python3 -m http.server $argv[1]'
alias clean='sed -e "s/\x1b\[[0-9;]*m//g"'


alias kitten="kitty +kitten icat"
alias pins='jump pins'
alias js='js-beautify'
alias hi='hash-identifier'

zoxide init fish | source

# ~/.config/fish/config.fish

# Aliases for zoxide
#alias x='z && lsd -A'
#alias xi='zi && lsd -A'
alias xr='zoxide remove'
alias xq='zoxide query'
alias xe='zoxide edit'
alias xa='zoxide add'

# Aliases for common commands
alias a='run'
#alias v='nvim'

function v
  if test (count $argv) -eq 0
    /root/.cargo/bin/neovide > /dev/null 2>&1 &
  else
    /root/.cargo/bin/neovide $argv > /dev/null 2>&1 &
  end
end


# Multiple directory listing commands
alias la='lsd -Aalh' # show hidden files
alias ls='lsd -aFh --color=always' # add colors and file type extensions
alias lx='lsd -lXBh' # sort by extension
alias lk='lsd -lSrh' # sort by size
alias lc='lsd -lcrh' # sort by change time
alias lu='lsd -lurh' # sort by access time
alias lr='lsd -lRh' # recursive ls
alias lt='lsd -ltrh' # sort by date
alias lm='lsd -alh | more' # pipe through 'more'
alias lw='lsd -xAh' # wide listing format
alias ll='lsd -Fls' # long listing format
alias labc='lsd -lap' # alphabetical sort
alias lf='lsd -l | egrep -v "^d"' # files only
alias ldir='lsd -l | egrep "^d"' # directories only

# Other common aliases
alias dir='dir --color=auto'
alias vdir='vdir --color=auto'
alias grep='grep --color=auto'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'

# Navigation shortcuts
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias .....='cd ../../../..'

# Search commands
alias h='history | grep'
alias p='ps aux | grep'
alias topcpu='/bin/ps -eo pcpu,pid,user,args | sort -k 1 -r | head -10'
alias f='find . | grep'

# File and directory operations
#alias countfiles='for t in files links directories; echo (find . -type $t | wc -l) $t; end 2>/dev/null'
#alias countfiles 'for t in files links directories; echo (find . -type $t | wc -l | tr -d " ") $t; end 2>/dev/null'
alias checkcommand='type -t'

# Network commands
#alias ipview="netstat -anpl | grep :80 | awk '{print \$5}' | cut -d\":\" -f1 | sort | uniq -c | sort -n | sed -e 's/^ *//' -e 's/ *\$//'"
alias openports='netstat -nape --inet'

# Reboot aliases
alias rebootsafe='sudo shutdown -r now'
alias rebootforce='sudo shutdown -r -n now'

# Disk and space information
alias diskspace='du -S | sort -n -r | more'
alias folders='du -h --max-depth=1'
alias folderssort='find . -maxdepth 1 -type d -print0 | xargs -0 du -sk | sort -rn'
alias tree='tree -CAhF --dirsfirst'
alias treed='tree -CAFd'
alias mountedinfo='df -hT'

# Logs
#alias logs='sudo find /var/log -type f -exec file {} + | grep "text" | cut -d" " -f1 | sed -e "s/:$//" | grep -v "[0-9]$" | xargs tail -f'



function ww
    if test (count $argv) -lt 1
        echo "Uso: ww <url>"
        return 1
    end
    set url $argv[1]
    whatweb $url -v
end


function info

    echo -e "\n$red [+]$endcolor$yellow OSCP:$endcolor$blue mk$endcolor ->$blue netscan$endcolor ->$blue multiscan$endcolor ->$blue tg$endcolor ->$blue ports$endcolor"
    # Configuración
    echo -e "\n$yellow settings:$endcolor"
    echo -e "$green [+]$endcolor $blue tx $endcolor tmux shortcuts"
    echo -e "$green [+]$endcolor $blue iface <interface>$endcolor Define interface to show in i3blocks"
    echo -e "$green [+]$endcolor $blue mipk$endcolor Print current iface ip"
    echo -e "$green [+]$endcolor $blue mip$endcolor Print VPN tun0 ip"
    echo -e "$green [+]$endcolor $blue tg$endcolor Defines IP target"
    echo -e "$green [+]$endcolor $blue mk$endcolor Makes working environment"
    echo -e "$green [+]$endcolor $blue stop$endcolor Stops yellow watch"
    echo -e "$green [+]$endcolor $blue iface$endcolor Sets interface to show"


    # Escaneos
    echo -e "\n$yellow scans:$endcolor"
    echo -e "$green [+]$endcolor $blue scan <ip>$endcolor Classic -sS and -sCV nmap scan"
    echo -e "$green [+]$endcolor $blue netscan <interface>$endcolor Ping sweep interface scan"
    echo -e "$green [+]$endcolor $blue multiscan <file>$endcolor Nmap -sS and -sCV a list of IPs"
    echo -e "$green [+]$endcolor $blue ports <file>$endcolor Parse nmap -sS"
    echo -e "$green [+]$endcolor $blue recon <protocol>$endcolor Search nmap scripts"
    echo -e "$green [+]$endcolor $blue tcpudpScan 192.168.1.0/24$endcolor Ping and fast tdp/udp scan"
    

    # Análisis de SMB
    echo -e "\n$yellow nxc smb analysis:$endcolor"
    echo -e "$green [+]$endcolor $blue relay <ips file> <output files>$endcolor Converts --gen-relay-list from nxc to targets file for ntlmrelay"
    echo -e "$green [+]$endcolor $blue swop <file>$endcolor Parse nxc smb output for /etc/hosts"
    echo -e "$green [+]$endcolor $blue swap <file>$endcolor Parse nxc smb -M spider_plus output"
    echo -e "$green [+]$endcolor $blue crack <file>$endcolor Parse nxc smb output"

    # Análisis de SMB
    echo -e "\n$yellow cracking:$endcolor"
    echo -e "$green [+]$endcolor $blue crack <file>$endcolor crack without -m format specified"
    echo -e "$green [+]$endcolor $blue cracktgt <file>$endcolor crack tgt"
    echo -e "$green [+]$endcolor $blue cracktgs <file>$endcolor crack tgs"
    echo -e "$green [+]$endcolor $blue cracknetntlm <file>$endcolor crack tgs" 

    # Escaneos rápidos
    echo -e "\n$yellow fast golang TCP scan:$endcolor"
    echo -e "$green [+]$endcolor $blue fast <ip> <threads>$endcolor Fast go TCP scan"
    echo -e "$green [+]$endcolor $blue multifast <file>$endcolor Fast scan a list of IPs"

    echo -e "\n$yellow utilities:$endcolor"
    echo -e "$green [+]$endcolor $blue router <192.168.142.0>$endcolor Configure routing to target AP"
    echo -e "$green [+]$endcolor $blue getips$endcolor Extracts IPv4 from file"
    echo -e "$green [+]$endcolor $blue getips6$endcolor Extracts IPv6 from file"
    echo -e "$green [+]$endcolor $blue extract <file>$endcolor Decompress the file"
    echo -e "$green [+]$endcolor $blue get <n field> <archivo> [FS]$endcolor AWK filter"
    echo -e "$green [+]$endcolor $blue creds <archivo> $endcolor It searchs for credentials in the file or path specified"
    echo -e "$green [+]$endcolor $blue word ./* $endcolor make a wordlist"
    echo -e "$green [+]$endcolor $blue ftext <keyword> $endcolor find txt in current directory"
    echo -e "$green [+]$endcolor $blue bloodusers <file>$endcolor Extract users from bloohound users.json"
    echo -e "$green [+]$endcolor $blue ldapusers <file>$endcolor Extract users from ldapdomaindump users.json"


    echo -e "\n$yellow share:$endcolor"
    echo -e "$green [+]$endcolor $blue share <share name>$endcolor share current folder via smb"
    echo -e "$green [+]$endcolor $blue serve <port>$endcolor share current folder via http"


end



function x
  z $argv[1]
  lsd -A
end

function xi
  zi
  lsd -A
end

function kroot
    /home/kermit/kitty.app/bin/kitty -e fish &>/dev/null &
    disown
end



function mipk
    echo $miipk
end

function mip
    echo $miip
end

function ipt
    echo $ip
end

function ipn
    echo $name
end

# Copy stdin to the clipboard.
#
# CHANGED for Wayland. `xclip -sel clip` talks to an X server; under
# Hyprland there isn't one, only XWayland. Hyprland does bridge the two
# clipboards, so xclip mostly still works -- but only while XWayland is
# running, and it loses the selection when the last X client exits, which
# is a confusing way to lose a copied hash. wl-copy talks to the Wayland
# clipboard directly.
#
# Falls back to xclip so this same config still works on the i3 session.
function xp
    if set -q WAYLAND_DISPLAY; and command -q wl-copy
        wl-copy
    else
        xclip -sel clip
    end
end

function hexen
    echo "$argv" | xxd -p
end

function hexde
    echo "$argv" | xxd -p -r
end

function rot13
    echo "$argv" | tr A-Za-z N-ZA-Mn-za-m
end

function pin
    jump pin $argv[1]
end

function unpin
    jump unpin $argv[1]
end


function fibtrie
    cat $argv[1] | grep LOCAL -B 1 | grep -oP '\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}' | sort -u
end


function neofetch
    command neofetch --source /home/kermit/ascii | lolcat
end

function urlencode
    python3 -c 'import sys, urllib.parse as ul; print(ul.quote_plus(sys.argv[1]))' $argv
end

function urldecode
    python3 -c 'import sys, urllib.parse as ul; print(ul.unquote_plus(sys.argv[1]))' $argv
end

function burpro
    java --illegal-access=permit -Dfile.encoding=utf-8 -javaagent:/home/kermit/Desktop/Burp-Suite/loader.jar -noverify -jar /home/kermit/Desktop/Burp-Suite/Burp_Suite_Pro.jar &
end


if ifdata -e tun0
    set -gx miip (/usr/sbin/ifconfig tun0 | grep inet | awk '{print $2}')
    echo -e (set_color green)"\n\n\t[+]"(set_color normal)" VPN tun0 interface detected \n"
else
    echo -e (set_color red)"\n\n\t[-]"(set_color normal)" No VPN tun0 interface detected \n"
end

# Verifica si la interfaz tap0 está presente
if ifdata -e tap0
    set -gx miip (/usr/sbin/ifconfig tap0 | grep inet | awk '{print $2}')
    echo -e (set_color green)"\t[+]"(set_color normal)" VPN tap0 interface detected \n"
else
    echo -e (set_color red)"\t[-]"(set_color normal)" No VPN tap0 interface detected \n"
end



#set -gx miipk (/usr/sbin/ifconfig | grep eth0 -A1 | grep inet | awk '{print $2}')

function update_ip
  set interface (cat /usr/share/i3blocks/iface)
  if ifdata -e $interface
    set -gx miipk (/usr/sbin/ifconfig $interface | grep inet | awk '{print $2}' | head -n 1)
    #else 
    #echo -e (set_color red)"\n\t[-] Error"(set_color normal)" check /usr/share/i3blocks/iface"
  end
end

update_ip


function share
    echo -ne "\n\t[+] Sharing at:"
    echo -ne "\n\n"

    # Lista de interfaces a verificar
    set interfaces eth0 eth1 tun0 tap0

    # Recorre cada interfaz y verifica si existe y tiene IP
    for iface in $interfaces
        if ifdata -e $iface
            # Obtiene la IP de la interfaz y almacena en variable mip
            set mip (ifdata -p $iface | awk '{print $1}')
            
            # Verifica si mip no está vacía y muestra el share
            if test -n "$mip"
                echo "\\\\$mip\\$argv[1]"
            end
        end
    end

    echo -ne "\n"
    # Inicia el servidor SMB
    impacket-smbserver $argv[1] (pwd) -smb2support
end


function serve
    python3 -m uploadserver $argv[1]
end


function recon
    locate .nse | grep "$argv" | sed 's|/usr/share/nmap/scripts/||' >>/tmp/nmap.tmp
    set archivo /tmp/nmap.tmp
    set lineas (wc -l < $archivo)
    echo -e (set_color blue)"\n\t[+] "(set_color normal)"$lineas scripts found\n"
    for linea in (cat $archivo)
        echo -e (set_color green)"\t[+] "(set_color normal)"$linea \n"
    end
    set scripts (locate .nse | grep "$argv" | sed 's|/usr/share/nmap/scripts/||' | tr '\n' ',' | xargs)
    set scripts2 (string trim -c ',' $scripts)
    echo "$scripts2" | xp >/dev/null 2>&1
    rm $archivo
end


function word
    if test -z $argv[1]
        echo "Por favor, proporciona la ruta del directorio o archivo."
        return 1
    end

    # Encuentra solo archivos en el directorio dado y sus subdirectorios, excluyendo directorios
    find $argv[1] -type f -exec cat {} + | grep -oE '\w+' | tr '[:upper:]' '[:lower:]' | sort | uniq > wordlist.txt

    echo "Wordlist creada como 'wordlist.txt'"
end


function creds
    if test (count $argv) -eq 0
        echo "Uso: creds <archivo o ruta>"
        return 1
    end

    set archivo $argv[1]

    if test -e $archivo
        grep -rinE '(password|username|user|pass|key|token|secret|admin|administrator|cred|login|credentials)' $archivo
    else
        echo "Error: El archivo '$archivo' no existe."
        return 1
    end
end



function swep
    if test -z "$argv[1]"
        echo "Uso: ping_sweep <base de IP>"
        echo "Ejemplo: ping_sweep 10.10.123"
        return 1
    end

    set -l ip_base $argv[1]

    for i in (seq 1 255)
        sleep 1
        ping -c 1 "$ip_base.$i" &>/dev/null; and echo "Host $ip_base.$i active" &
    end
    wait
end


# Agrega esta función a tu .config.fish

function getips
    # Verifica si se proporcionó un archivo como argumento
    if test (count $argv) -eq 0
        echo "Uso: getips <archivo>"
        return 1
    end

    # Guarda el archivo proporcionado en una variable
    set archivo $argv[1]

    # Verifica si el archivo existe
    if not test -f $archivo
        echo "El archivo '$archivo' no existe."
        return 1
    end

    # Extrae las direcciones IP usando grep con una expresión regular
    grep -oE '\b([0-9]{1,3}\.){3}[0-9]{1,3}\b' $archivo | sort -u | uniq
end



function getips6
    # Verifica si se proporcionó un archivo como argumento
    if test (count $argv) -eq 0
        echo "Uso: getips6 <archivo>"
        return 1
    end

    # Guarda el archivo proporcionado en una variable
    set archivo $argv[1]

    # Verifica si el archivo existe
    if not test -f $archivo
        echo "El archivo '$archivo' no existe."
        return 1
    end

    # Extrae las direcciones IPv6 usando grep con una expresión regular
    grep -oE '(([0-9a-fA-F]{1,4}:){7,7}[0-9a-fA-F]{1,4}|([0-9a-fA-F]{1,4}:){1,7}:|([0-9a-fA-F]{1,4}:){1,6}:[0-9a-fA-F]{1,4}|([0-9a-fA-F]{1,4}:){1,5}(:[0-9a-fA-F]{1,4}){1,2}|([0-9a-fA-F]{1,4}:){1,4}(:[0-9a-fA-F]{1,4}){1,3}|([0-9a-fA-F]{1,4}:){1,3}(:[0-9a-fA-F]{1,4}){1,4}|([0-9a-fA-F]{1,4}:){1,2}(:[0-9a-fA-F]{1,4}){1,5}|[0-9a-fA-F]{1,4}:((:[0-9a-fA-F]{1,4}){1,6})|:((:[0-9a-fA-F]{1,4}){1,7}|:)|fe80:(:[0-9a-fA-F]{0,4}){0,4}%[0-9a-zA-Z]{1,}|::(ffff(:0{1,4}){0,1}:){0,1}((25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])\.){3,3}(25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])|([0-9a-fA-F]{1,4}:){1,4}:((25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])\.){3,3}(25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9]))' $archivo | sort -u | uniq
end

function rmk
    scrub -p dod $argv[1]
    shred -zun 10 -v $argv[1]
end



function extract
    for archive in $argv
        if test -f $archive
            switch $archive
                case "*.tar.bz2"
                    tar xvjf $archive
                case "*.tar.gz"
                    tar xvzf $archive
                case "*.bz2"
                    bunzip2 $archive
                case "*.rar"
                    rar x $archive
                case "*.gz"
                    gunzip $archive
                case "*.tar"
                    tar xvf $archive
                case "*.tbz2"
                    tar xvjf $archive
                case "*.tgz"
                    tar xvzf $archive
                case "*.zip"
                    unzip $archive
                case "*.Z"
                    uncompress $archive
                case "*.7z"
                    7z x $archive
                case "*"
                    echo "don't know how to extract '$archive'..."
            end
        else
            echo "'$archive' is not a valid file!"
        end
    end
end

function relays
    if test (count $argv) -ne 2
        echo "Uso: relays <ips> <output file>"
        return 1
    end

    set entrada $argv[1]
    set salida $argv[2]

    grep -Eo '^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+' $entrada | sort -u | sed 's|^|smb://|' > $salida
end


function get
    # Verifica si se proporcionaron los argumentos necesarios
    if test (count $argv) -lt 2
        echo "Uso: get <n campo> [FS] <archivo>"
        return 1
    end

    # Guarda los argumentos en variables
    set campo $argv[1]
    set FS $argv[2]
    set archivo $argv[3]

    # Verifica si el archivo existe
    if not test -f $archivo
        echo "El archivo '$archivo' no existe."
        return 1
    end

    # Usa awk para imprimir el campo especificado con el delimitador especificado
    awk -v campo=$campo -v FS="$FS" '{print $campo}' $archivo
end


function crack
    if test -z $argv[1]
        echo "crack without hash type specified"
        return 1
    end

    sudo hashcat $argv[1] /usr/share/wordlists/rockyou.txt -r /usr/share/hashcat/rules/best64.rule --force
end


function cracktgt
    if test -z $argv[1]
        echo "Por favor, proporciona el nombre del archivo que contiene los hashes."
        return 1
    end

    sudo hashcat -m 18200 $argv[1] /usr/share/wordlists/rockyou.txt -r /usr/share/hashcat/rules/best64.rule --force
end

function cracknetntlm
    if test -z $argv[1]
        echo "Por favor, proporciona el nombre del archivo que contiene los hashes."
        return 1
    end

    sudo hashcat -m 5600 $argv[1] /usr/share/wordlists/rockyou.txt -r /usr/share/hashcat/rules/best64.rule --force
end


function cracktgs
    if test -z $argv[1]
        echo "Por favor, proporciona el nombre del archivo que contiene los hashes de TGS."
        return 1
    end

    sudo hashcat -m 13100 $argv[1] /usr/share/wordlists/rockyou.txt -r /usr/share/hashcat/rules/best64.rule --force
end



function swap

# Define default paths
  set default_paths 'NETLOGON' 'SYSVOL' 'Users' 'ADMIN$' 'C$' 'IPC$' 'wsus'

# Define colors
  set color_default (set_color normal)
  set color_red (set_color red)

# Function to check if the path contains any of the default paths
  function is_default_path
      set path $argv[1]
      for default_path in $default_paths
          if string match -q -r "/$default_path/" $path
              return 0
          end
      end
      return 1
  end

# Process the JSON file and apply color formatting
  cat $argv[1] | jq -r 'paths | select(. | length == 2) | join("/")' | while read path
      set path_lower (string lower $path)

      if is_default_path $path_lower
          if string match -q -r '\.xml$|\.txt$' $path_lower
              echo $color_red$path$color_default
          else
              echo $color_default$path$color_default
          end
      else
          if string match -q -r '\.xml$|\.txt$' $path_lower
              echo $color_red$path$color_default
          else
              echo $color_default$path$color_default
          end
      end
  end

end



function swop
    # Verificar si se pasó un archivo como argumento
    if test (count $argv) -eq 0
        echo "Usage: swop <file>"
        return 1
    end

    # Leer el archivo línea por línea y procesar su contenido
    cat $argv[1] | while read -l line
        # Procesar solo líneas con contenido relevante
        if string match -qr "SMB" $line
            # Extraer la IP
            set ip (echo $line | awk '{for (i=1; i<=NF; i++) if ($i ~ /^192\./) print $i}')
            # Extraer el nombre de host
            set name (echo $line | sed -n 's/.*(name:\([^)]*\)).*/\1/p')
            # Extraer el dominio
            set domain (echo $line | sed -n 's/.*(domain:\([^)]*\)).*/\1/p')

            # Combinar nombre y dominio, y mostrar el resultado
            if test -n "$ip" -a -n "$name" -a -n "$domain"
                echo "$ip $name.$domain"
            end
        end
    end
end



function scan
    if test (count $argv) -eq 0
        echo "Uso: scan <IP>"
        return 1
    end

    set ip $argv[1]
    # Formateamos la IP reemplazando los puntos con guiones para usar en el nombre del archivo
    #set formatted_ip (echo $ip | tr '.' '-')
    set formatted_ip (echo $ip | awk -F'.' '{print $4"."$3"."$2"."$1}')


    # Escaneo SYN en todos los puertos y guarda la salida en formato greppable
    echo "[*] Running: grc nmap -sS --open -p- $ip -n -Pn -oG nmap-$formatted_ip.txt -vvv"
    grc nmap -sS --open -p- $ip -n -Pn -oG nmap-$formatted_ip.txt -vvv

    # Extraemos los puertos abiertos y los formateamos en una lista separada por comas
    set ports (cat nmap-$formatted_ip.txt | grep -oP '\d{1,5}/open' | awk '{print $1}' FS='/' | xargs | tr ' ' ',')

    # Si no hay puertos abiertos, mostramos un mensaje y salimos
    if test -z "$ports"
        echo "No se encontraron puertos abiertos en $ip."
        return 1
    end

    # Escaneo detallado en los puertos abiertos
    echo "[*] Running: grc nmap -sCV -p$ports -n -Pn $ip -vvv -oN scan-$formatted_ip.txt"
    grc nmap -sCV -p$ports -n -Pn $ip -vvv -oN scan-$formatted_ip.txt

    echo "Escaneo completado. Resultado guardado en scan-$formatted_ip.txt."
end


function trash
  set -l file $argv[1]
  for ip in (cat $file)
    set -l last_octet (echo $ip | awk -F. '{print $4}')
    if test "$last_octet" -ne 0 -a "$last_octet" -ne 254 -a "$last_octet" -ne 255
      echo $ip
    end
  end
end


function netscan
    if test (count $argv) -eq 0
        echo "Uso: netscan <range>"
        echo "Ejemplo: netscan 192.168.1.0/24"
        return 1
    end

    set range $argv[1]

    # Realiza el ping sweep con nmap en el segmento de red dado
    echo "Realizando ping sweep en $range con nmap..."
    set output_file "ips.nmap"
    set results "hosts.nmap"
    nmap -sn $range -oG $output_file >/dev/null 2>&1
    echo "[*] Running: nmap -sn $range -oG $output_file >/dev/null 2>&1"


    # Extrae las IPs de los hosts vivos del archivo de salida de nmap
    set nmap_ips (grep 'Up' $output_file | awk '{print $2}')

    # Si no se encuentran IPs, muestra el mensaje correspondiente
    if test (count $nmap_ips) -eq 0
        echo "No se encontraron hosts vivos en $range."
        return 1
    end

    getips $output_file | sort -u | uniq | sponge $output_file

    for ip in (cat $output_file)
      set -l last_octet (echo $ip | awk -F. '{print $4}')
      if test "$last_octet" -ne 0 -a "$last_octet" -ne 254 -a "$last_octet" -ne 255
        echo $ip >> $results
      end
    end

    rm $output_file
    # Muestra las IPs encontradas
    echo "IPs guardadas en $results:"
    cat $results
end


#iface
#

#function iface
#    if test (count $argv) -eq 0
#        echo "Uso: iface <interfaz>"
#        echo "Ejemplo: iface tun0"
#        return 1
#    end

    # Guarda el primer argumento en una variable
#    set interface $argv[1]

    # Escribe la interfaz en el archivo
#    echo $interface > /usr/share/i3blocks/iface
#    echo "Interfaz $interface establecida en /usr/share/i3blocks/iface"
#    update_ip
#end


#iface gum

function iface
    # Obtener las interfaces
    set interfaces (ip -o link show | awk -F': ' '{print $2}')
    
    # Pasar cada interfaz como opción separada a gum choose
    set interface (printf "%s\n" $interfaces | gum choose)
    
    # Guardar la interfaz seleccionada
    if test -n "$interface"
        echo $interface > /usr/share/i3blocks/iface
        echo "Interfaz $interface establecida en /usr/share/i3blocks/iface"
    else
        echo "No se seleccionó ninguna interfaz."
    end
    update_ip
end



function multiscan
    if test (count $argv) -eq 0
        echo "Uso: scan <archivo_de_IPs>"
        return 1
    end

    set ip_file $argv[1]

    # Verifica si el archivo existe
    if not test -f $ip_file
        echo "Archivo $ip_file no encontrado."
        return 1
    end

    # Lee cada IP del archivo y realiza el escaneo
    for ip in (cat $ip_file)
        set formatted_ip (echo $ip | awk -F'.' '{print $4"."$3"."$2"."$1}')

        echo "[*] Running: grc nmap -sS --open -p- $ip -n -Pn -oG nmap-$formatted_ip.txt -vvv"
        grc nmap -sS --open -p- $ip -n -Pn -oG nmap-$formatted_ip.txt -vvv

        set ports (grep -oP '\d{1,5}/open' nmap-$formatted_ip.txt | awk '{print $1}' FS='/' | xargs | tr ' ' ',')

        if test -z "$ports"
            echo "No se encontraron puertos abiertos en $ip."
            continue
        end

        echo "[*] Running: grc nmap -sCV -p$ports -n -Pn $ip -v -oN scan-$formatted_ip.txt"
        grc nmap -sCV -p$ports -n -Pn $ip -v -oN scan-$formatted_ip.txt

        echo "Escaneo completado. Resultado guardado en scan-$formatted_ip.txt."
    end
end




function fast
    if test (count $argv) -ne 2
        echo "Error: 2 arguments required: host & threads."
        return 1
    end

    fastTCPscan -host=$argv[1] -threads=$argv[2]
end


function multifast
    if test (count $argv) -eq 0
        echo "Uso: multifast <archivo_de_ips>"
        return 1
    end

    set file $argv[1]
    for ip in (cat $file)
        set formatted_ip (echo $ip | tr '.' '_')

        echo "Escaneando IP: $ip"
        fast $ip >nmap_$formatted_ip.txt
    end
end


function ports
    set ports (cat $argv[1] | grep -oP '\d{1,5}/open' | awk '{print $1}' FS='/' | xargs | tr ' ' ',')
    set ncports (cat $argv[1] | grep -oP '\d{1,5}/open' | awk '{print $1}' FS='/' | xargs)
    #set ip_address (cat $argv[1] | grep -oP '\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}' | sort -u | head -n 1)
    set ip_address (cat $argv[1] | grep -oP '^Host: .* \(\)' | head -n 1 | awk '{print $2}')
    set red (set_color red)
    set green (set_color green)
    set endcolor (set_color normal)

    echo "nmap -sCV -p $ports $ip_address -n -vvv -oN SCV_$ip_address.txt" | tr -d '\n' | xp

    gum style --foreground "#FF0000" --border-foreground "#00FF00" --border rounded --align center --width 20 --margin "1 1 1 8" --padding "1 0" "IP: $ip_address"
    echo -e "\t$red [*]$endcolor Open ports: $green $ports$endcolor \n" >extractPorts.tmp
    /usr/bin/cat extractPorts.tmp
    /usr/bin/rm extractPorts.tmp

    echo -ne "\t$green [+]$endcolor Scripts scans"
    echo
    echo -ne "\t$yellow [!]$endcolor Copied to de clipboard\n $endcolor"
    echo
    echo -ne "\t$red [*]$endcolor nmap -sCV -p $ports $ip_address -n -oN SCV_$ip_address.txt"
    echo
    echo -ne "\t$red [*]$endcolor nmap --script 'vuln and exploit and intrusive' -p $ports $ip_address -n -Pn -oN vulns.nmap"
    echo
    echo -ne "\n\t$green [+]$endcolor IPv6 scan"
    echo
    echo -ne "\t$red [*]$endcolor nmap -p- -sS --open -vvv -n -Pn -6 <ipv6 >%eth0 -oG ipv6.nmap"
    echo
    echo -ne "\n\t$green [+]$endcolor UDP scans"
    echo
    echo -ne "\t$red [*]$endcolor nmap -sU --top-ports 100 --open -v -n $ip_address -oG udp.ports"
    echo
    echo -ne "\t$red [*]$endcolor nmap -sCV -p$ports -sU $ip_address -oN udpScan.nmap"
    echo
    echo -ne "\n\t$green [+]$endcolor Automated scans"
    echo
    echo -ne "\t$red [*]$endcolor enum4linux -a $ip_address"
    echo
    echo -ne "\t$red [*]$endcolor autorecon $ip_address"
    echo
    echo -ne "\t$red [*]$endcolor nc -nvv -w 1 -z $ip_address $ncports"
    echo
    echo -ne "\t$red [*]$endcolor nc -nv -u -z -w 1 $ip_address $ncports"
    echo
    echo -ne "\t$red [*]$endcolor incursore.sh -t All -H $ip_address"
    echo
    echo -ne "\n\t$green [+]$endcolor Recommended scans"

    echo -ne "\n\t Run$green recon <protocol>$endcolor to get nmap scripts"


    if echo $ports | grep -q '\b21\b'

        echo -ne "\n\n\t$yellow [21]$endcolor$red FTP $endcolor"
        echo -ne "\n\t ftp $ip_address"
    end
    if echo $ports | grep -q '\b43\b'

        echo -ne "\n\n\t$yellow [43]$endcolor$red whois $endcolor"
        echo -ne "\n\t whois $ip_address"
        echo -ne "\n\t whois <domain> -h $ip_address"
    end
    if echo $ports | grep -q '\b53\b'

        echo -ne "\n\n\t$yellow [53]$endcolor$red DNS $endcolor"
        echo -ne "\n\t dnsenum --dnsserver $ip_address --threads 50 -f /usr/share/seclists/Discovery/DNS/subdomains-top1million-110000.txt <domain>"
        echo -ne "\n\t dnsrecon -n $ip_address -d <domain> -t std,axfr,brt"
    end

    set open_ports (echo $ports | grep -oE '\b(80|81|443|8000|8080|8081|47001|80443)\b')
    if test -n "$open_ports"
      # Recorrer cada puerto y realizar las acciones
      for port in $open_ports
          echo -ne "\n\n\t$yellow [$port]$endcolor$red HTTP $endcolor"
          echo -ne "\n\t ntlm-info http $ip_address"
          echo -ne "\n\t whatweb http://$ip_address"
          echo -ne "\n\t curl -I http://$ip_address:$port -v"
          echo -ne "\n\t curl -I http://$ip_address:$port/certenroll"

          echo -ne "\n\t feroxbuster -u http://$ip_address:$port/ -x html,asp,aspx,jsp -w /usr/share/wordlists/dirbuster/directory-list-2.3-medium.txt -k -t 100"

          echo -ne "dirsearch -w /usr/share/wordlists/dirbuster/directory-list-2.3-medium.txt -t 200 -r -u http://$ip_address:$port -e html,asp,aspx,jsp -f" 
          echo -ne "\n\t nmap --script http-enum -p$port $ip_address"
          echo -ne "\n\t wfuzz -c --hc=404 -t 200 -w /usr/share/wordlists/dirbuster/directory-list-2.3-medium.txt http://$ip_address:$port/FUZZ"
          echo -ne "\n\t gobuster dir -u http://$ip_address:$port -w /usr/share/seclists/Discovery/Web-Content/directory-list-2.3-medium.txt -t 20 -x html,php,txt"
      end
    end


    if echo $ports | grep -q '\b123\b'
        echo -ne "\n\t ntpdate -s $ip_address"
    end
    if echo $ports | grep -qE '\b(135|137|139)\b'

        echo -ne "\n\n\t$yellow [135-139]$endcolor$red RPC $endcolor"
        echo -ne "\n\t impacket-rpcdump $ip_address -p <port>"
        echo -ne "\n\t rpcinfo $ip_address"
        echo -ne "\n\t rpcdump.py $ip_address -p 135 | grep -i uuid"
        echo -ne "\n\t impacket-rpcmap 'ncacn_ip_tcp:$ip_address' -no-pass"
        echo -ne "\n\t impacket-rpcmap 'ncacn_ip_tcp:$ip_address' -auth-rpc '<domain>\\guest' -no-pass"
        echo -ne "\n\t rpcmap.py 'ncacn_ip_tcp:$ip_address'"
        echo -ne "\n\t rpcmap.py 'ncacn_np:$ip_address" 
        echo "[\pipe\spoolss]'"
        echo -ne "\n\t rpcmap.py 'ncacn_http:$ip_address"
        echo "[593]'"
        echo -ne "\n\t rpcmap.py ncacn_http:[6001,RpcProxy=<domain>:443]"
        echo -ne "\n\t rpcmap.py ncacn_http:localhost[3388,RpcProxy=<domain>:443]"
        echo -ne "\n\t rpcclient -U \"\" $ip_address -N"
        echo -ne "\n\t rpcclient -U \"guest%\" $ip_address -N"
        echo -ne "\n\t IOXIDResolver -t $ip_address"
        echo -ne "\n\t rpcenum.sh -e All -i $ip_address"
    end
    if echo $ports | grep -q '\b161\b'
        echo -ne "\n\n\t$yellow [161]$endcolor$red SNMP $endcolor"

        echo -ne "\n\n\t nmap --script snmp-interfaces -p161 -sU $ip_address"
        echo -ne "\n\t onesixtyone $ip_address -c usr/share/SecLists/Discovery/SNMP/common-snmp-community-strings.txt -i ips"
        echo -ne "\n\t snmpwalk -v1 -c public $ip_address"
        echo -ne "\n\t snmpwalk -v2 -c public $ip_address"
        echo -ne "\n\t snmpwalk -v2c -c public $ip_address"
        echo -ne "\n\t snmpwalk -v2c -c public $ip_address 1"
        echo -ne "\n\t snmpwalk -v3 -c public $ip_address"
        echo -ne "\n\t snmpbulkwalk -v2c -c public $ip_address"
        echo -ne "\n\t snmpwalk -v2c -c public $ip_address NET-SNMP-EXTEND-MIB::nsExtendObjects"
        echo -ne "\n\t snmpwalk -v2c -c public $ip_address ipAddressType"
        echo -ne "\n\t snmpwalk -v2c -c public $ip_address 1.3.6.1.4.1.77.1.2.25"
        echo -ne "\n\t snmpwalk -v2c -c public $ip_address 1.3.6.1.2.1.25.6.3.1.2"
        echo -ne "\n\t snmpwalk -v2c -c public $ip_address 1.3.6.1.2.1.6.13.1.3"
        echo -ne "\n\t snmpwalk -v2c -c public $ip_address hrSWRunName"
        echo -ne "\n\t snmpwalk -v2c -c public $ip_address hrSWRunTable"

    end

    if echo $ports | grep -qE '\b(389|636)\b'
      echo -ne "\n\n\t$yellow [389]$endcolor$red LDAP $endcolor"
      echo -ne "\n\t ldapsearch -H ldap://<domain> -x -s base namingcontexts"
      echo -ne "\n\t ldapsearch -h $ip_address -x -b 'DC=<domain>,DC=<tld>'"
      echo -ne "\n\t nxc ldap $ip_address -u 'guest' -p '' --password-not-required"
      echo -ne "\n\t openssl s_client -connect <DC>:636 -showcerts -debug"

    end

    if echo $ports | grep -q '\b443\b'
        echo -ne "\n\n\t$yellow [443]$endcolor$red SSL / TLS $endcolor"
        echo -ne "\n\t openssl s_client -connect $ip_address:443"
    end
    if echo $ports | grep -q '\b445\b'
        echo -ne "\n\n\t$yellow [445]$endcolor$red SMB $endcolor"
        echo -ne "\n\t nbtscan -r $ip_address"
        echo -ne "\n\t nxc smb $ip_address --shares"
        echo -ne "\n\t nxc smb $ip_address -u 'guest' -p '' --shares"
        echo -ne "\n\t ntlm-info smb $ip_address"
        echo -ne "\n\t smbclient -N -L "
        echo "\\\\\\\\$ip_address\\\\"
        echo -ne "\n\t smbclient -U 'guest%' -L "
        echo "\\\\\\\\$ip_address\\\\"
        echo -ne "\n\t smbclient.py -k @<domain>"
        echo -ne "\n\t smbclient.py -k -no-pass @<domain>"
        echo -ne "\n\t smbmap -H $ip_address"
    end


    echo -ne "\n"
    echo
end



function tg
    tput civis

    set session_start_time (date +%s)
    echo $session_start_time >/home/kermit/.config/bin/session.txt

    set -l NEWLINE "\n"

    gum input --prompt="> " --placeholder "ip de la maquina" >/home/kermit/.config/bin/target.txt
    gum input --prompt="> " --placeholder "nombre de la maquina" >/home/kermit/.config/bin/target_sys.txt
    gum choose windows linux >/home/kermit/.config/bin/ttl.txt

    set ip_address (cat /home/kermit/.config/bin/target.txt)
    set nombre (cat /home/kermit/.config/bin/target_sys.txt)
    set sistema (cat /home/kermit/.config/bin/ttl.txt)

    set -x ip (cat /home/kermit/.config/bin/target.txt)
    set -x name (cat /home/kermit/.config/bin/target_sys.txt)

    echo -e "\n\t$blue [+]$endcolor Name: $red $nombre$endcolor\n"
    echo -e "\n\t$blue [+]$endcolor Ip: $red $ip_address$endcolor\n"
    echo -e "\n\t$blue [+]$endcolor System: $red $sistema$endcolor\n"

    tput cnorm

end


function lab
  git clone https://github.com/KermitPurple96/OSCP-PythonSupportTools
  cd OSCP-PythonSupportTools
  git clone https://github.com/KermitPurple96/Shellpy
  mv ./Shellpy/* .
  rm -rf ./Shellpy
  cd ..
end



function mk
    tput civis
    gum input --prompt="> " --placeholder "workspace name" >machine.txt
    gum input --prompt="> " --placeholder /path/to/create/files >path.txt
    set machine (cat ./machine.txt)
    set workspace (cat ./path.txt)
    set blue (set_color blue)
    set endcolor (set_color normal)
    set green (set_color green)
    echo -e "\n\t$blue [+]$endcolor Creating workspace...\n"
    mkdir $workspace/$machine
    mkdir $workspace/$machine/nmaps
    mkdir $workspace/$machine/tools
    mkdir $workspace/$machine/exploits
    mkdir $workspace/$machine/payloads
    mkdir $workspace/$machine/content
    mkdir $workspace/$machine/server
    touch $workspace/$machine/scope
    touch $workspace/$machine/hashes
    touch $workspace/$machine/users
    touch $workspace/$machine/notes.txt
    touch $workspace/$machine/pass
    touch $workspace/$machine/creds
    touch $workspace/$machine/wordlist
    touch $workspace/$machine/index.html
    rm ./path.txt
    cd $workspace/$machine
    lab
    cd nmaps
    echo -e "\n\t$blue [+]$endcolor Added $green$workspace/$machine $endcolor to zoxide"
    xa $workspace/
    tput cnorm
    echo
end



function stop
    # Limpiar el prompt y desactivar el contador de tiempo
    set -e session_start_time
    rm /home/kermit/.config/bin/session.txt
    echo "Session stopped. Time counter deactivated."
end



#BLOODHOUND

function bloodusers
    set -l file $argv[1]
    jq -r '.data[].Properties.name' $file | sed 's/@.*//' | tr '[:upper:]' '[:lower:]'
end

function ldapusers
    set -l file $argv[1]
    jq '.[].attributes.sAMAccountName[]' $file | sed 's/"//g'
end



function ftext
    # -i case-insensitive
    # -I ignore binary files
    # -H causes filename to be printed
    # -r recursive search
    # -n causes line number to be printed
    # optional: -F treat search term as a literal, not a regular expression
    # optional: -l only print filenames and not the matching lines ex. grep -irl "$1" *
    grep -iIHrn --color=always "$argv[1]" . | less -r
end

function cpp
    set -e
    strace -q -ewrite cp -- "$argv[1]" "$argv[2]" 2>&1 | awk '
  {
    count += $NF
    if (count % 10 == 0) {
      percent = count / total_size * 100
      printf "%3d%% [", percent
      for (i=0; i<=percent; i++)
        printf "="
      printf " >"
      for (i=percent; i<100; i++)
        printf " "
      printf "]\r"
    }
  }
  END { print "" }' total_size=(stat -c '%s' "$argv[1]") count=0
end

function cd
    if test -n "$argv[1]"
        builtin cd $argv
        and lsd -A
    else
        builtin cd ~
        and ls -A
    end
end




# Save type history for completion and easier life
set -U fish_history_file ~/.local/share/fish/fish_history
set -U fish_history_max_count 10000

# Append history from other shells
set -U fish_append_history true

# Ignore duplicate entries in history
set -U fish_history_ignore_dups true

# Share history across fish sessions
set -U fish_share_history true


set -U fish_greeting (set_color blue) "       glu glu 🐟"(set_color normal)



if status is-interactive
    # atuin init fish | source
    # Commands to run in interactive sessions can go here
end

# Created by `pipx` on 2024-07-13 13:34:55
set PATH $PATH /root/.local/bin
