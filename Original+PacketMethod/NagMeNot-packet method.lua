--[[
        Copyright © 2019, Rubenator
        All rights reserved.
        Redistribution and use in source and binary forms, with or without
        modification, are permitted provided that the following conditions are met:
            * Redistributions of source code must retain the above copyright
              notice, this list of conditions and the following disclaimer.
            * Redistributions in binary form must reproduce the above copyright
              notice, this list of conditions and the following disclaimer in the
              documentation and/or other materials provided with the distribution.
            * Neither the name of NagMeNot nor the
              names of its contributors may be used to endorse or promote products
              derived from this software without specific prior written permission.
        THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
        ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
        WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
        DISCLAIMED. IN NO EVENT SHALL Rubenator BE LIABLE FOR ANY
        DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
        (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
        LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
        ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
        (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
        SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
]]

_addon.author = 'Rubenator (ported to Ashita by Almavivaconte)'
_addon.command = 'nagmenot'
_addon.name = 'NagMeNot'
_addon.version = '1.0.1'

require 'common'

local MOG_EXIT_MENU_ID = 30004
local menu_zone;
local menu_id;
local runcount = 0;
local pkt_count = 0;
local sendcount = 0;
local magic_pkt = 0;

do
    -- Precompute hex string tables for lookups, instead of constant computation.
    local top_row = '          |   0  1  2  3  4  5  6  7  8  9  A  B  C  D  E  F      | 0123456789ABCDEF\n    ' .. string.rep('-', (16+1)*3 + 2) .. '  ' .. string.rep('-', 16 + 6) .. '\n'

    local chars = {}
    for i = 0x00, 0xFF do
        if i >= 0x20 and i < 0x7F then
            chars[i] = string.char(i)
        else
            chars[i] = '.'
        end
    end
    chars[0x5C] = '\\\\'
    chars[0x25] = '%%'

    local line_replace = {}
    for i = 0x01, 0x10 do
        line_replace[i] = '    %%%%3X |' .. string.rep(' %.2X', i) .. string.rep(' --', 0x10 - i) .. '  %%%%3X | ' .. '%%s\n'
    end
    local short_replace = {}
    for i = 0x01, 0x10 do
        short_replace[i] = string.rep('%s', i) .. string.rep('-', 0x10 - i)
    end

    -- Receives a byte string and returns a table-formatted string with 16 columns.
    string.hexformat_file = function(str, byte_colors)
        local length = #str
        local str_table = {}
        local from = 1
        local to = 16
        for i = 0, math.floor((length - 1)/0x10) do
            local partial_str = {str:byte(from, to)}
            local char_table = {
                [0x01] = chars[partial_str[0x01]],
                [0x02] = chars[partial_str[0x02]],
                [0x03] = chars[partial_str[0x03]],
                [0x04] = chars[partial_str[0x04]],
                [0x05] = chars[partial_str[0x05]],
                [0x06] = chars[partial_str[0x06]],
                [0x07] = chars[partial_str[0x07]],
                [0x08] = chars[partial_str[0x08]],
                [0x09] = chars[partial_str[0x09]],
                [0x0A] = chars[partial_str[0x0A]],
                [0x0B] = chars[partial_str[0x0B]],
                [0x0C] = chars[partial_str[0x0C]],
                [0x0D] = chars[partial_str[0x0D]],
                [0x0E] = chars[partial_str[0x0E]],
                [0x0F] = chars[partial_str[0x0F]],
                [0x10] = chars[partial_str[0x10]],
            }
            local bytes = math.min(length - from + 1, 16)
            str_table[i + 1] = line_replace[bytes]
                :format(unpack(partial_str))
                :format(short_replace[bytes]:format(unpack(char_table)))
                :format(i, i)
            from = to + 1
            to = to + 0x10
        end
        return string.format('%s%s', top_row, table.concat(str_table))
    end
end

function respond(menu_id, menu_zone)
  option = 1
  target = AshitaCore:GetDataManager():GetParty():GetMemberServerId(0)
  targetindex = AshitaCore:GetDataManager():GetParty():GetMemberTargetIndex(0)
  print("===respond-sent===")
  respond_packet = struct.pack('HbbbbbbHbbHH', target, 0x00, 0x00, option, 0x00, 0x00, 0x00, targetindex, 0x00, 0x00, menu_zone, menu_id)
  AddOutgoingPacket(0x5B, respond_packet:totable())
  print(string.hexformat_file(respond_packet))
end

function respond_printonly(menu_id, menu_zone)
  option = 1
  target = AshitaCore:GetDataManager():GetParty():GetMemberServerId(0)
  targetindex = AshitaCore:GetDataManager():GetParty():GetMemberTargetIndex(0)
    print("===respond-printonly===")
  respond_packet = struct.pack('HbbbbbbHbbHH', target, 0x00, 0x00, option, 0x00, 0x00, 0x00, targetindex, 0x00, 0x00, menu_zone, menu_id)
  --AddOutgoingPacket(0x5B, respond_packet:totable())
  print(string.hexformat_file(respond_packet))
end



---------------------------------------------------------------------------------------------------
-- func: incoming_packet
-- desc: Called when our addon receives an incoming packet.
---------------------------------------------------------------------------------------------------
ashita.register_event('incoming_packet', function(id, size, packet, data, blocked)
  pkt_count = pkt_count + 1;
  if id == 0x00D then
    magic_pkt = struct.unpack('H', packet, 0x03);
  end
  if id == 0x00E then
    runcount = struct.unpack('H', packet, 0x03);
    return false
  end
  if id == 0x00A then --[[Zone Packet]]
    pkt_count = 0;
    runcount = 0;
    sendcount = 0;
    magic_pkt = 0;
    menu_zone = struct.unpack('H', packet, 0x63)
    menu_id = struct.unpack('H', packet, 0x65)
    -- print('50:' .. struct.unpack('H', packet, 0x50))
    -- print('51:' .. struct.unpack('H', packet, 0x51))
    -- print('52:' .. struct.unpack('H', packet, 0x52))
    -- print('53:' .. struct.unpack('H', packet, 0x53))
    -- print('54:' .. struct.unpack('H', packet, 0x54))
    -- print('55:' .. struct.unpack('H', packet, 0x55))
    -- print('56:' .. struct.unpack('H', packet, 0x56))
    -- print('57:' .. struct.unpack('H', packet, 0x57))
    -- print('58:' .. struct.unpack('H', packet, 0x58))
    -- print('59:' .. struct.unpack('H', packet, 0x59))
    -- print('5A:' .. struct.unpack('H', packet, 0x5A))
    -- print('5B:' .. struct.unpack('H', packet, 0x5B))
    -- print('5C:' .. struct.unpack('H', packet, 0x5C))
    -- print('5D:' .. struct.unpack('H', packet, 0x5D))
    -- print('5E:' .. struct.unpack('H', packet, 0x5E))
    -- print('5F:' .. struct.unpack('H', packet, 0x5F))
    -- print('60:' .. struct.unpack('H', packet, 0x60))
    -- print('61:' .. struct.unpack('H', packet, 0x61))
    -- print('62:' .. struct.unpack('H', packet, 0x62))
    -- print('63:' .. struct.unpack('H', packet, 0x63))
    -- print('64:' .. struct.unpack('H', packet, 0x64))
    -- print('65:' .. struct.unpack('H', packet, 0x65))
    -- print('66:' .. struct.unpack('H', packet, 0x66))
    -- print('67:' .. struct.unpack('H', packet, 0x67))
    -- print('68:' .. struct.unpack('H', packet, 0x68))
    -- print('69:' .. struct.unpack('H', packet, 0x69))
    -- print('6A:' .. struct.unpack('H', packet, 0x6A))
    -- print('6B:' .. struct.unpack('H', packet, 0x6B))
    -- print('6C:' .. struct.unpack('H', packet, 0x6C))
    -- print('6D:' .. struct.unpack('H', packet, 0x6D))
    -- print('6E:' .. struct.unpack('H', packet, 0x6E))
    -- print('6F:' .. struct.unpack('H', packet, 0x6F))
    -- print('70:' .. struct.unpack('H', packet, 0x70))
    -- print('71:' .. struct.unpack('H', packet, 0x71))
    -- print('72:' .. struct.unpack('H', packet, 0x72))
    -- print('73:' .. struct.unpack('H', packet, 0x73))
    -- print('74:' .. struct.unpack('H', packet, 0x74))
    -- print('75:' .. struct.unpack('H', packet, 0x75))
    -- print('76:' .. struct.unpack('H', packet, 0x76))
    -- print('77:' .. struct.unpack('H', packet, 0x77))
    -- print('78:' .. struct.unpack('H', packet, 0x78))
    -- print('79:' .. struct.unpack('H', packet, 0x79))
    -- print('7A:' .. struct.unpack('H', packet, 0x7A))
    -- print('7B:' .. struct.unpack('H', packet, 0x7B))
    -- print('7C:' .. struct.unpack('H', packet, 0x7C))
    -- print('7D:' .. struct.unpack('H', packet, 0x7D))
    -- print('7E:' .. struct.unpack('H', packet, 0x7E))
    -- print('7F:' .. struct.unpack('H', packet, 0x7F))
    print("Got zone packet, menu_zone is " .. menu_zone .. ", menu_id is " .. menu_id)
    if menu_id == MOG_EXIT_MENU_ID then
      ashita.timer.once(12, respond, menu_id, menu_zone)
      return false;
    end
  end
  
  
  
  return false;
end);

ashita.register_event('command', function(command, ntype)
    local args = command:args();
    -- Toggle afk status on and off..
    if (args[1] == '/sendpacket') then
        respond(menu_id, menu_zone)
    end
    if (args[1] == '/runcount') then
        print(runcount)
    end
    if (args[1] == '/magicpkt') then
        print(string.format("%x", magic_pkt))
    end
    return false;
end);

ashita.register_event('outgoing_packet', function(id, size, packet, data, blocked)
    -- if id == 0x015 then
        -- runcount = struct.unpack('H', packet, 0x03);
    -- end
    sendcount = sendcount + 1;
    pkt_count = pkt_count + 1;
    if id == 0x05B then
        print("====THIS ONE IS THE ONE FROM THE CLIENT!====")
        print(string.hexformat_file(packet))
        --respond_printonly(menu_id, menu_zone)
        print("====THIS ONE ISN'T!====")
        respond_printonly(menu_id, menu_zone)
    end
    
    return false;
end);
    