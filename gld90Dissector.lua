-- GDL90 protocol dissector
-- declare our protocol
gdl90_proto = Proto("gdl90","GDL 90")

-- Define descriptions of message IDs
msgIDdescriptions = {}
msgIDdescriptions[0]  = "Heartbeat"
msgIDdescriptions[2]  = "Initialization"
msgIDdescriptions[7]  = "Uplink Data"
msgIDdescriptions[9]  = "Height Above Terain"
msgIDdescriptions[10] = "Ownship Report"
msgIDdescriptions[11] = "Ownship Geometric Altitude"
msgIDdescriptions[20] = "Traffic Report"
msgIDdescriptions[30] = "Basic Report"
msgIDdescriptions[31] = "Long Report"

-- create a function to dissect it
function gdl90_proto.dissector(buffer,pinfo,tree)
  pinfo.cols.protocol = "GDL90"

  local pktlen = buffer:reported_length_remaining()

  local subtree = tree:add(gdl90_proto,buffer(),"GDL 90 Data")
  subtree:add(buffer(0,1),"Flag Byte: " .. buffer(0,1):uint())
  subtree:add(buffer(1,1),"Message ID: " .. buffer(1,1):uint() .. " (" .. msgIDdescriptions[buffer(1,1):uint()] .. ")")

  subtree:add(buffer(pktlen-3,2),"Frame Check Sequence: 0x" .. string.format("%x",buffer(pktlen-3,2):uint()))
  subtree:add(buffer(pktlen-1,1),"Flag Byte: " .. buffer(pktlen-1,1):uint())
end
-- load the udp.port table
udp_table = DissectorTable.get("udp.port")
-- register our protocol to handle udp port 7777
udp_table:add(4000,gdl90_proto)
