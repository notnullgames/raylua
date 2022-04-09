local ffi = require("ffi")
local arch = ffi.arch
local sys = ffi.os

local lib = "" 

-- Get OS and architecture to set library file to use
if sys == "Windows" then
  if arch == "x64" then
    lib = "libraygui64.dll"
  else
    lib = "libraygui32.dll"
  end
elseif sys == "OSX" then
  lib = "./libraygui.dylib"
else
  lib = "./libraygui.so"
end

ffi.cdef([[
/*******************************************************************************************
*
*   raygui v3.0 - A simple and easy-to-use immediate-mode gui library
*
*   DESCRIPTION:
*
*   raygui is a tools-dev-focused immediate-mode-gui library based on raylib but also
*   available as a standalone library, as long as input and drawing functions are provided.
*
*   Controls provided:
*
*   # Container/separators Controls
*       - WindowBox
*       - GroupBox
*       - Line
*       - Panel
*
*   # Basic Controls
*       - Label
*       - Button
*       - LabelButton   --> Label
*       - Toggle
*       - ToggleGroup   --> Toggle
*       - CheckBox
*       - ComboBox
*       - DropdownBox
*       - TextBox
*       - TextBoxMulti
*       - ValueBox      --> TextBox
*       - Spinner       --> Button, ValueBox
*       - Slider
*       - SliderBar     --> Slider
*       - ProgressBar
*       - StatusBar
*       - ScrollBar
*       - ScrollPanel
*       - DummyRec
*       - Grid
*
*   # Advance Controls
*       - ListView
*       - ColorPicker   --> ColorPanel, ColorBarHue
*       - MessageBox    --> Window, Label, Button
*       - TextInputBox  --> Window, Label, TextBox, Button
*
*   It also provides a set of functions for styling the controls based on its properties (size, color).
*
*
*   GUI STYLE (guiStyle):
*
*   raygui uses a global data array for all gui style properties (allocated on data segment by default),
*   when a new style is loaded, it is loaded over the global style... but a default gui style could always be
*   recovered with GuiLoadStyleDefault() function, that overwrites the current style to the default one
*
*   The global style array size is fixed and depends on the number of controls and properties:
*
*       static unsigned int guiStyle[RAYGUI_MAX_CONTROLS*(RAYGUI_MAX_PROPS_BASE + RAYGUI_MAX_PROPS_EXTENDED)];
*
*   guiStyle size is by default: 16*(16 + 8) = 384*4 = 1536 bytes = 1.5 KB
*
*   Note that the first set of BASE properties (by default guiStyle[0..15]) belong to the generic style
*   used for all controls, when any of those base values is set, it is automatically populated to all
*   controls, so, specific control values overwriting generic style should be set after base values.
*
*   After the first BASE set we have the EXTENDED properties (by default guiStyle[16..23]), those
*   properties are actually common to all controls and can not be overwritten individually (like BASE ones)
*   Some of those properties are: TEXT_SIZE, TEXT_SPACING, LINE_COLOR, BACKGROUND_COLOR
*
*   Custom control properties can be defined using the EXTENDED properties for each independent control.
*
*   TOOL: rGuiStyler is a visual tool to customize raygui style.
*
*
*   GUI ICONS (guiIcons):
*
*   raygui could use a global array containing icons data (allocated on data segment by default),
*   a custom icons set could be loaded over this array using GuiLoadIcons(), but loaded icons set
*   must be same RICON_SIZE and no more than RICON_MAX_ICONS will be loaded
*
*   Every icon is codified in binary form, using 1 bit per pixel, so, every 16x16 icon
*   requires 8 integers (16*16/32) to be stored in memory.
*
*   When the icon is draw, actually one quad per pixel is drawn if the bit for that pixel is set.
*
*   The global icons array size is fixed and depends on the number of icons and size:
*
*       static unsigned int guiIcons[RICON_MAX_ICONS*RICON_DATA_ELEMENTS];
*
*   guiIcons size is by default: 256*(16*16/32) = 2048*4 = 8192 bytes = 8 KB
*
*   TOOL: rGuiIcons is a visual tool to customize raygui icons.
*
*
*   CONFIGURATION:
*
*   #define RAYGUI_IMPLEMENTATION
*       Generates the implementation of the library into the included file.
*       If not defined, the library is in header only mode and can be included in other headers
*       or source files without problems. But only ONE file should hold the implementation.
*
*   #define RAYGUI_STANDALONE
*       Avoid raylib.h header inclusion in this file. Data types defined on raylib are defined
*       internally in the library and input management and drawing functions must be provided by
*       the user (check library implementation for further details).
*
*   #define RAYGUI_NO_RICONS
*       Avoid including embedded ricons data (256 icons, 16x16 pixels, 1-bit per pixel, 2KB)
*
*   #define RAYGUI_CUSTOM_RICONS
*       Includes custom ricons.h header defining a set of custom icons,
*       this file can be generated using rGuiIcons tool
*
*
*   VERSIONS HISTORY:
*
*       3.0 (xx-Sep-2021) Integrated ricons data to avoid external file
*                         REDESIGNED: GuiTextBoxMulti()
*                         REMOVED: GuiImageButton*()
*                         Multiple minor tweaks and bugs corrected
*       2.9 (17-Mar-2021) REMOVED: Tooltip API
*       2.8 (03-May-2020) Centralized rectangles drawing to GuiDrawRectangle()
*       2.7 (20-Feb-2020) ADDED: Possible tooltips API
*       2.6 (09-Sep-2019) ADDED: GuiTextInputBox()
*                         REDESIGNED: GuiListView*(), GuiDropdownBox(), GuiSlider*(), GuiProgressBar(), GuiMessageBox()
*                         REVIEWED: GuiTextBox(), GuiSpinner(), GuiValueBox(), GuiLoadStyle()
*                         Replaced property INNER_PADDING by TEXT_PADDING, renamed some properties
*                         ADDED: 8 new custom styles ready to use
*                         Multiple minor tweaks and bugs corrected
*       2.5 (28-May-2019) Implemented extended GuiTextBox(), GuiValueBox(), GuiSpinner()
*       2.3 (29-Apr-2019) ADDED: rIcons auxiliar library and support for it, multiple controls reviewed
*                         Refactor all controls drawing mechanism to use control state
*       2.2 (05-Feb-2019) ADDED: GuiScrollBar(), GuiScrollPanel(), reviewed GuiListView(), removed Gui*Ex() controls
*       2.1 (26-Dec-2018) REDESIGNED: GuiCheckBox(), GuiComboBox(), GuiDropdownBox(), GuiToggleGroup() > Use combined text string
*                         REDESIGNED: Style system (breaking change)
*       2.0 (08-Nov-2018) ADDED: Support controls guiLock and custom fonts
*                         REVIEWED: GuiComboBox(), GuiListView()...
*       1.9 (09-Oct-2018) REVIEWED: GuiGrid(), GuiTextBox(), GuiTextBoxMulti(), GuiValueBox()...
*       1.8 (01-May-2018) Lot of rework and redesign to align with rGuiStyler and rGuiLayout
*       1.5 (21-Jun-2017) Working in an improved styles system
*       1.4 (15-Jun-2017) Rewritten all GUI functions (removed useless ones)
*       1.3 (12-Jun-2017) Complete redesign of style system
*       1.1 (01-Jun-2017) Complete review of the library
*       1.0 (07-Jun-2016) Converted to header-only by Ramon Santamaria.
*       0.9 (07-Mar-2016) Reviewed and tested by Albert Martos, Ian Eito, Sergio Martinez and Ramon Santamaria.
*       0.8 (27-Aug-2015) Initial release. Implemented by Kevin Gato, Daniel Nicolás and Ramon Santamaria.
*
*
*   CONTRIBUTORS:
*
*       Ramon Santamaria:   Supervision, review, redesign, update and maintenance
*       Vlad Adrian:        Complete rewrite of GuiTextBox() to support extended features (2019)
*       Sergio Martinez:    Review, testing (2015) and redesign of multiple controls (2018)
*       Adria Arranz:       Testing and Implementation of additional controls (2018)
*       Jordi Jorba:        Testing and Implementation of additional controls (2018)
*       Albert Martos:      Review and testing of the library (2015)
*       Ian Eito:           Review and testing of the library (2015)
*       Kevin Gato:         Initial implementation of basic components (2014)
*       Daniel Nicolas:     Initial implementation of basic components (2014)
*
*
*   LICENSE: zlib/libpng
*
*   Copyright (c) 2014-2021 Ramon Santamaria (@raysan5)
*
*   This software is provided "as-is", without any express or implied warranty. In no event
*   will the authors be held liable for any damages arising from the use of this software.
*
*   Permission is granted to anyone to use this software for any purpose, including commercial
*   applications, and to alter it and redistribute it freely, subject to the following restrictions:
*
*     1. The origin of this software must not be misrepresented; you must not claim that you
*     wrote the original software. If you use this software in a product, an acknowledgment
*     in the product documentation would be appreciated but is not required.
*
*     2. Altered source versions must be plainly marked as such, and must not be misrepresented
*     as being the original software.
*
*     3. This notice may not be removed or altered from any source distribution.
*
**********************************************************************************************/
//----------------------------------------------------------------------------------
// Types and Structures Definition
// NOTE: Some types are required for RAYGUI_STANDALONE usage
//----------------------------------------------------------------------------------
// Style property
typedef struct GuiStyleProp {
    unsigned short controlId;
    unsigned short propertyId;
    int propertyValue;
} GuiStyleProp;

// Gui control state
typedef enum {
    GUI_STATE_NORMAL = 0,
    GUI_STATE_FOCUSED,
    GUI_STATE_PRESSED,
    GUI_STATE_DISABLED,
} GuiControlState;

// Gui control text alignment
typedef enum {
    GUI_TEXT_ALIGN_LEFT = 0,
    GUI_TEXT_ALIGN_CENTER,
    GUI_TEXT_ALIGN_RIGHT,
} GuiTextAlignment;

// Gui controls
typedef enum {
    DEFAULT = 0,    // Generic control -> populates to all controls when set
    LABEL,          // Used also for: LABELBUTTON
    BUTTON,
    TOGGLE,         // Used also for: TOGGLEGROUP
    SLIDER,         // Used also for: SLIDERBAR
    PROGRESSBAR,
    CHECKBOX,
    COMBOBOX,
    DROPDOWNBOX,
    TEXTBOX,        // Used also for: TEXTBOXMULTI
    VALUEBOX,
    SPINNER,
    LISTVIEW,
    COLORPICKER,
    SCROLLBAR,
    STATUSBAR
} GuiControl;

// Gui base properties for every control
// NOTE: RAYGUI_MAX_PROPS_BASE properties (by default 16 properties)
typedef enum {
    BORDER_COLOR_NORMAL = 0,
    BASE_COLOR_NORMAL,
    TEXT_COLOR_NORMAL,
    BORDER_COLOR_FOCUSED,
    BASE_COLOR_FOCUSED,
    TEXT_COLOR_FOCUSED,
    BORDER_COLOR_PRESSED,
    BASE_COLOR_PRESSED,
    TEXT_COLOR_PRESSED,
    BORDER_COLOR_DISABLED,
    BASE_COLOR_DISABLED,
    TEXT_COLOR_DISABLED,
    BORDER_WIDTH,
    TEXT_PADDING,
    TEXT_ALIGNMENT,
    RESERVED
} GuiControlProperty;

// Gui extended properties depend on control
// NOTE: RAYGUI_MAX_PROPS_EXTENDED properties (by default 8 properties)

// DEFAULT extended properties
// NOTE: Those properties are actually common to all controls
typedef enum {
    TEXT_SIZE = 16,
    TEXT_SPACING,
    LINE_COLOR,
    BACKGROUND_COLOR,
} GuiDefaultProperty;

// Toggle/ToggleGroup
typedef enum {
    GROUP_PADDING = 16,
} GuiToggleProperty;

// Slider/SliderBar
typedef enum {
    SLIDER_WIDTH = 16,
    SLIDER_PADDING
} GuiSliderProperty;

// ProgressBar
typedef enum {
    PROGRESS_PADDING = 16,
} GuiProgressBarProperty;

// CheckBox
typedef enum {
    CHECK_PADDING = 16
} GuiCheckBoxProperty;

// ComboBox
typedef enum {
    COMBO_BUTTON_WIDTH = 16,
    COMBO_BUTTON_PADDING
} GuiComboBoxProperty;

// DropdownBox
typedef enum {
    ARROW_PADDING = 16,
    DROPDOWN_ITEMS_PADDING
} GuiDropdownBoxProperty;

// TextBox/TextBoxMulti/ValueBox/Spinner
typedef enum {
    TEXT_INNER_PADDING = 16,
    TEXT_LINES_PADDING,
    COLOR_SELECTED_FG,
    COLOR_SELECTED_BG
} GuiTextBoxProperty;

// Spinner
typedef enum {
    SPIN_BUTTON_WIDTH = 16,
    SPIN_BUTTON_PADDING,
} GuiSpinnerProperty;

// ScrollBar
typedef enum {
    ARROWS_SIZE = 16,
    ARROWS_VISIBLE,
    SCROLL_SLIDER_PADDING,
    SCROLL_SLIDER_SIZE,
    SCROLL_PADDING,
    SCROLL_SPEED,
} GuiScrollBarProperty;

// ScrollBar side
typedef enum {
    SCROLLBAR_LEFT_SIDE = 0,
    SCROLLBAR_RIGHT_SIDE
} GuiScrollBarSide;

// ListView
typedef enum {
    LIST_ITEMS_HEIGHT = 16,
    LIST_ITEMS_PADDING,
    SCROLLBAR_WIDTH,
    SCROLLBAR_SIDE,
} GuiListViewProperty;

// ColorPicker
typedef enum {
    COLOR_SELECTOR_SIZE = 16,
    HUEBAR_WIDTH,                  // Right hue bar width
    HUEBAR_PADDING,                // Right hue bar separation from panel
    HUEBAR_SELECTOR_HEIGHT,        // Right hue bar selector height
    HUEBAR_SELECTOR_OVERFLOW       // Right hue bar selector overflow
} GuiColorPickerProperty;

//----------------------------------------------------------------------------------
// Global Variables Definition
//----------------------------------------------------------------------------------
// ...

//----------------------------------------------------------------------------------
// Module Functions Declaration
//----------------------------------------------------------------------------------

// Global gui state control functions
void GuiEnable(void);                                         // Enable gui controls (global state)
void GuiDisable(void);                                        // Disable gui controls (global state)
void GuiLock(void);                                           // Lock gui controls (global state)
void GuiUnlock(void);                                         // Unlock gui controls (global state)
bool GuiIsLocked(void);                                       // Check if gui is locked (global state)
void GuiFade(float alpha);                                    // Set gui controls alpha (global state), alpha goes from 0.0f to 1.0f
void GuiSetState(int state);                                  // Set gui state (global state)
int GuiGetState(void);                                        // Get gui state (global state)

// Font set/get functions
void GuiSetFont(Font font);                                   // Set gui custom font (global state)
Font GuiGetFont(void);                                        // Get gui custom font (global state)

// Style set/get functions
void GuiSetStyle(int control, int property, int value);       // Set one style property
int GuiGetStyle(int control, int property);                   // Get one style property

// Container/separator controls, useful for controls organization
bool GuiWindowBox(Rectangle bounds, const char *title);                                       // Window Box control, shows a window that can be closed
void GuiGroupBox(Rectangle bounds, const char *text);                                         // Group Box control with text name
void GuiLine(Rectangle bounds, const char *text);                                             // Line separator control, could contain text
void GuiPanel(Rectangle bounds);                                                              // Panel control, useful to group controls
Rectangle GuiScrollPanel(Rectangle bounds, Rectangle content, Vector2 *scroll);               // Scroll Panel control

// Basic controls set
void GuiLabel(Rectangle bounds, const char *text);                                            // Label control, shows text
bool GuiButton(Rectangle bounds, const char *text);                                           // Button control, returns true when clicked
bool GuiLabelButton(Rectangle bounds, const char *text);                                      // Label button control, show true when clicked
bool GuiToggle(Rectangle bounds, const char *text, bool active);                              // Toggle Button control, returns true when active
int GuiToggleGroup(Rectangle bounds, const char *text, int active);                           // Toggle Group control, returns active toggle index
bool GuiCheckBox(Rectangle bounds, const char *text, bool checked);                           // Check Box control, returns true when active
int GuiComboBox(Rectangle bounds, const char *text, int active);                              // Combo Box control, returns selected item index
bool GuiDropdownBox(Rectangle bounds, const char *text, int *active, bool editMode);          // Dropdown Box control, returns selected item
bool GuiSpinner(Rectangle bounds, const char *text, int *value, int minValue, int maxValue, bool editMode);     // Spinner control, returns selected value
bool GuiValueBox(Rectangle bounds, const char *text, int *value, int minValue, int maxValue, bool editMode);    // Value Box control, updates input text with numbers
bool GuiTextBox(Rectangle bounds, char *text, int textSize, bool editMode);                   // Text Box control, updates input text
bool GuiTextBoxMulti(Rectangle bounds, char *text, int textSize, bool editMode);              // Text Box control with multiple lines
float GuiSlider(Rectangle bounds, const char *textLeft, const char *textRight, float value, float minValue, float maxValue);       // Slider control, returns selected value
float GuiSliderBar(Rectangle bounds, const char *textLeft, const char *textRight, float value, float minValue, float maxValue);    // Slider Bar control, returns selected value
float GuiProgressBar(Rectangle bounds, const char *textLeft, const char *textRight, float value, float minValue, float maxValue);  // Progress Bar control, shows current progress value
void GuiStatusBar(Rectangle bounds, const char *text);                                        // Status Bar control, shows info text
void GuiDummyRec(Rectangle bounds, const char *text);                                         // Dummy control for placeholders
int GuiScrollBar(Rectangle bounds, int value, int minValue, int maxValue);                    // Scroll Bar control
Vector2 GuiGrid(Rectangle bounds, float spacing, int subdivs);                                // Grid control

// Advance controls set
int GuiListView(Rectangle bounds, const char *text, int *scrollIndex, int active);            // List View control, returns selected list item index
int GuiListViewEx(Rectangle bounds, const char **text, int count, int *focus, int *scrollIndex, int active);      // List View with extended parameters
int GuiMessageBox(Rectangle bounds, const char *title, const char *message, const char *buttons);                 // Message Box control, displays a message
int GuiTextInputBox(Rectangle bounds, const char *title, const char *message, const char *buttons, char *text);   // Text Input Box control, ask for text
Color GuiColorPicker(Rectangle bounds, Color color);                                          // Color Picker control (multiple color controls)
Color GuiColorPanel(Rectangle bounds, Color color);                                           // Color Panel control
float GuiColorBarAlpha(Rectangle bounds, float alpha);                                        // Color Bar Alpha control
float GuiColorBarHue(Rectangle bounds, float value);                                          // Color Bar Hue control

// Styles loading functions
void GuiLoadStyle(const char *fileName);              // Load style file over global style variable (.rgs)
void GuiLoadStyleDefault(void);                       // Load style default over global style

const char *GuiIconText(int iconId, const char *text); // Get text with icon id prepended (if supported)

// Gui icons functionality
void GuiDrawIcon(int iconId, int posX, int posY, int pixelSize, Color color);

unsigned int *GuiGetIcons(void);                      // Get full icons data pointer
unsigned int *GuiGetIconData(int iconId);             // Get icon bit data
void GuiSetIconData(int iconId, unsigned int *data);  // Set icon bit data

void GuiSetIconPixel(int iconId, int x, int y);       // Set icon pixel value
void GuiClearIconPixel(int iconId, int x, int y);     // Clear icon pixel value
bool GuiCheckIconPixel(int iconId, int x, int y);     // Check icon pixel value
]])

return ffi.load(lib)
