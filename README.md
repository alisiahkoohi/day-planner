# Day Planner

A simple command-line hour-by-hour task scheduler.

## Install

```bash
curl -O https://raw.githubusercontent.com/alisiahkoohi/day-planner/main/planner.sh
chmod +x planner.sh
sudo mv planner.sh /usr/local/bin/planner
```

## Usage

```bash
planner                 # Edit today's plan
planner -v              # View today's plan
planner 2025-08-15      # Edit plan for specific date
planner -v 2025-08-15   # View plan for specific date
planner -l              # List all plans
planner -h              # Show help
```

## Example

```
Day Plan for 2025-08-15

+==+============+============+========================================+
|##| Start Time |  End Time  |            Task Description            |
+==+============+============+========================================+
| 1|   09:00    |   10:30    | Team meeting                           |
| 2|   10:30    |   12:00    | Teaching                               |
| 3|   14:00    |   16:00    | Research                               |
+==+============+============+========================================+

Total planned time: 4h 30m
```

Plans are stored in `~/.dayplanner/` as simple text files.

## Requirements

- Bash
- Unix/Linux/macOS

## Author

Ali Siahkoohi, with assistance from Anthropic's Claude