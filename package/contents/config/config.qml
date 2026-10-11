/*
 * Copyright 2026  Allen Hewes
 * SPDX-License-Identifier: GPL-2.0-or-later
 */
import QtQuick
import org.kde.plasma.configuration
import org.kde.plasma.plasmoid
import org.kde.plasma.workspace.calendar as PlasmaCalendar

ConfigModel {
    id: configModel

    ConfigCategory {
        name: i18n("General")
        icon: "view-calendar-month"
        source: "ConfigGeneral.qml"
    }

    ConfigCategory {
        name: i18n("Events")
        icon: "view-calendar-holiday"
        source: "ConfigEvents.qml"
    }

    // The event plugins' own settings pages (e.g. holiday regions), shown for enabled plugins
    // (same approach as Plasma's digital clock).
    readonly property PlasmaCalendar.EventPluginsManager eventPluginsManager: PlasmaCalendar.EventPluginsManager {
        Component.onCompleted: populateEnabledPluginsList(Plasmoid.configuration.enabledCalendarPlugins)
    }

    readonly property Instantiator __eventPlugins: Instantiator {
        model: configModel.eventPluginsManager.model
        delegate: ConfigCategory {
            required property string display
            required property string decoration
            required property string configUi
            required property string configModule
            required property string configComponent
            required property string pluginId

            name: display
            icon: decoration
            source: configUi
            configUiModule: configModule
            configUiComponent: configComponent
            visible: Plasmoid.configuration.enabledCalendarPlugins.indexOf(pluginId) > -1
        }
        onObjectAdded: (index, object) => configModel.appendCategory(object)
        onObjectRemoved: (index, object) => configModel.removeCategory(object)
    }
}
