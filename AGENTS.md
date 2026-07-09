# AGENTS.md

This file provides guidance to AI agents when working with code in this repository.

## What this module does

`simp-simp_snmpd` is a SIMP Puppet module that configures the **Net-SNMP agent
(`snmpd`)** on Enterprise Linux, driving the upstream `puppet/snmp` module with a
SIMP-flavoured, **SNMPv3 USM-only** opinion. It does *not* configure the
`snmptrap` service (only puts down enough config to point the trap daemon at a
user directory), and it explicitly refuses any protocol version other than 3
(`manifests/init.pp:3,234-250`, `types/secmodel.pp:4`).

The core job is to translate four Hiera hashes — users, views, groups, and
access entries — into the `snmp.conf`/`snmpd.conf` USM and VACM directives that
`puppet/snmp` expects, generate SNMPv3 credentials, and optionally wire up the
firewall, TCP wrappers, syslog/logrotate, and rsync integrations that a SIMP
host normally wants. The install → config flow is a fixed chain:

```
Class['simp_snmpd::install'] -> Class['simp_snmpd::config'] ~> Service['snmpd']
```

(`manifests/init.pp:238-240`), with `simp_snmpd::rsync` appended after `config`
when either rsync toggle is on (`init.pp:242-245`).

### Business logic

The public entry class is `simp_snmpd`; everything else is `assert_private()`'d
(see the Gotchas section for the list). `simp_snmpd::install::vacmusers` is a
private *parameterized* class (it takes a `$daemon`), and the four functions plus
three types are the data-transformation layer.

- **`simp_snmpd` (`manifests/init.pp:172-251`)** — Public class. Four **required,
  defaultless** `Hash` parameters — `$v3_users_hash`, `$view_hash`,
  `$group_hash`, `$access_hash` (`init.pp:173-176`) — are supplied from module
  data (`data/common.yaml`) and deep-merged (all four have `merge: strategy:
  hash` `lookup_options`, `data/common.yaml:2-13`). `$snmpd_options` is likewise
  required and comes from data (`data/common.yaml` → `'-LS0-6d'`). Version-gates
  on `$version == 3`: any other value just emits a `notify` telling you to use
  `puppet/snmp` directly (`init.pp:247-250`). The nine `simp_options::*` defaults
  are the config seam (see the table below).

- **`simp_snmpd::install` (`manifests/install.pp`)** — Runs *before* config.
  Key behaviours:
  - **FIPS pre-flight** (`install.pp:13-20`): if `$fips` **or** the
    `fips_enabled` fact is true, `fail()`s when `$defauthtype == 'MD5'` or
    `$defprivtype == 'DES'` — those algorithms are not FIPS-allowed. (The same
    check is repeated per-user in `vacmusers`, see below.)
  - **includeDir wiring** (`install.pp:25-37`): always adds `includeDir
    ${simp_snmpd_dir}`; when `$include_userdir` is true it *also* creates and
    includes `${user_snmpd_dir}`. Order matters — "last one wins", so the
    user directory is listed after the SIMP directory so operators can override
    SIMP's files (`install.pp:22-24`).
  - Manages `${simp_snmpd_dir}` as a **recursed, purged** directory
    (`install.pp:39-47`) — files not managed by Puppet in there are removed.
  - `manage_client` (`install.pp:57-78`): when true, seeds `snmp.conf` client
    defaults (`defVersion`/`defSecurityModel`/`defSecurityLevel`/`defAuthType`/
    `defPrivType`/`mibdirs`). When false, `$_snmp_config = []` and the class
    creates `${snmp_basedir}` itself, because `puppet/snmp` only creates that
    directory when the client is managed (`install.pp:68-78`).
  - `$_autoupgrade` is derived from `$package_ensure`: `true` only when it is
    `'latest'` (`install.pp:80-83`).
  - Trap config dir (`install.pp:84-98`): the user trap dir + `includeDir` line
    are only created when `$trap_service_ensure != 'stopped'`.
  - **Data transform** (`install.pp:100-103`): calls the three list functions to
    turn the view/group/access hashes into arrays of `snmpd.conf` directive
    strings, then declares `class { 'simp_snmpd::install::vacmusers': daemon =>
    'snmpd' }` and the big `class { 'snmp': ... }` (`install.pp:106-142`),
    passing the generated `views`/`groups`/`accesses` arrays and forcing
    `com2sec`/`com2sec6` empty (USM-only, no community strings).

- **`simp_snmpd::install::vacmusers` (`manifests/install/vacmusers.pp`)** —
  Private, `$daemon`-parameterized. Iterates `$v3_users_hash` and declares a
  `snmp::snmpv3_user` per user (`vacmusers.pp:37-43`). Per user:
  - `authpass`/`privpass`: if the hash value is `undef`/`UNDEF` (string or real
    undef) it **auto-generates a stable password** via
    `simplib::passgen("snmp_auth_${user}")` / `passgen("snmp_priv_${user}")`;
    otherwise it uses the supplied value (`vacmusers.pp:13-20`).
  - `authtype`/`privtype` default to `$defauthtype`/`$defprivtype` when unset
    (`vacmusers.pp:21-26`).
  - **Per-user FIPS guard** (`vacmusers.pp:28-35`): re-checks the *resolved*
    per-user auth/priv types (which may differ from the class defaults) and
    `fail()`s on `MD5`/`DES` under FIPS.

- **`simp_snmpd::config` (`manifests/config.pp`)** — `contain`s
  `config::agent` unconditionally, then `include`s `config::firewall`,
  `config::tcpwrappers`, and `config::logging` gated on `$firewall`,
  `$tcpwrappers`, and `$syslog` respectively (`config.pp:6-19`).
  - **`config::agent` (`config/agent.pp`)** — writes
    `${simp_snmpd_dir}/agent.conf` from `templates/snmpd/agent.conf.epp`
    (agentuser/agentgroup, getbulk limits, leave_pidfile).
  - **`config::firewall` (`config/firewall.pp`)** — asserts `simp/iptables`,
    runs `simp_snmpd::firewall_list($agentaddress)`, then opens
    `iptables::listen::udp` / `iptables::listen::tcp_stateful` per parsed entry
    with `trusted_nets => $trusted_nets`. `ipx`/`pvc` and other transports are
    silently ignored (`config/firewall.pp:3-8,16-34`).
  - **`config::logging` (`config/logging.pp`)** — asserts `simp/rsyslog`,
    `include`s `rsyslog`, adds an `rsyslog::rule::local` routing `programname ==
    'snmpd'` to `$logfile` with `stop_processing => true`; if `$logrotate` is
    also set, asserts `simp/logrotate` and adds a `logrotate::rule`. Manages
    `$logfile` with `seltype => 'snmpd_log_t'`.
  - **`config::tcpwrappers` (`config/tcpwrappers.pp`)** — asserts
    `simp/tcpwrappers`, `include`s `tcpwrappers`, adds `tcpwrappers::allow {
    'snmpd': pattern => $trusted_nets }`.

- **`simp_snmpd::rsync` (`manifests/rsync.pp`)** — the **only** non-private,
  non-entry class (no `assert_private()`). Asserts `simp/rsync`, `include`s
  `rsync`, and pulls dlmod `.so` modules (`rsync_dlmod`) and/or MIBs
  (`rsync_mibs`) from `$rsync_server`, authenticating with a `simplib::passgen`
  password keyed on `snmp_${environment}_${os_name}`. When `$dlmods` is set it
  writes a `dlmod.conf` with `dlmod` lines. All rsyncs `notify => Service['snmpd']`.

- **`simp_snmpd::install::snmpduser` (`manifests/install/snmpduser.pp`)** —
  Included only when `$manage_snmpd_user` or `$manage_snmpd_group`. Creates the
  config owner `user` / group `group` — but **only when the owner/group is not
  `'root'`** (`snmpduser.pp:8-25`).

**The VACM / USM model.** SNMPv3 access control is expressed as four moving
parts that the module builds from Hiera and hands to `puppet/snmp`:

1. **Users** (`$v3_users_hash`) → `snmp::snmpv3_user` — USM identities with
   auth/priv type + password (auto-generated if omitted).
2. **Views** (`$view_hash`) → `simp_snmpd::viewlist` — each entry is
   `included`/`excluded` OID subtrees, emitted as `"<viewname> <included|
   excluded> <oid>"` lines (`viewlist.rb:16-38`). Any key other than
   included/excluded raises.
3. **Groups** (`$group_hash`) → `simp_snmpd::grouplist` — map a security name
   (user) to a group under a security model, emitted as `"<group> <model>
   <secname>"`; `secname` may be an array (one line each). Requires `secname`;
   validates `model` (`grouplist.rb:18-42`).
4. **Access** (`$access_hash`) → `simp_snmpd::accesslist` — bind a group to a
   `read/write/notify` view triple at a security level, emitted as `"<group>
   <context> <model> <level> <prefx> <read> <write> <notify>"`; requires both
   `view` and `groups`, defaults unspecified views to `none` and level/model to
   the class defaults (`accesslist.rb:21-80`).

`data/common.yaml` ships a working example of all four (users `snmp_ro`/
`snmp_rw`, `systemview`/`iso1` views, `readonly_group`/`readwrite_group`,
`readaccess`/`systemwrite` access).

**Functions** (all Ruby, `lib/puppet/functions/simp_snmpd/`, all return arrays
of `snmpd.conf` directive strings):

- `simp_snmpd::accesslist(access_hash, defaultmodel, defaultlevel)` — VACM
  access lines (`accesslist.rb`).
- `simp_snmpd::firewall_list(agent_array)` — parses `$agentaddress` entries into
  `[protocol, port, apply]` triples for the firewall class; skips
  `localhost`/`127.0.0.1`/`[::1]` and non-IP transports, defaults port 161 (22
  for ssh) (`firewall_list.rb`).
- `simp_snmpd::grouplist(group_hash, defaultmodel)` — VACM group lines
  (`grouplist.rb`).
- `simp_snmpd::viewlist(view_hash)` — VACM view lines (`viewlist.rb`).

**Types** (`types/`):

- `Simp_snmpd::Seclevel = Enum['noAuthNoPriv','authNoPriv','authPriv']`
  (`seclevel.pp:2`).
- `Simp_snmpd::Secmodel = Enum['usm']` — **USM only** by design; the broader
  enum is commented out (`secmodel.pp:1-4`).
- `Simp_snmpd::Vacmlevel = Enum['noauth','auth','priv']` (`vacmlevel.pp:2`).

**Templates** (`templates/`): `snmpd/agent.conf.epp` (EPP, agent.conf, used by
`config::agent`); `snmp/snmpd.conf.erb` and `snmp/snmptrapd.conf.erb` (ERB —
present in-tree but the config path drives `puppet/snmp`, which renders the
main config files).

### Gotchas / non-obvious details

- **USM / SNMPv3 only.** `$version` other than `3` does nothing but emit a
  `notify` (`init.pp:247-250`); `Secmodel` is locked to `usm` (`secmodel.pp:4`);
  `com2sec`/`com2sec6` are forced empty (`install.pp:136-137`). No SNMPv1/v2c
  community strings. Use `puppet/snmp` directly for older versions.
- **This module does not manage snmptrap.** It only lays down an `includeDir`
  for the trap daemon and leaves the service `stopped` by default
  (`init.pp:182-183`, `install.pp:84-98`).
- **FIPS is enforced in two places.** Class-level pre-flight on the *defaults*
  (`install.pp:13-20`) and per-user on the *resolved* types
  (`vacmusers.pp:28-35`). A user can set a per-user `authtype`/`privtype` that
  passes the class check but fails the per-user check. Both trigger on `$fips`
  **or** the live `fips_enabled` fact.
- **The `${simp_snmpd_dir}` is purged** (`install.pp:44-45`) — anything Puppet
  doesn't manage there is deleted. The `${user_snmpd_dir}` (`snmpd.d`) is the
  intended place for out-of-band operator config, and only exists when
  `$include_userdir` is true.
- **Passwords are auto-generated and stable** via `simplib::passgen` keyed on
  the username (`vacmusers.pp:13-20`) and on `snmp_${environment}_${os_name}`
  for rsync (`rsync.pp:23-24,57-58`). Omitting `authpass`/`privpass` is the norm,
  not an error.
- **Every optional integration is guarded** by
  `simplib::assert_optional_dependency` *and* a `simp_options::*` toggle
  (default `false`); nothing optional is hard-`include`d. See the dependency and
  seam sections.
- **`rsync` is the one non-private class besides the entry class** — it has no
  `assert_private()` (`rsync.pp`), unlike the other seven manifests.
- **`snmpduser` no-ops for `root`.** User/group are only created when the
  configured owner/group differs from `'root'` (`snmpduser.pp:9,18`).
- **`system_info` is deprecated** — `puppet/snmp` always sets the system
  parameters, so there is no way to leave them writable (`init.pp:141-146`).
- **`simp/simp_options` is NOT a declared dependency**, yet the manifest reads
  the `simp_options::*` seam via `simplib::lookup` (provided by `simp/simplib`).
  Keep the explicit `default_value` on every lookup.

### Manifests using `assert_private()`

Seven of the ten classes are private (only `simp_snmpd` and `simp_snmpd::rsync`
are not): `config.pp:4`, `config/agent.pp:5`, `config/firewall.pp:11`,
`config/logging.pp:4`, `config/tcpwrappers.pp:7`, `install/snmpduser.pp:6`,
`install/vacmusers.pp:9`.

## The `simp_options` / `simplib::lookup` seam

This is the module's SIMP-integration seam (the natural target for a lookup-path
unit test). All nine calls are parameter defaults in `manifests/init.pp`:

| Line | Key | `default_value` |
|------|-----|-----------------|
| `init.pp:223` | `simp_options::rsync::server` | `'127.0.0.1'` |
| `init.pp:224` | `simp_options::rsync::timeout` | `2` |
| `init.pp:225` | `simp_options::firewall` | `false` |
| `init.pp:226` | `simp_options::tcpwrappers` | `false` |
| `init.pp:227` | `simp_options::syslog` | `false` |
| `init.pp:228` | `simp_options::logrotate` | `false` |
| `init.pp:229` | `simp_options::fips` | `false` |
| `init.pp:230` | `simp_options::trusted_nets` | `['127.0.0.1']` |
| `init.pp:231` | `simp_options::package_ensure` | `'installed'` |

Keep routing SIMP feature toggles through `simplib::lookup('simp_options::*', {
'default_value' => ... })` with an explicit default rather than assuming
`simp_options` is included.

## Dependencies

Module dependencies (from `metadata.json`):

- `simp/simplib` `>= 4.9.0 < 5.0.0` (provides `simplib::lookup`,
  `simplib::assert_optional_dependency`, `simplib::passgen`, and the `Simplib::*`
  types).
- `puppet/snmp` `>= 5.1.0 < 8.0.0` (the upstream Net-SNMP module — provides
  `class { 'snmp' }` and the `snmp::snmpv3_user` define this module drives).
- `puppetlabs/stdlib` `>= 8.0.0 < 10.0.0` (provides `Stdlib::*` types and
  `pick()`).

Optional dependencies (from `metadata.json` `simp.optional_dependencies`), each
enforced at runtime by `simplib::assert_optional_dependency` only when its
`simp_options` toggle is on:

- `simp/tcpwrappers` `>= 6.2.0 < 7.0.0` (`config/tcpwrappers.pp:9`)
- `simp/iptables` `>= 6.5.3 < 8.0.0` (`config/firewall.pp:13`)
- `simp/rsyslog` `>= 7.6.0 < 9.0.0` (`config/logging.pp:6`)
- `simp/logrotate` `>= 6.5.0 < 7.0.0` (`config/logging.pp:18`)
- `simp/rsync` `>= 6.1.1 < 8.0.0` (`rsync.pp:5`)

Runtime requirement (from `metadata.json` `requirements`): `puppet
>= 7.0.0 < 9.0.0`. This is an **older baseline** that still names `puppet`. SIMP
is migrating Puppet → OpenVox; when `metadata.json` switches this to `openvox`,
update this line (and the `Gemfile` gem, below) to match.

Supported OS matrix (from `metadata.json`): CentOS 7/8/9; RedHat 7/8/9;
OracleLinux 7/8/9; Rocky 8/9; AlmaLinux 8/9.

## Repository layout

- `manifests/init.pp` — public `simp_snmpd` class; parameters + the version gate
  and install→config→service chain.
- `manifests/install.pp` — `simp_snmpd::install`; FIPS pre-flight, includeDir
  wiring, data transform, the `class { 'snmp' }` declaration.
- `manifests/install/vacmusers.pp` — private, `$daemon`-parameterized; creates
  `snmp::snmpv3_user` per user (auto-passgen, per-user FIPS guard).
- `manifests/install/snmpduser.pp` — private; optional owner user/group.
- `manifests/config.pp` — private; contains `config::agent`, gates the three
  optional config classes.
- `manifests/config/{agent,firewall,logging,tcpwrappers}.pp` — private config
  sub-classes (agent.conf template; iptables; rsyslog+logrotate; tcpwrappers).
- `manifests/rsync.pp` — `simp_snmpd::rsync`; dlmod/MIB rsync (non-private).
- `lib/puppet/functions/simp_snmpd/{accesslist,firewall_list,grouplist,viewlist}.rb`
  — Ruby functions that build `snmpd.conf` directive arrays.
- `types/{seclevel,secmodel,vacmlevel}.pp` — the three custom data types.
- `templates/snmpd/agent.conf.epp`, `templates/snmp/{snmpd,snmptrapd}.conf.erb`
  — config templates.
- `data/common.yaml` — required hashes (users/views/groups/access), their
  `hash`-merge `lookup_options`, and `snmpd_options`.
- `metadata.json` — deps, optional deps, OS matrix, Puppet requirement.
- `spec/` — rspec-puppet unit tests; `spec/spec_helper.rb:11` requires
  `puppetlabs_spec_helper/module_spec_helper`.
- `REFERENCE.md` — generated Puppet Strings reference.
- **CI has no acceptance job.** `.github/workflows/pr_tests.yml` runs the
  standard six jobs only (`puppet-syntax`, `puppet-style`, `ruby-style`,
  `file-checks`, `releng-checks`, `spec-tests`). Beaker nodesets exist
  (`spec/acceptance/nodesets/default.yml`, `oel.yml`) but are **run manually**,
  not in CI.

## Common commands

```sh
# Install dependencies
bundle install

# Run all unit tests
bundle exec rake spec

# Puppet lint
bundle exec rake lint

# Ruby lint
bundle exec rake rubocop

# Regenerate REFERENCE.md from puppet-strings docstrings
puppet strings generate --format markdown --out REFERENCE.md

# Run a beaker acceptance suite manually (not run in CI)
bundle exec rake beaker:suites[default]
bundle exec rake beaker:suites[default,oel]
```

Relevant gem pins (from `Gemfile`): the tested Puppet range defaults to
`['>= 7', '< 9']` (`Gemfile:23`) and is applied via `gem 'puppet',
puppet_version` — the **`puppet` gem only** (`Gemfile:29`), matching the older
`metadata.json` baseline. Other pins: `rubocop ~> 1.88.0` (`Gemfile:16`),
`puppetlabs_spec_helper ~> 8.0.0` (`Gemfile:30`), `simp-rake-helpers ~> 5.24.0`
(`Gemfile:36`), `simp-beaker-helpers ~> 2.0.0` (`Gemfile:52`).

## Conventions

- Preserve the `@summary` / `@param` puppet-strings docstrings — they drive
  `REFERENCE.md`. Regenerate `REFERENCE.md` after changing docs or parameters.
- Keep the module **USM/SNMPv3-only**: don't reintroduce `com2sec` or non-`usm`
  security models here — send those to `puppet/snmp` directly.
- Build `snmpd.conf` directives through the four functions; keep their strict
  validation (unknown keys raise) rather than silently accepting bad hashes.
- Enforce FIPS at both the class default level and per-user, matching the
  existing double check — never let `MD5`/`DES` through under FIPS.
- Guard every optional integration with `simplib::assert_optional_dependency`
  plus its `simp_options::*` toggle; don't hard-`include` optional modules.
- Route SIMP feature toggles through `simplib::lookup('simp_options::*', {
  'default_value' => ... })` with an explicit default.
- Keep the required hashes and `snmpd_options` in `data/common.yaml` with their
  `hash`-merge `lookup_options`, not hard-coded in the manifest.
- `Gemfile`, `spec/spec_helper.rb`, and `.github/workflows/pr_tests.yml` are
  baseline-managed (puppetsync) — push changes upstream to the baseline, not
  here.
- Match the existing 2-space Puppet indentation and aligned-arrow parameter
  style used in `manifests/init.pp`.
