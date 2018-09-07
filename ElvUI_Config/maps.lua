﻿local E, L, V, P, G = unpack(ElvUI)
local WM = E:GetModule("WorldMap")
local MM = E:GetModule("Minimap")

local HIDE, FONT_SIZE, NONE = HIDE, FONT_SIZE, NONE
local MAIL_LABEL, MINIMAP_LABEL = MAIL_LABEL, MINIMAP_LABEL
local LEAVE_VEHICLE, WORLD_MAP = LEAVE_VEHICLE, WORLD_MAP
local ZOOM_IN, ZOOM_OUT = ZOOM_IN, ZOOM_OUT

E.Options.args.maps = {
	type = "group",
	name = L["Maps"],
	childGroups = "tab",
	args = {
		worldMap = {
			order = 1,
			type = "group",
			name = WORLD_MAP,
			args = {
				header = {
					order = 1,
					type = "header",
					name = WORLD_MAP
				},
				generalGroup = {
					order = 2,
					type = "group",
					name = L["General"],
					guiInline = true,
					args = {
						smallerWorldMap = {
							order = 1,
							type = "toggle",
							name = L["Smaller World Map"],
							desc = L["Make the world map smaller."],
							get = function(info) return E.global.general.smallerWorldMap end,
							set = function(info, value) E.global.general.smallerWorldMap = value E:StaticPopup_Show("GLOBAL_RL") end
						},
						mapAlphaWhenMoving = {
							order = 2,
							type = "range",
							name = L["Map Opacity When Moving"],
							isPercent = true,
							min = 0, max = 1, step = 0.01,
							get = function(info) return E.global.general.mapAlphaWhenMoving end,
							set = function(info, value) E.global.general.mapAlphaWhenMoving = value E:GetModule("Misc"):UpdateMapAlpha() end
						}
					}
				},
				spacer  = {
					order = 3,
					type = "description",
					name = "\n"
				},
				coordinatesGroup = {
					order = 4,
					type = "group",
					name = L["World Map Coordinates"],
					guiInline = true,
					args = {
						enable = {
							order = 1,
							type = "toggle",
							name = L["Enable"],
							desc = L["Puts coordinates on the world map."],
							get = function(info) return E.global.general.WorldMapCoordinates.enable end,
							set = function(info, value) E.global.general.WorldMapCoordinates.enable = value E:StaticPopup_Show("GLOBAL_RL") end
						},
						spacer = {
							order = 2,
							type = "description",
							name = " "
						},
						position = {
							order = 3,
							type = "select",
							name = L["Position"],
							get = function(info) return E.global.general.WorldMapCoordinates.position end,
							set = function(info, value) E.global.general.WorldMapCoordinates.position = value WM:PositionCoords() end,
							disabled = function() return not E.global.general.WorldMapCoordinates.enable end,
							values = {
								["TOP"] = "TOP",
								["TOPLEFT"] = "TOPLEFT",
								["TOPRIGHT"] = "TOPRIGHT",
								["BOTTOM"] = "BOTTOM",
								["BOTTOMLEFT"] = "BOTTOMLEFT",
								["BOTTOMRIGHT"] = "BOTTOMRIGHT"
							}
						},
						xOffset = {
							order = 4,
							type = "range",
							name = L["X-Offset"],
							get = function(info) return E.global.general.WorldMapCoordinates.xOffset end,
							set = function(info, value) E.global.general.WorldMapCoordinates.xOffset = value WM:PositionCoords() end,
							disabled = function() return not E.global.general.WorldMapCoordinates.enable end,
							min = -200, max = 200, step = 1
						},
						yOffset = {
							order = 5,
							type = "range",
							name = L["Y-Offset"],
							get = function(info) return E.global.general.WorldMapCoordinates.yOffset end,
							set = function(info, value) E.global.general.WorldMapCoordinates.yOffset = value WM:PositionCoords() end,
							disabled = function() return not E.global.general.WorldMapCoordinates.enable end,
							min = -200, max = 200, step = 1
						}
					}
				}
			}
		},
		minimap = {
			order = 2,
			type = "group",
			name = MINIMAP_LABEL,
			get = function(info) return E.db.general.minimap[ info[#info] ] end,
			childGroups = "tab",
			args = {
				minimapHeader = {
					order = 1,
					type = "header",
					name = MINIMAP_LABEL
				},
				generalGroup = {
					order = 2,
					type = "group",
					name = L["General"],
					guiInline = true,
					args = {
						enable = {
							order = 1,
							type = "toggle",
							name = L["Enable"],
							desc = L["Enable/Disable the minimap. |cffFF0000Warning: This will prevent you from seeing the consolidated buffs bar, and prevent you from seeing the minimap datatexts.|r"],
							get = function(info) return E.private.general.minimap[ info[#info] ] end,
							set = function(info, value) E.private.general.minimap[ info[#info] ] = value E:StaticPopup_Show("PRIVATE_RL") end
						},
						size = {
							order = 2,
							type = "range",
							name = L["Size"],
							desc = L["Adjust the size of the minimap."],
							min = 120, max = 250, step = 1,
							get = function(info) return E.db.general.minimap[ info[#info] ] end,
							set = function(info, value) E.db.general.minimap[ info[#info] ] = value MM:UpdateSettings() end,
							disabled = function() return not E.private.general.minimap.enable end
						}
					}
				},
				locationTextGroup = {
					order = 3,
					type = "group",
 					name = L["Location Text"],
					args = {
						locationHeader = {
							order = 1,
							type = "header",
							name = L["Location Text"]
						},
						locationText = {
						    order = 2,
						    type = "select",
						    name = L["Location Text"],
						    desc = L["Change settings for the display of the location text that is on the minimap."],
						    get = function(info) return E.db.general.minimap.locationText end,
						    set = function(info, value) E.db.general.minimap.locationText = value MM:UpdateSettings() MM:Update_ZoneText() end,
						    values = {
						        ["MOUSEOVER"] = L["Minimap Mouseover"],
						        ["SHOW"] = L["Always Display"],
						        ["HIDE"] = HIDE
						    },
						    disabled = function() return not E.private.general.minimap.enable end
						},
						spacer = {
							order = 3,
							type = "description",
							name = " "
						},
						locationFont = {
						    order = 4,
						    type = "select",
						    dialogControl = "LSM30_Font",
						    name = L["Font"],
						    values = AceGUIWidgetLSMlists.font,
						    set = function(info, value) E.db.general.minimap.locationFont = value MM:Update_ZoneText() end,
							disabled = function() return not E.private.general.minimap.enable end
						},
						locationFontSize = {
						    order = 5,
						    type = "range",
						    name = FONT_SIZE,
						    min = 6, max = 36, step = 1,
						    set = function(info, value) E.db.general.minimap.locationFontSize = value MM:Update_ZoneText() end,
							disabled = function() return not E.private.general.minimap.enable end
						},
						locationFontOutline = {
						    order = 6,
						    type = "select",
						    name = L["Font Outline"],
						    set = function(info, value) E.db.general.minimap.locationFontOutline = value MM:Update_ZoneText() end,
							disabled = function() return not E.private.general.minimap.enable end,
						    values = {
						        ["NONE"] = NONE,
						        ["OUTLINE"] = "OUTLINE",
						        ["MONOCHROMEOUTLINE"] = "MONOCROMEOUTLINE",
						        ["THICKOUTLINE"] = "THICKOUTLINE"
						    }
						}
					}
				},
				zoomResetGroup = {
					order = 4,
					type = "group",
					name = L["Reset Zoom"],
					args = {
						zoomResetHeader = {
							order = 1,
							type = "header",
							name = L["Reset Zoom"]
						},
						enableZoomReset = {
							order = 2,
							type = "toggle",
							name = L["Reset Zoom"],
							get = function(info) return E.db.general.minimap.resetZoom.enable end,
							set = function(info, value) E.db.general.minimap.resetZoom.enable = value MM:UpdateSettings() end,
							disabled = function() return not E.private.general.minimap.enable end
						},
						zoomResetTime = {
							order = 3,
							type = "range",
							name = L["Seconds"],
							min = 1, max = 15, step = 1,
							get = function(info) return E.db.general.minimap.resetZoom.time end,
							set = function(info, value) E.db.general.minimap.resetZoom.time = value MM:UpdateSettings() end,
							disabled = function() return (not E.db.general.minimap.resetZoom.enable or not E.private.general.minimap.enable) end
						}
					}
				},
				icons = {
					order = 5,
					type = "group",
					name = L["Buttons"],
					args = {
						header = {
							order = 0,
							type = "header",
							name = L["Buttons"]
						},
						calendar = {
							order = 1,
							type = "group",
							name = L["Calendar"],
							get = function(info) return E.db.general.minimap.icons.calendar[ info[#info] ] end,
							set = function(info, value) E.db.general.minimap.icons.calendar[ info[#info] ] = value MM:UpdateSettings() end,
							disabled = function() return not E.private.general.minimap.enable end,
							args = {
								calendarHeader = {
									order = 1,
									type = "header",
									name = L["Calendar"]
								},
								hideCalendar = {
									order = 2,
									type = "toggle",
									name = HIDE,
									get = function(info) return E.private.general.minimap.hideCalendar end,
									set = function(info, value) E.private.general.minimap.hideCalendar = value MM:UpdateSettings() end,
									width = "full"
								},
								spacer = {
									order = 3,
									type = "description",
									name = "",
									width = "full"
								},
								position = {
									order = 4,
									type = "select",
									name = L["Position"],
									disabled = function() return E.private.general.minimap.hideCalendar end,
									values = {
										["LEFT"] = L["Left"],
										["RIGHT"] = L["Right"],
										["TOP"] = L["Top"],
										["BOTTOM"] = L["Bottom"],
										["TOPLEFT"] = L["Top Left"],
										["TOPRIGHT"] = L["Top Right"],
										["BOTTOMLEFT"] = L["Bottom Left"],
										["BOTTOMRIGHT"] = L["Bottom Right"]
									}
								},
								scale = {
									order = 5,
									type = "range",
									name = L["Scale"],
									min = 0.5, max = 2, step = 0.05,
									disabled = function() return E.private.general.minimap.hideCalendar end
								},
								xOffset = {
									order = 6,
									type = "range",
									name = L["xOffset"],
									min = -50, max = 50, step = 1,
									disabled = function() return E.private.general.minimap.hideCalendar end
								},
								yOffset = {
									order = 7,
									type = "range",
									name = L["yOffset"],
									min = -50, max = 50, step = 1,
									disabled = function() return E.private.general.minimap.hideCalendar end
								}
							}
						},
						worldMap = {
							order = 2,
							type = "group",
							name = WORLD_MAP,
							get = function(info) return E.db.general.minimap.icons.worldMap[ info[#info] ] end,
							set = function(info, value) E.db.general.minimap.icons.worldMap[ info[#info] ] = value MM:UpdateSettings() end,
							disabled = function() return not E.private.general.minimap.enable end,
							args = {
								worldMapHeader = {
									order = 1,
									type = "header",
									name = WORLD_MAP
								},
								hideWorldMap = {
									order = 2,
									type = "toggle",
									name = HIDE,
									get = function(info) return E.private.general.minimap.hideWorldMap end,
									set = function(info, value) E.private.general.minimap.hideWorldMap = value MM:UpdateSettings() end,
									width = "full"
								},
								position = {
									order = 3,
									type = "select",
									name = L["Position"],
									values = {
										["LEFT"] = L["Left"],
										["RIGHT"] = L["Right"],
										["TOP"] = L["Top"],
										["BOTTOM"] = L["Bottom"],
										["TOPLEFT"] = L["Top Left"],
										["TOPRIGHT"] = L["Top Right"],
										["BOTTOMLEFT"] = L["Bottom Left"],
										["BOTTOMRIGHT"] = L["Bottom Right"]
									}
								},
								scale = {
									order = 4,
									type = "range",
									name = L["Scale"],
									min = 0.5, max = 2, step = 0.05
								},
								xOffset = {
									order = 5,
									type = "range",
									name = L["xOffset"],
									min = -50, max = 50, step = 1
								},
								yOffset = {
									order = 6,
									type = "range",
									name = L["yOffset"],
									min = -50, max = 50, step = 1
								}
							}
						},
						mail = {
							order = 3,
							type = "group",
							name = MAIL_LABEL,
							get = function(info) return E.db.general.minimap.icons.mail[ info[#info] ] end,
							set = function(info, value) E.db.general.minimap.icons.mail[ info[#info] ] = value MM:UpdateSettings() end,
							disabled = function() return not E.private.general.minimap.enable end,
							args = {
								mailHeader = {
									order = 1,
									type = "header",
									name = MAIL_LABEL
								},
								position = {
									order = 2,
									type = "select",
									name = L["Position"],
									values = {
										["LEFT"] = L["Left"],
										["RIGHT"] = L["Right"],
										["TOP"] = L["Top"],
										["BOTTOM"] = L["Bottom"],
										["TOPLEFT"] = L["Top Left"],
										["TOPRIGHT"] = L["Top Right"],
										["BOTTOMLEFT"] = L["Bottom Left"],
										["BOTTOMRIGHT"] = L["Bottom Right"]
									}
								},
								scale = {
									order = 3,
									type = "range",
									name = L["Scale"],
									min = 0.5, max = 2, step = 0.05
								},
								xOffset = {
									order = 4,
									type = "range",
									name = L["xOffset"],
									min = -50, max = 50, step = 1
								},
								yOffset = {
									order = 5,
									type = "range",
									name = L["yOffset"],
									min = -50, max = 50, step = 1
								}
							}
						},
						lfgEye = {
							order = 4,
							type = "group",
							name = L["LFG Queue"],
							get = function(info) return E.db.general.minimap.icons.lfgEye[ info[#info] ] end,
							set = function(info, value) E.db.general.minimap.icons.lfgEye[ info[#info] ] = value MM:UpdateSettings() end,
							disabled = function() return not E.private.general.minimap.enable end,
							args = {
								lfgEyeHeader = {
									order = 1,
									type = "header",
									name = L["LFG Queue"]
								},
								position = {
									order = 2,
									type = "select",
									name = L["Position"],
									values = {
										["LEFT"] = L["Left"],
										["RIGHT"] = L["Right"],
										["TOP"] = L["Top"],
										["BOTTOM"] = L["Bottom"],
										["TOPLEFT"] = L["Top Left"],
										["TOPRIGHT"] = L["Top Right"],
										["BOTTOMLEFT"] = L["Bottom Left"],
										["BOTTOMRIGHT"] = L["Bottom Right"]
									}
								},
								scale = {
									order = 3,
									type = "range",
									name = L["Scale"],
									min = 0.5, max = 2, step = 0.05
								},
								xOffset = {
									order = 4,
									type = "range",
									name = L["xOffset"],
									min = -50, max = 50, step = 1
								},
								yOffset = {
									order = 5,
									type = "range",
									name = L["yOffset"],
									min = -50, max = 50, step = 1
								}
							}
						},
						battlefield = {
							order = 5,
							type = "group",
							name = L["PvP Queue"],
							get = function(info) return E.db.general.minimap.icons.battlefield[ info[#info] ] end,
							set = function(info, value) E.db.general.minimap.icons.battlefield[ info[#info] ] = value MM:UpdateSettings() end,
							disabled = function() return not E.private.general.minimap.enable end,
							args = {
								battlefieldHeader = {
									order = 1,
									type = "header",
									name = L["PvP Queue"]
								},
								position = {
									order = 2,
									type = "select",
									name = L["Position"],
									values = {
										["LEFT"] = L["Left"],
										["RIGHT"] = L["Right"],
										["TOP"] = L["Top"],
										["BOTTOM"] = L["Bottom"],
										["TOPLEFT"] = L["Top Left"],
										["TOPRIGHT"] = L["Top Right"],
										["BOTTOMLEFT"] = L["Bottom Left"],
										["BOTTOMRIGHT"] = L["Bottom Right"]
									}
								},
								scale = {
									order = 3,
									type = "range",
									name = L["Scale"],
									min = 0.5, max = 2, step = 0.05
								},
								xOffset = {
									order = 4,
									type = "range",
									name = L["xOffset"],
									min = -50, max = 50, step = 1
								},
								yOffset = {
									order = 5,
									type = "range",
									name = L["yOffset"],
									min = -50, max = 50, step = 1
								}
							}
						},
						difficulty = {
							order = 6,
							type = "group",
							name = L["Instance Difficulty"],
							get = function(info) return E.db.general.minimap.icons.difficulty[ info[#info] ] end,
							set = function(info, value) E.db.general.minimap.icons.difficulty[ info[#info] ] = value MM:UpdateSettings() end,
							disabled = function() return not E.private.general.minimap.enable end,
							args = {
								difficultyHeader = {
									order = 1,
									type = "header",
									name = L["Instance Difficulty"]
								},
								position = {
									order = 2,
									type = "select",
									name = L["Position"],
									values = {
										["LEFT"] = L["Left"],
										["RIGHT"] = L["Right"],
										["TOP"] = L["Top"],
										["BOTTOM"] = L["Bottom"],
										["TOPLEFT"] = L["Top Left"],
										["TOPRIGHT"] = L["Top Right"],
										["BOTTOMLEFT"] = L["Bottom Left"],
										["BOTTOMRIGHT"] = L["Bottom Right"]
									}
								},
								scale = {
									order = 3,
									type = "range",
									name = L["Scale"],
									min = 0.5, max = 2, step = 0.05
								},
								xOffset = {
									order = 4,
									type = "range",
									name = L["xOffset"],
									min = -50, max = 50, step = 1
								},
								yOffset = {
									order = 5,
									type = "range",
									name = L["yOffset"],
									min = -50, max = 50, step = 1
								}
							}
						},
						vehicleLeave = {
							order = 7,
							type = "group",
							name = LEAVE_VEHICLE,
							get = function(info) return E.db.general.minimap.icons.vehicleLeave[ info[#info] ] end,
							set = function(info, value) E.db.general.minimap.icons.vehicleLeave[ info[#info] ] = value E:GetModule("ActionBars"):UpdateVehicleLeave() end,
							disabled = function() return not E.private.general.minimap.enable end,
							args = {
								vehicleLeaveHeader = {
									order = 1,
									type = "header",
									name = LEAVE_VEHICLE
								},
								hide = {
									order = 2,
									type = "toggle",
									name = HIDE
								},
								spacer = {
									order = 3,
									type = "description",
									name = "",
									width = "full"
								},
								position = {
									order = 4,
									type = "select",
									name = L["Position"],
									values = {
										["LEFT"] = L["Left"],
										["RIGHT"] = L["Right"],
										["TOP"] = L["Top"],
										["BOTTOM"] = L["Bottom"],
										["TOPLEFT"] = L["Top Left"],
										["TOPRIGHT"] = L["Top Right"],
										["BOTTOMLEFT"] = L["Bottom Left"],
										["BOTTOMRIGHT"] = L["Bottom Right"]
									}
								},
								scale = {
									order = 5,
									type = "range",
									name = L["Scale"],
									min = 0.5, max = 2, step = 0.05,
								},
								xOffset = {
									order = 6,
									type = "range",
									name = L["xOffset"],
									min = -50, max = 50, step = 1
								},
								yOffset = {
									order = 7,
									type = "range",
									name = L["yOffset"],
									min = -50, max = 50, step = 1
								}
							}
						},
						ticket = {
							order = 8,
							type = "group",
							name = L["Open Ticket"],
							get = function(info) return E.db.general.minimap.icons.ticket[ info[#info] ] end,
							set = function(info, value) E.db.general.minimap.icons.ticket[ info[#info] ] = value MM:UpdateSettings() end,
							disabled = function() return not E.private.general.minimap.enable end,
							args = {
								ticketHeader = {
									order = 1,
									type = "header",
									name = L["Open Ticket"]
								},
								position = {
									order = 2,
									type = "select",
									name = L["Position"],
									values = {
										["LEFT"] = L["Left"],
										["RIGHT"] = L["Right"],
										["TOP"] = L["Top"],
										["BOTTOM"] = L["Bottom"],
										["TOPLEFT"] = L["Top Left"],
										["TOPRIGHT"] = L["Top Right"],
										["BOTTOMLEFT"] = L["Bottom Left"],
										["BOTTOMRIGHT"] = L["Bottom Right"]
									}
								},
								scale = {
									order = 3,
									type = "range",
									name = L["Scale"],
									min = 0.5, max = 2, step = 0.05
								},
								xOffset = {
									order = 4,
									type = "range",
									name = L["xOffset"],
									min = -50, max = 50, step = 1
								},
								yOffset = {
									order = 5,
									type = "range",
									name = L["yOffset"],
									min = -50, max = 50, step = 1
								}
							}
						},
						zoomIn = {
							order = 9,
							type = "group",
							name = ZOOM_IN,
							get = function(info) return E.db.general.minimap.icons.zoomIn[ info[#info] ] end,
							set = function(info, value) E.db.general.minimap.icons.zoomIn[ info[#info] ] = value MM:UpdateSettings() end,
							disabled = function() return not E.private.general.minimap.enable end,
							args = {
								zoomInHeader = {
									order = 1,
									type = "header",
									name = ZOOM_IN
								},
								hideZoomIn = {
									order = 2,
									type = "toggle",
									name = HIDE,
									get = function(info) return E.private.general.minimap.hideZoomIn end,
									set = function(info, value) E.private.general.minimap.hideZoomIn = value MM:UpdateSettings() end,
									width = "full"
								},
								position = {
									order = 3,
									type = "select",
									name = L["Position"],
									values = {
										["LEFT"] = L["Left"],
										["RIGHT"] = L["Right"],
										["TOP"] = L["Top"],
										["BOTTOM"] = L["Bottom"],
										["TOPLEFT"] = L["Top Left"],
										["TOPRIGHT"] = L["Top Right"],
										["BOTTOMLEFT"] = L["Bottom Left"],
										["BOTTOMRIGHT"] = L["Bottom Right"]
									},
									disabled = function() return E.private.general.minimap.hideZoomIn end
								},
								scale = {
									order = 4,
									type = "range",
									name = L["Scale"],
									min = 0.5, max = 2, step = 0.05,
									disabled = function() return E.private.general.minimap.hideZoomIn end
								},
								xOffset = {
									order = 5,
									type = "range",
									name = L["xOffset"],
									min = -50, max = 50, step = 1,
									disabled = function() return E.private.general.minimap.hideZoomIn end
								},
								yOffset = {
									order = 6,
									type = "range",
									name = L["yOffset"],
									min = -50, max = 50, step = 1,
									disabled = function() return E.private.general.minimap.hideZoomIn end
								}
							}
						},
						zoomOut = {
							order = 10,
							type = "group",
							name = ZOOM_OUT,
							get = function(info) return E.db.general.minimap.icons.zoomOut[ info[#info] ] end,
							set = function(info, value) E.db.general.minimap.icons.zoomOut[ info[#info] ] = value MM:UpdateSettings() end,
							disabled = function() return not E.private.general.minimap.enable end,
							args = {
								zoomOutHeader = {
									order = 1,
									type = "header",
									name = ZOOM_OUT
								},
								hideZoomOut = {
									order = 2,
									type = "toggle",
									name = HIDE,
									get = function(info) return E.private.general.minimap.hideZoomOut end,
									set = function(info, value) E.private.general.minimap.hideZoomOut = value MM:UpdateSettings() end,
									width = "full"
								},
								position = {
									order = 3,
									type = "select",
									name = L["Position"],
									values = {
										["LEFT"] = L["Left"],
										["RIGHT"] = L["Right"],
										["TOP"] = L["Top"],
										["BOTTOM"] = L["Bottom"],
										["TOPLEFT"] = L["Top Left"],
										["TOPRIGHT"] = L["Top Right"],
										["BOTTOMLEFT"] = L["Bottom Left"],
										["BOTTOMRIGHT"] = L["Bottom Right"]
									},
									disabled = function() return E.private.general.minimap.hideZoomOut end
								},
								scale = {
									order = 4,
									type = "range",
									name = L["Scale"],
									min = 0.5, max = 2, step = 0.05,
									disabled = function() return E.private.general.minimap.hideZoomOut end
								},
								xOffset = {
									order = 5,
									type = "range",
									name = L["xOffset"],
									min = -50, max = 50, step = 1,
									disabled = function() return E.private.general.minimap.hideZoomOut end
								},
								yOffset = {
									order = 6,
									type = "range",
									name = L["yOffset"],
									min = -50, max = 50, step = 1,
									disabled = function() return E.private.general.minimap.hideZoomOut end
								}
							}
						}
					}
				}
			}
		}
	}
}