-- GDL90 protocol dissector
-- declare our protocol
gdl90_proto = Proto("gdl90","GDL 90")

local function dissectMessageID(buffer,pinfo,subtree,desc)
  subtree:add(buffer(1,1),"Message ID: " .. buffer(1,1):uint() .. " (" .. desc .. ")")
  pinfo.cols.info = desc
end

local function bitValue(byteValue,pos)
 return bit.rshift(bit.band(bit.lshift(1,pos),byteValue),pos)
end

local function dissectHeartbeat(buffer,pinfo,subtree)
  dissectMessageID(buffer,pinfo,subtree,"Heartbeat")

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

  local timeStampValueMSB = bit.lshift(buffer(3,1):uint(),16)
  local timeStampValue = bit.bor(timeStampValueMSB,buffer(4,1):uint())
  timeStampValue = bit.bor(timeStampValue,bit.lshift(buffer(5,1):uint(),8))

  subtree:add(buffer(3,3),"Time Stamp: " .. timeStampValue .. " Seconds since 0000Z")

  local msgCountsTree = subtree:add(gdl90_proto,buffer(6,2),"Message Counts")
  local uplinkReceptionsValue = bit.rshift(buffer(6,1):uint(),3)
  local basicAndLongReceptionsValue = bit.bor(bit.band(buffer(6,1):uint(),3),buffer(7,1):uint())
  msgCountsTree:add(buffer(6,1),"Uplink Receptions: " .. uplinkReceptionsValue)
  msgCountsTree:add(buffer(6,2),"Basic and Long Receptions: " .. basicAndLongReceptionsValue)
end

local function dissectInitialization(buffer,pinfo,subtree)
  dissectMessageID(buffer,pinfo,subtree,"Initialization")

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
  dissectMessageID(buffer,pinfo,subtree,"Uplink Data")

  subtree:add(buffer(2,3),"Time Of Reception: " .. buffer(2,3):uint())
  subtree:add(buffer(5,8),"UAT Header: " .. buffer(5,8))

  local appDataLen = buffer:reported_length_remaining() - 14
  subtree:add(buffer(11,appDataLen),"Application Data: " .. buffer(11,appDataLen))
end

local function dissectHeightAboveTerrain(buffer,pinfo,subtree)
  dissectMessageID(buffer,pinfo,subtree,"Height Above Terrain")

  subtree:add(buffer(2,2),"Height Above Terrain: " .. buffer(2,2):int() .. " ft.")
end

-- Convert to degrees
-- Provided as 24-bit signed binary fraction
-- Encoded as a "semicircle" 2s complement
-- North and East are positive, +-180
-- No valid position is lat=lon=NIC=0
-- TODO Validate proper decode
local function decodeLatLon(value)
  local deg = value
  if (bit.band(value, 0x800000) == 0x800000) then
    -- Negative value
    deg = bit.band(value, 0x000007FFFFF)-0x800000
  end
  deg = deg * 180 / 0x800000
  return deg
end

local function dissectTrafficReportFields(buffer,pinfo,subtree)
  local trafficAlertStatus = bit.rshift(buffer(0,1):uint(),4)
  subtree:add(buffer(0,1), "Traffic Alert Status: " .. trafficAlertStatus)

  local addressType = bit.extract(buffer(0,1):uint(),0,4)
  subtree:add(buffer(0,1), "Address Type: " .. addressType)

  subtree:add(buffer(1,3), "Participant Address (hex): " .. buffer(1,3):bytes():tohex())

  local latitude = buffer(4,3):uint()
  latitude = decodeLatLon(latitude)
  subtree:add(buffer(4,3), "Latitude: " .. latitude)
  local longitude = buffer(7,3):uint()
  longitude = decodeLatLon(longitude)
  subtree:add(buffer(7,3), "Longitude: " .. longitude)

  -- Altitude given in feet ("ddd" * 25) - 1000
  local altitude = bit.rshift(buffer(10,2):uint(),4)
  altitude = altitude * 25 - 1000
  subtree:add(buffer(10,2), "Altitude: " .. altitude .. " feet")

  local miscIndicatorsTree = subtree:add(gdl90_proto,buffer(11,1),"Miscellaneous Indicators")
  local miscIndicatorsValue = bit.extract(buffer(11,1):uint(),0,4)
  miscIndicatorsTree:add(buffer(11,1), "Airborne: " .. bitValue(miscIndicatorsValue,3))
  miscIndicatorsTree:add(buffer(11,1), "Report Extrapolated: " .. bitValue(miscIndicatorsValue,2))
  miscIndicatorsTree:add(buffer(11,1), "TT: " .. bit.extract(miscIndicatorsValue,0,2))

  subtree:add(buffer(12,1), "NIC: " .. bit.rshift(buffer(12,1):uint(),4))
  subtree:add(buffer(12,1), "NACp: " .. bit.extract(buffer(12,1):uint(),0,4))

  subtree:add(buffer(13,2), "Horizontal Velocity: " .. bit.rshift(buffer(13,2):uint(),4) .. " knots")

  -- Vertical velocity signed in units of 64 fpm
  -- 0x000 is 0
  -- 0x001 is +64
  -- 0xFFF is -64
  local verticalVelocity = bit.extract(buffer(14,2):uint(),0,12)
  if (bit.band(verticalVelocity, 0x800) == 0x800) then
    -- Negative value, convert
    verticalVelocity = bit.band(verticalVelocity, 0x000007FF)-0x800
  end
  verticalVelocity = verticalVelocity * 64
  subtree:add(buffer(14,2), "Vertical Velocity: " .. verticalVelocity .. " fpm")

  -- Track/Heading 8-bit angular weighted binary, resolution 360/256 degrees
  -- 0=North, 128=South
  local tt = buffer(16,1):uint() * 360 / 256;
  subtree:add(buffer(16,1), "Track/Heading: " .. tt)

  subtree:add(buffer(17,1), "Emitter Category: " .. buffer(17,1):uint())

  subtree:add(buffer(18,8), "Callsign: " .. buffer(18,8):string())

  subtree:add(buffer(26,1), "Emergency/Priority Code: " .. bit.rshift(buffer(26,1):uint(),4))
  subtree:add(buffer(26,1), "Spare: " .. bit.extract(buffer(26,1):uint(),0,4))

end

local function dissectOwnshipReport(buffer,pinfo,subtree)
  dissectMessageID(buffer,pinfo,subtree,"Ownship Report")

  dissectTrafficReportFields(buffer(2,27),pinfo,subtree);
end

local function dissectOwnshipGeometricAltitude(buffer,pinfo,subtree)
  dissectMessageID(buffer,pinfo,subtree,"Ownship Geometric Altitude")

  subtree:add(buffer(2,2),"Ownship Geometric Altitude: " .. buffer(2,2):int() * 5 .. " ft.")

  local verticalMetricsTree = subtree:add(gdl90_proto,buffer(4,2),"Vertical Metrics")
  verticalMetricsTree:add(buffer(4,1),"Vertical Warning indicator: " .. bitValue(buffer(4,1):uint(),7))

  local verticalFigureOfMerritValue = bit.band(32767, buffer(4,2):uint())
  verticalMetricsTree:add(buffer(4,2),"Vertical Figure of Merit: " .. verticalFigureOfMerritValue)
end

local function dissectTrafficReport(buffer,pinfo,subtree)
  dissectMessageID(buffer,pinfo,subtree,"Traffic Report")

  dissectTrafficReportFields(buffer(2,27),pinfo,subtree);
end

local function dissectBasicReport(buffer,pinfo,subtree)
  dissectMessageID(buffer,pinfo,subtree,"Basic Report")
end

local function dissectLongReport(buffer,pinfo,subtree)
  dissectMessageID(buffer,pinfo,subtree,"Long Report")
end

local function dissectUavionixStatic(buffer,pinfo,subtree)
  dissectMessageID(buffer,pinfo,subtree,"uAvionix Static Configuration")

  subtree:add(buffer(2,1), "Signature: " .. buffer(2,1):uint())
  local subtype = buffer(3,1):uint()
  subtree:add(buffer(3,1), "Subtype: " .. subtype)
  subtree:add(buffer(4,1), "Version: " .. buffer(4,1):uint())

  if (subtype == 1) then
    -- Static packet

    subtree:add(buffer(5,3), "ICAO Address (hex): " .. buffer(5,3):bytes():tohex())
    subtree:add(buffer(8,1), "Emitter Category: " .. buffer(8,1):uint())
    subtree:add(buffer(9,8), "Callsign: " .. buffer(9,8):string())
    subtree:add(buffer(17,1), "Vs0: " .. buffer(17,1):uint())

    local lenWidth = bit.extract(buffer(18,1):uint(),0,4)
    subtree:add(buffer(18,1), "Vehicle Length/Width: " .. lenWidth .. " (0x" .. string.format("%x", lenWidth) .. ")")

    local antOffsetLat = bit.rshift(buffer(19,1):uint(),5)
    subtree:add(buffer(19,1), "Antenna Offset Lat: " .. antOffsetLat .. " (0x" .. string.format("%x", antOffsetLat) .. ")")
    local antOffsetLon = bit.extract(buffer(19,1):uint(),0,5)
    subtree:add(buffer(19,1), "Antenna Offset Lon: " .. antOffsetLon .. " (0x" .. string.format("%x", antOffsetLon) .. ")")
  elseif (subtype == 2) then
    -- Setup packet
    local sil = buffer(5,1):uint()
    local sda = buffer(6,1):uint()
    local threshold = bit.bxor(bit.lshift(buffer(8,1):uint(), 8), buffer(7,1):uint())
    if (sil == 0xFF) then
      subtree:add(buffer(5,1), "SIL: Not Provided (0xff)")
    else
      subtree:add(buffer(5,1), "SIL: " .. sil)
    end
    if (sda == 0xFF) then
      subtree:add(buffer(6,1), "SDA: Not Provided (0xff)")
    else
      subtree:add(buffer(6,1), "SDA: " .. sda)
    end
    if (threshold == 0xFFFF) then
      subtree:add(buffer(7,2), "Sniffer Threshold: Not Provided (0xffff)")
    else
      subtree:add(buffer(7,2), "Sniffer Threshold: " .. threshold)
    end
  end
end

local function dissectUnknown(buffer,pinfo,subtree)
  dissectMessageID(buffer,pinfo,subtree,"Unknown 0x" .. string.format("%x", buffer(1,1):uint()))
end

local crcTable = {0x0000, 0x1021, 0x2042, 0x3063, 0x4084, 0x50a5,
              0x60c6, 0x70e7, 0x8108, 0x9129, 0xa14a, 0xb16b,
              0xc18c, 0xd1ad, 0xe1ce, 0xf1ef, 0x1231, 0x0210,
              0x3273, 0x2252, 0x52b5, 0x4294, 0x72f7, 0x62d6,
              0x9339, 0x8318, 0xb37b, 0xa35a, 0xd3bd, 0xc39c,
              0xf3ff, 0xe3de, 0x2462, 0x3443, 0x0420, 0x1401,
              0x64e6, 0x74c7, 0x44a4, 0x5485, 0xa56a, 0xb54b,
              0x8528, 0x9509, 0xe5ee, 0xf5cf, 0xc5ac, 0xd58d,
              0x3653, 0x2672, 0x1611, 0x0630, 0x76d7, 0x66f6,
              0x5695, 0x46b4, 0xb75b, 0xa77a, 0x9719, 0x8738,
              0xf7df, 0xe7fe, 0xd79d, 0xc7bc, 0x48c4, 0x58e5,
              0x6886, 0x78a7, 0x0840, 0x1861, 0x2802, 0x3823,
              0xc9cc, 0xd9ed, 0xe98e, 0xf9af, 0x8948, 0x9969,
              0xa90a, 0xb92b, 0x5af5, 0x4ad4, 0x7ab7, 0x6a96,
              0x1a71, 0x0a50, 0x3a33, 0x2a12, 0xdbfd, 0xcbdc,
              0xfbbf, 0xeb9e, 0x9b79, 0x8b58, 0xbb3b, 0xab1a,
              0x6ca6, 0x7c87, 0x4ce4, 0x5cc5, 0x2c22, 0x3c03,
              0x0c60, 0x1c41, 0xedae, 0xfd8f, 0xcdec, 0xddcd,
              0xad2a, 0xbd0b, 0x8d68, 0x9d49, 0x7e97, 0x6eb6,
              0x5ed5, 0x4ef4, 0x3e13, 0x2e32, 0x1e51, 0x0e70,
              0xff9f, 0xefbe, 0xdfdd, 0xcffc, 0xbf1b, 0xaf3a,
              0x9f59, 0x8f78, 0x9188, 0x81a9, 0xb1ca, 0xa1eb,
              0xd10c, 0xc12d, 0xf14e, 0xe16f, 0x1080, 0x00a1,
              0x30c2, 0x20e3, 0x5004, 0x4025, 0x7046, 0x6067,
              0x83b9, 0x9398, 0xa3fb, 0xb3da, 0xc33d, 0xd31c,
              0xe37f, 0xf35e, 0x02b1, 0x1290, 0x22f3, 0x32d2,
              0x4235, 0x5214, 0x6277, 0x7256, 0xb5ea, 0xa5cb,
              0x95a8, 0x8589, 0xf56e, 0xe54f, 0xd52c, 0xc50d,
              0x34e2, 0x24c3, 0x14a0, 0x0481, 0x7466, 0x6447,
              0x5424, 0x4405, 0xa7db, 0xb7fa, 0x8799, 0x97b8,
              0xe75f, 0xf77e, 0xc71d, 0xd73c, 0x26d3, 0x36f2,
              0x0691, 0x16b0, 0x6657, 0x7676, 0x4615, 0x5634,
              0xd94c, 0xc96d, 0xf90e, 0xe92f, 0x99c8, 0x89e9,
              0xb98a, 0xa9ab, 0x5844, 0x4865, 0x7806, 0x6827,
              0x18c0, 0x08e1, 0x3882, 0x28a3, 0xcb7d, 0xdb5c,
              0xeb3f, 0xfb1e, 0x8bf9, 0x9bd8, 0xabbb, 0xbb9a,
              0x4a75, 0x5a54, 0x6a37, 0x7a16, 0x0af1, 0x1ad0,
              0x2ab3, 0x3a92, 0xfd2e, 0xed0f, 0xdd6c, 0xcd4d,
              0xbdaa, 0xad8b, 0x9de8, 0x8dc9, 0x7c26, 0x6c07,
              0x5c64, 0x4c45, 0x3ca2, 0x2c83, 0x1ce0, 0x0cc1,
              0xef1f, 0xff3e, 0xcf5d, 0xdf7c, 0xaf9b, 0xbfba,
              0x8fd9, 0x9ff8, 0x6e17, 0x7e36, 0x4e55, 0x5e74,
              0x2e93, 0x3eb2, 0x0ed1, 0x1ef0}

-- Calculate CRC16
local function calculateCrc16(buffer)
  local pktlen = buffer:reported_length_remaining()
  local crc = 0x0000;
  local crcTemp1, crcTemp2, crcTemp3
  -- Don't calculate CRC over flag bytes or CRC
  for i=1,pktlen-4 do
    crcTemp1 = crcTable[bit.band(bit.rshift(crc, 8),0xFF)+1]
    crcTemp2 = bit.lshift(bit.band(crc,0xFF), 8)
    crcTemp3 = buffer(i,1):uint()
    crc = bit.bxor(crcTemp1, crcTemp2, crcTemp3)
  end
  return crc;
end

local function swap16(value)
  return bit.band(bit.rshift(value, 8) + bit.lshift(value,8), 0xFFFF)
end

-- Return true if valid
local function validateFcs(buffer,pinfo,subtree)
  local pktlen = buffer:reported_length_remaining()
  local crcCalculated = calculateCrc16(buffer)
  local crcReceived = swap16(buffer(pktlen-3,2):uint())
  if crcCalculated == crcReceived then
    subtree:add(buffer(pktlen-3,2),"Frame Check Sequence: 0x" .. string.format("%x",crcReceived))
    return true
  else
    local fcs = subtree:add(buffer(pktlen-3,2),"Frame Check Sequence: INVALID " .. string.format("recv=0x%x,calc=0x%x",crcReceived,crcCalculated))
    fcs:add_expert_info(PI_CHECKSUM, PI_ERROR, "Invalid FCS")
    subtree:add_expert_info(PI_CHECKSUM, PI_ERROR, "Invalid FCS")
    return false
  end
end

-- TODO optimize by running through buffer instead of moving
-- a byte at a time
local function unBytestuff(buffer)
  local pktlen = buffer:reported_length_remaining()
  local baOutput = ByteArray.new()
  local outputIndex = 0
  local flagged = false
  for i=0,pktlen-1 do
    if buffer(i,1):uint() == 0x7D then
      flagged = true
    else
      if flagged then
        -- TODO UNSTUFF
        local dataByte = bit.bxor(buffer(i,1):uint(),0x20)
        baOutput:append(ByteArray.new(string.format("%x",dataByte)))
      else
        baOutput:append(buffer(i,1):bytes())
      end
      flagged = false
    end
  end
  return ByteArray.tvb(baOutput, "Unstuffed GDL90")
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

  local decodedBuffer = unBytestuff(buffer)
  local decodedLen = decodedBuffer:reported_length_remaining()

  local pktlen = buffer:reported_length_remaining()

  local subtree = tree:add(gdl90_proto,decodedBuffer(),"GDL 90 Data")
  subtree:add(buffer(0,pktlen),"Stuffed Len: " .. pktlen)
  subtree:add(decodedBuffer(0,decodedLen),"Unstuffed Len: " .. decodedLen)
  subtree:add(decodedBuffer(0,1),string.format("Flag Byte: 0x%02x", decodedBuffer(0,1):uint()))
  
  if (msgDissectFunctions[decodedBuffer(1,1):uint()] == nil) then
    dissectUnknown(decodedBuffer,pinfo,subtree)
  else
    msgDissectFunctions[decodedBuffer(1,1):uint()](decodedBuffer,pinfo,subtree)
  end

  local validFcs = validateFcs(decodedBuffer,pinfo,subtree)
  subtree:add(decodedBuffer(decodedLen-1,1),string.format("Flag Byte: 0x%02x", decodedBuffer(decodedLen-1,1):uint()))

  if pktlen ~= decodedLen then
    pinfo.cols.info = tostring(pinfo.cols.info) .. ", Stuffed"
  end
  if validFcs == false then
    pinfo.cols.info = tostring(pinfo.cols.info) .. ", Invalid FCS"
  end
  pinfo.cols.info = tostring(pinfo.cols.info) .. ", Len=" .. pktlen
end
-- load the udp.port table
udp_table = DissectorTable.get("udp.port")
-- register our protocol to handle udp port 4000
udp_table:add(4000,gdl90_proto)
