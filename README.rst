taskwarrior scripts
===================

This repository contains various scripts around taskwarrior_.

- A hook to synchronize taskwarrior_'s start/stop with timewarrior_.
- Scripts to manipulate data exported from taskwarrior_ and timewarrior_.
- Scripts to visualize timewarrior_ data.

**This is a work in progress**.
Data structures and script interfaces are not stable for the moment.

Install instructions
--------------------

Installing taskwarrior_'s hook is essentially adding a file in your taskwarrior_ directory.
The following script shows how it can be done —
please refer to `taskwarrior hooks documentation`_ for details.

.. code-block:: bash

    # Install taskwarrior's hook script
    taskw_dir=$(realpath ${HOME}/.task)
    repo_dir=$(realpath .)
    ln -s ${repo_dir}/hook-on-modify-timewarrior.py ${taskw_dir}/hooks/on-modify-timewarrior

Other scripts are not installable yet.
Calling them directly requires Nix_ for the moment.
Directly call the script with an interpreter if you want to avoid this.

.. _taskwarrior: https://taskwarrior.org/docs
.. _taskwarrior hooks documentation: https://taskwarrior.org/docs/hooks.html
.. _timewarrior: https://taskwarrior.org/docs/timewarrior/
.. _Nix: https://nixos.org/nix/
