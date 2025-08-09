<div align="center">

# Ready Cooldown Alert

![Build Status](https://img.shields.io/badge/build-passing-brightgreen) ![WoW Version](https://img.shields.io/badge/WoW-Retail-blue) ![License](https://img.shields.io/badge/license-MIT-green)

</div>

Ready Cooldown Alert is a lightweight and efficient World of Warcraft addon that provides customizable visual notifications when your spells, abilities, and items are ready to use. When you use a spell or ability, the addon tracks its cooldown and displays an animated icon on your screen when it becomes available again, ensuring you never miss important abilities during combat. You can customize the animation style, position, size, and filter which spells to track.

**Inspired by [Doom_CooldownPulse](https://github.com/aduth/Doom_CooldownPulse)**, Ready Cooldown Alert was built from the ground up to include all the features I always wanted: advanced filtering system, dynamic spell suggestions, modular architecture, and enhanced customization options that go beyond the original concept.

## Features

- **Smart Cooldown Detection**: Automatically tracks spells, abilities, and items.
- **Animations**: Multiple animations including pulse, glow, bounce, and more
- **Advanced Filtering System**: Include or exclude specific spells with name-based or ID-based filtering
- **Performance Optimized**: Minimal CPU usage with efficient cooldown tracking algorithms
- **User-Friendly Interface**: Intuitive configuration panel
- **Position Settings**: Adjust X/Y coordinates and icon size
- **Threshold Settings**: Set when notifications should appear based on remaining cooldown time
- **Add Spells/Items**: Use the search system to add spells by name or ID
- **Invert Mode**: Switch between include/exclude filtering modes

## Quick Start

To open the options window, type `/rca` into your chat and hit enter.

### Basic Setup
1. Install the addon and restart World of Warcraft
2. Type `/rca` to open the configuration panel
3. Configure your preferred animation settings in the **General** tab
4. Set up spell filters in the **Filters** tab if desired
5. Position the notification area using the **Unlock** button
6. Test your settings with the **Test** button


## Commands

| Command | Description |
|---------|-------------|
| `/rca` | Open configuration panel |

## Performance

Ready Cooldown Alert is designed with performance in mind:
- **Efficient OnUpdate loops** that only run when necessary
- **Smart caching** of spell and item data
- **Minimal memory footprint** with automatic cleanup
- **CPU optimization** through conditional processing
- **Modern WoW APIs** (C_Spell, C_Item, etc.) for better performance

## Compatibility

- **World of Warcraft**: Retail


## Problems

- If you encounter any issues, please check that the addon is up to date
- For bugs or feature requests, please create an [issue](https://github.com/Jacuv01/Ready_Cooldown_Alert/issues)

## Support

By me beard! I'm just one lad who loves this grand world of Azeroth and enjoys crafting tools for our mighty community. If ye'd like to support me work and help me continue forging addons and features for fellow adventurers, buying me a coffee would warm me heart like a good ale by the forge! Your feedback and suggestions are worth more than gold in making this addon better for everyone, aye!

[![Buy Me a Coffee](https://img.buymeacoffee.com/button-api/?text=Buy%20me%20a%20coffee&emoji=☕&slug=jacuv&button_colour=5F7FFF&font_colour=ffffff&font_family=Cookie&outline_colour=000000&coffee_colour=FFDD00)](https://www.buymeacoffee.com/jacuv)


## Acknowledgments

This addon was inspired by [Doom_CooldownPulse](https://github.com/aduth/Doom_CooldownPulse) by aduth. While keeping the main idea of showing cooldown alerts, Ready Cooldown Alert was built from scratch with new features that I always wanted in a cooldown addon.

---  

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
