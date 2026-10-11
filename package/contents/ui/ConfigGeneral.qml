/*
 * Copyright 2026  Allen Hewes
 * SPDX-License-Identifier: GPL-2.0-or-later
 */
// Font, size, layout and colours.
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC
import QtQuick.Dialogs as Dialogs
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM
import org.kde.kquickcontrols as KQControls

KCM.SimpleKCM {
    id: generalPage

    property string cfg_fontFamily
    property alias cfg_fontPointSize: fontPointSize.value
    property int cfg_firstDayOfWeek
    property alias cfg_showWeekNumbers: showWeekNumbers.checked
    property int cfg_textColorMode
    property string cfg_customPrimaryColor
    property int cfg_autoContrastStyle
    property string cfg_autoContrastColor
    property alias cfg_weekdayChips: weekdayChips.checked
    property alias cfg_adaptColors: adaptColors.checked
    property string cfg_wallpaperAverageColor
    property string cfg_accentColor
    property string cfg_eventColor

    Kirigami.FormLayout {

        Kirigami.Separator {
            Kirigami.FormData.label: i18n("Font")
            Kirigami.FormData.isSection: true
        }

        RowLayout {
            Kirigami.FormData.label: i18n("Font family:")
            spacing: Kirigami.Units.smallSpacing
            QQC.Label {
                text: cfg_fontFamily === "" ? i18n("System font (%1)", Kirigami.Theme.defaultFont.family) : cfg_fontFamily
                font.family: cfg_fontFamily === "" ? Kirigami.Theme.defaultFont.family : cfg_fontFamily
            }
            QQC.Button {
                text: i18n("Choose…")
                icon.name: "preferences-desktop-font"
                onClicked: {
                    fontDialogLoader.active = true;
                    fontDialogLoader.item.open();
                }
            }
            QQC.Button {
                text: i18n("System font")
                enabled: cfg_fontFamily !== ""
                onClicked: cfg_fontFamily = ""
            }
        }

        QQC.SpinBox {
            id: fontPointSize
            Kirigami.FormData.label: i18n("Size (points):")
            from: 6
            to: 72
            editable: true
        }

        QQC.Label {
            text: i18n("Labels, cells and gaps scale with this size.")
            opacity: 0.75
        }

        Kirigami.Separator {
            Kirigami.FormData.label: i18n("Layout")
            Kirigami.FormData.isSection: true
        }

        QQC.ComboBox {
            Kirigami.FormData.label: i18n("First day of week:")
            textRole: "text"
            model: [-1, 0, 1, 6].map(day => ({
                day: day,
                text: day === -1 ? i18n("Region default") : Qt.locale().dayName(day)
            }))
            currentIndex: model.findIndex(item => item.day === cfg_firstDayOfWeek)
            onActivated: index => cfg_firstDayOfWeek = model[index].day
        }

        QQC.CheckBox {
            id: showWeekNumbers
            text: i18n("Show week numbers")
        }

        QQC.CheckBox {
            id: weekdayChips
            text: i18n("Shade weekday labels (LuaCalendar style)")
        }

        Kirigami.Separator {
            Kirigami.FormData.label: i18n("Colours")
            Kirigami.FormData.isSection: true
        }

        QQC.ButtonGroup { id: colorModeGroup }

        QQC.RadioButton {
            Kirigami.FormData.label: i18n("Text colour:")
            text: i18n("Automatic: best contrast with the wallpaper")
            checked: cfg_textColorMode === 2
            QQC.ButtonGroup.group: colorModeGroup
            onToggled: if (checked) cfg_textColorMode = 2
        }

        RowLayout {
            enabled: cfg_textColorMode === 2
            Layout.leftMargin: Kirigami.Units.gridUnit
            spacing: Kirigami.Units.largeSpacing
            QQC.RadioButton {
                text: i18n("White or black")
                checked: cfg_autoContrastStyle === 0
                onToggled: if (checked) cfg_autoContrastStyle = 0
            }
            QQC.RadioButton {
                text: i18n("Tinted from the wallpaper")
                checked: cfg_autoContrastStyle === 1
                onToggled: if (checked) cfg_autoContrastStyle = 1
            }
        }

        QQC.Label {
            visible: cfg_textColorMode === 2 && cfg_autoContrastColor !== ""
            Layout.leftMargin: Kirigami.Units.gridUnit
            text: i18n("Current automatic colour: %1", cfg_autoContrastColor)
            opacity: 0.75
        }

        RowLayout {
            QQC.RadioButton {
                text: i18n("Custom:")
                checked: cfg_textColorMode === 1
                QQC.ButtonGroup.group: colorModeGroup
                onToggled: if (checked) cfg_textColorMode = 1
            }
            KQControls.ColorButton {
                enabled: cfg_textColorMode === 1
                color: cfg_customPrimaryColor
                showAlphaChannel: false
                dialogTitle: i18n("Text colour")
                onAccepted: function (colour) { cfg_customPrimaryColor = colour.toString(); }
            }
        }

        QQC.RadioButton {
            text: i18n("Plasma theme colour")
            checked: cfg_textColorMode === 0
            QQC.ButtonGroup.group: colorModeGroup
            onToggled: if (checked) cfg_textColorMode = 0
        }

        QQC.CheckBox {
            id: adaptColors
            Kirigami.FormData.label: i18n("Accent colours:")
            text: i18n("Keep readable on light wallpapers (darker, same hue)")
        }

        RowLayout {
            Kirigami.FormData.label: i18n("Accent:")
            KQControls.ColorButton {
                color: cfg_accentColor
                showAlphaChannel: false
                dialogTitle: i18n("Accent colour (week numbers, other months, today's underline)")
                onAccepted: function (colour) { cfg_accentColor = colour.toString(); }
            }
            QQC.Button {
                text: i18n("Default")
                enabled: cfg_accentColor !== "#80c0ff"
                onClicked: cfg_accentColor = "#80c0ff"
            }
        }

        RowLayout {
            Kirigami.FormData.label: i18n("Days with events:")
            KQControls.ColorButton {
                color: cfg_eventColor
                showAlphaChannel: false
                dialogTitle: i18n("Colour of days with events")
                onAccepted: function (colour) { cfg_eventColor = colour.toString(); }
            }
            QQC.Button {
                text: i18n("Default")
                enabled: cfg_eventColor !== "#aaaaaa"
                onClicked: cfg_eventColor = "#aaaaaa"
            }
        }
    }

    Loader {
        id: fontDialogLoader
        active: false
        sourceComponent: Component {
            Dialogs.FontDialog {
                title: i18n("Choose a Font")
                currentFont.family: cfg_fontFamily === "" ? Kirigami.Theme.defaultFont.family : cfg_fontFamily
                onAccepted: cfg_fontFamily = selectedFont.family
            }
        }
    }
}
