#!/bin/bash

# Script para reloj de palabras matriz compatible con hyprlock
# Genera marcado Pango correctamente escapado

# Cargar colores generados por matugen (ver ../../matugen/.config/matugen/)
if [ -f ~/.cache/matugen/colors.sh ]; then
  source ~/.cache/matugen/colors.sh
  highlight_hex="${primary#\#}"
  dim_hex="${dim#\#}"
else
  # Colores por defecto si todavia no se corrio matugen una vez
  highlight_hex="00ff00"
  dim_hex="666666"
fi

# Obtener hora actual y convertir a decimal (eliminar ceros iniciales)
hour=$(date +%H | sed 's/^0*//')
minute=$(date +%M | sed 's/^0*//')

# Manejar caso especial cuando es 00
[ -z "$hour" ] && hour=0
[ -z "$minute" ] && minute=0

# Convertir a formato 12 horas
original_hour=$hour
if [ $hour -gt 12 ]; then
  hour=$((hour - 12))
elif [ $hour -eq 0 ]; then
  hour=12
fi

# Función para crear la matriz con resaltado y atenuación
create_matrix_clock() {
  local highlight_color="$highlight_hex" # Color para las palabras activas
  local dim_color="$dim_hex"             # Color para las palabras atenuadas

  # "Respiracion" de brillo en las palabras activas: onda triangular de 10
  # pasos (un paso por segundo, el script ya se refresca cada 500ms via
  # cmd[update:500] en hyprlock.conf). Sin bc/awk, solo aritmetica entera.
  local pulse_steps=(100 92 84 76 68 60 68 76 84 92)
  local pulse=${pulse_steps[$(($(date +%s) % ${#pulse_steps[@]}))]}

  # Matriz base optimizada (11 filas x 11 columnas)
  local grid_template=(
    "ITLISASTIME" # Fila 0: IT IS AS TIME
    "ACQUARTERDC" # Fila 1: A QUARTER
    "TWENTYFIVEX" # Fila 2: TWENTY FIVE
    "HALFBTENFTO" # Fila 3: HALF TEN TO
    "PASTERUNINE" # Fila 4: PAST NINE
    "ONESIXTHREE" # Fila 5: ONE SIX THREE
    "FOURFIVETWO" # Fila 6: FOUR FIVE TWO
    "EIGHTELEVEN" # Fila 7: EIGHT ELEVEN
    "SEVENTWELVE" # Fila 8: SEVEN TWELVE
    "TENSEOCLOCK" # Fila 9: TEN O'CLOCK
    "MIDNIGHTDAY" # Fila 10: MIDNIGHT DAY
  )

  # Mapeo optimizado de palabras a posiciones (fila, columna_inicio, longitud)
  declare -A word_map=(
    # Fila 0
    ["IT"]="0,0,2"
    ["IS"]="0,3,2"

    # Fila 1
    ["QUARTER"]="1,2,7"

    # Fila 2
    ["TWENTY"]="2,0,6"
    ["FIVE_MIN"]="2,6,4"

    # Fila 3
    ["HALF"]="3,0,4"
    ["TEN_MIN"]="3,5,3"
    ["TO"]="3,9,2"

    # Fila 4
    ["PAST"]="4,0,4"
    ["NINE"]="4,7,4"

    # Fila 5
    ["ONE"]="5,0,3"
    ["SIX"]="5,3,3"
    ["THREE"]="5,6,5"

    # Fila 6
    ["FOUR"]="6,0,4"
    ["FIVE_HOUR"]="6,4,4"
    ["TWO"]="6,8,3"

    # Fila 7
    ["EIGHT"]="7,0,5"
    ["ELEVEN"]="7,5,6"

    # Fila 8
    ["SEVEN"]="8,0,5"
    ["TWELVE"]="8,5,6"

    # Fila 9
    ["TEN_HOUR"]="9,0,3"
    ["OCLOCK"]="9,5,6"

    # Fila 10
    ["MIDNIGHT"]="10,0,8"
    ["DAY"]="10,8,3"
  )

  local active_words=() # Lista de palabras activas

  # Siempre activar "IT IS"
  active_words+=("IT" "IS")

  local target_hour=$hour

  # Lógica optimizada para minutos - más precisa y limpia
  case $minute in
  0 | 1 | 2 | 3 | 4)
    active_words+=("OCLOCK")
    ;;
  5 | 6 | 7 | 8 | 9)
    active_words+=("FIVE_MIN" "PAST")
    ;;
  10 | 11 | 12 | 13 | 14)
    active_words+=("TEN_MIN" "PAST")
    ;;
  15 | 16 | 17 | 18 | 19)
    active_words+=("QUARTER" "PAST")
    ;;
  20 | 21 | 22 | 23 | 24)
    active_words+=("TWENTY" "PAST")
    ;;
  25 | 26 | 27 | 28 | 29)
    active_words+=("TWENTY" "FIVE_MIN" "PAST")
    ;;
  30 | 31 | 32 | 33 | 34)
    active_words+=("HALF" "PAST")
    ;;
  35 | 36 | 37 | 38 | 39)
    active_words+=("TWENTY" "FIVE_MIN" "TO")
    target_hour=$((hour == 12 ? 1 : hour + 1))
    ;;
  40 | 41 | 42 | 43 | 44)
    active_words+=("TWENTY" "TO")
    target_hour=$((hour == 12 ? 1 : hour + 1))
    ;;
  45 | 46 | 47 | 48 | 49)
    active_words+=("QUARTER" "TO")
    target_hour=$((hour == 12 ? 1 : hour + 1))
    ;;
  50 | 51 | 52 | 53 | 54)
    active_words+=("TEN_MIN" "TO")
    target_hour=$((hour == 12 ? 1 : hour + 1))
    ;;
  55 | 56 | 57 | 58 | 59)
    active_words+=("FIVE_MIN" "TO")
    target_hour=$((hour == 12 ? 1 : hour + 1))
    ;;
  esac

  # Añadir palabra de la hora usando case optimizado
  case $target_hour in
  1) active_words+=("ONE") ;;
  2) active_words+=("TWO") ;;
  3) active_words+=("THREE") ;;
  4) active_words+=("FOUR") ;;
  5) active_words+=("FIVE_HOUR") ;;
  6) active_words+=("SIX") ;;
  7) active_words+=("SEVEN") ;;
  8) active_words+=("EIGHT") ;;
  9) active_words+=("NINE") ;;
  10) active_words+=("TEN_HOUR") ;;
  11) active_words+=("ELEVEN") ;;
  12) active_words+=("TWELVE") ;;
  esac

  # Caso especial para medianoche
  if [ $original_hour -eq 0 ] && [ $minute -le 4 ]; then
    active_words=("IT" "IS" "MIDNIGHT")
  fi

  # Función para verificar si un carácter está activo
  is_char_active() {
    local row=$1 col=$2
    for word in "${active_words[@]}"; do
      local pos_info="${word_map[$word]}"
      [ -z "$pos_info" ] && continue

      IFS=',' read -r word_row word_col_start word_len <<<"$pos_info"
      if [ "$word_row" -eq "$row" ] && [ "$col" -ge "$word_col_start" ] && [ "$col" -lt "$((word_col_start + word_len))" ]; then
        return 0
      fi
    done
    return 1
  }

  # Construir la matriz de salida optimizada
  local output=""
  for row_idx in "${!grid_template[@]}"; do
    local current_line="${grid_template[$row_idx]}"
    local processed_line=""

    for ((col_idx = 0; col_idx < ${#current_line}; col_idx++)); do
      local char="${current_line:$col_idx:1}"

      if is_char_active "$row_idx" "$col_idx"; then
        processed_line+="<span foreground=\"#${highlight_color}\" alpha=\"${pulse}%\" font_weight=\"bold\">${char}</span>"
      else
        processed_line+="<span foreground=\"#${dim_color}\" alpha=\"30%\">${char}</span>"
      fi

      # Agregar espacio entre caracteres excepto al final
      [ $col_idx -lt $((${#current_line} - 1)) ] && processed_line+=" "
    done

    output+="$processed_line"
    [ $row_idx -lt $((${#grid_template[@]} - 1)) ] && output+=$'\n'
  done

  echo "$output"
}

# Ejecutar la función principal
create_matrix_clock
