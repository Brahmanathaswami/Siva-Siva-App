Script "stack_Siva-Siva-App_card_id_1002"

/*
# Name: card "InitializeApp" of stack "Siva-Siva-App"
# ID: card id 1002 of stack "Siva-Siva-App"
# Behavior: stack "behavior_InitSivaSivaProject"
*/


/*
This is the Siva-Siva-App's project loading card.
The handlers for this card have been moved to the "behavior_InitSivaSivaProject" = this cards behavior.
*/

on mouseup
   if  commandKey() = "down" then
      toplevel "Siva-Siva-Portal"
   end if
end mouseup

on preopencard
   hide button "enable network tracer"
   hide button "Enable Logging"
end preopencard

on opencard
   local tCard
   put the short name of this card into tCard
   switch tCard
      case "InitializeApp"
         if isMobile() then
            hide button "enable network tracer"
            hide button "Enable Logging"
         else
            show button "enable network tracer"
            show button "Enable Logging"
            choose browse tool
         end if
         break
   end switch
   pass opencard
end opencard


