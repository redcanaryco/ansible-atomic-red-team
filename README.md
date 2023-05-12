ansible_atomic_red_team
=========

A role to execute atomic red team tests.

This role facilitates executing Atomic Red Team tests via PowerShell and
Invoke-AtomicRedTeam, on Windows and Linux hosts. It runs powershell core if
necessary, installs Invoke-AtomicRedTeam and adds it to the powershell profile,
and then runs tests against target hosts in the ansible-inventory.

This role can be included in a playbook using `include_role` along with
variables with a list of Atomic Red Team tests to execute.

Tests are specified by Technique ID and optionally also by TestNumber or
TestGuid to pick specific ART tests.

The default variables contain a list of "banned" TIDs, which contain behavior
that is not condusive to automated or repeated testing (eg [T1070.004-8 Delete
Filesystem
Linux](https://github.com/redcanaryco/atomic-red-team/blob/master/atomics/T1070.004/T1070.004.md#atomic-test-8---delete-filesystem---linux),
or involve extended dependencies or resources beyond a single VM (eg cloud
tests). These tests are filtered out at the TID level (eg, matching
`T[0-9]{4}(\.?[0-9]{3})?`), but can still be specified by TID+GUID if desired.

## Why another way to execute ART Tests?

There are several exellent execution frameworks for Atomic Red Team, but we desired easy
integreation between our test framework and other devops tools that create VMs,
configure sensors and prerequisites, and run other non-AtomicRedTeam tests.

Ansible and Terraform allow us to meet these goals for fully automated
testing. Terraform creates VMs provisioned by Ansible. Ansible playbooks run
test scenarios so that we can repeatably generate live telemetry for testing
using different combinations of sensors or configurations. This playbook
integrates Atomic Red Team into this automation-focused testing model.

## Notes

Each TID should to 'evaluated' manually prior to being permanently added to the
defaults, as some tests are 'unsafe.' This is why this role doesn't execute
all the TIDs.

`tasks/gather-art-tids.yml` runs locally from the ansible host, to directly
query the Atomic Red Team test inventory CSV files on github and create/update
`{{ playbook_dir }}/art-tids.yml`. This file is used by the playbook when running
all execpt "banned" TIDs.

If you want to disable this fetch from github on the machine running the
playbook, set `disable_fetch_art_index: true`. This will cause
`tasks/main.yml` to fall back to `vars/art-tids.yml` which can be manually
updates with `vars/update-art-tids.sh`


Role Variables
--------------

in `defaults/main.yml`:
- `banned_tids_linux`: annotated list of TIDs to *NOT* run
- `art_tids_linux`: list of the linux TIDs available in ART
- `art_tids_mac`: list of the mac TIDs available in ART
- `art_tids_windows`: list of the windows TIDs available in ART
- `art_repository_owner: redcanaryco` - override with the github repo owner for the atomic_red_team repo to use.
- `art_branch: master` - override with the branch to use


Example Playbook
----------------

Including an example of how to use your role (for instance, with variables passed in as parameters) is always nice for users too:

```yaml
---
- hosts: all
  gather_facts: True
  become: True
  tasks:

    - include_role:
        name: ansible_atomic_red_team
        # you cannot use become directly on include_role, but can control elevation using apply
        apply:
          become: True
      when: ansible_system == 'Linux'
      vars:
        art_tids_linux:
          - T1136.001
          - T1053.003
          - T1003.008-1,2,3
          - T1003.008 f5aa6543-6cb2-4fae-b9c2-b96e14721713
          - T1070.003 47966a1d-df4f-4078-af65-db6d9aa20739,7e6721df-5f08-4370-9255-f06d8a77af4c
        # separators MUST be - for TID and testnumbers
        # separator MAY be ' ' or ':' for TID and GUIDs
        # TID.SUBTID MUST be specified and match GUIDs, as required by Invoke-AtomicTest

    - include_role:
        name: ansible_atomic_red_team
        apply:
          become: False
      when: ansible_system == 'Win32NT'
      vars:
        art_tids_windows:
          - T1027
          - T1053.005
          - T1547.001-1,2
          - T1547.001:eb44f842-0457-4ddc-9b92-c4caa144ac42
          - T1547.001:2cb98256-625e-4da9-9d44-f2e5f90b8bd5,dade9447-791e-4c8f-b04b-3a35855dfa06

    # this runs all available tests against all target systems
    # - include_role:
    #     name: ansible_atomic_red_team
```
