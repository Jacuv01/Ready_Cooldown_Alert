# Ready Cooldown Alert



## 🚀 Características

- **Alertas visuales** cuando los cooldowns de habilidades están listos
- **Soporte completo** para hechizos, items y habilidades de mascota  
- **Sistema de filtros** avanzado (whitelist/blacklist)
- **Animaciones personalizables** (tamaño, tiempo, opacidad)
- **Posicionamiento libre** con drag & drop
- **Interfaz de configuración** completa con sliders y opciones

## 📁 Arquitectura Modular

```
Ready_Cooldown_Alert/
├── Core/
│   └── Init.lua                 # Inicializador principal
├── Modules/
│   ├── Data/                    # APIs del juego
│   │   ├── SpellData.lua       # Información de hechizos
│   │   ├── ItemData.lua        # Información de items
│   │   ├── PetData.lua         # Información de mascotas
│   │   └── CooldownData.lua    # Coordinador de cooldowns
│   ├── Hooks/                   # Detectores de acciones
│   │   ├── ActionHooks.lua     # UseAction, UseInventoryItem, etc.
│   │   ├── SpellHooks.lua      # UNIT_SPELLCAST_SUCCEEDED
│   │   ├── CombatHooks.lua     # COMBAT_LOG_EVENT_UNFILTERED
│   │   └── HookManager.lua     # Coordinador de hooks
│   ├── Logic/                   # Procesamiento de datos
│   │   ├── CooldownProcessor.lua   # Lógica de cooldowns
│   │   ├── FilterProcessor.lua     # Sistema de filtros
│   │   ├── AnimationProcessor.lua  # Control de animaciones
│   │   └── LogicManager.lua        # Coordinador de lógica
│   └── UI/                      # Interfaz de usuario
│       ├── MainFrame.lua       # Frame principal de alertas
│       └── OptionsFrame.lua    # Panel de configuración
└── Libs/
```

## 🎮 Comandos

| Comando | Descripción |
|---------|-------------|
| `/rca` | Abrir panel de opciones |
| `/rca test` | Probar animación |
| `/rca unlock` | Desbloquear para mover |
| `/rca lock` | Bloquear posición |
| `/rca status` | Mostrar estado del addon |
| `/rca reset` | Resetear posición al centro |

## ⚙️ Configuración

### Panel de Opciones (`/rca`)

- **Fade In Time**: Tiempo de aparición (0-2s)
- **Fade Out Time**: Tiempo de desaparición (0-2s)  
- **Max Alpha**: Opacidad máxima (0-1)
- **Animation Scale**: Escala de animación (0.5-3x)
- **Icon Size**: Tamaño del icono (32-256px)
- **Hold Time**: Tiempo de mantener visible (0-5s)
- **Alert When**: Alertar X segundos antes (0-10s)

### Sistema de Filtros

- **Ignored Spells**: Lista de hechizos ignorados (separados por comas)
- **Invert Filter**: Modo whitelist (solo mostrar los listados)
- **Show Spell Names**: Mostrar nombres debajo del icono
- **Pet Overlay**: Color personalizado para habilidades de mascota

## 🔧 Flujo de Funcionamiento

1. **Hooks** detectan cuando usas una habilidad
2. **Data modules** obtienen información de APIs del juego  
3. **Logic modules** procesan cooldowns y aplican filtros
4. **UI modules** muestran animaciones visuales

## 📊 Separación de Responsabilidades

### Data Layer - Obtener Datos
- `SpellData`: APIs de hechizos (`C_Spell.*`)
- `ItemData`: APIs de items (`C_Item.*`, `C_Container.*`)
- `PetData`: APIs de mascotas (`GetPetActionInfo`, etc.)
- `CooldownData`: Coordinador que unifica todos los tipos

### Hook Layer - Detectar Acciones  
- `ActionHooks`: `UseAction`, `UseInventoryItem`, `UseContainerItem`
- `SpellHooks`: `UNIT_SPELLCAST_SUCCEEDED`
- `CombatHooks`: `COMBAT_LOG_EVENT_UNFILTERED` (mascotas)
- `HookManager`: Coordinador central de eventos

### Logic Layer - Procesar Datos
- `CooldownProcessor`: Lógica de cuándo alertar (watching → cooldowns → animating)
- `FilterProcessor`: Sistema whitelist/blacklist
- `AnimationProcessor`: Control de fases de animación (fadeIn → hold → fadeOut)
- `LogicManager`: Coordinador que conecta toda la lógica

### UI Layer - Visualización
- `MainFrame`: Frame de alertas con drag & drop
- `OptionsFrame`: Panel de configuración completo


## 🔄 Estados del Sistema

### Tablas de Estado
- **watching{}**: Buffer temporal (0.5s) para acciones recién detectadas
- **cooldowns{}**: Cooldowns activos >2s siendo monitoreados  
- **animating{}**: Cola de animaciones pendientes

### Flujo de Estados
```
Usuario usa habilidad → Hook detecta → watching[] → 
cooldown >2s → cooldowns[] → cooldown listo → animating[] → 
animación visual → fin
```

## 📈 Rendimiento

- **Memoización** para evitar cálculos repetidos
- **OnUpdate** solo activo cuando necesario
- **APIs modernas** de WoW (C_Spell, C_Item, etc.)
- **Cleanup automático** de memoria

## 🐛 Debug

- Variable `ReadyCooldownAlertDB.debug = true` para logs detallados
- Comando `/rca status` para información del estado
- Separación modular facilita testing individual

## 📝 Changelog

### v1.0.0
- ✅ Reescritura modular completa
- ✅ Arquitectura separada en capas
- ✅ Sistema de hooks mejorado  
- ✅ Logic processors independientes
- ✅ UI con mejor configuración
- ✅ Soporte para APIs modernas de WoW
- ✅ Sistema de comandos expandido

---

**Autor**: Jacuv  
**Licencia**: Ver LICENSE