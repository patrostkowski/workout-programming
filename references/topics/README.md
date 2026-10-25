# Topic files

One topic file per language, named after the language id: `references/topics/<id>.md`, where `<id>` is the same id used by `scripts/new-workout.sh` and `scripts/validate-<id>.sh`.

Current ids: `go`, `c`.

## Shape

```markdown
# <Language> topic areas

## Areas

- `<Area name>`: <one line, usable as the topic question's description>.
- `<Area name>`: <one line>.

## Easy

<scope note>

### <Group>
- <topic>

## Medium

Areas added at this level. Medium includes every easy topic.

### <Group>
- <topic>

## Hard

Areas added at this level. Hard includes every easy and medium topic.

### <Group>
- <topic>
```

- `## Areas` holds 1 to 4 area names. They become the session-start topic options, after `Random`, and are the rotation buckets.
- Each level lists only the topics added at that level. Do not repeat inherited lists; the levels are cumulative.
- Keep bullets short and concrete. A single task draws on one or two bullets, not a whole group.
- A group is a sub-theme inside a level. It does not have to match an area name.

## Adding a language

1. `references/<id>.md`: setup, code scope, test scaffold, doc links, and validation for that language.
2. `references/topics/<id>.md`: the file described above.
3. `scripts/validate-<id>.sh`: runs the checks, prints raw tool output, ends with a `PASS`, `FAIL`, `WARN`, or `NOTE` summary, and exits non-zero on a required failure.
4. `scripts/new-workout.sh`: add the `<id>` case that writes the entry file and build files.

`SKILL.md` needs no change. It resolves the language, its reference, and its topic file from the id.
