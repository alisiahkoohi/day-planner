#!/bin/bash

# Day Planner - Command line hour-by-hour task scheduler
# Usage: ./planner.sh [date in YYYY-MM-DD format]

# Use environment variable or default to ~/.dayplanner
PLANNER_DIR="${PLANNER_DATA_DIR:-$HOME/.dayplanner}"
mkdir -p "$PLANNER_DIR"

# Color codes for better display
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# ===== FUNCTION DEFINITIONS =====

show_help() {
    echo "Day Planner - Command line task scheduler"
    echo ""
    echo "Usage: $0 [date] [options]"
    echo ""
    echo "Options:"
    echo "  -h, --help     Show this help"
    echo "  -l, --list     List all available plans"
    echo "  -v, --view     View plan for date (default: today)"
    echo "  -e, --edit     Edit plan for date"
    echo "  -d, --delete   Delete plan for date"
    echo "  --data-dir     Set custom data directory"
    echo ""
    echo "Date format: YYYY-MM-DD (e.g., 2024-03-15)"
    echo "If no date provided, defaults to today"
    echo ""
    echo "Examples:"
    echo "  $0                    # Edit today's plan"
    echo "  $0 2024-03-15         # Edit plan for March 15, 2024"
    echo "  $0 -v                 # View today's plan"
    echo "  $0 -v 2024-03-15      # View plan for March 15, 2024"
    echo "  $0 -l                 # List all plans"
}

list_plans() {
    echo -e "${BLUE}Available plans:${NC}"
    echo ""
    if ls "$PLANNER_DIR"/plan_*.txt 2>/dev/null | head -1 > /dev/null; then
        for file in "$PLANNER_DIR"/plan_*.txt; do
            date_part=$(basename "$file" .txt | sed 's/plan_//')
            echo "  $date_part"
        done
    else
        echo "  No plans found."
    fi
}

validate_time() {
    if [[ ! "$1" =~ ^([0-1]?[0-9]|2[0-3]):[0-5][0-9]$ ]]; then
        echo "Invalid time format. Use HH:MM (24-hour format)"
        return 1
    fi
    return 0
}

time_to_minutes() {
    local time="$1"
    local hours=$(echo "$time" | cut -d: -f1)
    local minutes=$(echo "$time" | cut -d: -f2)
    # Force decimal interpretation by removing leading zeros
    hours=$((10#$hours))
    minutes=$((10#$minutes))
    echo $((hours * 60 + minutes))
}

format_time() {
    local minutes="$1"
    local hours=$((minutes / 60))
    local mins=$((minutes % 60))
    printf "%02d:%02d" "$hours" "$mins"
}

add_entry() {
    echo ""
    echo -e "${GREEN}Adding new task entry for $DATE${NC}"
    echo ""

    # Get start time
    while true; do
        echo -n "Start time (HH:MM): "
        read -r start_time
        if validate_time "$start_time"; then
            break
        fi
    done

    # Get end time
    while true; do
        echo -n "End time (HH:MM): "
        read -r end_time
        if validate_time "$end_time"; then
            start_minutes=$(time_to_minutes "$start_time")
            end_minutes=$(time_to_minutes "$end_time")
            if [ "$end_minutes" -gt "$start_minutes" ]; then
                break
            else
                echo "End time must be after start time"
            fi
        fi
    done

    # Get task description
    echo -n "Task description: "
    read -r task_desc

    # Save entry
    echo "$start_time|$end_time|$task_desc" >> "$PLAN_FILE"
    echo ""
    echo -e "${GREEN}Entry added successfully!${NC}"
}

view_plan() {
    if [ ! -f "$PLAN_FILE" ]; then
        echo -e "${YELLOW}No plan found for $DATE${NC}"
        return
    fi

    echo -e "${BLUE}Day Plan for $DATE${NC}"
    echo ""

    # Sort entries by start time
    sort -t'|' -k1,1 "$PLAN_FILE" > /tmp/sorted_plan.txt

    # Create ASCII table with simple characters (80 chars max)
    echo "+==+============+============+========================================+"
    echo "|##| Start Time |  End Time  |            Task Description            |"
    echo "+==+============+============+========================================+"

    local line_num=1
    while IFS='|' read -r start_time end_time task_desc; do
        # Truncate task description if too long (38 chars max)
        if [ ${#task_desc} -gt 38 ]; then
            task_desc="${task_desc:0:35}..."
        fi
        printf "|%2d|   %s    |   %s    | %-38s |\n" "$line_num" "$start_time" "$end_time" "$task_desc"
        ((line_num++))
    done < /tmp/sorted_plan.txt

    echo "+==+============+============+========================================+"

    # Calculate total planned time
    total_minutes=0
    while IFS='|' read -r start_time end_time task_desc; do
        start_minutes=$(time_to_minutes "$start_time")
        end_minutes=$(time_to_minutes "$end_time")
        duration=$((end_minutes - start_minutes))
        total_minutes=$((total_minutes + duration))
    done < /tmp/sorted_plan.txt

    total_hours=$((total_minutes / 60))
    remaining_minutes=$((total_minutes % 60))

    echo ""
    echo -e "${GREEN}Total planned time: ${total_hours}h ${remaining_minutes}m${NC}"

    rm -f /tmp/sorted_plan.txt
}

print_task() {
    local task_num="$1"

    if [ ! -f "$PLAN_FILE" ]; then
        echo -e "${YELLOW}No plan found for $DATE${NC}"
        return
    fi

    # Sort and get the specific task
    sort -t'|' -k1,1 "$PLAN_FILE" > /tmp/sorted_plan.txt

    local line_count=$(wc -l < /tmp/sorted_plan.txt)

    if [ "$task_num" -lt 1 ] || [ "$task_num" -gt "$line_count" ]; then
        echo -e "${RED}Invalid task number. Available tasks: 1-$line_count${NC}"
        rm -f /tmp/sorted_plan.txt
        return
    fi

    local current_line=1
    while IFS='|' read -r start_time end_time task_desc; do
        if [ "$current_line" -eq "$task_num" ]; then
            local start_minutes=$(time_to_minutes "$start_time")
            local end_minutes=$(time_to_minutes "$end_time")
            local duration=$((end_minutes - start_minutes))
            local duration_hours=$((duration / 60))
            local duration_mins=$((duration % 60))

            echo -e "${BLUE}Task #$task_num Details:${NC}"
            echo "  Start Time: $start_time"
            echo "  End Time: $end_time"
            echo "  Duration: ${duration_hours}h ${duration_mins}m"
            echo "  Description: $task_desc"
            break
        fi
        ((current_line++))
    done < /tmp/sorted_plan.txt

    rm -f /tmp/sorted_plan.txt
}

edit_entry() {
    local task_num="$1"

    if [ ! -f "$PLAN_FILE" ]; then
        echo -e "${YELLOW}No plan found for $DATE${NC}"
        return
    fi

    # Sort and get the specific task
    sort -t'|' -k1,1 "$PLAN_FILE" > /tmp/sorted_plan.txt

    local line_count=$(wc -l < /tmp/sorted_plan.txt)

    if [ "$task_num" -lt 1 ] || [ "$task_num" -gt "$line_count" ]; then
        echo -e "${RED}Invalid task number. Available tasks: 1-$line_count${NC}"
        rm -f /tmp/sorted_plan.txt
        return
    fi

    # Show current task details
    local current_line=1
    local old_start_time old_end_time old_task_desc
    while IFS='|' read -r start_time end_time task_desc; do
        if [ "$current_line" -eq "$task_num" ]; then
            old_start_time="$start_time"
            old_end_time="$end_time"
            old_task_desc="$task_desc"

            echo -e "${BLUE}Editing Task #$task_num:${NC}"
            echo "  Current Start Time: $start_time"
            echo "  Current End Time: $end_time"
            echo "  Current Description: $task_desc"
            echo ""
            break
        fi
        ((current_line++))
    done < /tmp/sorted_plan.txt

    # Get new values (allow Enter to keep current)
    echo -n "New start time (HH:MM) [current: $old_start_time]: "
    read -r new_start_time
    if [ -z "$new_start_time" ]; then
        new_start_time="$old_start_time"
    else
        while ! validate_time "$new_start_time"; do
            echo -n "New start time (HH:MM) [current: $old_start_time]: "
            read -r new_start_time
            if [ -z "$new_start_time" ]; then
                new_start_time="$old_start_time"
                break
            fi
        done
    fi

    echo -n "New end time (HH:MM) [current: $old_end_time]: "
    read -r new_end_time
    if [ -z "$new_end_time" ]; then
        new_end_time="$old_end_time"
    else
        while ! validate_time "$new_end_time"; do
            echo -n "New end time (HH:MM) [current: $old_end_time]: "
            read -r new_end_time
            if [ -z "$new_end_time" ]; then
                new_end_time="$old_end_time"
                break
            fi
        done
    fi

    # Validate time order
    if [ "$new_start_time" != "$old_start_time" ] || [ "$new_end_time" != "$old_end_time" ]; then
        start_minutes=$(time_to_minutes "$new_start_time")
        end_minutes=$(time_to_minutes "$new_end_time")
        if [ "$end_minutes" -le "$start_minutes" ]; then
            echo -e "${RED}End time must be after start time. Edit cancelled.${NC}"
            rm -f /tmp/sorted_plan.txt
            return
        fi
    fi

    echo -n "New description [current: $old_task_desc]: "
    read -r new_task_desc
    if [ -z "$new_task_desc" ]; then
        new_task_desc="$old_task_desc"
    fi

    # Update the file by replacing the specific line
    local temp_file="/tmp/updated_plan.txt"
    current_line=1
    > "$temp_file"

    while IFS='|' read -r start_time end_time task_desc; do
        if [ "$current_line" -eq "$task_num" ]; then
            echo "$new_start_time|$new_end_time|$new_task_desc" >> "$temp_file"
        else
            echo "$start_time|$end_time|$task_desc" >> "$temp_file"
        fi
        ((current_line++))
    done < /tmp/sorted_plan.txt

    # Replace the original file with updated content
    mv "$temp_file" "$PLAN_FILE"

    echo ""
    echo -e "${GREEN}Task #$task_num updated successfully!${NC}"

    rm -f /tmp/sorted_plan.txt
}

remove_entry() {
    local task_num="$1"

    if [ ! -f "$PLAN_FILE" ]; then
        echo -e "${YELLOW}No plan found for $DATE${NC}"
        return
    fi

    # Sort and get the specific task
    sort -t'|' -k1,1 "$PLAN_FILE" > /tmp/sorted_plan.txt

    local line_count=$(wc -l < /tmp/sorted_plan.txt)

    if [ "$task_num" -lt 1 ] || [ "$task_num" -gt "$line_count" ]; then
        echo -e "${RED}Invalid task number. Available tasks: 1-$line_count${NC}"
        rm -f /tmp/sorted_plan.txt
        return
    fi

    # Show task to be deleted
    local current_line=1
    while IFS='|' read -r start_time end_time task_desc; do
        if [ "$current_line" -eq "$task_num" ]; then
            echo -e "${BLUE}Task #$task_num to be deleted:${NC}"
            echo "  Start Time: $start_time"
            echo "  End Time: $end_time"
            echo "  Description: $task_desc"
            echo ""
            break
        fi
        ((current_line++))
    done < /tmp/sorted_plan.txt

    echo -n "Are you sure you want to delete this task? (y/N): "
    read -r confirm
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        echo "Deletion cancelled."
        rm -f /tmp/sorted_plan.txt
        return
    fi

    # Create new file without the specified task
    local temp_file="/tmp/updated_plan.txt"
    current_line=1
    > "$temp_file"

    while IFS='|' read -r start_time end_time task_desc; do
        if [ "$current_line" -ne "$task_num" ]; then
            echo "$start_time|$end_time|$task_desc" >> "$temp_file"
        fi
        ((current_line++))
    done < /tmp/sorted_plan.txt

    # Replace the original file with updated content
    mv "$temp_file" "$PLAN_FILE"

    echo ""
    echo -e "${GREEN}Task #$task_num deleted successfully!${NC}"

    rm -f /tmp/sorted_plan.txt
}

edit_plan() {
    echo -e "${BLUE}Editing plan for $DATE${NC}"
    echo ""

    # If no plan exists, just start adding entries
    if [ ! -f "$PLAN_FILE" ]; then
        echo "No existing plan found. Creating new plan..."
        add_entry

        # Keep adding entries until user says no
        while true; do
            echo ""
            echo -n "Add another entry? (Y/n): "
            read -r add_more
            if [[ "$add_more" =~ ^[Nn]$ ]]; then
                break
            else
                add_entry
            fi
        done

        echo ""
        echo "Final plan:"
        view_plan
        return
    fi

    # Main menu loop for existing plans
    while true; do
        echo "Current plan:"
        view_plan
        echo ""
        echo "Choose an option:"
        echo "  (a) Add new entry"
        echo "  (c) Clear all entries and start fresh"
        echo "  (q) Quit without changes"
        echo "  (p #) Print task details (e.g., 'p 1' for task 1)"
        echo "  (r #) Replace/edit task (e.g., 'r 1' to edit task 1)"
        echo "  (d #) Delete task (e.g., 'd 1' to delete task 1)"
        echo ""
        echo -n "Enter choice: "
        read -r choice

        case $choice in
            a|A)
                # Add entries in a loop
                add_entry
                while true; do
                    echo ""
                    echo -n "Add another entry? (Y/n): "
                    read -r add_more
                    if [[ "$add_more" =~ ^[Nn]$ ]]; then
                        break
                    else
                        add_entry
                    fi
                done
                ;;
            c|C)
                echo -n "Are you sure you want to clear all entries? (y/N): "
                read -r confirm
                if [[ "$confirm" =~ ^[Yy]$ ]]; then
                    > "$PLAN_FILE"
                    echo -e "${GREEN}Plan cleared. Adding new entries...${NC}"
                    echo ""
                    add_entry

                    # Keep adding entries until user says no
                    while true; do
                        echo ""
                        echo -n "Add another entry? (Y/n): "
                        read -r add_more
                        if [[ "$add_more" =~ ^[Nn]$ ]]; then
                            break
                        else
                            add_entry
                        fi
                    done
                fi
                ;;
            q|Q)
                echo "Quitting without changes."
                exit 0
                ;;
            p\ *|P\ *)
                # Extract number after 'p '
                task_num=$(echo "$choice" | sed 's/^[pP] *//')
                if [[ "$task_num" =~ ^[0-9]+$ ]]; then
                    print_task "$task_num"
                    echo ""
                    echo -n "Press Enter to continue..."
                    read -r
                else
                    echo "Invalid format. Use 'p #' where # is the task number."
                fi
                ;;
            r\ *|R\ *)
                # Extract number after 'r '
                task_num=$(echo "$choice" | sed 's/^[rR] *//')
                if [[ "$task_num" =~ ^[0-9]+$ ]]; then
                    edit_entry "$task_num"
                    echo ""
                    echo -n "Press Enter to continue..."
                    read -r
                else
                    echo "Invalid format. Use 'r #' where # is the task number."
                fi
                ;;
            d\ *|D\ *)
                # Extract number after 'd '
                task_num=$(echo "$choice" | sed 's/^[dD] *//')
                if [[ "$task_num" =~ ^[0-9]+$ ]]; then
                    remove_entry "$task_num"
                    echo ""
                    echo -n "Press Enter to continue..."
                    read -r
                else
                    echo "Invalid format. Use 'd #' where # is the task number."
                fi
                ;;
            *)
                echo "Invalid choice. Use: a, c, q, p #, r #, or d #"
                ;;
        esac
    done
}

delete_plan() {
    if [ ! -f "$PLAN_FILE" ]; then
        echo -e "${YELLOW}No plan found for $DATE${NC}"
        return
    fi

    echo -n "Are you sure you want to delete the plan for $DATE? (y/N): "
    read -r confirm
    if [[ "$confirm" =~ ^[Yy]$ ]]; then
        rm "$PLAN_FILE"
        echo -e "${GREEN}Plan for $DATE deleted successfully!${NC}"
    else
        echo "Deletion cancelled."
    fi
}

# ===== MAIN LOGIC =====

# Parse command line arguments first, before setting DATE
TEMP_DATE=""
while [[ $# -gt 0 ]]; do
    case "$1" in
        -h|--help)
            show_help
            exit 0
            ;;
        -l|--list)
            list_plans
            exit 0
            ;;
        -v|--view)
            if [ -n "$2" ] && [[ ! "$2" =~ ^- ]]; then
                TEMP_DATE="$2"
                shift
            fi
            # Set DATE after parsing
            if [ -n "$TEMP_DATE" ]; then
                DATE="$TEMP_DATE"
            else
                DATE=$(date +%Y-%m-%d)
            fi
            PLAN_FILE="$PLANNER_DIR/plan_$DATE.txt"
            view_plan
            exit 0
            ;;
        -e|--edit)
            if [ -n "$2" ] && [[ ! "$2" =~ ^- ]]; then
                TEMP_DATE="$2"
                shift
            fi
            # Set DATE after parsing
            if [ -n "$TEMP_DATE" ]; then
                DATE="$TEMP_DATE"
            else
                DATE=$(date +%Y-%m-%d)
            fi
            PLAN_FILE="$PLANNER_DIR/plan_$DATE.txt"
            edit_plan
            exit 0
            ;;
        -d|--delete)
            if [ -n "$2" ] && [[ ! "$2" =~ ^- ]]; then
                TEMP_DATE="$2"
                shift
            fi
            # Set DATE after parsing
            if [ -n "$TEMP_DATE" ]; then
                DATE="$TEMP_DATE"
            else
                DATE=$(date +%Y-%m-%d)
            fi
            PLAN_FILE="$PLANNER_DIR/plan_$DATE.txt"
            delete_plan
            exit 0
            ;;
        --data-dir)
            if [ -n "$2" ]; then
                PLANNER_DIR="$2"
                mkdir -p "$PLANNER_DIR"
                shift
            else
                echo "Error: --data-dir requires a directory path"
                exit 1
            fi
            ;;
        -*)
            echo "Unknown option: $1"
            show_help
            exit 1
            ;;
        *)
            # If argument looks like a date, set it
            if [[ "$1" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]; then
                TEMP_DATE="$1"
            else
                echo "Invalid date format: $1"
                echo "Use YYYY-MM-DD format (e.g., 2024-03-15)"
                exit 1
            fi
            ;;
    esac
    shift
done

# Set final DATE
if [ -n "$TEMP_DATE" ]; then
    DATE="$TEMP_DATE"
else
    DATE=$(date +%Y-%m-%d)
fi

# Update PLAN_FILE after all parsing is complete
PLAN_FILE="$PLANNER_DIR/plan_$DATE.txt"

# Default action is edit
edit_plan