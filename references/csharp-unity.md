# C# Coding Style

Applies to C# code in a Unity project (game code, editor code, tests).

A project's `.editorconfig` can enforce part of this guide in the IDE
(Rider, Visual Studio, VS Code). Rules marked **[IDE]** are the ones such a
config checks; rules marked **[review]** are not, so the author and the reviewer
keep them by hand. Unity does not report IDE rules in its Console or block a
build on them.

## Guiding principles

- **Readability over brevity.** Write clear, self-documenting code. A good name
  beats a clever abbreviation.
- **Comment the "why", not the "what".** The code says what it does; a comment
  says why it does it, so a later reader does not undo a deliberate choice.

## Quick reference

| Element | Casing | Prefix | Example |
|---|---|---|---|
| Class, struct, delegate | PascalCase | — | `PlayerController`, `ScoreRecord` |
| Enum | PascalCase | `E` | `EGameState` |
| Interface | PascalCase | `I` | `IDamageable` |
| Public / protected field | PascalCase | — | `public int Score;` |
| Private / internal field | camelCase | `_` | `private int _maxHealth;` |
| Constant (`const`, field or local) | PascalCase | — | `private const int MaxSquads = 8;` |
| Property | PascalCase | — | `public int Health { get; }` |
| Method, event | PascalCase | — | `CalculateDamage()`, `PlayerDied` |
| Local variable | camelCase | — | `float totalDamage;` |
| Parameter | camelCase | — | `TakeDamage(int amount)` |

---

## 1. Formatting

### 1.1 Indent with 2 spaces, never tabs **[IDE]**

### 1.2 Braces on their own line (Allman) **[IDE]**

`else`, `catch` and `finally` also start a new line.

```csharp
// Good
if (isDead)
{
  Respawn();
}
else
{
  Move();
}

// Bad
if (isDead) {
  Respawn();
} else {
  Move();
}
```

### 1.3 Files end with a newline and carry no trailing whitespace **[IDE]**

---

## 2. Naming

### 2.1 Names reveal intent **[review]**

```csharp
// Good
Unit targetEnemy;
float secondsUntilDawn;

// Bad
Unit tEn;
float t;
```

Short names are fine where the scope is a few lines and the meaning is
conventional: loop indices (`i`, `j`), coordinates (`x`, `y`).

### 2.2 Casing follows the quick-reference table **[IDE]**

```csharp
public sealed class Squad
{
  private const int MaxMembers = 12;

  public int Morale;

  private int _memberCount;

  public int Size => _memberCount;

  public void AddMember(Unit newMember)
  {
    int slotIndex = _memberCount;
    // ...
  }
}
```

### 2.3 Booleans read as a yes/no question **[review]**

Prefix with a verb: `is`, `has`, `can`, `should`.

```csharp
// Good
bool isDead;
bool hasKey;
bool canJump;

// Bad
bool dead;
bool key;
bool jump;
```

### 2.4 Methods are verb phrases **[review]**

A method that returns `bool` is a question.

```csharp
// Good
void FireWeapon();
void LoadScene(string sceneName);
bool IsGameOver();
bool CanAfford(int cost);

// Bad
void Weapon();
bool GameOver();
```

### 2.5 Enums: `E` prefix; singular for plain enums, plural for `[Flags]` **[review]**

The prefix tells an enum from a class at a glance (`EGameState`, `ETileState`). One enum per
file, in the module's `Enums/` folder.

```csharp
public enum EDirection { North, East, South, West }

[Flags]
public enum EAttackModes
{
  None = 0,
  Melee = 1 << 0,
  Ranged = 1 << 1,
  Charge = 1 << 2,
}
```

### 2.6 Interfaces are adjectives, prefixed with `I` **[IDE prefix / review wording]**

```csharp
// Good
public interface IDamageable { void TakeDamage(int amount); }
public interface IHealable { void Heal(int amount); }

// Bad
public interface Damage { }
public interface IDamageManager { }   // a noun: this is a class role, not a capability
```

### 2.7 Renaming a serialized field loses data unless you say where it came from **[review]**

Unity stores `[SerializeField]` and public fields by name in scenes, prefabs and
assets. Renaming the field drops the saved value silently. Keep the old name with
`[FormerlySerializedAs]`:

```csharp
using UnityEngine.Serialization;

[FormerlySerializedAs("moveSpeed")]
[SerializeField] private float _moveSpeed = 5f;
```

Types read by `JsonUtility` bind by **exact field name**. Renaming such a field means
renaming the key in every JSON file that holds it, in the same change, or the value
loads as its default with no error.

---

## 3. Class and file structure

### 3.1 One MonoBehaviour per file, and the file has the class's name **[review]**

Unity cannot attach a MonoBehaviour whose file name differs from its class name.
Small helper classes and structs used only by that class may share the file.

```text
Assets/Scripts/Features/Gameplay/CameraRig.cs   →  public sealed class CameraRig : MonoBehaviour
```

### 3.2 Order of members **[review]**

1. Fields: static, then constant, then serialized, then private
2. Properties
3. Events
4. Constructors
5. MonoBehaviour messages (`Awake`, `OnEnable`, `Start`, `Update`, …, `OnDestroy`)
6. Public methods
7. Private methods
8. Nested classes and structs

```csharp
public sealed class Keep : MonoBehaviour
{
  private const int MaxArchers = 6;

  [Tooltip("Hit points the keep starts the night with.")]
  [SerializeField] private int _startingHp = 500;

  private int _hp;

  public bool IsStanding => _hp > 0;

  public event Action Fell;

  private void Awake()
  {
    _hp = _startingHp;
  }

  public void TakeDamage(int amount)
  {
    _hp -= amount;
    if (!IsStanding)
    {
      OnFell();
    }
  }

  private void OnFell() => Fell?.Invoke();

  private struct ArcherSlot
  {
    public int Index;
  }
}
```

### 3.3 `using` directives at the top, outside the namespace; no unused ones **[IDE]**

`System.*` comes first, the rest in alphabetical order.

```csharp
using System;
using System.Collections.Generic;
using Game.Foundation.Audio;
using UnityEngine;

namespace Game.Features.Gameplay
{
  // ...
}
```

### 3.4 No `#region` **[review]**

Regions hide classes that have grown too long. If a class needs regions to be
readable, split it: a partial class per concern (`Board.Match.cs`, `Board.Shuffle.cs`),
or a separate type.

### 3.5 Namespaces follow the folder **[review]**

Every type lives in a namespace that mirrors its folder path under the project's script
root, for example `Game.<Layer>.<Module>`. Folders below a module (`Logic/`,
`View/`, `SOs/`, …) sort its files and add no namespace segment. Namespaces are
block-scoped **[IDE]**: Unity 6 compiles C# 9, which has no file-scoped namespaces.

```csharp
// Assets/Scripts/Features/Gameplay/Logic/Board.cs
namespace Game.Features.Gameplay
{
  public sealed partial class Board { }
}
```

---

## 4. Comments and documentation

### 4.1 XML comments on every public class, method and property **[review]**

```csharp
/// <summary>
/// Applies damage to the character and checks for death.
/// </summary>
/// <param name="amount">The amount of damage to apply.</param>
public void TakeDamage(int amount)
{
  // ...
}
```

**Exception:** a test method (`[Test]`, `[UnityTest]`, `[TestCase]`, `[SetUp]`, `[TearDown]`) needs no comment:
its name says what it checks (`Sell_BrokenCross_IsRejected`). The test class keeps its summary.

**Exception:** a member that implements an interface member or overrides a base member
needs no comment of its own: the IDE shows the base one. Do not write `/// <inheritdoc/>`
for it. Write a comment only when the member does something the base comment does not say.

```csharp
// Good: the interface's comment covers it
public string Name => "Audio";

// Good: says what this implementation adds
/// <summary>A new instance of <paramref name="prefab"/> under <paramref name="parent"/>, its components injected.</summary>
public GameObject Instantiate(GameObject prefab, Transform parent) => _resolver.Instantiate(prefab, parent);

// Bad: says nothing the base does not
/// <inheritdoc/>
public string Name => "Audio";
```

### 4.2 Comments explain why **[review]**

```csharp
// Good: says why
// The cooldown counts down once per tick, so the blow lands when it reaches 0.
int next = Tick + Math.Max(1, unit.Cooldown);

// Bad: repeats the code
// Add the cooldown to the tick.
int next = Tick + Math.Max(1, unit.Cooldown);
```

### 4.3 `[Tooltip]` instead of a comment on Inspector fields **[review]**

The tooltip shows in the Inspector, where the designer tuning the value is looking.

```csharp
// Good
[Tooltip("The speed at which the player moves, in cells per second.")]
[SerializeField] private float _moveSpeed = 5f;

// Bad
// The speed at which the player moves.
[SerializeField] private float _moveSpeed = 5f;
```

### 4.4 No attribution comments **[review]**

Git records who changed what and when.

```csharp
// Bad
// Created by Alex, 2026-10-20
// Modified by ...
```

---

## 5. C# language

### 5.1 Always write the access modifier **[IDE]**

```csharp
// Good
private int _hp;
private void Die() { }
internal sealed class SquadSlot { }

// Bad
int _hp;
void Die() { }
sealed class SquadSlot { }
```

### 5.2 `[SerializeField] private` for Inspector fields, not `public` **[review]**

```csharp
// Good
[SerializeField] private float _moveSpeed = 5f;

// Bad: public only so the Inspector shows it
public float moveSpeed = 5f;
```

**Exception:** types Unity or `JsonUtility` serializes as plain data (`[Serializable]`
classes and structs) use public fields, because neither serializer reads properties.

### 5.3 `var` only when the right-hand side shows the type **[IDE]**

```csharp
// Good: the type is on the right
var player = GetComponent<PlayerController>();
var numbers = new List<int>();

// Good: the type is not obvious, so write it
int count = 5;
LevelData data = LoadLevel();

// Bad
var count = 5;
var data = LoadLevel();
```

### 5.4 Properties over public fields **[review]**

Use an auto-property for a plain get/set **[IDE]**, a private setter for a value only
the class changes, and an expression body for a short read-only property **[IDE]**.

```csharp
// Auto-implemented property
public string PlayerName { get; set; }

// Read-only from outside
public int Health { get; private set; }

private int _maxHealth;

// Concise read-only property
public bool IsAtMaxHealth => Health == _maxHealth;
```

The exception in 5.2 (serialized data types) applies here too.

### 5.5 Do not initialize a field or property to its default value **[review]**

A field or property already starts at its type's default (`0`, `0f`, `false`,
`null`, `default`). Writing it out adds noise and makes a reader look for a reason
that is not there. Initialize only when the starting value differs from the
default. This includes `[SerializeField]` fields. `const` is not affected: C#
requires its value. Where the non-default value is written depends on the type:
see 5.8.

```csharp
// Good: fields
private int _count;
private bool _isPaused;
private Unit _target;
[SerializeField] private float _moveSpeed = 5f;  // not the default: keep it (a MonoBehaviour, 5.8)

// Bad: fields
private int _count = 0;
private bool _isPaused = false;
private Unit _target = null;
[SerializeField] private float _delay = 0f;

// Good: properties
public int Kills { get; private set; }
public bool IsOpen { get; set; }
public string Title { get; set; }
public float Speed { get; set; }      // a plain class sets its 5f in the constructor (5.8)
public List<Unit> Members { get; }    // and its new List<Unit>() there too

// Bad: properties
public int Kills { get; private set; } = 0;
public bool IsOpen { get; set; } = false;
public string Title { get; set; } = null;
public Vector2 Offset { get; set; } = default;
```

### 5.6 Events **[review, except `?.Invoke` which is IDE]**

- Use `System.Action` (or `Action<T>`) for simple events.
- Name the event with a verb phrase in the past tense: `PlayerDied`, `TimerExpired`.
- Name the method that raises it `On` + event name: `OnPlayerDied()`.
- Invoke with `?.` so an event with no subscribers does not throw **[IDE]**.

```csharp
public event Action PlayerDied;

private void Die()
{
  // ... death logic
  OnPlayerDied();
}

private void OnPlayerDied() => PlayerDied?.Invoke();
```

### 5.7 `static` only when there is no other choice **[review]**

Static state is shared by everything and owned by nothing: it survives scene loads
and test runs, cannot be replaced by a fake in a unit test, and hides who depends
on whom. Make members and classes instance members, and pass what a class needs in
through its constructor, a serialized field or a method parameter.

`static` is allowed only where C# or Unity leaves no other way:

- `const` (implicitly static).
- Extension methods and the `static class` that holds them.
- Methods Unity calls through an attribute that requires `static`:
  `[MenuItem]`, `[RuntimeInitializeOnLoadMethod]`, `[InitializeOnLoadMethod]`,
  `[DidReloadScripts]`, and the static constructor of an `[InitializeOnLoad]` class.

Never use mutable static fields, static events or static singletons (`Instance`).

```csharp
// Good: the dependency is handed in, so a test can pass its own
public sealed class Hud
{
  private readonly GameSettings _settings;

  public Hud(GameSettings settings)
  {
    _settings = settings;
    _settings.Changed += Refresh;
  }
}

// Good: Unity requires this method to be static
public static class BuildTool
{
  [MenuItem("Game/Build macOS")]
  private static void BuildMac() { }
}

// Bad: global mutable state, reachable from anywhere
public sealed class GameSettings
{
  public static GameSettings Instance;
  public static event Action Changed;
  public static float MusicVolume;
}
```

### 5.8 A plain class sets its starting values in the constructor **[review]**

In a plain C# class (anything that is not a `MonoBehaviour` or `ScriptableObject`),
an instance field or auto-property whose starting value is not the default gets it
in the constructor, not at its declaration. Add a parameterless constructor if the
class has none.

Why: the constructor is then the one place that shows everything an instance
starts with. Initializers at the declarations scatter that across the class and run
before the base constructor and the constructor body, an order a reader does not
see.

Not affected:

- `const`, and `static` fields (an instance constructor cannot set them).
- Types Unity serializes: `MonoBehaviour`, `ScriptableObject`, and `[Serializable]`
  data. Unity advises against constructors on its objects, and the initializer is the
  default the Inspector shows, so a value such as `= 5f` stays at the declaration. An
  object made with `new` does not: see 5.9.

```csharp
// Good
public sealed class Squad
{
  private readonly List<Unit> _members;
  private float _morale;

  /// <summary>An empty squad at full morale.</summary>
  public Squad()
  {
    _members = new List<Unit>();
    _morale = 1f;
  }
}

// Bad
public sealed class Squad
{
  private readonly List<Unit> _members = new List<Unit>();
  private float _morale = 1f;
}
```

### 5.9 `new` where the object is needed, never at the declaration **[review]**

A field or property is never initialized with `new` where it is declared. The object
is made where it is first needed:

- a plain class: in its constructor (5.8);
- a `MonoBehaviour` or `ScriptableObject`: in `Awake` or `OnEnable`, and only when the
  field is still null, so the value Unity loaded from the scene or asset is kept;
- an object only some calls need: at the first use (made lazily).

Why: an initializer at the declaration runs for every instance, before the
constructor and before Unity loads the saved values, and hides where the object
comes from. Making it in one known place shows when it exists.

A value that is not an object (`= 5f`, `= true`, an enum, a struct such as
`= new Color(1f, 0.8f, 0.2f)` or `= new Vector2(0f, 40f)`) is not affected: a struct is copied, not shared, and for a
serialized field the initializer is the default the Inspector shows. 5.5 and 5.8 say where it goes.

```csharp
// Good: a ScriptableObject made with CreateInstance has no list until OnEnable
[field: SerializeField] public List<AudioEntrySO> Entries { get; private set; }

private void OnEnable()
{
  if (Entries == null)
  {
    Entries = new List<AudioEntrySO>();
  }
}

// Good: made at the first lookup
private Dictionary<string, AudioEntrySO> _entriesByKey;

public bool TryGet(string key, out AudioEntrySO entry)
{
  if (_entriesByKey == null)
  {
    BuildEntriesByKey();
  }
  // ...
}

// Bad
[SerializeField] private List<AudioEntrySO> _entries = new List<AudioEntrySO>();
private readonly Dictionary<string, float> _lastPlayTimes = new Dictionary<string, float>();
```

### 5.10 Name a condition that has two operations or more **[review]**

When the condition of an `if` holds two operators or more (`&&`, `||`, a
comparison, arithmetic), put it in a `bool` local with a name that says what it
means (2.3), or in a private method that returns `bool` (2.4), and test that name.
A single check (`if (!IsAlive)`, `if (clip == null)`) stays in the `if`.

Why: the name says what is being decided; the reader does not have to work it out
from the operators, and a long condition no longer hides a step.

```csharp
// Good
bool isSameTrack = key == CurrentBGM;
bool isUnchanged = isSameTrack && (key == null || _musicSource.isPlaying);
if (isUnchanged)
{
  return;
}

if (IsTooSoon(key, now, minGap))
{
  return false;
}

// Bad
if (key == CurrentBGM && (key == null || _musicSource.isPlaying))
{
  return;
}

if (_lastPlayTimes.TryGetValue(key, out float last) && now - last < minGap)
{
  return false;
}
```
