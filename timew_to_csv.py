#!/usr/bin/env nix-shell
#!nix-shell -i python -A pyEnv
'''Converts a timew JSON export to a convenient CSV to analyze and visualize.

JSON entries with multiple tags are split into several CSV entries.'''
import math
import subprocess
import sys
import pandas as pd

def is_entry_hooked_with_semantic_tags(tags):
    '''Returns whether the entry was manually entered by the user or got from our taskw hook with semantic tags.'''
    for tag in tags:
        if tag.startswith('uuid:'):
            uuid = ''.join(tag.split('uuid:')[1:])
            return True, uuid
    return False, None

def describe_interval(row):
    '''Returns a description of a row regardless of its type (hooked or not).'''
    if isinstance(row['task_description'], str):
        return row['task_description']
    return row['timew_tag']

def obtain_rich_df(taskw_df, timew_df):
    '''Merge taskwarrior and timewarrior dataframes into one dataframe.'''
    def add_hooked_or_not_row(row, rows):
        '''Convenience function to create the enriched dataframe.'''
        tags = row['tag']
        is_hooked, uuid = is_entry_hooked_with_semantic_tags(tags)

        if is_hooked:
            new_row = {
                'timew_interval_start': row['start'],
                'timew_interval_end': row['end'],
                'task_uuid': uuid,
            }
            rows.append(new_row)
        else:
            tag_to_keep = tags[0]
            if (len(tags) > 1):
                print("A manual entry has several tags. Only the first ({}) will be kept. Tags were {}".format(tag_to_keep, split_row), file=sys.stderr)
            new_row = {
                'timew_interval_start': row['start'],
                'timew_interval_end': row['end'],
                'timew_tag': tag_to_keep
            }
            rows.append(new_row)

    new_rows = []
    timew_df.apply(add_hooked_or_not_row, axis=1, args=(new_rows,))
    new_df = pd.DataFrame(new_rows)

    merged_df = pd.merge(new_df, taskw_df, on='task_uuid', how='left')
    merged_df['task_description'] = merged_df.apply(lambda row: describe_interval(row), axis=1)
    if 'timew_tag' in merged_df:
        merged_df.drop('timew_tag', axis=1, inplace=True)
    return merged_df

# Read input JSON from stdin (should be a timewarrior export).
time_df = pd.read_json(sys.stdin)
time_df.rename(columns={'tags':'tag'}, inplace=True)

# Call task to retrieve its database.
task_db_process = subprocess.run(["task", "export"], capture_output=True)
task_db = pd.read_json(task_db_process.stdout.decode('utf-8'))
task_db.rename(columns={col:'task_'+col for col in task_db.columns}, inplace=True)
task_db.rename(columns={'task_entry':'task_creation_date', 'task_modified':'task_last_modification_date'}, inplace=True)

# Generate a special merge of the two dataframes then write it on stdout.
rich_df = obtain_rich_df(task_db, time_df)
rich_df.to_csv(sys.stdout, index=False)
