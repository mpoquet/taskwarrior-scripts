#!/usr/bin/env python3
'''Converts a timew JSON export to a convenient CSV to analyze and visualize.

JSON entries with multiple tags are split into several CSV entries.'''
import sys
import pandas as pd

def multivalue_df_to_multientry_df(df, column):
    '''Splits an entry into several ones based on a column.

    For example, transformation on column='tag' transforms A into B.

    A:
    begin,end,tag
        0,  1,eat
        2,  3,[eat, drink]

    B:
    begin,end,  tag
        0,  1,  eat
        2,  3,  eat
        3,  3,drink
    '''

    def split_list_to_row(row, rows, col):
        '''Convenience function to achieve multivalue_df_to_multientry_df.'''
        split_row = row[col]
        for s in split_row:
            new_row = row.to_dict()
            new_row[col] = s
            rows.append(new_row)
    new_rows = []
    df.apply(split_list_to_row, axis=1, args=(new_rows, column))
    new_df = pd.DataFrame(new_rows)
    return new_df

a = pd.read_json(sys.stdin)
a.rename(columns={'tags':'tag'}, inplace=True)
b = multivalue_df_to_multientry_df(a, 'tag')
b.to_csv(sys.stdout, index=False)
