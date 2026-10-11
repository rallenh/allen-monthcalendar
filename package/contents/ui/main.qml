/*
 * Copyright 2026  Allen Hewes
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License as
 * published by the Free Software Foundation; either version 2 of
 * the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http: //www.gnu.org/licenses/>.
 */

// Month Calendar: the whole month at a glance (modelled on Smurfier's LuaCalendar for Rainmeter, style
// "DefaultWeeks"). Every size and gap is derived from the day-number font, so one size setting scales the
// whole grid. Events come from Plasma's calendar event plugins (holidays, astronomical events).

import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.components as PlasmaComponents
import org.kde.kirigami as Kirigami
import org.kde.plasma.workspace.calendar as PlasmaCalendar
import "../code/contrast.js" as Contrast

PlasmoidItem {
    id: root

    Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground | PlasmaCore.Types.ConfigurableBackground
    preferredRepresentation: fullRepresentation

    // ---- text colour (same model as the Wunderground fork: theme / custom / automatic contrast) ----
    readonly property int textColorMode: Plasmoid.configuration.textColorMode
    property color autoTextColor: Plasmoid.configuration.autoContrastColor !== "" ? Plasmoid.configuration.autoContrastColor : Kirigami.Theme.textColor
    readonly property color primaryColor: textColorMode === 1 ? Plasmoid.configuration.customPrimaryColor
                                        : textColorMode === 2 ? autoTextColor
                                        : Kirigami.Theme.textColor
    readonly property color accentColor: Plasmoid.configuration.accentColor
    readonly property color eventColor: Plasmoid.configuration.eventColor

    function withAlpha(c, a) {
        return Qt.rgba(c.r, c.g, c.b, a);
    }

    // ---- fonts: everything is measured from these ----
    readonly property string fontFamily: Plasmoid.configuration.fontFamily !== "" ? Plasmoid.configuration.fontFamily : Kirigami.Theme.defaultFont.family
    readonly property real basePointSize: Plasmoid.configuration.fontPointSize
    readonly property font dayFont: Qt.font({ family: fontFamily, pointSize: basePointSize })
    readonly property font labelFont: Qt.font({ family: fontFamily, pointSize: basePointSize * 0.86 })   // Rainmeter: 12 vs 14
    readonly property font headerFont: Qt.font({ family: fontFamily, pointSize: basePointSize })

    FontMetrics { id: dayMetrics; font: root.dayFont }
    FontMetrics { id: labelMetrics; font: root.labelFont }

    // Day labels from the locale ("Sun", "Mon", ...), in week order
    readonly property int firstDay: Plasmoid.configuration.firstDayOfWeek >= 0 ? Plasmoid.configuration.firstDayOfWeek : Qt.locale().firstDayOfWeek
    readonly property var dayLabels: {
        var labels = [];
        for (var i = 0; i < 7; i++)
            labels.push(Qt.locale().dayName((firstDay + i) % 7, Locale.ShortFormat));
        return labels;
    }

    // Cell geometry: wide enough for the widest day label (bold) or "88", in the chosen font.
    // Gaps keep LuaCalendar's proportions (cell 24 px, gaps 18/10 px at a 14 pt font).
    readonly property real cellWidth: {
        var widest = dayMetrics.advanceWidth("88");
        for (var i = 0; i < dayLabels.length; i++)
            widest = Math.max(widest, labelMetrics.advanceWidth(dayLabels[i]) * 1.08);
        return Math.ceil(widest + dayMetrics.height * 0.35);
    }
    readonly property real cellHeight: Math.ceil(dayMetrics.height * 1.3)
    readonly property real gapX: Math.round(dayMetrics.height * 0.45)
    readonly property real gapY: Math.round(dayMetrics.height * 0.35)
    readonly property bool showWeekNumbers: Plasmoid.configuration.showWeekNumbers

    // ---- calendar data ----
    property date today: new Date()

    PlasmaCalendar.EventPluginsManager {
        id: eventPlugins
        enabledPlugins: Plasmoid.configuration.enabledCalendarPlugins
    }

    PlasmaCalendar.Calendar {
        id: calendar
        days: 7
        weeks: 6
        firstDayOfWeek: root.firstDay
        today: root.today
        Component.onCompleted: daysModel.setPluginsManager(eventPlugins)
    }

    function isToday(y, m, d) {
        return y === today.getFullYear() && m === today.getMonth() + 1 && d === today.getDate();
    }

    function eventTitles(y, m, d) {
        var events = calendar.daysModel.eventsForDate(new Date(y, m - 1, d));
        var titles = [];
        for (var i = 0; i < events.length; i++) {
            if (titles.indexOf(events[i].title) < 0)
                titles.push(events[i].title);
        }
        return titles;
    }

    function showCurrentMonth() {
        calendar.resetToToday();
    }

    // The date changes at midnight: one timer for that, nothing per second.
    function msUntilMidnight() {
        var now = new Date();
        return new Date(now.getFullYear(), now.getMonth(), now.getDate() + 1, 0, 0, 5) - now;
    }

    Timer {
        id: midnightTimer
        repeat: false
        running: true
        interval: root.msUntilMidnight()
        onTriggered: {
            var shownCurrent = calendar.displayedDate.getMonth() === root.today.getMonth()
                            && calendar.displayedDate.getFullYear() === root.today.getFullYear();
            root.today = new Date();
            if (shownCurrent)
                root.showCurrentMonth();
            interval = root.msUntilMidnight();   // recomputed each day, so DST changes don't drift it
            start();
        }
    }

    // ---- automatic text colour (as in the Wunderground fork): analyse the wallpaper once, not per frame ----
    Kirigami.ImageColors {
        id: wallpaperColors
        onPaletteChanged: root.updateAutoContrast()
    }

    function analyseWallpaper() {
        if (textColorMode !== 2)
            return;
        var wallpaper = Plasmoid.containment ? Plasmoid.containment.wallpaperGraphicsObject : null;
        if (!wallpaper)
            return;
        wallpaperColors.source = wallpaper;
        wallpaperColors.update();
    }

    function updateAutoContrast() {
        var palette = wallpaperColors.palette;
        if (!palette || palette.length === 0)
            return;
        var background = wallpaperColors.average;
        var colour;
        if (Plasmoid.configuration.autoContrastStyle === 1) {
            var tint = palette[0].color;
            for (var i = 1; i < palette.length; i++) {
                if (palette[i].color.hslSaturation > tint.hslSaturation)
                    tint = palette[i].color;
            }
            colour = Contrast.tinted(background, tint);
        } else {
            colour = Contrast.blackOrWhite(background);
        }
        var hex = Contrast.toHex(colour);
        autoTextColor = hex;
        if (Plasmoid.configuration.autoContrastColor !== hex)
            Plasmoid.configuration.autoContrastColor = hex;
    }

    Timer {
        id: wallpaperTimer
        interval: 30 * 1000
        repeat: true
        running: root.textColorMode === 2
        onTriggered: {
            root.analyseWallpaper();
            interval = 30 * 60 * 1000;
        }
    }

    Connections {
        target: Plasmoid.containment
        ignoreUnknownSignals: true
        function onWallpaperGraphicsObjectChanged() {
            wallpaperTimer.interval = 5 * 1000;
            wallpaperTimer.restart();
        }
    }

    Connections {
        target: Plasmoid.configuration
        function onAutoContrastStyleChanged() { root.analyseWallpaper(); }
        function onTextColorModeChanged() { root.analyseWallpaper(); }
    }

    Plasmoid.contextualActions: [
        PlasmaCore.Action {
            text: i18n("Current Month")
            icon.name: "go-jump-today"
            onTriggered: root.showCurrentMonth()
        },
        PlasmaCore.Action {
            text: i18n("Previous Month")
            icon.name: "go-previous"
            onTriggered: calendar.previousMonth()
        },
        PlasmaCore.Action {
            text: i18n("Next Month")
            icon.name: "go-next"
            onTriggered: calendar.nextMonth()
        },
        PlasmaCore.Action {
            text: i18n("Previous Year")
            icon.name: "go-previous-skip"
            onTriggered: calendar.previousYear()
        },
        PlasmaCore.Action {
            text: i18n("Next Year")
            icon.name: "go-next-skip"
            onTriggered: calendar.nextYear()
        }
    ]

    fullRepresentation: Item {
        id: view

        readonly property real weekColumnWidth: root.showWeekNumbers ? root.cellWidth + root.gapX : 0
        readonly property real margin: root.gapX * 0.5

        implicitWidth: margin * 2 + weekColumnWidth + 7 * root.cellWidth + 6 * root.gapX
        implicitHeight: margin * 2 + header.height + root.gapY + 7 * root.cellHeight + 6 * root.gapY
        Layout.preferredWidth: implicitWidth
        Layout.preferredHeight: implicitHeight
        Layout.minimumWidth: implicitWidth
        Layout.minimumHeight: implicitHeight

        // Mouse wheel changes the month (as in LuaCalendar)
        WheelHandler {
            acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
            onWheel: function (event) {
                if (event.angleDelta.y < 0)
                    calendar.nextMonth();
                else if (event.angleDelta.y > 0)
                    calendar.previousMonth();
            }
        }

        // Header: "Oct - 2026"; click it to go back to the current month
        PlasmaComponents.Label {
            id: header
            x: view.margin + view.weekColumnWidth
            y: view.margin
            width: 7 * root.cellWidth + 6 * root.gapX
            height: root.cellHeight
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            font: root.headerFont
            color: root.withAlpha(root.primaryColor, 0.63)
            text: Qt.locale().monthName(calendar.month - 1, Locale.ShortFormat) + " - " + calendar.year

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: root.showCurrentMonth()
            }
        }

        // Weekday labels on a faint chip; today's weekday in bold
        Repeater {
            model: 7
            delegate: Rectangle {
                required property int index
                readonly property bool isTodayColumn: (root.firstDay + index) % 7 === root.today.getDay()
                x: view.margin + view.weekColumnWidth + index * (root.cellWidth + root.gapX)
                y: header.y + header.height + root.gapY
                width: root.cellWidth
                height: root.cellHeight
                color: root.withAlpha(root.primaryColor, 0.10)

                PlasmaComponents.Label {
                    anchors.centerIn: parent
                    font.family: root.fontFamily
                    font.pointSize: root.labelFont.pointSize
                    font.bold: parent.isTodayColumn
                    color: root.withAlpha(root.primaryColor, 0.59)
                    text: root.dayLabels[parent.index]
                }
            }
        }

        // Week numbers (ISO), left column
        Repeater {
            model: root.showWeekNumbers ? calendar.weeksModel : []
            delegate: PlasmaComponents.Label {
                required property int index
                required property var modelData
                x: view.margin
                y: header.y + header.height + root.gapY + (index + 1) * (root.cellHeight + root.gapY)
                width: root.cellWidth
                height: root.cellHeight
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                font: root.dayFont
                color: root.withAlpha(root.accentColor, 0.39)
                text: modelData
            }
        }

        // The days: 6 weeks x 7
        Repeater {
            model: calendar.daysModel
            delegate: Item {
                id: cell
                required property int index
                required property var model

                readonly property bool inMonth: model.monthNumber === calendar.month && model.yearNumber === calendar.year
                readonly property bool isToday: root.isToday(model.yearNumber, model.monthNumber, model.dayNumber)
                readonly property bool hasEvents: model.eventCount !== undefined && model.eventCount > 0

                x: view.margin + view.weekColumnWidth + (index % 7) * (root.cellWidth + root.gapX)
                y: header.y + header.height + root.gapY + (Math.floor(index / 7) + 1) * (root.cellHeight + root.gapY)
                width: root.cellWidth
                height: root.cellHeight

                PlasmaComponents.Label {
                    anchors.fill: parent
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    font.family: root.fontFamily
                    font.pointSize: root.basePointSize
                    font.bold: cell.isToday
                    // LuaCalendar order: today > event day > other month > normal
                    color: cell.isToday ? root.primaryColor
                         : (cell.hasEvents && cell.inMonth) ? root.withAlpha(root.eventColor, 0.39)
                         : !cell.inMonth ? root.withAlpha(root.accentColor, 0.63)
                         : root.withAlpha(root.primaryColor, 0.63)
                    text: cell.model.dayNumber
                }

                // Today's underline
                Rectangle {
                    visible: cell.isToday
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.bottom: parent.bottom
                    width: dayMetrics.advanceWidth("88") * 1.1
                    height: Math.max(2, Math.round(dayMetrics.height * 0.08))
                    color: root.withAlpha(root.accentColor, 0.63)
                }

                // Event names in a tooltip balloon
                PlasmaCore.ToolTipArea {
                    anchors.fill: parent
                    active: cell.hasEvents
                    mainText: Qt.formatDate(new Date(cell.model.yearNumber, cell.model.monthNumber - 1, cell.model.dayNumber), Qt.locale().dateFormat(Locale.LongFormat))
                    subText: cell.hasEvents ? root.eventTitles(cell.model.yearNumber, cell.model.monthNumber, cell.model.dayNumber).join("\n") : ""
                }
            }
        }
    }
}
