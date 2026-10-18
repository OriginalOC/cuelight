# CueLight

CueLight is a fork of [Falcon Player (FPP)](https://github.com/FalconChristmas/fpp), focused
on reliability and portability fixes for deployments stock FPP doesn't support well — notably
Docker, and anywhere Apache isn't reachable on its default port. The upstream project describes
Docker as explicitly "not supported"; every self-request FPP's own code makes was hardcoded to
assume port 80, which breaks outright the moment that's not true. CueLight fixes the underlying
bugs rather than working around them.

See each commit's message for what changed and why; the intent is one fix per commit, not a
single large diff. Everything not called out in CueLight's own commits is unmodified FPP —
most of this codebase, documentation, and functionality is unchanged from upstream, and credit
for it belongs there.

## What upstream FPP is

The Falcon Player (FPP) is a lightweight, optimized, feature-rich sequence player designed to
run on low-cost Single Board Computers (SBC). It was originally created to run on the $35
Raspberry Pi, hence the middle 'P' in the short name but now the FPP supports many more
systems. It is still mostly commonly used on a Raspberry Pi (Zero, 2, 3, 4, 5) or a Beagle Bone (Black, Green, Pocket).
The FPP shorthand is still used but it is now just called Falcon Player.

FPP aims to be controller agnostic, it can talk E1.31,
DDP, DMX, Pixelnet, and Renard to hardware from multiple hardware vendors. Using various capes, FPP
can also be a controller on P5 and P10 Matrixes, or strings of ws2811 pixels.

Upstream FPP is intended to be used on Raspberry Pi and Beagle based SBC (single board
computers); Docker, other SBCs eg Orange Pi, PC hardware, virtual machines, Debian, Ubuntu
installs etc are not 'supported' there. CueLight exists because of that gap — if you're running
in Docker, this fork's fixes apply to you.

## Links

- [Documentation in Github](./docs/README.md)
- Upstream: [FalconChristmas/fpp](https://github.com/FalconChristmas/fpp), [Falcon Player website](https://www.falconplayer.com), [Falcon Christmas forums](http://falconchristmas.com/forum/), [Falcon Player sub-forum](http://falconchristmas.com/forum/index.php/board,8.0.html), [Wiki](http://falconchristmas.com/wiki/index.php/Main_Page)
