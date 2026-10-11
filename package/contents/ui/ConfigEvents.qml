/*
 * Copyright 2026  Allen Hewes
 * SPDX-License-Identifier: GPL-2.0-or-later
 */
// Which calendar event sources to show (Plasma's calendar plugins), as in the digital clock's settings.
import QtQuick
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM
import org.kde.plasma.plasmoid
import org.kde.plasma.workspace.calendar as PlasmaCalendar

KCM.ScrollViewKCM {
    id: eventsPage

    property bool unsavedChanges: false

    function saveConfig() {
        Plasmoid.configuration.enabledCalendarPlugins = eventPluginsManager.enabledPlugins;
        Plasmoid.configuration.writeConfig();
        unsavedChanges = false;
    }

    function checkUnsavedChanges() {
        const saved = Plasmoid.configuration.enabledCalendarPlugins;
        const now = eventPluginsManager.enabledPlugins;
        unsavedChanges = !(saved.every(entry => now.includes(entry)) && now.every(entry => saved.includes(entry)));
    }

    header: QQC2.Label {
        text: i18n("Days with events are shown dimmed; hover over a day to see its events. Holidays: pick the regions on the Holidays page.")
        wrapMode: Text.WordWrap
        padding: Kirigami.Units.largeSpacing
    }

    PlasmaCalendar.EventPluginsManager {
        id: eventPluginsManager
        Component.onCompleted: populateEnabledPluginsList(Plasmoid.configuration.enabledCalendarPlugins)
    }

    view: ListView {
        id: pluginListView
        model: eventPluginsManager.model
        delegate: QQC2.CheckDelegate {
            id: delegate
            required property var model
            width: pluginListView.width
            checked: model.checked
            text: model.display
            icon.source: model.decoration
            onClicked: {
                model.checked = checked;   // the model's setData updates enabledPlugins
                eventsPage.checkUnsavedChanges();
            }
            contentItem: Kirigami.IconTitleSubtitle {
                width: delegate.availableWidth
                icon: icon.fromControlsIcon(delegate.icon)
                title: delegate.text
                subtitle: delegate.model.toolTip
                selected: delegate.highlighted || delegate.pressed
            }
        }
    }
}
