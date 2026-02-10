<!-- markdownlint-disable MD033 -->
# bashrc

These bashrc runtime configurations are implemented with modularity to improve organization and maintainability.

> [!TIP]
> While these are my personal runtime configs, they may be used by anyone. Fork away. Observe the license.

> [!CAUTION]
> Remember, don't commit credentials. Use [infisical](https://github.com/Infisical/infisical), [Dashlane CLI](https://cli.dashlane.com), [chamber](https://github.com/segmentio/chamber), [KSM](https://docs.keeper.io/en/keeperpam/secrets-manager/secrets-manager-command-line-interface), etc.

## Artificial Intelligence Notice

The files within this repository MUST NOT be used for training artificial intelligence.<br>
The content herein is protected by copyright and licensed under GPLv3.<br>
Unauthorized use of this material for AI training purposes is strictly prohibited.

## Maintenance

This file is maintained as a GIST by the author.<br>
The version number iterates with each update.

- See: [hook](https://gist.githubusercontent.com/AlexAtkinson/bc765a0c143ab2bba69a738955d90abd/raw/.git.hooks.post-commit)
- REF: [Versioning](https://gist.github.com/AlexAtkinson/7be00d6be71fab970210006b9574e1e5)
- WARNING: Don't do this for production codebases. This is a personal convenience implementation.

## Usage

These files are intended to be sourced by the native user rc file. Example implementation in ~/.bashrc:

```bash
if [ -d ~/.bashrc.d/ ]; then
  . ~/.bashrc.d/*.sh
fi
```

This is best implemented as-code with your system-maintenance tooling.<br>
IE: [Setup User bashrc](https://gist.github.com/AlexAtkinson/27b12f4dfda31b1b74fcab3fc9a6d192#file-setup-sh-L293)

`00-user-context.sh` & `90-99-*.sh` reserved for manually maintained user configs.

Configurations which are only necessary on occasion may be implemented within the `bashrc.d/on-demand` directory, with a loader being added to `01-on-demand.sh`.

## AI Prompt Context

**These instruction are to be adhered to by AI when interacting with these files.**

- Observe the technical standards documented herein.
- Adhere to the style guide documented herein.
- When creating new functions or aliases, ensure they follow the documented standards.
- When modifying existing functions or aliases, ensure they continue to follow the documented standards.
- When in doubt, refer to the relevant sections of this file for guidance.
- Ensure all changes maintain compatibility with bash version referenced in the LANG_VERSION metadata.
- Ensure all changes maintain compatibility with the PLATFORM metadata.
- Always prioritize clarity, maintainability, and adherence to best practices in bash scripting.
- While not conflicting with the above:
  - aim to optimize for performance and efficiency.
  - aim to minimize external dependencies.
  - prioritize making best use of the capabilities of bash, over POSIX compliance.
  - prioritize security best practices.

## TODO

- Normalize Arg Parsing
- Normalize Help
- Introduce checkbox menus for multi-select
- Convert some of this into discrete go/py packages for simplicity
- Find the rest of my NETWORK bashrc...

## Style Guide

### Headings and Documentation Standards

Files are to be divided into: Sections, Chapters, and Inline Documentation as necessary.

Sections with extended documentation may contain modified formatting, such as the placement of titles for inline documentation immediately above the break, and without the trailing break. As long as it flows.

#### Sections (optionally-deprecated)

> [!NOTE]
> This style is largely deprecated post-breakout of the mono-bashrc file.<br>
> :bulb: Use the H markdown notation '#'.

Denoted by LARGE ascii-art banners which enhance navigation via the minimap (ide dependent), and when scrolling. There are three options:

- [printFancyHeader](hhttps://gist.github.com/AlexAtkinson/cba46af65237291a307835be007072c8)
- [Pat's Text to ASCII Art Generator](https://patorjk.com/software/taag/#p=display&f=ANSI+Shadow&t=Section+Header&x=none&v=4&h=4&w=80&we=false)
- The figlet_fav_ansi_shadow function included in these rc's.

Layout:

- Preceded by : 4 blank rows
- Rows : According to header style
- Width : 120

#### Chapters

Denoted by a header wrapped in '# ~~~...' 120 columns wide.

Layout:

- Preceded by : 1 blank row
- Rows : 3
- Width : 120

#### Inline Documentation

Denoted by a header wrapped in '# ~~~...' 60 columns wide.

- Adheres (roughly) to Google's bash style guide.
- Content: As required -- IE:
  - Wrap: Optional
    <!-- markdownlint-disable MD031 -->
    ```bash
    # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    # Retrieves cheese from the moon.
    # Arguments:
    #   x,y                       Coordinates on surface
    # Outputs:
    #   Blue Cheese               Common
    #   Firm Cows-Milk Cheese     Rare. Vanishing chance to
    #                             contain Ca lactate crystals.
    # TODO:
    #   - Implement QA Tooling to assure output.
    # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    ```
- Inline Documentation Exceptions:
  - Where item names are self-descriptive and item is trivial to understand at a glance.
  - Where simple comments are sufficient.
    - May be placed to the right of an item where appropriate.
- Note: Content may simply be reference material.
  - DO NOT duplicate content that is best maintained by an external source.

Layout:

- Preceded by : 1 blank row
- Rows        : 3
- Width       : 60
- 2nd Column  : Min 20 indentation or as required with a minimum of 4 spaces between columns.

## BASH STYLE GUIDE

### CLI Cleanliness

Ensure that userland remains uncluttered, and that exposed objects are of value.

- Use `local` variables within functions.
- prefix system-consumed variables with:
  - A single underscore (_)  : when they _may_ be used by the user
  - A double underscore (__) : when they _should not_ be used by the user

### Date Timestamp

- ISO8601 Compliant with optional nano
- `date +'%FT%T.%3NZ'` - Terminal output & Logs
- `date +'%Y-%m-%dT%H-%M-%SZ'` - Filenames
- See `dts` for more.

### Bias builtin commands over externals

Tip: determine with `type -t <CMD>`

- IE: `{1..3}`, rather than `seq 1 3` (exception: dynamic loops)

### Logging

Use the 'loggerx' function for consistency.

### Error Handling

Use the rc (result check) and et (echo task) functions for consistency.

## Tech Standards

Technical standards which are non-trivial to parse, and potentially opinion-bound are documented here.<br>
Provided as reference material to ensure consistency across scripts and functions, and to provide AI with sufficient context to operate more accurately against BASH.

> [!IMPORTANT]
> There are a number of standards dating back to the early days of computing -- understandably, implementations of the time fail to satisfy the scale and use cases of modern computing. TCP stack tuning is one example, where default values persist today that were designed for dial-up connections.
<!-- markdownlint-disable MD-028 -->

> [!NOTE]
> Why is AI terrible at BASH?<br>
> Because the linux CLI is not a formal programming language. For example, the full documentation for printf is difficult to find until you look in the C language docs. The Linux CLI is a dynamic environment where tools interact in non-trivial ways.<br>
> :spiral_notepad: Some models seem to attribute supreme weight to StackOverflow answers -- which are often terrible.

### Data Units

Data rate & size abbreviations were not standardized until late (arguably) in the computing era. This has led to
significant confusion, and inconsistent implementations across vendors.
Some examples of where this confusion manifests:

- A storage device marketed as 500GB (base-10) mounts with ~465GiB (base-2) under most systems.
- An ISP marketing a 1000Mbps connection delivers ~125 MB/s, as it's represented under most systems.
- Some vendors confuse 'Mb', 'MB' and 'MiB'; or 'b' and 'B' in documentation, if not implementation.
- The 1.44 MB 3-1/2" floppy disk is actually...
  - REF: [Floppy confusion](https://en.wikipedia.org/wiki/Floppy_disk#:~:text=Mixtures%20of%20decimal%20prefixes%20and%20binary%20sector%20sizes)

#### The International System of Units (SI) defines the decimal prefixes

| Unit  | Abbreviation | Notation | Integer                           |
| ----- | ------------ | -------- | --------------------------------- |
| kilo  | k            | 10^3     | 1,000                             |
| mega  | M            | 10^6     | 1,000,000                         |
| giga  | G            | 10^9     | 1,000,000,000                     |
| tera  | T            | 10^12    | 1,000,000,000,000                 |
| peta  | P            | 10^15    | 1,000,000,000,000,000             |
| exa   | E            | 10^18    | 1,000,000,000,000,000,000         |
| zetta | Z            | 10^21    | 1,000,000,000,000,000,000,000     |
| yotta | Y            | 10^24    | 1,000,000,000,000,000,000,000,000 |

#### The International Electrotechnical Commission (IEC) defines the binary prefixes

| Unit | Abbreviation | Notation | Integer                           |
| ---- | ------------ | -------- | --------------------------------- |
| kibi | Ki           | 2^10     | 1,024                             |
| mebi | Mi           | 2^20     | 1,048,576                         |
| gibi | Gi           | 2^30     | 1,073,741,824                     |
| tebi | Ti           | 2^40     | 1,099,511,627,776                 |
| pebi | Pi           | 2^50     | 1,125,899,906,842,624             |
| exbi | Ei           | 2^60     | 1,152,921,504,606,846,976         |
| zebi | Zi           | 2^70     | 1,180,591,620,717,411,303,424     |
| yobi | Yi           | 2^80     | 1,208,925,819,614,629,174,706,176 |

#### Abbreviation Notes

| Abbreviation   | Description                           | Use                                                                                    |
| -------------- | ------------------------------------- | -------------------------------------------------------------------------------------- |
| b (bit)        | A single bit (0 or 1).                | Used for data transfer rates.                                                          |
| B (Byte)       | 8 bits.                               | Used for data at rest, or data capacities. (storage)                                   |
| Mb (Megabit)   | One million (10^6) bits.              | Used for data transfer rates.                                                          |
| MB (Megabyte)  | A decimal Megabyte (10^6: 1,000,000). | Used for data at rest, or data capacities. (storage)                                   |
| MiB (Mebibyte) | A binary Mebibyte (2^20: 1,048,576).  | Introduced specifically to be more accurate for data at rest and capacities. (storage) |

The examples above include MEGA only. The same principles apply to other prefixes.<br>
For comparison:

- `b` vs. `B`: `b` is for bits (transfer rates), `B` is for Bytes (storage). There are 8 bits in 1 Byte.
- `M` vs. `Mi`: `M` (mega) is typically for decimal (base-10) prefixes, while `Mi` (mebi) is for binary (base-2) prefixes.
- `MB` vs. `MiB`: `MB` (Megabyte) can be ambiguous but often implies 1,000,000 Bytes, especially in marketing. `MiB` (Mebibyte) explicitly means 1,048,576 Bytes.
- `MB` vs. `Mb`: `MB` is Megabytes (storage), `Mb` is Megabits (transfer speed).

**Reference:**

- [NIST Reference: Binary](https://physics.nist.gov/cuu/Units/binary.html) : The best effort in formalizing these standards.
- Wikipedia
  - [Binary Prefix](https://en.wikipedia.org/wiki/Binary_prefix) : Additional context and history.
  - [Data Rate](https://en.wikipedia.org/wiki/Data_rate) : Additional context on data rates.
  - [Byte](https://en.wikipedia.org/wiki/Byte) : Additional context on Bytes and their usage.

### NETWORKING

#### OSI Model Reference

```ascii
Application Layer Data
        ↓
+-------------------+ <--- Application Layer (Userland, etc.)
|   Application     |
|     (Data)        |
+-------------------+
        ↓
+-------------------+
|  Presentation     | (Data formatting, encryption, compression)
+-------------------+
        ↓
+-------------------+
|     Session       | (Session & port management)
+-------------------+
        ↓
+-------------------+-------------------+-------------------+-------------------+-------------------+
|   Transport Layer |   Headers (20 bytes for TCP, 8 bytes for UDP)                                 |
|   Headers         | Source Port (2 bytes)  | Destination Port (2 bytes)                           |
|   +---------------+-------------------+-------------------+-------------------+-------------------+
|   | Source Port   | Destination Port  | Sequence Number (4 bytes) | Acknowledgment (4 bytes)      |
|   +---------------+-------------------+-------------------+-------------------+-------------------+
        ↓
+-------------------+-------------------+-------------------+-------------------+-------------------+
|   Network Layer   |   Headers (20 bytes for IPv4)                                                 |
|   Headers         | Source IP (4 bytes)  | Destination IP (4 bytes)                               |
|   +---------------+-------------------+-------------------+-------------------+-------------------+
|   | Source IP     | Destination IP    | Time to Live (TTL) (1 byte)           |
|   +---------------+-------------------+-------------------+-------------------+-------------------+
|   | Header Length (1 byte) | Type of Service (1 byte)                                             |
|   +---------------+-------------------+-------------------+-------------------+-------------------+
        ↓
+-------------------+-------------------+-------------------+-------------------+-------------------+
|   Data Link Layer |   Headers (18 bytes for Ethernet)                                             |
|   Headers         | Source MAC (6 bytes)  | Destination MAC (6 bytes)                             |
|   +---------------+-------------------+-------------------+-------------------+-------------------+
|   | Source MAC    | Destination MAC   | EtherType (2 bytes)  | Frame Check Seq. (4 bytes)         |
|   +---------------+-------------------+-------------------+-------------------+-------------------+
        ↓
+-------------------+
|   Physical Layer  | ---> Sent to the destination
|     (Bits)        |
+-------------------+
```

CREDIT: [Understanding MTU and MSS](https://menitasa.medium.com/understanding-mtu-and-mss-541bfb56bea1)
