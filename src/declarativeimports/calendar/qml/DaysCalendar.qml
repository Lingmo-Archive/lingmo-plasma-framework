/*
    SPDX-FileCopyrightText: 2013 Heena Mahour <heena393@gmail.com>
    SPDX-FileCopyrightText: 2013 Sebastian Kügler <sebas@kde.org>
    SPDX-FileCopyrightText: 2015, 2016 Kai Uwe Broulik <kde@privat.broulik.de>

    SPDX-License-Identifier: GPL-2.0-or-later
*/

import QtQuick 2.2
import QtQuick.Layouts 1.1
import QtQuick.Controls 1.1

import org.kde.plasma.calendar 2.0
import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.plasma.components 2.0 as Components
import org.kde.plasma.extras 2.0 as PlasmaExtras

Item {
    id: daysCalendar

    signal headerClicked

    signal previous
    signal next

    signal activated(int index, var date, var item)
    // so it forwards it to the delegate which then emits activated with all the necessary data
    signal activateHighlightedItem

    readonly property int gridColumns: showWeekNumbers ? calendarGrid.columns + 1 : calendarGrid.columns

    property alias previousLabel: previousButton.tooltip
    property alias nextLabel: nextButton.tooltip

    property int rows
    property int columns

    property bool showWeekNumbers

    onShowWeekNumbersChanged: canvas.requestPaint()

    // how precise date matching should be, 3 = day+month+year, 2 = month+year, 1 = just year
    property int dateMatchingPrecision

    property alias headerModel: days.model
    property alias gridModel: repeater.model

    property alias title: heading.text

    // Take the calendar width, subtract the inner and outer spacings and divide by number of columns (==days in week)
    readonly property int cellWidth: Math.floor((stack.width - (daysCalendar.columns + 1) * root.borderWidth) / (daysCalendar.columns + (showWeekNumbers ? 1 : 0)))
    // Take the calendar height, subtract the inner spacings and divide by number of rows (root.weeks + one row for day names)
    readonly property int cellHeight:  Math.floor((stack.height - heading.height - calendarGrid.rows * root.borderWidth) / calendarGrid.rows)

    property real transformScale: 1
    property point transformOrigin: Qt.point(width / 2, height / 2)

    transform: Scale {
        xScale: daysCalendar.transformScale
        yScale: xScale
        origin.x: transformOrigin.x
        origin.y: transformOrigin.y
    }

    Behavior on scale {
        id: scaleBehavior
        ScaleAnimator {
            duration: PlasmaCore.Units.longDuration
        }
    }

    Stack.onStatusChanged: {
        if (Stack.status === Stack.Inactive) {
            daysCalendar.transformScale = 1
            opacity = 1
        }
    }

    RowLayout {
        anchors {
            top: parent.top
            left: canvas.left
            right: canvas.right
        }
        spacing: PlasmaCore.Units.smallSpacing

        PlasmaExtras.Heading {
            id: heading

            Layout.fillWidth: true

            level: 2
            elide: Text.ElideRight
            font.capitalization: Font.Capitalize
            //SEE QTBUG-58307
            //try to make all heights an even number, otherwise the layout engine gets confused
            Layout.preferredHeight: implicitHeight + implicitHeight%2

            MouseArea {
                id: monthMouse
                property int previousPixelDelta

                anchors.fill: parent
                onClicked: {
                    if (!stack.busy) {
                        daysCalendar.headerClicked()
                    }
                }
                onExited: previousPixelDelta = 0
                onWheel: {
                    var delta = wheel.angleDelta.y || wheel.angleDelta.x
                    var pixelDelta = wheel.pixelDelta.y || wheel.pixelDelta.x

                    // For high-precision touchpad scrolling, we get a wheel event for basically every slightest
                    // finger movement. To prevent the view from suddenly ending up in the next century, we
                    // cumulate all the pixel deltas until they're larger than the label and then only change
                    // the month. Standard mouse wheel scrolling is unaffected since it's fine.
                    if (pixelDelta) {
                        if (Math.abs(previousPixelDelta) < monthMouse.height) {
                            previousPixelDelta += pixelDelta
                            return
                        }
                    }

                    if (delta >= 15) {
                        daysCalendar.previous()
                    } else if (delta <= -15) {
                        daysCalendar.next()
                    }
                    previousPixelDelta = 0
                }
            }
        }

        Components.ToolButton {
            id: previousButton
            iconName: Qt.application.layoutDirection === Qt.RightToLeft ? "go-next" : "go-previous"
            onClicked: daysCalendar.previous()
            Accessible.name: tooltip
            //SEE QTBUG-58307
            Layout.preferredHeight: implicitHeight + implicitHeight%2
        }

        Components.ToolButton {
            iconName: "go-jump-today"
            onClicked: root.resetToToday()
            tooltip: i18ndc("libplasma5", "Reset calendar to today", "Today")
            Accessible.name: tooltip
            Accessible.description: i18nd("libplasma5", "Reset calendar to today")
            //SEE QTBUG-58307
            Layout.preferredHeight: implicitHeight + implicitHeight%2
        }

        Components.ToolButton {
            id: nextButton
            iconName: Qt.application.layoutDirection === Qt.RightToLeft ? "go-previous" : "go-next"
            onClicked: daysCalendar.next()
            Accessible.name: tooltip
            //SEE QTBUG-58307
            Layout.preferredHeight: implicitHeight + implicitHeight%2
        }
    }

    // Paints the inner grid and the outer frame
    Canvas {
        id: canvas

        anchors {
            horizontalCenter: parent.horizontalCenter
            bottom: parent.bottom
        }
        width: (daysCalendar.cellWidth + root.borderWidth) * gridColumns + root.borderWidth
        height: (daysCalendar.cellHeight + root.borderWidth) * calendarGrid.rows + root.borderWidth

        opacity: root.borderOpacity
        antialiasing: false
        clip: false
        onPaint: {
            var ctx = getContext("2d");
            // this is needed as otherwise the canvas seems to have some sort of
            // inner clip region which does not update on size changes
            ctx.reset();
            ctx.save();
            ctx.clearRect(0, 0, canvas.width, canvas.height);
            ctx.strokeStyle = PlasmaCore.Theme.textColor;
            ctx.lineWidth = root.borderWidth
            ctx.globalAlpha = 1.0;

            ctx.beginPath();

            // When line is more wide than 1px, it is painted with 1px line at the actual coords
            // and then 1px lines are added first to the left of the middle then right (then left again)
            // So all the lines need to be offset a bit to have their middle point in the center
            // of the grid spacing rather than on the left most pixel, otherwise they will be painted
            // over the days grid which will be visible on eg. mouse hover
            var lineBasePoint = Math.floor(root.borderWidth / 2)

            // horizontal lines
            for (var i = 0; i < calendarGrid.rows + 1; i++) {
                var lineY = lineBasePoint + (daysCalendar.cellHeight + root.borderWidth) * (i);

                if (i == 0 || i == calendarGrid.rows) {
                    ctx.moveTo(0, lineY);
                } else {
                    ctx.moveTo(showWeekNumbers ? daysCalendar.cellWidth + root.borderWidth : root.borderWidth, lineY);
                }
                ctx.lineTo(width, lineY);
            }

            // vertical lines
            for (var i = 0; i < gridColumns + 1; i++) {
                var lineX = lineBasePoint + (daysCalendar.cellWidth + root.borderWidth) * (i);

                // Draw the outer vertical lines in full height so that it closes
                // the outer rectangle
                if (i == 0 || i == gridColumns || !daysCalendar.headerModel) {
                    ctx.moveTo(lineX, 0);
                } else {
                    ctx.moveTo(lineX, root.borderWidth + daysCalendar.cellHeight);
                }
                ctx.lineTo(lineX, height);
            }

            ctx.closePath();
            ctx.stroke();
            ctx.restore();
        }
    }

    PlasmaCore.Svg {
        id: calendarSvg
        imagePath: "widgets/calendar"
    }

    Component {
        id: eventsMarkerComponent

        PlasmaCore.SvgItem {
            id: eventsMarker
            svg: calendarSvg
            elementId: "event"
        }
    }

    Connections {
        target: theme
        onTextColorChanged: {
            canvas.requestPaint();
        }
    }

    Column {
        id: weeksColumn
        visible: showWeekNumbers
        anchors {
            top: canvas.top
            left: parent.left
            bottom: canvas.bottom
            // The borderWidth needs to be counted twice here because it goes
            // in fact through two lines - the topmost one (the outer edge)
            // and then the one below weekday strings
            topMargin: daysCalendar.cellHeight + root.borderWidth + root.borderWidth
        }
        spacing: root.borderWidth

        Repeater {
            model: showWeekNumbers ? calendarBackend.weeksModel : []

            Components.Label {
                height: daysCalendar.cellHeight
                width: daysCalendar.cellWidth
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                opacity: 0.4
                text: modelData
                font.pixelSize: Math.max(PlasmaCore.Theme.smallestFont.pixelSize, daysCalendar.cellHeight / 3)
            }
        }
    }

    Grid {
        id: calendarGrid

        anchors {
            right: canvas.right
            rightMargin: root.borderWidth
            bottom: parent.bottom
            bottomMargin: root.borderWidth
        }

        columns: daysCalendar.columns
        rows: daysCalendar.rows + (daysCalendar.headerModel ? 1 : 0)

        spacing: root.borderWidth
        property bool containsEventItems: false // FIXME
        property bool containsTodoItems: false // FIXME

        Repeater {
            id: days

            Components.Label {
                width: daysCalendar.cellWidth
                height: daysCalendar.cellHeight
                text: Qt.locale(Qt.locale().uiLanguages[0]).dayName(((calendarBackend.firstDayOfWeek + index) % days.count), Locale.ShortFormat)
                font.pixelSize: Math.max(PlasmaCore.Theme.smallestFont.pixelSize, daysCalendar.cellHeight / 3)
                opacity: 0.4
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                elide: Text.ElideRight
                fontSizeMode: Text.HorizontalFit
            }
        }

        Repeater {
            id: repeater

            DayDelegate {
                id: delegate
                width: daysCalendar.cellWidth
                height: daysCalendar.cellHeight

                onClicked: daysCalendar.activated(index, model, delegate)

                Connections {
                    target: daysCalendar
                    onActivateHighlightedItem: {
                        if (delegate.containsMouse) {
                            delegate.clicked(null)
                        }
                    }
                }
            }
        }
    }
}
