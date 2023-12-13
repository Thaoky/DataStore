# DataStore

DataStore is the main component of a series of add-ons that serve as data repositories in World of Warcraft. Their respective purpose is to offer scanning and storing services to other add-ons.

The advantages of this approach are:

- data is scanned only once for all client addons (performance gain).
- data is stored only once for all client addons (memory gain).
- add-on authors can spend more time coding higher level features.
- each module is an independant add-on, and therefore has its own SavedVariables file, meaning that you could clean _Crafts without disturbing _Containers.

## Scope : a note to contributing authors

The core of the database is based on my work in Altoholic, and is thus designed with multiple-account support in mind. If client add-ons want to store data from foreign accounts, the database will be ready for it. Nothing is final at this point though, feel free to contribute, as the concept can and will be perfected.

The scope of each addons is to provide common methods for client addons. For instance, DataStore_Crafts embeds LibPeriodicTable-3.1-Tradeskill allowing it to give more than just scanning & storing data. However, the goal is not to put _everything_ into these addons, they must be seen as an abstraction layer and a service provider, nothing more.

These libraries cannot and should not be embedded, as they all manage their respective SavedVariables.

### Existing modules

* [DataStore_Achievements](https://github.com/Thaoky/DataStore_Achievements) : Achievements
* [DataStore_Agenda](https://github.com/Thaoky/DataStore_Agenda) : Calendar & Raid ID's
* [DataStore_Auctions](https://github.com/Thaoky/DataStore_Auctions) : Auctions & Bids
* [DataStore_Characters](https://github.com/Thaoky/DataStore_Characters) : Base information about your characters
* [DataStore_Containers](https://github.com/Thaoky/DataStore_Agenda) : Bags, Bank and Guild Banks
* [DataStore_Crafts](https://github.com/Thaoky/DataStore_Crafts) : Tradeskills & Recipes
* [DataStore_Currencies](https://github.com/Thaoky/DataStore_Currencies) : Currencies
* [DataStore_Garrisons](https://github.com/Thaoky/DataStore_Garrisons) : Garrisons
* [DataStore_Inventory](https://github.com/Thaoky/DataStore_Inventory) : Equipment
* [DataStore_Mails](https://github.com/Thaoky/DataStore_Mails) : Mails
* [DataStore_Pets](https://github.com/Thaoky/DataStore_Pets) : Companions & Mounts
* [DataStore_Quests](https://github.com/Thaoky/DataStore_Quests) : Quest log
* [DataStore_Reputations](https://github.com/Thaoky/DataStore_Reputations) : Reputations
* [DataStore_Spells](https://github.com/Thaoky/DataStore_Spells) : Spells
* [DataStore_Stats](https://github.com/Thaoky/DataStore_Stats) : Character Statistics
* [DataStore_Talents](https://github.com/Thaoky/DataStore_Agenda) : Talent trees & Glyphs

Each module will exist as a separate add-on, so that authors can package only the ones they want with their own project.

More modules will come later.

Information Pages

    Project overview : A slightly more detailed overview of the scope
    API : Samples of commonly used methods (work-in-progress)

 

The development of DataStore compatible modules is not authorized without my express consent.

Any authorized development must respect the coding style/structure of existing modules, and respect Blizzard's TOS.

 

Current list of authorized modules : none
