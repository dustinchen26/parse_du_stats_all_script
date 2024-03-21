#!/bin/bash

# Function to parse GNB DU Statistics line
parseGNBLine() {
    local line="$1"
    #echo "$line"
	echo -e "\n$line"
}

# calculate DL BLER and UL BLER
calculateDLandULbler() {
    local dlTx="$1"
    local dlRetx="$2"
    local ulCRCsucces="$3"
    local ulCRCfail="$4"

    local dlBler="0"
    local ulBler="0"

    # Check if the denominator is not zero before calculating DL BLER
    if [[ $(($dlTx + $dlRetx)) -ne 0 ]]; then
        dlBler=$(awk "BEGIN {printf \"%.4f\", $dlRetx / ($dlTx + $dlRetx)}")
    fi

    # Check if the denominator is not zero before calculating UL BLER
    if [[ $(($ulCRCsucces + $ulCRCfail)) -ne 0 ]]; then
        ulBler=$(awk "BEGIN {printf \"%.4f\", $ulCRCfail / ($ulCRCsucces + $ulCRCfail)}")
    fi

    echo "UE-ID=$ueId dlbler=$dlBler ulbler=$ulBler"
}

# Function to parse UE data
parseUEData() {
    local line="$1"
    local values=($line)
    local ueId=${values[0]}
    local dlTx=${values[3]}
    local dlRetx=${values[4]}
    local ulCRCsucces=${values[18]}
    local ulCRCfail=${values[19]}
	
    #echo "UE-ID=$ueId DL-TX=$dlTx DL-RETX=$dlRetx UL-CRC-SUCC=$ulCRCsucces UL-CRC-FAIL=$ulCRCfail"
    calculateDLandULbler "$dlTx" "$dlRetx" "$ulCRCsucces" "$ulCRCfail" 

    # Continue parsing subsequent lines with numbers
    while read -r nextLine && [[ $nextLine =~ ^[0-9] ]]; do
        values=($nextLine)
        ueId=${values[0]}
        dlTx=${values[3]}
        dlRetx=${values[4]}
        ulCRCsucces=${values[18]}
		ulCRCfail=${values[19]}
		
        #echo "UE-ID=$ueId DL-TX=$dlTx DL-RETX=$dlRetx UL-CRC-SUCC=$ulCRCsucces UL-CRC-FAIL=$ulCRCfail"
        calculateDLandULbler "$dlTx" "$dlRetx" "$ulCRCsucces" "$ulCRCfail" 
    done
}

# Main script
for file in du_stats_*; do
    echo "Processing file: $file"

    while IFS= read -r line; do
        line=$(echo "$line" | tr -d '\r')  # Remove carriage return character if present
        line=$(echo "$line" | sed 's/^ *//;s/ *$//')  # Trim leading and trailing spaces

        if [[ $line == *"GNB DU Statistics  "* ]]; then
            parseGNBLine "$line"
        elif [[ $line == *"UE-ID   CELL-ID   ON-SUL"* ]]; then
            # Check if the next line has numbers
            read -r nextLine
            if [[ $nextLine =~ ^[0-9] ]]; then
                parseUEData "$nextLine"
            fi
        fi
    done < "$file"

    echo "Finished processing file: $file"
done