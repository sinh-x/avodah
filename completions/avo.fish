# Fish completions for avo (Avodah CLI)

# Disable file completions by default
complete -c avo -f

# --- Dynamic task ID completions ---
function __avo_tasks
  avo task list --format completion 2>/dev/null
end

# Global options
complete -c avo -n __fish_use_subcommand -l version -d 'Show version'

# Top-level commands
complete -c avo -n __fish_use_subcommand -a start -d 'Start timer on a task'
complete -c avo -n __fish_use_subcommand -a stop -d 'Stop timer and log time'
complete -c avo -n __fish_use_subcommand -a status -d 'Show dashboard'
complete -c avo -n __fish_use_subcommand -a pause -d 'Pause running timer'
complete -c avo -n __fish_use_subcommand -a resume -d 'Resume paused timer'
complete -c avo -n __fish_use_subcommand -a cancel -d 'Cancel timer without logging'
complete -c avo -n __fish_use_subcommand -a log -d 'Log time manually'
complete -c avo -n __fish_use_subcommand -a recent -d 'Show recent worklogs'
complete -c avo -n __fish_use_subcommand -a today -d 'Today\'s work summary'
complete -c avo -n __fish_use_subcommand -a daily -d 'Daily report for any date'
complete -c avo -n __fish_use_subcommand -a week -d 'This week\'s summary'
complete -c avo -n __fish_use_subcommand -a plan -d 'Daily planning'
complete -c avo -n __fish_use_subcommand -a task -d 'Task management'
complete -c avo -n __fish_use_subcommand -a project -d 'Project management'
complete -c avo -n __fish_use_subcommand -a worklog -d 'Worklog management'
complete -c avo -n __fish_use_subcommand -a jira -d 'Jira integration'
complete -c avo -n __fish_use_subcommand -a db -d 'Database inspection'

# start — dynamic task completions
complete -c avo -n '__fish_seen_subcommand_from start' -s n -l note -d 'Note about current work'
complete -c avo -n '__fish_seen_subcommand_from start; and not __fish_prev_arg_in -n --note' -a '(__avo_tasks)'

# log options
complete -c avo -n '__fish_seen_subcommand_from log' -s m -l message -d 'Comment for the worklog'

# recent options
complete -c avo -n '__fish_seen_subcommand_from recent' -s n -l count -d 'Number of entries'

# --- task subcommands ---
set -l __avo_task_subs add list done undone show delete undelete due cat note
complete -c avo -n "__fish_seen_subcommand_from task; and not __fish_seen_subcommand_from $__avo_task_subs" -a add -d 'Create a new task'
complete -c avo -n "__fish_seen_subcommand_from task; and not __fish_seen_subcommand_from $__avo_task_subs" -a list -d 'List tasks'
complete -c avo -n "__fish_seen_subcommand_from task; and not __fish_seen_subcommand_from $__avo_task_subs" -a done -d 'Mark task as done'
complete -c avo -n "__fish_seen_subcommand_from task; and not __fish_seen_subcommand_from $__avo_task_subs" -a undone -d 'Reopen a completed task'
complete -c avo -n "__fish_seen_subcommand_from task; and not __fish_seen_subcommand_from $__avo_task_subs" -a show -d 'Show task details'
complete -c avo -n "__fish_seen_subcommand_from task; and not __fish_seen_subcommand_from $__avo_task_subs" -a delete -d 'Delete a task'
complete -c avo -n "__fish_seen_subcommand_from task; and not __fish_seen_subcommand_from $__avo_task_subs" -a undelete -d 'Restore a deleted task'
complete -c avo -n "__fish_seen_subcommand_from task; and not __fish_seen_subcommand_from $__avo_task_subs" -a due -d 'Set due date'
complete -c avo -n "__fish_seen_subcommand_from task; and not __fish_seen_subcommand_from $__avo_task_subs" -a cat -d 'Set category'
complete -c avo -n "__fish_seen_subcommand_from task; and not __fish_seen_subcommand_from $__avo_task_subs" -a note -d 'Append note to task'

# task subcommands that take a task ID
complete -c avo -n '__fish_seen_subcommand_from task; and __fish_seen_subcommand_from show done undone delete undelete due cat note' -a '(__avo_tasks)'

# task add options
complete -c avo -n '__fish_seen_subcommand_from task; and __fish_seen_subcommand_from add' -s p -l project -d 'Project ID'
complete -c avo -n '__fish_seen_subcommand_from task; and __fish_seen_subcommand_from add' -l due -d 'Due date (YYYY-MM-DD)'
complete -c avo -n '__fish_seen_subcommand_from task; and __fish_seen_subcommand_from add' -l cat -d 'Category'

# task list options
complete -c avo -n '__fish_seen_subcommand_from task; and __fish_seen_subcommand_from list' -s a -l all -d 'Include completed tasks'
complete -c avo -n '__fish_seen_subcommand_from task; and __fish_seen_subcommand_from list' -l deleted -d 'Show only deleted tasks'
complete -c avo -n '__fish_seen_subcommand_from task; and __fish_seen_subcommand_from list' -s l -l local -d 'Show only local tasks'
complete -c avo -n '__fish_seen_subcommand_from task; and __fish_seen_subcommand_from list' -s s -l source -d 'Filter by source' -ra 'jira github'
complete -c avo -n '__fish_seen_subcommand_from task; and __fish_seen_subcommand_from list' -s p -l project -d 'Filter by project'
complete -c avo -n '__fish_seen_subcommand_from task; and __fish_seen_subcommand_from list' -l profile -d 'Filter by Jira profile'
complete -c avo -n '__fish_seen_subcommand_from task; and __fish_seen_subcommand_from list' -l format -d 'Output format' -ra completion

# --- project subcommands ---
complete -c avo -n '__fish_seen_subcommand_from project; and not __fish_seen_subcommand_from add list show delete' -a add -d 'Create a new project'
complete -c avo -n '__fish_seen_subcommand_from project; and not __fish_seen_subcommand_from add list show delete' -a list -d 'List projects'
complete -c avo -n '__fish_seen_subcommand_from project; and not __fish_seen_subcommand_from add list show delete' -a show -d 'Show project details'
complete -c avo -n '__fish_seen_subcommand_from project; and not __fish_seen_subcommand_from add list show delete' -a delete -d 'Delete a project'

# project add options
complete -c avo -n '__fish_seen_subcommand_from project; and __fish_seen_subcommand_from add' -s i -l icon -d 'Project icon'

# project list options
complete -c avo -n '__fish_seen_subcommand_from project; and __fish_seen_subcommand_from list' -s a -l all -d 'Include archived projects'

# --- worklog subcommands ---
set -l __avo_wl_subs list delete add edit
complete -c avo -n "__fish_seen_subcommand_from worklog; and not __fish_seen_subcommand_from $__avo_wl_subs" -a list -d 'List recent worklogs'
complete -c avo -n "__fish_seen_subcommand_from worklog; and not __fish_seen_subcommand_from $__avo_wl_subs" -a delete -d 'Delete a worklog'
complete -c avo -n "__fish_seen_subcommand_from worklog; and not __fish_seen_subcommand_from $__avo_wl_subs" -a add -d 'Add a manual worklog'
complete -c avo -n "__fish_seen_subcommand_from worklog; and not __fish_seen_subcommand_from $__avo_wl_subs" -a edit -d 'Edit a worklog'

# worklog list options
complete -c avo -n '__fish_seen_subcommand_from worklog; and __fish_seen_subcommand_from list' -s n -l count -d 'Number of entries'

# --- jira subcommands ---
complete -c avo -n '__fish_seen_subcommand_from jira; and not __fish_seen_subcommand_from init setup sync status' -a init -d 'Generate credentials template'
complete -c avo -n '__fish_seen_subcommand_from jira; and not __fish_seen_subcommand_from init setup sync status' -a setup -d 'Configure Jira connection'
complete -c avo -n '__fish_seen_subcommand_from jira; and not __fish_seen_subcommand_from init setup sync status' -a sync -d 'Sync with Jira'
complete -c avo -n '__fish_seen_subcommand_from jira; and not __fish_seen_subcommand_from init setup sync status' -a status -d 'Show Jira sync status'

# jira setup options
complete -c avo -n '__fish_seen_subcommand_from jira; and __fish_seen_subcommand_from setup' -l profile -d 'Profile name'

# jira sync options
complete -c avo -n '__fish_seen_subcommand_from jira; and __fish_seen_subcommand_from sync' -l profile -d 'Switch to profile before syncing'
complete -c avo -n '__fish_seen_subcommand_from jira; and __fish_seen_subcommand_from sync' -l dry-run -d 'Preview changes without applying'
complete -c avo -n '__fish_seen_subcommand_from jira; and __fish_seen_subcommand_from sync' -l no-interactive -d 'Skip conflict prompts'

# --- db subcommands ---
complete -c avo -n '__fish_seen_subcommand_from db; and not __fish_seen_subcommand_from stats orphans integrity dump' -a stats -d 'Show database statistics'
complete -c avo -n '__fish_seen_subcommand_from db; and not __fish_seen_subcommand_from stats orphans integrity dump' -a orphans -d 'Find orphaned records'
complete -c avo -n '__fish_seen_subcommand_from db; and not __fish_seen_subcommand_from stats orphans integrity dump' -a integrity -d 'Run integrity checks'
complete -c avo -n '__fish_seen_subcommand_from db; and not __fish_seen_subcommand_from stats orphans integrity dump' -a dump -d 'Dump tables as JSON'

# db dump options
complete -c avo -n '__fish_seen_subcommand_from db; and __fish_seen_subcommand_from dump' -s t -l table -d 'Table to dump' -ra 'tasks worklogs projects timer plans all'
