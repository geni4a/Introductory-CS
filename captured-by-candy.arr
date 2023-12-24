# load the project support code
include shared-gdrive(
  "table-functions.arr",
  "14jG4wvAMhjJue1-EmY-u9hX4UwmPHCO8")

include shared-gdrive(
  "project-2-support.arr",
  "1N1pwFonshMA_CH99wH00h0HuuiXRja9A")

include image
include tables
include reactors
import lists as L

ssid = "1U7a8ysb9PaOQ-9O-pJGzlUSUjywnJA5Zk2_n6ovJ-ls"
maze-data = load-maze(ssid)
item-data = load-items(ssid)

#constants
TILE = load-texture("tile.png")
WALLS = load-texture("walls.png")
BACKGROUND1 = rectangle(35 * 30, 19 * 30, "solid", "white")
BACKGROUND2 = rectangle(35 * 30, 19 * 30, "solid", "transparent")
DOUG-UP = load-texture("doug-up.png")
DOUG-DOWN = load-texture("doug-down.png")
DOUG-LEFT = load-texture("doug-left.png")
DOUG-RIGHT = load-texture("doug-right.png")
SNICKERS = load-texture("snickers.png")
TWIZZLER = load-texture("twizzlers.png")
CANDY-CANE = load-texture("candy-cane.png")
DOOR = load-texture("door.png")
STAMINA-START = L.length(maze-data.first) #starting stamina unit
NUM = -30 #this is multiplied by coordinates to get items/players to land on the maze


#Datatypes
data Posn:
  |posn(x :: Number, y:: Number)
end

pos1 = posn(2, 3)
pos2 = posn(10, 9)
pos3 = posn(7, 5)

data Direction:
  |up
  |down
  |left
  |right
end

data Gadget:
  |snickers
  |twizzler
  |candy-cane
  |door
  |tile #for when the item disappears
end 
gadg1 = snickers
gadg2 = twizzler
gadg3 = candy-cane
gadg4 = door

data Items:
  | item(item-type :: Gadget, posn :: Posn, pic :: Image)
end

item1 = [list: 
  item(gadg1, pos1, SNICKERS), 
  item(gadg2, pos2, TWIZZLER), 
  item(gadg3, pos3, CANDY-CANE)]
item2 = [list: 
  item(gadg4, pos3, DOOR), 
  item(gadg2, pos2, TWIZZLER), 
  item(gadg3, pos1, CANDY-CANE)]

data Player:
  |doug(posn :: Posn, pic :: Image, stamina :: Number)
end

play1 = doug(pos1, DOUG-UP, 100)
play2 = doug(pos2, DOUG-LEFT, 200)

data GameState:
  | frames(player :: Player,  gadgets :: List<Items>)
end

state1 = frames(play1, item1)
state2 = frames(play2, item2)

#making maze background with only walls and tiles
fun maze-row(lst :: List<String>) -> Image:
  doc: ```takes in a list of strings and outputs images next to each other: a wall image if an element is x or a tile if an element is o.```
  cases (List) lst:
    | empty => empty-image
    | link(fst, rst) => 
      if fst == "x":
        beside(WALLS, maze-row(rst))
      else if fst == "o":
        beside(TILE, maze-row(rst))
      else:
        empty-image
      end
  end
end


fun background-image(static-background :: List<List<String>>) -> Image:
  doc: ```takes in a list of lists of strings and produces an maze image of walls and tiles. This assumes that the lists within the bigger list are of the same length.```
  cases (List) static-background:
    | empty => empty-image
    | link(fst, rst) =>
      above(maze-row(fst), background-image(rst))
  end
end
BACKGROUND = background-image(maze-data)


#Putting gagdgets onto the maze of walls and tiles
gadget-x-list = item-data.get-column("x")
gadget-y-list = item-data.get-column("y")
gadget-name-list = item-data.get-column("name")


fun gadget-to-list(x :: List, y :: List) -> List<List>:
  doc: ```takes in two lists and pairs the elements together to form a list of lists. This works best if the two lists are of the same length```
  cases (List) x:
    | empty => empty
    | link(fst, rst) =>
      cases (List) y:
        | empty => empty
        | link(fst2, rst2) => link(link(fst, link(fst2, empty)), gadget-to-list(rst, rst2))
      end
  end   
where:
  gadget-to-list([list: ], [list: ]) is empty
  gadget-to-list([list: 1, 2], [list: 3, 4]) is [list: [list: 1, 3], [list: 2, 4 ]]
  gadget-to-list([list: 5], [list: 4, 3]) is [list: [list: 5, 4]] #there can only be pairs
  gadget-to-list([list: 9, 5, 7], [list: 4, 3]) is [list: [list: 9, 4], [list: 5, 3]] #there can only be pairs
  gadget-to-list([list: 9, 5], [list: 4, 3]) is [list: [list: 9, 4], [list: 5, 3]]
  gadget-to-list([list: "a","b"], [list: "c", "d"]) is [list: [list: "a", "c"], [list: "b", "d"]]
  gadget-to-list([list: true, false], [list: true, false]) is [list: [list: true, true], [list: false, false]]
end


gadget-coord-list = gadget-to-list(gadget-x-list, gadget-y-list)
final-gadget-list = gadget-to-list(gadget-name-list, gadget-coord-list)


fun list-to-position(lst :: List<Number>) -> Posn:
  doc:"takes in a list of two numbers and converts them into the Posn data type"
  posn(lst.first, lst.rest.first)
where:
  list-to-position([list: 1, 2]) is posn(1, 2)
  list-to-position([list: 0, 9]) is posn(0, 9)
  list-to-position([list: 5, 5]) is  posn(5, 5)
  list-to-position([list: 1, 2, 3]) is posn(1, 2) #3 disappears because this works on a list of two numbers. The first two numbers are used while the 3rd is discarded
end


fun list-to-item-helper(lst :: List<String, List<Number>>) -> Items:
  doc:"takes in a list(containing a name string and list of two numbers) and converts it into an Items data type"
  if lst.first == "Snickers":
    item(snickers, list-to-position(lst.rest.first), SNICKERS)
  else if lst.first == "Twizzler":
    item(twizzler, list-to-position(lst.rest.first), TWIZZLER)
  else if lst.first == "Candy Cane":
    item(candy-cane, list-to-position(lst.rest.first), CANDY-CANE)
  else:
    item(door, list-to-position(lst.rest.first), DOOR)
  end
where:
  list-to-item-helper([list: "Snickers", [list:1, 2]]) is item(snickers, posn(1, 2), SNICKERS)
  list-to-item-helper([list: "Candy Cane", [list: 100, 2]]) is item(candy-cane, posn(100, 2), CANDY-CANE)
  list-to-item-helper([list: "door", [list:100, 20]]) is item(door, posn(100, 20), DOOR)
end


fun list-to-item(lst :: List<List<String, List<Number>>>) -> List<Items>:
  doc:"takes in a list of lists(that contain with a string and a list of two numbers) and converts it into a list of  Items data types"
  cases (List<List<String, List<Number>>>) lst:
    | empty => empty
    | link(fst, rst) => link(list-to-item-helper(fst), list-to-item(rst))
  end
where:
  list-to-item([list: ]) is empty
  list-to-item([list: [list: "Snickers", [list: 7, 1]], [list: "Door", [list: 9, 100] ]]) is [list: item(snickers, posn(7, 1), SNICKERS), item(door, posn(9, 100), DOOR)]
end

#expressions and constants making the game with gadgets, maze, player and stamina bar
POSN-START = posn(1, 1) #the first tile that appears on the maze. 
init-items = list-to-item(final-gadget-list)
init-state = frames(doug(POSN-START, DOUG-RIGHT, STAMINA-START), init-items)


fun get-item(lst :: List<List<String>>, x :: Number, y :: Number) -> String:
  doc: ```takes in a list of lists of strings and outputs the xth element of the yth list. This function assumes the lists within the bigger lists are off the same length.```
  if (y > L.length(lst)) or (x > L.length(lst.first)):
    ""
  else:
    (lst.get(y)).get(x)
  end
where:
  get-item(maze-data, 0, 0) is "x"
  get-item(maze-data, 1, 1) is "o"
  get-item(maze-data, 34, 18) is "x"
  get-item(maze-data, 4, 3) is "o"
  get-item([list: [list: "b", "c"], [list: "e", "f" ]], 0, 0) is "b"
  get-item(maze-data, 99, 99) is ""
  #do we have to include an example with numbers outside the range
end


fun draw-items(lst :: List<Items>) -> Image:
  doc: "takes in a list of items and outputs an image of the gadgets on the maze background"
  cases (List<Items>) lst:
    |empty => empty-image
    |link(fst, rst) => overlay-align("left", "top",  (overlay-xy(fst.pic, (fst.posn.x * NUM), (fst.posn.y * NUM), BACKGROUND2)), draw-items(rst))
  end
end


fun stamina-bar(width :: Number) -> Image:
  doc:```takes in a number representing width and then draws a green rectangle. Since this will be used to build the bar for stamina, the width cannot be negative. ```
  rectangle((num-abs(width) * 30), 30, "solid","green")
end
#|Player hasn't completed eating item until they step off of the item, at which point their stamina will decrease by 1 for their movement, but will also change depending on what item they consumed.
|#


fun draw-game(state :: GameState) -> Image:
  doc: "takes in a gamestate and outputs a frame/image of the game"
  cases (GameState) state:
    | frames(p, i) => 
      cases (Player) p:
        | doug(pos, pic, stamina) =>             
          item-background = overlay-align("left", "top",  draw-items(i), BACKGROUND)
          above(above-align("left", (overlay-xy(pic, pos.x * NUM, pos.y * NUM, item-background)), stamina-bar(stamina)), text(num-to-string(stamina), 36, "blue"))
      end
  end
end 


#helper functions for key-pressed
fun candy-disappear(p :: Player, l :: List<Items>) ->List<Items>:
  doc: ```takes a player and list of items and outputs list of items based on the position of the player relative to a gadget. If a player is on a gadget, it disappears (aka turns into a tile). ```
  cases (List<Items>) l:
    |empty => empty
    |link(fst, rst) =>
      fun item-disappear(lst :: Items) ->Items:
        if p.posn == lst.posn:
          item(tile, lst.posn, TILE)  #the item disappearance is its replacement with a tile
        else:
          lst
        end
      end
      if p.posn == fst.posn:
        link(item-disappear(fst), rst)
      else:
        link(fst, candy-disappear(p, rst))
      end
  end
where:
  candy-disappear(doug(posn(7, 1), DOUG-RIGHT, 33), [list: item(snickers, posn(7, 1), SNICKERS), item(twizzler, posn(10, 2), TWIZZLER)]) is ([list: item(tile, posn(7, 1), TILE), item(twizzler, posn(10, 2), TWIZZLER)]) #since player lands on snickers, it turns into a tile but the twizzler remains as is.
  candy-disappear(init-state.player,empty) is empty
  candy-disappear(doug(posn(3, 1), DOUG-RIGHT, 30), [list:item(twizzler, posn(10, 2), TWIZZLER)]) is [list:item(twizzler, posn(10, 2), TWIZZLER)]#since the player does not land on candy, the candy remains as is.
  candy-disappear(doug(posn(17, 11), DOUG-RIGHT, 30), [list:item(twizzler, posn(10, 2), TWIZZLER), item(snickers, posn(7,1), SNICKERS)]) is  [list:item(twizzler, posn(10, 2), TWIZZLER), item(snickers, posn(7,1), SNICKERS)] #if the player is not on either candy, they both remain as is. 
end


fun candy-change-stamina(p :: Player, direction :: Direction, l :: List<Items>) -> Number:
  doc:```takes in a list of items, a Player and a direction to output the stamina of the player based on the position of the player relative to a gadget.```
  cases (List) l:
    | empty => p.stamina - 1
    | link(fst,rst) => 
      if ((posn(p.posn.x + 1, p.posn.y) == fst.posn) and (direction == right))
        or ((posn(p.posn.x - 1, p.posn.y) == fst.posn) and (direction == left))
        or  ((posn(p.posn.x, p.posn.y + 1) == fst.posn) and (direction == down))
        or ((posn(p.posn.x, p.posn.y - 1) == fst.posn) and (direction == up)):
        if fst.pic == SNICKERS: 
          STAMINA-START
        else if fst.pic == TWIZZLER: #|the conditions prevents the results of subtracting stamina units assigned to twizzler from getting below 0|#
          if p.stamina <= 4:#we say 4 and below instead of below 4 because 4 - 4 is 0 regardless
            0
          else:
            p.stamina - 4
          end
        else if fst.pic == CANDY-CANE:  #the conditions prevents the results of adding stamina units assigned to candy-cane from exceeding the original
          if p.stamina >= (STAMINA-START - 6): #we say - 6 instead of 5 because 29 + 6 is equal to 35 regardless
            STAMINA-START
          else:
            p.stamina + 6
          end
        else: 
          p.stamina - 1
        end
      else: 
        candy-change-stamina(p, direction, rst)
      end
  end
where:
  candy-change-stamina(doug(posn(7, 1), DOUG-RIGHT, 25), right,  [list: item(snickers, posn(8, 1),SNICKERS)]) is 35 #when player lands on snickers, stamina is replenished up to original
  candy-change-stamina(doug(posn(21, 5), DOUG-RIGHT, 1), left,  [list: item(snickers, posn(20, 5),SNICKERS)]) is 35 #when player lands on snickers, stamina is replenished up to original even if player is about to hit 0
  candy-change-stamina(doug(posn(21, 5), DOUG-RIGHT, 0), up,  [list: item(snickers, posn(21, 6),SNICKERS)]) is -1 #|if the player is already at 0, snickers cannot save them because they cannot get to the snicker. other changes in the game will make the game end then and there. Hence, the stamina becomes negative|#
  candy-change-stamina(doug(posn(1, 7), DOUG-RIGHT, 20), up,  [list: item(candy-cane, posn(1, 6), CANDY-CANE)]) is 26 #when player lands on candy-cane and stamina is below 29, stamina is replenished by 6
 candy-change-stamina(doug(posn(1, 2), DOUG-RIGHT, 29), down,  [list: item(candy-cane, posn(1, 3), CANDY-CANE)]) is 35 #when player lands on candy-cane and stamina is 29 or above, stamina is replenished by up to original
  candy-change-stamina(doug(posn(7, 1), DOUG-RIGHT, 31), right,  [list: item(candy-cane, posn(8, 1), CANDY-CANE)]) is 35 #when player lands on candy-cane and stamina is 29 or above, stamina is replenished by up to original
  candy-change-stamina(doug(posn(3, 16), DOUG-RIGHT, 28), left,  [list: item(candy-cane, posn(2, 16), CANDY-CANE)]) is 34#when player lands on candy-cane and stamina is below 29, stamina is replenished by 6
  candy-change-stamina(doug(posn(10, 5), DOUG-RIGHT, 20),up,  [list: item(twizzler, posn(10, 4), TWIZZLER)]) is 16 #when a player lands on twizzler with stamina above 4, stamina goes down by 4
  candy-change-stamina(doug(posn(9, 5), DOUG-RIGHT, 4), left,  [list: item(twizzler, posn(8, 5), TWIZZLER)]) is 0#when a player lands on twizzler with stamina  4 or below, stamina goes down to 0
  candy-change-stamina(doug(posn(19, 5), DOUG-RIGHT, 3), right,  [list: item(twizzler, posn(20, 5), TWIZZLER)]) is 0 #when a player lands on twizzler with stamina  4 or below, stamina goes down to 0
  candy-change-stamina(doug(posn(19, 5), DOUG-RIGHT, 5), down,  [list: item(twizzler, posn(19, 6), TWIZZLER)]) is 1#when a player lands on twizzler with stamina above 4, stamina goes down by 4
end


fun key-pressed(state :: GameState, key :: String) -> GameState:
  doc: "takes in the current gamestate and alters it depending on keys pressed for doug's movement"
  cases (GameState) state:
    | frames(a, b) =>
      cases (Player) a: 
        |doug(pos, picture, stam) =>
          if key == "w":
            if get-item(maze-data, pos.x, pos.y - 1) == "x":
              frames(doug(posn(pos.x, pos.y), DOUG-UP, stam), b)
            else:
              frames(doug(posn(pos.x, pos.y - 1), DOUG-UP, (candy-change-stamina(a, up, b))), candy-disappear(a, b))
            end
          else if key == "a":
            if get-item(maze-data, pos.x - 1, pos.y) == "x":
              frames(doug(posn(pos.x, pos.y), DOUG-LEFT, stam), b)
            else:
              frames(doug(posn(pos.x - 1, pos.y), DOUG-LEFT, (candy-change-stamina(a, left, b))), candy-disappear(a, b))
            end
          else if key == "s":
            if get-item(maze-data, pos.x, pos.y + 1) == "x":
              frames(doug(posn(pos.x, pos.y), DOUG-DOWN, stam), b)
            else:
              frames(doug(posn(pos.x, pos.y + 1), DOUG-DOWN, (candy-change-stamina(a, down, b))), candy-disappear(a, b))
            end
          else if key == "d":
            if get-item(maze-data, pos.x + 1,  pos.y) == "x":
              frames(doug(posn(pos.x, pos.y), DOUG-RIGHT, stam), b)
            else:
              frames(doug(posn(pos.x + 1, pos.y), DOUG-RIGHT, (candy-change-stamina(a, right, b))), candy-disappear(a, b))
            end
          else:
            state
          end
      end
  end
where:
  key-pressed(state1, "n") is state1  #using a different letter does not affect the state
  key-pressed(state1, "a") is frames(doug(posn(2, 3), DOUG-LEFT, 100), item1)
  key-pressed(state1, "s") is frames(doug(posn(2, 3), DOUG-DOWN, 100), item1)
  key-pressed(frames(doug(posn(1, 1), DOUG-LEFT, 35), init-items), "w") is frames(doug(posn(1, 1), DOUG-UP, 35), init-items)#there is no change in stamina because the player cannot move. This is due to a wall up ahead  
  key-pressed(frames(doug(posn(7, 1), DOUG-RIGHT, 0), init-items), "d") is frames(doug(posn(8, 1), DOUG-RIGHT, -1), (link(item(tile, posn(7, 1), TILE),init-items.rest)))#If the player gets to snicker with stamina zero, he will not be replenished.

  key-pressed(frames(doug(posn(4, 1), DOUG-RIGHT, 35), init-items), "s") is frames(doug(posn(4, 2), DOUG-DOWN, 35), init-items) #if a player with full stamina lands on a candy-cane, it's stamina remains unchanged. 
  key-pressed(frames(doug(posn(3, 1), DOUG-RIGHT, 2), [list: item(snickers, posn(7, 1), SNICKERS), item(twizzler, posn(3, 1), TWIZZLER)]), "a") is 
  frames(doug(posn(2, 1), DOUG-LEFT, 1), [list: item(snickers, posn(7, 1), SNICKERS), item(tile, posn(3, 1), TILE)])#|if a player is already on a twizzler/ any other candy, the candy will have already affected the stamina, so now it is only a tile. Thus the stamina goes down by one as usual |#   
  key-pressed(frames(doug(posn(2, 1), DOUG-LEFT, 35), [list: item(snickers, posn(2, 1), SNICKERS), item(snickers, posn(3, 1), SNICKERS)]), "d")  is frames(doug(posn(3, 1), DOUG-RIGHT, 35), [list: item(tile, posn(2, 1), TILE), item(snickers, posn(3, 1), SNICKERS)]) #|if a player moves from a snicker to another snicker, the stamina remains at original. But the first snicker will now disappear |#
  key-pressed(frames(doug(posn(2, 1), DOUG-RIGHT, 34), [list: item(candy-cane, posn(2, 1), CANDY-CANE), item(candy-cane, posn(3, 1), CANDY-CANE)]), "d") is frames(doug(posn(3, 1), DOUG-RIGHT, 35), [list: item(tile, posn(2, 1), TILE), item(candy-cane, posn(3, 1), CANDY-CANE)])#if a player moves from a candy cane to another candy cane, the stamina will increase up to 35. if it is 35, nothing changes. |#
end




fun game-complete(state :: GameState) -> Boolean:
  doc: ```outputs true if the player's  stamina is 0 or less or if the player's position corresponds with that of the last connected tile. The input gamestate's list of items must have a door item for this function to work appropriately. This function assumes the list of lists used for the maze will not change.  ```

  (state.player.stamina <= 0) or (state.player.posn == posn(34, 14))

where:
  game-complete(state2) is false
  game-complete(frames(doug(posn(34, 14), DOUG-LEFT, 35), init-items)) is true
  #when player hits the door even if player has a lot of stamina
  game-complete(frames(doug(posn(10, 9), DOUG-RIGHT, 0), init-items)) is true
  #when stamina hits 0 even if player is not on the door
  game-complete(frames(doug(posn(34, 14), DOUG-RIGHT, 100), init-items)) is true
  #when player hits the door even if player has a lot of stamina
  game-complete(frames(doug(posn(34, 14), DOUG-RIGHT, 0), init-items)) is true
  #when player hits the door and has 0 stamina
end


maze-game =
  reactor:
    init              : init-state,
    to-draw           : draw-game,
    on-key            : key-pressed,
    stop-when       : game-complete,
    close-when-stop : true, 
    title             : "Captured by Candy!" 
  end

#interact(maze-game)




#| Reflection answers
    1) One advantage of using lists rather than a table is that lists were a lot easier to work with within the code. For example, in our get-item function  we only needed to write two nested .get functions rather than transforming the information from an entire table. One disadvantage is that tables are easier for us to read and identify where elements are within the table.

   2) The google sheet was helpful because it was our guide to making sure our maze looked accurate and that our items, tiles, and walls were in the correct positions. A disadvantage of the google sheet is that it was only a visual representation of the walls and the tiles without visual indication of where items were and we couldn't manipulate it directly in our code. The list-of-lists was helpful because with only two different elements within the lists, it was easy to write code to develop an image of walls and tiles. A disadvantage of the list-of-lists is that it was difficult to visualize before the code was completed. The final image itself was beneficial because we could interact with it and make sure that our code was reflecting what we wanted the game to do. A disadvantage of the final image is that if the code is not written correctly, the image won't give us any insight into what error we made within the code.


   3) Member Insights
   Ariana: This project really helped me gain insight to the power of lists. Before this project, I preferred tables because of their visual organization, but I realize now after creating such an interactive game from a list-of-lists how powerful lists are and to what extent they can be manipulated. The benefit of organizing data is also apparent through lists and I got a lot of practice writing and testing functions with list inputs and outputs.

   Eugenia: During labs, I used to write recursions even for cases where it was more efficient to use list functions. I wrote Making this game helped me become more aware of this problem and avoid them.  Also, I can understand how reactors work fully. 

   Isy: I was able to appreciate the usefulness of lists in writing efficiently and easy to work with code because before this project I was not super comfortable with lists and lists of lists and so on.  These advantages became especially clear in writing code to build the image from the list of X's and O's.

   4)
   One problem that we had to work through was getting used to working with a form of coordinates that we were not used to.  In general we are used to working in a cartesian plane in which the bottom left would be (0,0) and the coordinates would  move in a positive direction going up and to the right.  Getting used to coordinates starting at the top left, getting more negative, and moving by units of 30 (due to the size of our images) took some getting used to.

   One mistake we made along the way was trying to figure out how to make the candy disappear after the player passed them by referencing either the name of the image or the type in our code. We didn't realize until after the gadget functions were written that we had to reference just the images in order to make the changes to the visual representation that affect the internal code.

   5) 
   When is it more efficient to create a new data type rather than use an existing datatype to represent your information?

|#