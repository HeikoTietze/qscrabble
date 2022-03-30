import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick3D

Item {

    function updateCubeModel() {
        //TODO: cube: feeback on init
        cube.model = GamePlay.cubeModel //assign model not until it is used to avoid delay on app start
    }

    View3D {
        id: view
        anchors.fill: parent
        camera: camera

        environment: SceneEnvironment {
            id: seEnvironment
            backgroundMode: SceneEnvironment.Transparent
            antialiasingMode: SceneEnvironment.SSAA
            antialiasingQuality: SceneEnvironment.VeryHigh
        }

        PerspectiveCamera {
            id: pcCamera
            position: Qt.vector3d(0, 0, 30)
        }

        DirectionalLight {
        }

        Skeleton {
            id: sceneRoot
            eulerRotation.y: -180
            Repeater3D {
                id: cube
                model: {} //empty to quickly start; will be initialized at first usage
                Model {
                    property int bs: GamePlay.boardSize
                    property real bs2: bs/2
                    property int x: (index % bs)
                    property int y: Math.floor(index / bs) % bs
                    property int z: Math.floor(index / (bs * bs)) % bs

                    property int aFieldType: fieldtype
                    property string aWhat: what
                    property int aValue: value
                    property int aWhen: when
                    property int aWho: who

                    source: "#Cube"
                    position: Qt.vector3d(bs2-x, bs2-y,  bs2-z)
                    scale: Qt.vector3d(0.01, 0.01, 0.01)

                    materials: [
                        DefaultMaterial {
                            diffuseMap: Texture {
                                sourceItem:
                                    ScrPiece {
                                        implicitWidth: 128
                                        implicitHeight: 128
                                        pieceColor: aWhat == String.fromCharCode(0) //empty?
                                                    ? config.colors.get(aFieldType).itemColor //use field color when empty
                                                    : aWhen === GamePlay.currentMove
                                                      ? config.colors.get(8).itemColor //use (yellow) field color for non-empty squares
                                                      : Qt.lighter(config.colors.get(8).itemColor) // ... but a bit lighter when removing is not possible
                                        pieceShadow: (isPlaced && config.bColoredPlayers)
                                                     ? config.playercolors.get(aWho).itemColor //colored shadow to show who placed a piece
                                                     : "transparent"
                                        pieceLabel: aWhat
                                        pieceValue: aValue
                                    }
                                }
                            lighting: DefaultMaterial.NoLighting
                            opacity: (aWhat == String.fromCharCode(0))
                                     ? (aFieldType == 1) ? 0.025 : 0.25 //normal fields are almost fully transparent, bonus fields largely
                                     : 1.0
                         }
                     ]
                }
            }
            Model {
                id: plane
                property int bs: GamePlay.boardSize
                property real pos: bs/2 - GamePlay.activePosition
                source: "#Cube"
                scale: (GamePlay.activeDimension === 0)
                               ? Qt.vector3d(bs*0.01+0.02, bs*0.01+0.02, 0)
                               : GamePlay.activeDimension === 1
                                 ? Qt.vector3d(0, bs*0.01+0.02, bs*0.01+0.02)
                                 : Qt.vector3d(bs*0.01+0.02, 0, bs*0.01+0.02)
                position: (GamePlay.activeDimension === 0)
                          ? Qt.vector3d(0, 0, pos)
                          : GamePlay.activeDimension === 1
                            ? Qt.vector3d(pos, 0, 0)
                            : Qt.vector3d(0, pos, 0)

                materials: [
                    DefaultMaterial {
                        diffuseColor: "lightgrey"
                        opacity: 0.25
                        cullMode: Material.NoCulling
                     }
                 ]
            }
        }

        MouseArea {
             id: inputArea
             anchors.fill: parent
             hoverEnabled: true
             acceptedButtons: Qt.LeftButton | Qt.RightButton
             property point lastPos
             property real wheelpos
             onPressed:
                 if (mouse.buttons == Qt.LeftButton) //rotate with left mouse button pressed
                    lastPos = Qt.point(mouse.x, mouse.y);
                 else if (mouse.modifiers & Qt.ControlModifier) //toggle dimension with right mb and control pressed
                    GamePlay.activeDimension += 1

             onPositionChanged:
                 if (mouse.buttons == Qt.LeftButton) {
                     sceneRoot.eulerRotation.x -= mouse.y - lastPos.y
                     sceneRoot.eulerRotation.y += mouse.x - lastPos.x
                     lastPos = Qt.point(mouse.x, mouse.y);
                 }
             onWheel:
                if (wheel.modifiers & Qt.ControlModifier)
                {
                     wheelpos += wheel.angleDelta.y/120
                     if (wheelpos < -1) {
                        GamePlay.activePosition -= 1
                        wheelpos = 0
                     } else
                     if (wheelpos > 1) {
                        GamePlay.activePosition += 1
                        wheelpos = 0
                     }
                 } else
                 {
                    var fZoom = pcCamera.position.z
                    fZoom += wheel.angleDelta.y / 50
                    pcCamera.position.z = fZoom
                 }
        }
    }
    RowLayout {
        id: topPanel
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        height: 50
        Label {
            Layout.leftMargin: 8
            text: qsTr("Pos: ")
        }
        Slider {
            id: pos3D
            implicitWidth: 100
            from: 0
            to: GamePlay.is3D ? GamePlay.boardSize-1 : 0
            value: GamePlay.activePosition
            onValueChanged: GamePlay.activePosition = value
            snapMode: Slider.SnapAlways
            stepSize: 1
        }
        Label {
            text: pos3D.value + 1
        }
        Label {
            Layout.leftMargin: 16
            text: qsTr("Dim: ")
        }
        Rectangle {
            height: 38
            width: 38
            color: "lightgrey"
            border.width: GamePlay.activeDimension === 0 ? 3 : 0
            Image {
                anchors.fill: parent
                anchors.margins: 6
                source: "qrc:///resources/abscissa.png"
            }
            MouseArea {
                anchors.fill: parent
                onClicked: GamePlay.activeDimension = 0
            }
        }
        Rectangle {
            height: 38
            width: 38
            color: "lightgrey"
            border.width: GamePlay.activeDimension === 1 ? 3 : 0
            Image {
                anchors.fill: parent
                anchors.margins: 6
                source: "qrc:///resources/ordinate.png"
            }
            MouseArea {
                anchors.fill: parent
                onClicked: GamePlay.activeDimension = 1
            }
        }
        Rectangle {
            height: 38
            width: 38
            color: "lightgrey"
            border.width: GamePlay.activeDimension === 2 ? 3 : 0
            Image {
                anchors.fill: parent
                anchors.margins: 6
                source: "qrc:///resources/applicate.png"
            }
            MouseArea {
                anchors.fill: parent
                onClicked: GamePlay.activeDimension = 2
            }
        }
        Item {
            Layout.fillWidth: true
        }
    }
    Image {
        id: showTopPanel
        width: 24
        height: 24
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.rightMargin: 16
        anchors.topMargin: 16
        source: "qrc:///resources/up.png"
        MouseArea {
            anchors.fill: parent
            onClicked: {
                topPanel.visible = !topPanel.visible;
                if (topPanel.visible)
                    parent.source = "qrc:///resources/up.png"
                else
                    parent.source = "qrc:///resources/down.png"
            }
        }
    }
}
