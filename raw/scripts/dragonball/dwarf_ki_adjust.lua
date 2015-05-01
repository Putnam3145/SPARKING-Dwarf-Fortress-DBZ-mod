local ki = dfhack.script_environment('dragonball/ki')

local guidm=require('gui.dwarfmode')

local widgets=require('gui.widgets')

local kiViewScreen=defclass(kiViewScreen,guidm.MenuOverlay)

function kiViewScreen:onInput(keys)
    if keys.LEAVESCREEN then
        self:dismiss()
    else
        self:inputToSubviews(keys)
    end
end

function kiViewScreen:init(args)
    local kiText='Ki investment (higher is less, 1 is all at once):'
    self.kiInvestText='Ki investment currently set to '
    local adventureID=dfhack.gui.getSelectedUnit().id
    self.kiInvestment=tostring(ki.get_ki_investment(adventureID))
    self.investmentLabel=widgets.Label{
        frame={t=1},
        text=self.kiInvestText..self.kiInvestment
    }
    self:addviews{
        widgets.Label{
            frame={t=0},
            text=kiText
        },
        widgets.EditField{
            frame={t=0,l=#kiText+1},
            text=tostring(ki.get_unit_ki_persist_entry(adventureID).ints[3]),
            on_submit=function(text)
                if tonumber(text) and tonumber(text)>=1 then
                    ki.set_ki_investment(adventureID,tonumber(text))
                    self.kiInvestment=tostring(ki.get_ki_investment(adventureID))
                    self.investmentLabel:setText(self.kiInvestText..self.kiInvestment)
                end
            end
        },
        self.investmentLabel,
        widgets.Label{
            frame={t=2},
            text='Current ki amount: ' .. ki.get_ki(adventureID)..'/'..ki.get_max_ki(adventureID)..' ('..100*ki.get_ki(adventureID)/ki.get_max_ki(adventureID)..'%)'
        }
    }
end

local kiScreen=kiViewScreen{frame_title='Ki settings',frame_width=80,frame_height=3}

kiScreen:show()