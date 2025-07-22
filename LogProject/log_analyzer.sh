#!/bin/bash
# Log File Analyzer - Full Version

if [ $# -ne 1 ]; then 
    echo "Usage: $0 <log_file>"  
    exit 1 
fi 

log_file="$1"

# If File doesnot Exist then display error 
if [ ! -f "$log_file" ]; then
    echo "Error: File $log_file does not exist"
    exit 1
fi

# Getting real time date and time stored in variable
timestamp=$(date +"%Y%m%d_%H%M%S")

# Create a var to save the file with timestamp detail
report_file="log_analysis_${timestamp}.txt"

{
    echo "===== LOG FILE ANALYSIS REPORT ====="
    echo "File: $log_file"
    echo "Analyzed on: $(date)"
    echo "Size: $(du -h "$log_file" | cut -f1) ($(wc -c < "$log_file") bytes)"

    echo -e "\nMESSAGE COUNTS:"
    error_count=$(grep -c "ERROR" "$log_file")
    warning_count=$(grep -c "WARNING" "$log_file")
    info_count=$(grep -c "INFO" "$log_file")
    echo "ERROR: $error_count messages"
    echo "WARNING: $warning_count messages"
    echo "INFO: $info_count messages"

    echo -e "\nTOP 5 ERROR MESSAGES:"
    grep "ERROR" "$log_file" | cut -d']' -f2- | sed 's/^ *//' | sort | uniq -c | sort -nr | head -5 | awk '{printf " %3d - %s\n", $1, substr($0, index($0,$2))}'

    echo -e "\nERROR TIMELINE:"
    first_error=$(grep "ERROR" "$log_file" | head -1)
    last_error=$(grep "ERROR" "$log_file" | tail -1)
    echo "First error: ${first_error}"
    echo "Last error:  ${last_error}"

    echo -e "\nError frequency by hour:"
    grep "ERROR" "$log_file" | cut -d'[' -f2 | cut -d']' -f1 | cut -d' ' -f2 | cut -d':' -f1 | \
    awk '{count[int($1/4)]++} END {
        for (i=0; i<6; i++) {
            start = i*4
            end = start+4
            label = sprintf("%02d-%02d", start, end)
            bar = ""
            for (j=0; j<count[i]/2; j++) bar=bar "█"
            printf "%s: %s (%d)\n", label, bar, count[i]
        }
    }'

    echo -e "\nReport saved to: $report_file"
} | tee "$report_file"
