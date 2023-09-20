#!/bin/bash

#PIDSTAT: sudo apt-get install sysstat -y

read -p "Insira o identificador do processo (PID): " PID
#PID=31933

array_dados_cpu=()
array_dados_mem=()
array_dados_disk_write=()
array_dados_disk_read=()

sinal_tecla=0

trap 'sinal_tecla=1' INT

coleta_dados() {
    if ! ps -p $PID > /dev/null; then
        echo -e "O processo com o PID $PID não foi encontrado.\nPrograma Encerrado"
        exit 1
    fi

    echo -e "\nCOLETANDO DADOS --> Precione 'Ctrl-C' para encerrar\n"
    while [ $sinal_tecla -eq 0 ]; do
        local dados_brutos=$(ps -p $PID -o %cpu,%mem --no-headers)
        local dados_disk_brutos=$(pidstat -d -p $PID | grep $PID | awk '{gsub(",", ".", $4); gsub(",", ".", $5); print $4, $5}')
        
        local dado_cpu=$(echo "$dados_brutos" | awk '{print $1}')
        local dado_mem=$(echo "$dados_brutos" | awk '{print $2}')
        local disk_write=$(echo "$dados_disk_brutos" | awk '{print $1}')
        local disk_read=$(echo "$dados_disk_brutos" | awk '{print $2}')

        echo "| CPU: $dado_cpu | MEMORIA: $dado_mem | DISCO_LEITURA: $disk_read | DISCO_ESCRITA: $disk_write |"

        array_dados_cpu+=("$dado_cpu")
        array_dados_mem+=("$dado_mem")
        array_dados_disk_write+=("$disk_write")
        array_dados_disk_read+=("$disk_read")

        sleep 5
    done
}

calculo_media(){
    local array=("$@")
    local soma=0
    local qnt_ele="${#array[@]}"
    local media=0
 
    for dado in "${array[@]}"; do
        valor=$(echo "$dado" | sed 's/ //g')
        soma=$(bc -l <<< "$soma + $valor")
    done

    media=$(bc -l <<< "scale=5; $soma / $qnt_ele")

    echo "$media"
}

maior_menor(){
    local array=("$@")
    local maior=${array[0]}
    local menor=${array[0]}

    for dado in "${array[@]}"; do
        if [[ $dado > $maior ]]; then
            maior=$dado
        else
            menor=$dado
        fi
    done

    echo "      Maior: $maior Menor: $menor"
}

calculo_desvio_padrao(){
    local array=("$@")
    local media=$2
    local qnt_ele="${#array[@]}"
    local desvio_quadrado=0
    local soma_desvio=0
    local desvio_padrao=0

    for dado in "${array[@]}"; do
        valor=$(echo "$dado" | sed 's/ //g')
        desvio=$(bc -l <<< "$valor - $media")
        desvio_quadrado=$(bc -l <<< "$desvio * $desvio")
        soma_desvio=$(bc -l <<< "$soma_desvio + $desvio_quadrado")
    done

    desvio_padrao=$(bc -l <<< "scale=5; sqrt($soma_desvio / $qnt_ele)")
    
    echo "$desvio_padrao"
}

coleta_dados

echo -e "\nRELATORIO\n"
#MEDIA
media_cpu=$(calculo_media "${array_dados_cpu[@]}")
media_mem=$(calculo_media "${array_dados_mem[@]}")
media_disk_w=$(calculo_media "${array_dados_disk_write[@]}")
media_disk_r=$(calculo_media "${array_dados_disk_read[@]}")
echo -e "\nMEDIA:\n  CPU: $media_cpu | MEMORIA: $media_mem | DR: $media_disk_r | DW: $media_disk_w |"

#MAIOR E MENOR
echo -e "\nMAIOR MENOR"
echo "  CPU:"
maior_menor "${array_dados_cpu[@]}"
echo "  MEMORIA:"
maior_menor "${array_dados_mem[@]}"
echo -e "  DISCO LEITURA:"
maior_menor "${array_dados_disk_read[@]}"
echo -e "  DISCO ESCRITA:"
maior_menor "${array_dados_disk_write[@]}"

#DESVIO PADRÃO
desvio_cpu=$(calculo_desvio_padrao "${array_dados_cpu[@]}" "$media_cpu")
desvio_mem=$(calculo_desvio_padrao "${array_dados_mem[@]}" "$media_mem")
desvio_disk_w=$(calculo_desvio_padrao "${array_dados_disk_write[@]}" "$media_disk_w")
desvio_disk_r=$(calculo_desvio_padrao "${array_dados_disk_read[@]}" "$media_disk_r")
echo -e "\nDESVIO PADRAO\n  CPU: $desvio_cpu | MEM: $desvio_mem | DR: $desvio_disk_r | DW: $desvio_disk_w |"