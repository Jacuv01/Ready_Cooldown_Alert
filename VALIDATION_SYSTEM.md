# 🔍 Sistema de Validación de Filtros

## 📋 Descripción

Implementación de un **sistema de validación robusto** para la nueva interfaz de filtros que valida entradas en tiempo real y proporciona feedback inmediato al usuario.

## 🛡️ **Características de Validación**

### **1. Validaciones Básicas**
- ✅ **Entrada vacía** - Rechaza campos vacíos o placeholder text
- ✅ **Longitud** - Min: 2 caracteres, Max: 50 caracteres  
- ✅ **Whitespace** - Trim automático de espacios
- ✅ **Duplicados** - Previene agregar filtros existentes

### **2. Validación de Spell IDs**
- ✅ **Rango válido** - 1 a 999,999
- ✅ **Verificación en juego** - Usa `C_Spell.GetSpellName()` para validar
- ✅ **Feedback específico** - Muestra nombre del spell si existe
- ⚠️ **Warning para IDs desconocidos** - Permite agregar pero advierte

### **3. Validación de Item IDs**  
- ✅ **Verificación en juego** - Usa `C_Item.GetItemInfo()` para validar
- ✅ **Detección automática** - Diferencia entre spell y item IDs
- ✅ **Feedback específico** - Muestra nombre del item si existe

### **4. Validación de Nombres**
- ✅ **Caracteres válidos** - Letras, números, espacios, apostrophes, guiones, puntos
- ✅ **Búsqueda en spellbook** - Verifica en spells conocidos del jugador
- ✅ **Búsqueda en items** - Verifica en items equipados
- ⚠️ **Warning para nombres desconocidos** - Permite agregar pero advierte

## 🔧 **Funciones Implementadas**

### **`ValidateInput(text)`**
```lua
-- Función principal de validación
-- Returns: isValid, message, validatedText
local isValid, message = FiltersUI:ValidateInput("Fireball")
```

### **`DetectInputType(text)`**  
```lua
-- Detecta automáticamente el tipo de entrada
-- Returns: type, id, name
local type, id, name = FiltersUI:DetectInputType("12345")
-- Tipos: "spell_id", "item_id", "spell_name", "item_name", "unknown_id", "unknown_name"
```

### **`FindSpellByName(spellName)`**
```lua
-- Busca spell en el spellbook del jugador
local spellID = FiltersUI:FindSpellByName("Fireball")
```

### **`ValidateItemID(itemID)`**
```lua
-- Valida si un item ID existe
local isValid, itemName = FiltersUI:ValidateItemID(12345)
```

### **`FindItemByName(itemName)`**
```lua
-- Busca item en equipo del jugador
local itemID = FiltersUI:FindItemByName("Thunderfury")
```

## 🎨 **Feedback Visual en Tiempo Real**

### **Estados de Validación:**

#### ✅ **Entrada Válida (Verde)**
```
✅ Valid spell ID: Fireball (ID: 133)
✅ Valid spell name: Fireball (ID: 133)  
✅ Valid item ID: Thunderfury (ID: 19019)
```

#### ⚠️ **Warning (Amarillo)**
```
⚠️ Warning: ID 99999 not found in game (will be added anyway)
⚠️ Warning: 'Unknown Spell' not found in game (will be added anyway)
```

#### ❌ **Error (Rojo)**
```
❌ Please enter a spell name or ID
❌ Name/ID too long (max 50 characters)
❌ Invalid ID range (1-999999)
❌ Filter already exists: Fireball
❌ Invalid characters (only letters, numbers, spaces, apostrophes, hyphens and dots allowed)
```

## 📊 **Flujo de Validación**

### **1. Input en Tiempo Real**
```
Usuario escribe → OnTextChanged → ValidateInput() → Feedback Visual
```

### **2. Agregar Filtro**
```
Enter/Click Add → ValidateInput() → AddIgnoredSpell() → RefreshFiltersList()
```

### **3. Manejo de Errores**
```
Error detectado → Mostrar mensaje rojo → Bloquear agregado → Mantener input para corrección
```

## 🔄 **Tipos de Validación por Entrada**

### **Entrada Numérica (ID):**
1. ✅ Verificar rango (1-999999)
2. ✅ Intentar como Spell ID → `C_Spell.GetSpellName()`
3. ✅ Si falla, intentar como Item ID → `C_Item.GetItemInfo()`
4. ⚠️ Si ambos fallan, permitir con warning

### **Entrada de Texto (Nombre):**
1. ✅ Verificar caracteres válidos
2. ✅ Buscar en spellbook del jugador
3. ✅ Buscar en items equipados
4. ⚠️ Si no se encuentra, permitir con warning

## 🛠️ **Casos de Uso Soportados**

### **✅ Entradas Válidas**
- `"133"` → Spell ID válido
- `"Fireball"` → Nombre de spell
- `"Ice Bolt"` → Nombre con espacios
- `"Player's Heal"` → Nombre con apostrophe
- `"Multi-Shot"` → Nombre con guión
- `"Healing Potion 2"` → Nombre con número

### **❌ Entradas Rechazadas**
- `""` → Vacío
- `"A"` → Muy corto
- `"0"` → ID fuera de rango
- `"Spell@Name"` → Caracteres inválidos
- `"Filter existente"` → Ya existe en lista

### **⚠️ Entradas con Warning**
- `"99999"` → ID no encontrado pero válido
- `"Unknown Spell"` → Nombre no encontrado pero formato válido

## 🎯 **Beneficios del Sistema**

### **1. Experiencia de Usuario**
- ✅ **Feedback inmediato** mientras escribe
- ✅ **Prevención de errores** antes de agregar
- ✅ **Mensajes claros** sobre qué está mal
- ✅ **Colores intuitivos** (verde/amarillo/rojo)

### **2. Robustez del Sistema**
- ✅ **Validación exhaustiva** de todos los tipos de entrada
- ✅ **Detección automática** de tipo (spell/item/ID/nombre)
- ✅ **Prevención de duplicados** automática
- ✅ **Manejo de edge cases** (espacios, caracteres especiales)

### **3. Flexibilidad**
- ✅ **Soporte multilenguaje** (permite nombres no encontrados)
- ✅ **Soporte para addons** (IDs de addons externos)
- ✅ **Warnings en lugar de errors** para casos inciertos

---
**Estado**: ✅ **COMPLETAMENTE IMPLEMENTADO**

### 🧪 **Para Testear:**
1. Abrir pestaña "Filters" en opciones
2. Escribir diferentes tipos de entrada en el campo
3. Observar feedback visual en tiempo real
4. Verificar que solo entradas válidas se agregan
5. Confirmar que duplicados son rechazados
