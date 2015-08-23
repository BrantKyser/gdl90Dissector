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

  local timeStampValueMSB = bit32.lshift(buffer(3,1):uint(),9)
  local timeStampValue = bit32.bor(timeStampValueMSB,buffer(4,2):uint())

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
end

local function dissectHeightAboveTerrain(buffer,pinfo,subtree)
  dissectMessageID(buffer,pinfo,subtree," (Height Above Terrain)")

  subtree:add(buffer(2,2),"Height Above Terrain: " .. buffer(2,2):int() .. " ft.")
end

local function dissectOwnshipReport(buffer,pinfo,subtree)
  dissectMessageID(buffer,pinfo,subtree," (Ownship Report)")
end

local function dissectOwnshipGeometricAltitude(buffer,pinfo,subtree)
  dissectMessageID(buffer,pinfo,subtree," (Ownship Geometric Altitude)")
end

local function dissectTrafficReport(buffer,pinfo,subtree)
  dissectMessageID(buffer,pinfo,subtree," (Traffic Report)")
end

local function dissectBasicReport(buffer,pinfo,subtree)
  dissectMessageID(buffer,pinfo,subtree," (Basic Report)")
end

local function dissectLongReport(buffer,pinfo,subtree)
  dissectMessageID(buffer,pinfo,subtree," (Long Report)")
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
msgDissectFunctions[31] = dissectLongReport

-- create a function to dissect it
function gdl90_proto.dissector(buffer,pinfo,tree)
  pinfo.cols.protocol = "GDL90"

  local pktlen = buffer:reported_length_remaining()

  local subtree = tree:add(gdl90_proto,buffer(),"GDL 90 Data")
  subtree:add(buffer(0,1),"Flag Byte: " .. buffer(0,1):uint())
  
  msgDissectFunctions[buffer(1,1):uint()](buffer,pinfo,subtree)

  subtree:add(buffer(pktlen-3,2),"Frame Check Sequence: 0x" .. string.format("%x",buffer(pktlen-3,2):uint()))
  subtree:add(buffer(pktlen-1,1),"Flag Byte: " .. buffer(pktlen-1,1):uint())
end
-- load the udp.port table
udp_table = DissectorTable.get("udp.port")
-- register our protocol to handle udp port 7777
udp_table:add(4000,gdl90_proto)
