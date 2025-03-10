/*
    SPDX-FileCopyrightText: 2009 Alan Alpert <alan.alpert@nokia.com>
    SPDX-FileCopyrightText: 2010 Ménard Alexis <menard@kde.org>

    SPDX-License-Identifier: LGPL-2.0-or-later
*/

#include <QQmlComponent>
#include <QQmlContext>
#include <QQmlExpression>
#include <QQmlProperty>
#include <QFile>
#include <QTimer>
#include <QWidget>

#include <KConfigGroup>
#include <QDebug>
#include <KLocalizedString>

#include <Plasma/Applet>
#include <Plasma/Corona>
#include <Plasma/Package>
#include <Plasma/PluginLoader>
#include <Plasma/Service>

#include "plasmoid/declarativeappletscript.h"

#include "plasmoid/appletinterface.h"
#include "plasmoid/containmentinterface.h"
#include "plasmoid/wallpaperinterface.h"

#include <kdeclarative/qmlobject.h>
#include <kdeclarative/configpropertymap.h>

DeclarativeAppletScript::DeclarativeAppletScript(QObject *parent, const QVariantList &args)
    : Plasma::AppletScript(parent),
      m_interface(nullptr),
      m_args(args)
{
    //qmlRegisterType<AppletInterface>();
    //FIXME: use this if/when will be possible to have properties of attached items subclasses on the left hand of expressions
    /*qmlRegisterUncreatableType<AppletLoader>("org.kde.plasma.plasmoid", 2, 0, "Plasmoid",
                                             QLatin1String("Do not create objects of type Plasmoid"));*/
    qmlRegisterUncreatableType<AppletInterface>("org.kde.plasma.plasmoid", 2, 0, "Plasmoid",
            QStringLiteral("Do not create objects of type Plasmoid"));
    qmlRegisterUncreatableType<ContainmentInterface>("org.kde.plasma.plasmoid", 2, 0, "Containment",
            QStringLiteral("Do not create objects of type Containment"));

    qmlRegisterUncreatableType<WallpaperInterface>("org.kde.plasma.plasmoid", 2, 0, "Wallpaper",
            QStringLiteral("Do not create objects of type Wallpaper"));

    qmlRegisterAnonymousType<KDeclarative::ConfigPropertyMap>("org.kde.plasma.plasmoid", 1);
}

DeclarativeAppletScript::~DeclarativeAppletScript()
{
}

bool DeclarativeAppletScript::init()
{
    //make possible to import extensions from the package
    //FIXME: probably to be removed, would make possible to use native code from within the package :/
    //m_interface->qmlObject()->engine()->addImportPath(package()->path()+"/contents/imports");

    Plasma::Applet *a = applet();
    Plasma::Containment *pc = qobject_cast<Plasma::Containment *>(a);

    if (pc && pc->isContainment()) {
        m_interface = new ContainmentInterface(this, m_args);

        //fail? so it's a normal Applet
    } else {
        m_interface = new AppletInterface(this, m_args);
    }

    m_interface->setParent(this);

    return true;
}

QString DeclarativeAppletScript::filePath(const QString &type, const QString &file) const
{
    return applet()->kPackage().filePath(type.toLocal8Bit().constData(), file);
}

void DeclarativeAppletScript::constraintsEvent(Plasma::Types::Constraints constraints)
{
    if (constraints & Plasma::Types::FormFactorConstraint) {
        emit formFactorChanged();
    }

    if (constraints & Plasma::Types::LocationConstraint) {
        emit locationChanged();
    }

    if (constraints & Plasma::Types::ContextConstraint) {
        emit contextChanged();
    }
}

void DeclarativeAppletScript::executeAction(const QString &name)
{
    m_interface->executeAction(name);
}

QList<QAction *> DeclarativeAppletScript::contextualActions()
{
    if (!m_interface) {
        return QList<QAction *>();
    }

    return m_interface->contextualActions();
}

K_EXPORT_PLASMA_APPLETSCRIPTENGINE_WITH_JSON(plasma_appletscript_declarative, DeclarativeAppletScript, "plasma-scriptengine-applet-declarative.json")

#include "declarativeappletscript.moc"

