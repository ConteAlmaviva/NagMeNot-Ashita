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
local nmn_on = true
local in_menu = false;
local ranonce = false;

nag_message = "For your own safety, it is recommended you set the Mog House exit as your home point after changing jobs."

---------------------------------------------------------------------------------------------------
-- func: incoming_packet
-- desc: Called when our addon receives an incoming packet.
---------------------------------------------------------------------------------------------------
ashita.register_event('command', function(command, ntype)
    local args = command:args();
    if (args[1] == '/nmn') then
        if(args[2] == 'off') then
            print("\30\201[\30\82NagMeNot\30\201]\31\255 NagMeNot disabled; you will receive prompts to set your home point after changing jobs in your Mog House and zoning out.")
            nmn_on = false;
        elseif(args[2] == 'on') then
            print("\30\201[\30\82NagMeNot\30\201]\31\255 NagMeNot enabled; you will automatically select no on the home point prompt.")
            nmn_on = true;
        else
            print("\30\201[\30\82NagMeNot\30\201]\31\255 Usage: /nmn off to disable, /nmn on to enable. Enabled by default/on addon load.")
        end
    end
    return false;
end);

ashita.register_event('outgoing_packet', function(id, size, packet, data, blocked)
    
    if id == 0x05B then
        ranonce = false;
    end
    
    return false;
end);

ashita.register_event('incoming_text', function(mode, message)
    if(message:contains(nag_message)) and not ranonce and nmn_on then
        AshitaCore:GetChatManager():QueueCommand("/exec nagmenot", 1);
        ranonce = true;
    end
    return false;
end);
    