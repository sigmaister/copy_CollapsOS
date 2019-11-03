# Recipes

Because Collapse OS is a meta OS that you assemble yourself on an improvised
machine of your own design, there can't really be a build script. Not a
reliable one anyways.

Because the design of post-collapse machines is hard to predict, it's hard to
write a definitive guide to it.

The approach we're taking here is a list of recipes: Walkthrough guides for
machines that were built and tried pre-collapse. With a wide enough variety of
recipes, I hope that it will be enough to cover most post-collapse cases.

That's what this folder contains: a list of recipes that uses parts supplied
by Collapse OS to run on some machines people tried.

In other words, parts often implement logic for hardware that isn't available
off the shelf, but they implement a logic that you are likely to need post
collapse. These parts, however *have* been tried on real material and they all
have a recipe describing how to build the hardware that parts have been written
for.

## Structure

Each top folder represents an architecture. In that top folder, there's a
`README.md` file presenting the architecture as well as instructions to
minimally get Collapse OS running on it. Then, in the same folder, there are
auxiliary recipes for nice stuff built around that architecture.

Installation procedures are centered around using a modern system to install
Collapse OS. This is the most useful instructions to have most pre-collapse and
post-collapse because even after the collapse, we'll interact mostly with modern
technology for many years.

There are, however, recipes to write to different storage media, thus making
Collapse OS fully reproducible. For example, you can use `rc2014/eeprom` to
write arbitrary data to a `AT28` EEPROM.

The `rc2014` architecture is considered the "canonical" one. That means that
if a recipe is considered architecture independent, it's the `rc2014` recipe
folder that's going to contain it.

For example, `rc2014/eeprom` can be considered architecture independent because
it's much more about the `AT28` than about a specific z80 architecture. You can
adapt it to any supported architecture with minimal hassle. Therefore, it's
not going to be copied in every architecture recipe folder.

`rc2014` installation recipe also contains more "newbie-friendly" instructions
than other installation recipes, which take this knowledge for granted. It is
therefore recommended to have a look at it even if you're not planning on using
a RC2014.
