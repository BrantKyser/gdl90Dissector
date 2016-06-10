-- GDL90 protocol dissector
-- declare our protocol
gdl90_proto = Proto("gdl90","GDL 90")

local function dissectMessageID(buffer,pinfo,subtree,desc)
  subtree:add(buffer(1,1),"Message ID: " .. buffer(1,1):uint() .. desc)
end

local function bitValue(byteValue,pos)
 return bit32.rshift(bit32.band(bit32.lshift(1,pos),byteValue),pos)
end

local function dissectHeartbeat(buffer,pinfo,subtree)
  dissectMessageID(buffer,pinfo,subtree," (Heartbeat)")

  local statusByte1Tree = subtree:add(gdl90_proto,buffer(2,1),"Status Byte 1")
  local statusByteValue = buffer(2,1):uint()
  statusByte1Tree:add(buffer(2,1),"GPS Pos Valid  : " .. bitValue(statusByteValue,7))
  statusByte1Tree:add(buffer(2,1),"Maint Required : " .. bitValue(statusByteValue,6))
  statusByte1Tree:add(buffer(2,1),"IDENT          : " .. bitValue(statusByteValue,5))
  statusByte1Tree:add(buffer(2,1),"Address Type   : " .. bitValue(statusByteValue,4))
  statusByte1Tree:add(buffer(2,1),"GPS Batt Low   : " .. bitValue(statusByteValue,3))
  statusByte1Tree:add(buffer(2,1),"RATCS          : " .. bitValue(statusByteValue,2))
  statusByte1Tree:add(buffer(2,1),"Reserved       : " .. bitValue(statusByteValue,1))
  statusByte1Tree:add(buffer(2,1),"UAT Initialized: " .. bitValue(statusByteValue,0))

  local statusByte2Tree = subtree:add(gdl90_proto,buffer(3,1),"Status Byte 2")
  local statusByte2Value = buffer(3,1):uint()
  statusByte2Tree:add(buffer(3,1),"Time Stamp MSB   : " .. bitValue(statusByte2Value,7))
  statusByte2Tree:add(buffer(3,1),"CSA Requested    : " .. bitValue(statusByte2Value,6))
  statusByte2Tree:add(buffer(3,1),"CSA Not Available: " .. bitValue(statusByte2Value,5))
  statusByte2Tree:add(buffer(3,1),"Reserved         : " .. bitValue(statusByte2Value,4))
  statusByte2Tree:add(buffer(3,1),"Reserved         : " .. bitValue(statusByte2Value,3))
  statusByte2Tree:add(buffer(3,1),"Reserved         : " .. bitValue(statusByte2Value,2))
  statusByte2Tree:add(buffer(3,1),"Reserved         : " .. bitValue(statusByte2Value,1))
  statusByte2Tree:add(buffer(3,1),"UTC OK           : " .. bitValue(statusByte2Value,0))

  local timeStampValueMSB = bit32.lshift(buffer(3,1):uint(),16)
  local timeStampValue = bit32.bor(timeStampValueMSB,buffer(4,1):uint())
  timeStampValue = bit32.bor(timeStampValue,bit32.lshift(buffer(5,1):uint(),8))

  subtree:add(buffer(3,3),"Time Stamp: " .. timeStampValue .. " Seconds since 0000Z")

  local msgCountsTree = subtree:add(gdl90_proto,buffer(6,2),"Message Counts")
  local uplinkReceptionsValue = bit32.rshift(buffer(6,1):uint(),3)
  local basicAndLongReceptionsValue = bit32.bor(bit32.band(buffer(6,1):uint(),3),buffer(7,1):uint())
  msgCountsTree:add(buffer(6,1),"Uplink Receptions: " .. uplinkReceptionsValue)
  msgCountsTree:add(buffer(6,2),"Basic and Long Receptions: " .. basicAndLongReceptionsValue)
end

local function dissectInitialization(buffer,pinfo,subtree)
  dissectMessageID(buffer,pinfo,subtree," (Initialization)")

  local configByte1Tree = subtree:add(gdl90_proto,buffer(2,1),"Configuration Byte 1")
  local configByteValue = buffer(2,1):uint()
  configByte1Tree:add(buffer(2,1),"Reserved     : " .. bitValue(configByteValue,7))
  configByte1Tree:add(buffer(2,1),"Audio Test   : " .. bitValue(configByteValue,6))
  configByte1Tree:add(buffer(2,1),"Reserved     : " .. bitValue(configByteValue,5))
  configByte1Tree:add(buffer(2,1),"Reserved     : " .. bitValue(configByteValue,4))
  configByte1Tree:add(buffer(2,1),"Reserved     : " .. bitValue(configByteValue,3))
  configByte1Tree:add(buffer(2,1),"Reserved     : " .. bitValue(configByteValue,2))
  configByte1Tree:add(buffer(2,1),"Audio Inhibit: " .. bitValue(configByteValue,1))
  configByte1Tree:add(buffer(2,1),"CDTI OK      : " .. bitValue(configByteValue,0))

  local configByte2Tree = subtree:add(gdl90_proto,buffer(3,1),"Configuration Byte 2")
  local configByte2Value = buffer(3,1):uint()
  configByte2Tree:add(buffer(3,1),"Reserved         : " .. bitValue(configByte2Value,7))
  configByte2Tree:add(buffer(3,1),"Reserved         : " .. bitValue(configByte2Value,6))
  configByte2Tree:add(buffer(3,1),"Reserved         : " .. bitValue(configByte2Value,5))
  configByte2Tree:add(buffer(3,1),"Reserved         : " .. bitValue(configByte2Value,4))
  configByte2Tree:add(buffer(3,1),"Reserved         : " .. bitValue(configByte2Value,3))
  configByte2Tree:add(buffer(3,1),"Reserved         : " .. bitValue(configByte2Value,2))
  configByte2Tree:add(buffer(3,1),"CSA Audio Disable: " .. bitValue(configByte2Value,1))
  configByte2Tree:add(buffer(3,1),"CSA Disable      : " .. bitValue(configByte2Value,0))

end

local function dissectUplinkData(buffer,pinfo,subtree)
  dissectMessageID(buffer,pinfo,subtree," (Uplink Data)")

  subtree:add(buffer(2,3),"Time Of Reception: " .. buffer(2,3):uint())
  subtree:add(buffer(5,8),"UAT Header: " .. buffer(5,8))

  local appDataLen = buffer:reported_length_remaining() - 14
  subtree:add(buffer(11,appDataLen),"Application Data: " .. buffer(11,appDataLen))
end

local function dissectHeightAboveTerrain(buffer,pinfo,subtree)
  dissectMessageID(buffer,pinfo,subtree," (Height Above Terrain)")

  subtree:add(buffer(2,2),"Height Above Terrain: " .. buffer(2,2):int() .. " ft.")
end

local function dissectTrafficReportFields(buffer,pinfo,subtree)
  local trafficAlertStatus = bit32.rshift(buffer(0,1):uint(),4)
  subtree:add(buffer(0,1), "Traffic Alert Status: " .. trafficAlertStatus)

  local addressType = bit32.extract(buffer(0,1):uint(),0,4)
  subtree:add(buffer(0,1), "Address Type: " .. addressType)

  subtree:add(buffer(1,3), "Participant Address: 0x" .. string.format("%x", buffer(1,3):uint()))

  -- TODO Convert to DMS or other
  -- Provided as 24-bit signed binary fraction
  local latitude = buffer(4,3):uint()
  subtree:add(buffer(4,3), "Latitude: " .. latitude)
  local longitude = buffer(7,3):uint()
  subtree:add(buffer(7,3), "Longitude: " .. longitude)

  -- Altitude given in feet ("ddd" * 25) - 1000
  local altitude = bit32.rshift(buffer(10,2):uint(),4)
  altitude = altitude * 25 - 1000
  subtree:add(buffer(10,2), "Altitude: " .. altitude .. " feet")

  local miscIndicatorsTree = subtree:add(gdl90_proto,buffer(11,1),"Miscellaneous Indicators")
  local miscIndicatorsValue = bit32.extract(buffer(11,1):uint(),0,4)
  miscIndicatorsTree:add(buffer(11,1), "Airborne: " .. bitValue(miscIndicatorsValue,3))
  miscIndicatorsTree:add(buffer(11,1), "Report Extrapolated: " .. bitValue(miscIndicatorsValue,2))
  miscIndicatorsTree:add(buffer(11,1), "TT: " .. bit32.extract(miscIndicatorsValue,0,2))

  subtree:add(buffer(12,1), "NIC: " .. bit32.rshift(buffer(12,1):uint(),4))
  subtree:add(buffer(12,1), "NACp: " .. bit32.extract(buffer(12,1):uint(),0,4))

  subtree:add(buffer(13,2), "Horizontal Velocity: " .. bit32.rshift(buffer(13,2):uint(),4) .. " knots")

  -- Vertical velocity signed in units of 64 fpm
  local verticalVelocity = bit32.extract(buffer(14,2):uint(),0,12)
  if (bit32.band(verticalVelocity, 0x800) == 0x800) then
    -- Negative value, convert
    verticalVelocity = -bit32.bxor(verticalVelocity, 0x00000FFF) - 1
  end
  verticalVelocity = verticalVelocity * 64
  subtree:add(buffer(14,2), "Vertical Velocity: " .. verticalVelocity .. " fpm")

  -- Track/Heading 8-bit angular weighted binary, resolution 360/256 degrees
  -- 0=North, 128=South
  local tt = buffer(16,1):uint() * 360 / 256;
  subtree:add(buffer(16,1), "Track/Heading: " .. tt)

  subtree:add(buffer(17,1), "Emitter Category: " .. buffer(17,1):uint())

  subtree:add(buffer(18,8), "Callsign: " .. buffer(18,8):string())

  subtree:add(buffer(26,1), "Emergency/Priority Code: " .. bit32.rshift(buffer(26,1):uint(),4))
  subtree:add(buffer(26,1), "Spare: " .. bit32.extract(buffer(26,1):uint(),0,4))

end

local function dissectOwnshipReport(buffer,pinfo,subtree)
  dissectMessageID(buffer,pinfo,subtree," (Ownship Report)")

  dissectTrafficReportFields(buffer(2,27),pinfo,subtree);
end

local function dissectOwnshipGeometricAltitude(buffer,pinfo,subtree)
  dissectMessageID(buffer,pinfo,subtree," (Ownship Geometric Altitude)")

  subtree:add(buffer(2,2),"Ownship Geometric Altitude: " .. buffer(2,2):int() * 5 .. " ft.")

  local verticalMetricsTree = subtree:add(gdl90_proto,buffer(4,2),"Vertical Metrics")
  verticalMetricsTree:add(buffer(4,1),"Vertical Warning indicator: " .. bitValue(buffer(4,1):uint(),7))

  local verticalFigureOfMerritValue = bit32.band(32767, buffer(4,2):uint())
  verticalMetricsTree:add(buffer(4,2),"Vertical Figure of Merit: " .. verticalFigureOfMerritValue)
end

local function dissectTrafficReport(buffer,pinfo,subtree)
  dissectMessageID(buffer,pinfo,subtree," (Traffic Report)")

  dissectTrafficReportFields(buffer(2,27),pinfo,subtree);
end

local function dissectBasicReport(buffer,pinfo,subtree)
  dissectMessageID(buffer,pinfo,subtree," (Basic Report)")
end

local function dissectLongReport(buffer,pinfo,subtree)
  dissectMessageID(buffer,pinfo,subtree," (Long Report)")
end

local function dissectUavionixStatic(buffer,pinfo,subtree)
  dissectMessageID(buffer,pinfo,subtree," (uAvionix Static Configuration)")

  subtree:add(buffer(2,1), "Signature: " .. buffer(2,1):uint())
  subtree:add(buffer(3,1), "Subtype: " .. buffer(3,1):uint())
  subtree:add(buffer(4,1), "Version: " .. buffer(4,1):uint())

  subtree:add(buffer(5,3), "ICAO Address: 0x" .. string.format("%x", buffer(5,3):uint()))

  subtree:add(buffer(8,1), "Emitter Category: " .. buffer(8,1):uint())

  subtree:add(buffer(9,8), "Callsign: " .. buffer(9,8):string())

  subtree:add(buffer(17,1), "Vs0: " .. buffer(17,1):uint())

  local lenWidth = bit32.extract(buffer(18,1):uint(),0,4)
  subtree:add(buffer(18,1), "Vehicle Length/Width: " .. lenWidth .. "(0x" .. string.format("%x", lenWidth) .. ")")

  local antOffsetLat = bit32.rshift(buffer(19,1):uint(),5)
  subtree:add(buffer(19,1), "Antenna Offset Lat: " .. antOffsetLat .. "(0x" .. string.format("%x", antOffsetLat) .. ")")
  local antOffsetLon = bit32.extract(buffer(19,1):uint(),0,5)
  subtree:add(buffer(19,1), "Antenna Offset Lon: " .. antOffsetLon .. "(0x" .. string.format("%x", antOffsetLon) .. ")")
end

local function dissectUnknown(buffer,pinfo,subtree)
  dissectMessageID(buffer,pinfo,subtree," (Unknown 0x" .. string.format("%x", buffer(1,1):uint()) .. ")")
end

-- Map Message ID values to methods to dissect particular type of message
msgDissectFunctions = {}
msgDissectFunctions[0]  = dissectHeartbeat
msgDissectFunctions[2]  = dissectInitialization
msgDissectFunctions[7]  = dissectUplinkData
msgDissectFunctions[9]  = dissectHeightAboveTerrain
msgDissectFunctions[10] = dissectOwnshipReport
msgDissectFunctions[11] = dissectOwnshipGeometricAltitude
msgDissectFunctions[20] = dissectTrafficReport
msgDissectFunctions[30] = dissectBasicReport
msgDissectFunctions[117] = dissectUavionixStatic

-- create a function to dissect it
function gdl90_proto.dissector(buffer,pinfo,tree)
  pinfo.cols.protocol = "GDL90"

  local pktlen = buffer:reported_length_remaining()

  local subtree = tree:add(gdl90_proto,buffer(),"GDL 90 Data")
  subtree:add(buffer(0,1),"Flag Byte: " .. buffer(0,1):uint())
  
  if (msgDissectFunctions[buffer(1,1):uint()] == nil) then
    dissectUnknown(buffer,pinfo,subtree)
  else
    msgDissectFunctions[buffer(1,1):uint()](buffer,pinfo,subtree)
  end


  subtree:add(buffer(pktlen-3,2),"Frame Check Sequence: 0x" .. string.format("%x",buffer(pktlen-3,2):uint()))
  subtree:add(buffer(pktlen-1,1),"Flag Byte: " .. buffer(pktlen-1,1):uint())
end
-- load the udp.port table
udp_table = DissectorTable.get("udp.port")
-- register our protocol to handle udp port 7777
udp_table:add(4000,gdl90_proto)
