playergroups = {};

minetest.register_chatcommand("pgroups", {
	params = "<params>",
	description = "Handle groups of players. Type /pgroups help for help. ",
	privs = {},
	func = function(name, param)

           if( not( param ) or param=="" or param=="help") then
              minetest.chat_send_player(name,
                 "/pgroups list                  lists all groups you have defined\n"..
                 "/pgroups create <group>        creates a new empty group <group> for you\n"..
                 "/pgroups remove <group>        removes (deletes) your group <group>\n"..
                 "/pgroups add <player> <group>  adds <player> to your group <group>\n"..
                 "/pgroups del <player> <group>  deletes <player> from your group <group>\n"..
                 "/pgroups show <group>          shows all members of your group <group>");
              return;
           end

           local params = param:split( " " );
           if(    #params < 1
               or ( params[1]=="create" and #params<2 )
               or ( params[1]=="remove" and #params<2 )
               or ( params[1]=="add"    and #params<3 )
               or ( params[1]=="del"    and #params<3 )
               or ( params[1]=="show"   and #params<2 )) then
              minetest.chat_send_player(name, "Missing parameters to /pgroups. Type /pgroups help for help.");
           end

           if( params[1]=="list") then
              playergroups:list_groups( name );
              return;
           end

           -- sanitize player input; names of groups may not contain : or ,
           if( params[2] and params[2]:match("[^%a%d%s_- ]")) then


              minetest.chat_send_player(name, "Input contains unsupported characters. Allowed: a-z, A-Z, 0-9, _, -.");
              return;
           end
    

           if( params[1]=="create") then 
              playergroups:create_group( name, params[2] );
              return;
           end

           if( params[1]=="remove") then 
              playergroups:remove_group( name, params[2]);
              return;
           end
 
           if( params[1]=="add") then 
              playergroups:add_group_member( name, params[3], params[2]);
              return;
           end

           if( params[1]=="del") then 
              playergroups:del_group_member( name, params[3], params[2]);
              return;
           end

           if( params[1]=="show") then 
              playergroups:list_group_members( name, params[2] );
              return;
           end

           minetest.chat_send_player(name, "pgroup: unknown command/parameter");
        end
        });


-- returns true if a player with the given name exists
-- group_owner is the player who gets the error message if the player doesn't exist
-- internal function
function playergroups:player_exists( group_owner, name )
   local privs = minetest.get_player_privs( name );

   if( not( privs ) or not( privs.interact )) then
      minetest.chat_send_player(group_owner, "Player \""..name.."\" not found or has no interact privs.");
      return false;
   end

   return true;
end


-- returns true if player group_owner has a group named group_name defined that includes candidat as a member
-- all parameters have to be passed as string
function playergroups:is_group_member( group_owner, group_name, candidat )

   -- wrong/missing parameters? then it's not a group member
   if( not( group_owner ) or group_owner == "" 
    or not( group_name  ) or group_name  == "" 
    or not( candidat    ) or candidat    == "" ) then
      return false;
   end
  
   local groups = playergroups:read_group_file( group_owner );
   if( not( groups ) or not( groups[ group_name ]) or groups[ group_name ]=="" ) then
      return false;
   end
  
   local liste = groups[ group_name ]:split(",");
   for i,n in ipairs( liste ) do
      if( n == candidat ) then
         return true;
      end
   end
   return false;
end

  
-- does the group exist?
function playergroups:is_playergroup( group_owner, group_name )

   local groups = playergroups:read_group_file( group_owner );

   if( not( groups ) or not( groups[ group_name ])) then
      return false;
   end
   return true;
end





-- helper function
function playergroups:extract_group_members( memberlist )

   if( not( memberlist ) or memberlist=="") then
      return "- none; empty group -";
   end

   local liste = memberlist:split(",");
   return table.concat( liste, ", " );
end


-- needed because lua can't do much on its own...it simply crashes if a file does not exist
function playergroups:read_group_file( group_owner )
 
   local lines = {};
   local line;
   local groups = {};
 

   if( not( group_owner ) or group_owner=="" ) then
      return groups;
   end

   -- each player who has groups defined has them stored in the groups folder with the playername as filename
   local file_name = minetest.get_modpath( "playergroups" ).."/groups/"..group_owner;

   -- can we read the file?
   local file = io.open( file_name, "r" );
   if( not( file )) then
      return groups;
   end

   line = file:read();
   while( line ) do

      help = line:split( ":" );
      if( #help >0 and help[1]~="" ) then
         if( #help>1 ) then
            -- don't bother to split it up into names yet - lua doesn't have member functions which could make use of it...
            groups[ help[1] ] = help[2];
         else
            groups[ help[1] ] = "";
         end
      end
      line = file:read();
   end

   file:close();
   return groups; 
end




-- list the members of a group
function playergroups:list_group_members( group_owner, group_name )

   local groups = playergroups:read_group_file( group_owner );

   if( not( groups ) or not( groups[ group_name ])) then
      minetest.chat_send_player(group_owner, "You do not have a group named \""..group_name.."\".");
      return;
   end

   local liste = groups[ group_name ]:split( "," );
   if( #liste < 1) then
      minetest.chat_send_player(group_owner, "Your group \""..group_name.."\" is empty.");
      return;
   end

   minetest.chat_send_player(group_owner, "Members of your group "..group_name..": "..( table.concat( liste, ", " ))..".");
end



function playergroups:list_groups( group_owner )

   local groups = playergroups:read_group_file( group_owner );
   
   local list = {};

   -- each line is constructed this way: group_name:member1,member2,member3,member4,...
   for g, m in pairs( groups ) do
      -- we're only intrested in the names of the groups
      if( g and g ~= "" ) then
         table.insert( list, g );
      end
   end

   if( not( list ) or #list<1 ) then
      minetest.chat_send_player(group_owner, "You do not have any groups defined.");
      return;
   end

   minetest.chat_send_player(group_owner, "You have defined the following groups: "..(table.concat( list, ", "))..".");
end




function playergroups:create_group( group_owner, group_name )


   if( not( group_name ) or group_name=="" ) then
      minetest.chat_send_player(group_owner, "Error: No group name given. Cannot create group.");
      return;
   end
     
   local groups = playergroups:read_group_file( group_owner );
   if( groups and groups[ group_name ]) then
      minetest.chat_send_player(group_owner, "Error: A group named \""..group_name.."\" already exists.");
      return;
   end


   local file_name = minetest.get_modpath( "playergroups" ).."/groups/"..group_owner;
   -- open file for append
   local file = io.open( file_name, "a" );
   if( file==nil ) then
     file = io.open( file_name, "w" );
   end
   if( file==nil ) then
      minetest.chat_send_player(group_owner, "Error: Cannot write playergroup savefile \""..file_name.."\".");
      return;
   end
      
   file:write( "\n"..group_name..":\n");
   file:flush();
   file:close();
   
   minetest.chat_send_player(group_owner, "New (empty) group \""..group_name.."\" created.");
end




function playergroups:remove_group( group_owner, group_name )

   if( not( group_name ) or group_name=="" ) then
      minetest.chat_send_player(group_owner, "Error: No group name given. Cannot remove group.");
      return;
   end
     
   local groups = playergroups:read_group_file( group_owner );
   if( not( groups ) or not( groups[ group_name ])) then
      minetest.chat_send_player(group_owner, "There is no group named \""..group_name.."\". Nothing to do.");
      return;
   end

   local old_members = playergroups:extract_group_members( groups[ group_name ] );

   -- set the group to empty
   if( playergroups:save_group_change( group_owner, group_name, nil ) ) then
      minetest.chat_send_player(group_owner, "Group \""..group_name.."\" with members "..tostring( old_members ).." deleted.");
   end
end


-- internal function
function playergroups:save_group_change( group_owner, group_name, new_group_string )

   -- no player we might send the output to
   if( not( group_owner ) or group_onwer == "" ) then
      return;
   end

   if( not( group_name ) or group_name == "" ) then
      minetest.chat_send_player(group_owner, "Error: Name of playergroup to be saved not given.");
      return false;
   end

   local groups = playergroups:read_group_file( group_owner );
   -- if the group doesn't exist there is nothing to do
   if( not( groups ) or not( groups[ group_name ] )) then
      minetest.chat_send_player(group_owner, "Error: Cannot modify non-existing playergroup \""..group_name.."\".");
      return false;
   end

   -- actually store the new values
   groups[ group_name ] = new_group_string;

   local file_name = minetest.get_modpath( "playergroups" ).."/groups/"..group_owner;

   -- actually write new_lines to file
   local file = io.open( file_name, "w" );
   if( not( file )) then
      minetest.chat_send_player(group_owner, "Error: Unable to write group information. Please contact your admin!");
      return false;
   end

   for g, m in pairs( groups ) do
      if( g and g ~= "" ) then
         file:write( g..":"..m.."\n" );
      end
   end
   file:flush();
   file:close();
   return true;
end







function playergroups:add_group_member( group_owner, group_name, candidat )

   if( not( candidat ) or candidat == "" ) then
      minetest.chat_send_player(group_owner, "Error: No player name given.");
      return;
   end

   if( not( group_name ) or group_name == "" ) then
      minetest.chat_send_player(group_owner, "Error: No group name given.");
      return;
   end

   local groups = playergroups:read_group_file( group_owner );
   if( not( groups ) or not( groups[ group_name ])) then
      minetest.chat_send_player(group_owner, "Group \""..group_name.."\" does not exist.");
      return;
   end

   local liste = groups[ group_name ]:split(",");
   local found = false;
   for i,n in ipairs( liste ) do
      if( n == candidat ) then
         found = true;
      end
   end
   
   if( found ) then 
      minetest.chat_send_player(group_owner, candidat.." is already a member of your group "..group_name..". Nothing to do.");
      return;
   end

   -- check if the player exists
   if( not( playergroups:player_exists( group_owner, candidat ))) then
      return;
   end

   -- insert the new player
   table.insert( liste, candidat );
   -- save the new list of the group
   if( playergroups:save_group_change( group_owner, group_name, table.concat( liste, ","))) then
      minetest.chat_send_player(group_owner, candidat.." added to group \""..group_name.."\".");
   end
end



function playergroups:del_group_member( group_owner, group_name, candidat )


   if( not( candidat ) or candidat == "" ) then
      minetest.chat_send_player(group_owner, "Error: No player name given.");
      return;
   end

   if( not( group_name ) or group_name == "" ) then
      minetest.chat_send_player(group_owner, "Error: No group name given.");
      return;
   end

   local groups = playergroups:read_group_file( group_owner );
   if( not( groups ) or not( groups[ group_name ])) then
      minetest.chat_send_player(group_owner, "Group \""..group_name.."\" does not exist.");
      return;
   end

   local liste = groups[ group_name ]:split(",");
   local found = -1;
   for i,n in ipairs( liste ) do
      if( n == candidat ) then
         found = i;
      end
   end
   
   if( found==-1 ) then 
      minetest.chat_send_player(group_owner, candidat.." is not a member of your group "..group_name..". Nothing to do.");
      return;
   end

   -- remove the player
   table.remove( liste, found );
   -- save the new list of the group
   if( playergroups:save_group_change( group_owner, group_name, table.concat( liste, ","))) then
      minetest.chat_send_player(group_owner, candidat.." removed from group \""..group_name.."\".");
   end
end

