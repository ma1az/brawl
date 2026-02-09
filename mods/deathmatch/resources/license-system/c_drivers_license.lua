local localPlayer = getLocalPlayer()

guiIntroLabel1 = nil
guiIntroProceedButton = nil
guiIntroWindow = nil
guiQuestionLabel = nil
guiQuestionAnswer1Radio = nil
guiQuestionAnswer2Radio = nil
guiQuestionAnswer3Radio = nil
guiQuestionWindow = nil
guiFinalPassTextLabel = nil
guiFinalFailTextLabel = nil
guiFinalRegisterButton = nil
guiFinalCloseButton = nil
guiFinishWindow = nil

-- variable for the max number of possible questions
local NoQuestions = 10
local NoQuestionToAnswer = 7
local correctAnswers = 0
local passPercent = 80
		
selection = {}

-- functon makes the intro window for the quiz
function createlicenseTestIntroWindow()
	
	showCursor(true)
	
	local screenwidth, screenheight = guiGetScreenSize ()
	
	local Width = 450
	local Height = 200
	local X = (screenwidth - Width)/2
	local Y = (screenheight - Height)/2
	
	guiIntroWindow = guiCreateWindow ( X , Y , Width , Height , "Driving Theory Test" , false )
	
	guiCreateStaticImage (0.35, 0.1, 0.3, 0.2, "banner.png", true, guiIntroWindow)
	
	guiIntroLabel1 = guiCreateLabel(0, 0.3,1, 0.5, [[You will now proceed with the driving theory test. You will
be given seven questions based on basic driving theory. You must score
a minimum of 80 percent to pass.

Good luck.]], true, guiIntroWindow)
	
	guiLabelSetHorizontalAlign ( guiIntroLabel1, "center", true )
	guiSetFont ( guiIntroLabel1,"default-bold-small")
	
	guiIntroProceedButton = guiCreateButton ( 0.4 , 0.75 , 0.2, 0.1 , "Start Test" , true ,guiIntroWindow)
	
	addEventHandler ( "onClientGUIClick", guiIntroProceedButton,  function(button, state)
		if(button == "left" and state == "up") then
		
			-- start the quiz and hide the intro window
			startLicenceTest()
			guiSetVisible(guiIntroWindow, false)
		
		end
	end, false)
	
end


-- function create the question window
function createLicenseQuestionWindow(number)

	local screenwidth, screenheight = guiGetScreenSize ()
	
	local Width = 450
	local Height = 200
	local X = (screenwidth - Width)/2
	local Y = (screenheight - Height)/2
	
	-- create the window
	guiQuestionWindow = guiCreateWindow ( X , Y , Width , Height , "Question "..number.." of "..NoQuestionToAnswer , false )
	
	guiQuestionLabel = guiCreateLabel(0.1, 0.2, 0.9, 0.2, selection[number][1], true, guiQuestionWindow)
	guiSetFont ( guiQuestionLabel,"default-bold-small")
	guiLabelSetHorizontalAlign ( guiQuestionLabel, "left", true)
	
	
	if not(selection[number][2]== "nil") then
		guiQuestionAnswer1Radio = guiCreateRadioButton(0.1, 0.4, 0.9,0.1, selection[number][2], true,guiQuestionWindow)
	end
	
	if not(selection[number][3] == "nil") then
		guiQuestionAnswer2Radio = guiCreateRadioButton(0.1, 0.5, 0.9,0.1, selection[number][3], true,guiQuestionWindow)
	end
	
	if not(selection[number][4]== "nil") then
		guiQuestionAnswer3Radio = guiCreateRadioButton(0.1, 0.6, 0.9,0.1, selection[number][4], true,guiQuestionWindow)
	end
	
	-- if there are more questions to go, then create a "next question" button
	if(number < NoQuestionToAnswer) then
		guiQuestionNextButton = guiCreateButton ( 0.4 , 0.75 , 0.2, 0.1 , "Next Question" , true ,guiQuestionWindow)
		
		addEventHandler ( "onClientGUIClick", guiQuestionNextButton,  function(button, state)
			if(button == "left" and state == "up") then
				
				local selectedAnswer = 0
			
				-- check all the radio buttons and seleted the selectedAnswer variabe to the answer that has been selected
				if(guiRadioButtonGetSelected(guiQuestionAnswer1Radio)) then
					selectedAnswer = 1
				elseif(guiRadioButtonGetSelected(guiQuestionAnswer2Radio)) then
					selectedAnswer = 2
				elseif(guiRadioButtonGetSelected(guiQuestionAnswer3Radio)) then
					selectedAnswer = 3
				else
					selectedAnswer = 0
				end
				
				-- don't let the player continue if they havn't selected an answer
				if(selectedAnswer ~= 0) then
					
					-- if the selection is the same as the correct answer, increase correct answers by 1
					if(selectedAnswer == selection[number][5]) then
						correctAnswers = correctAnswers + 1
					end
				
					-- hide the current window, then create a new window for the next question
					guiSetVisible(guiQuestionWindow, false)
					createLicenseQuestionWindow(number+1)
				end
			end
		end, false)
		
	else
		guiQuestionSumbitButton = guiCreateButton ( 0.4 , 0.75 , 0.3, 0.1 , "Submit Answers" , true ,guiQuestionWindow)
		
		-- handler for when the player clicks submit
		addEventHandler ( "onClientGUIClick", guiQuestionSumbitButton,  function(button, state)
			if(button == "left" and state == "up") then
				
				local selectedAnswer = 0
			
				-- check all the radio buttons and seleted the selectedAnswer variabe to the answer that has been selected
				if(guiRadioButtonGetSelected(guiQuestionAnswer1Radio)) then
					selectedAnswer = 1
				elseif(guiRadioButtonGetSelected(guiQuestionAnswer2Radio)) then
					selectedAnswer = 2
				elseif(guiRadioButtonGetSelected(guiQuestionAnswer3Radio)) then
					selectedAnswer = 3
				elseif(guiRadioButtonGetSelected(guiQuestionAnswer4Radio)) then
					selectedAnswer = 4
				else
					selectedAnswer = 0
				end
				
				-- don't let the player continue if they havn't selected an answer
				if(selectedAnswer ~= 0) then
					
					-- if the selection is the same as the correct answer, increase correct answers by 1
					if(selectedAnswer == selection[number][5]) then
						correctAnswers = correctAnswers + 1
					end
				
					-- hide the current window, then create the finish window
					guiSetVisible(guiQuestionWindow, false)
					createTestFinishWindow()


				end
			end
		end, false)
	end
end


-- funciton create the window that tells the
function createTestFinishWindow()

	local score = math.floor((correctAnswers/NoQuestionToAnswer)*100)

	local screenwidth, screenheight = guiGetScreenSize ()
		
	local Width = 450
	local Height = 200
	local X = (screenwidth - Width)/2
	local Y = (screenheight - Height)/2
		
	-- create the window
	guiFinishWindow = guiCreateWindow ( X , Y , Width , Height , "End of test.", false )
	
	if(score >= passPercent) then
	
		guiCreateStaticImage (0.35, 0.1, 0.3, 0.2, "pass.png", true, guiFinishWindow)
	
		guiFinalPassLabel = guiCreateLabel(0, 0.3, 1, 0.1, "Congratulations! You have passed this section of the test.", true, guiFinishWindow)
		guiSetFont ( guiFinalPassLabel,"default-bold-small")
		guiLabelSetHorizontalAlign ( guiFinalPassLabel, "center")
		guiLabelSetColor ( guiFinalPassLabel ,0, 255, 0 )
		
		guiFinalPassTextLabel = guiCreateLabel(0, 0.4, 1, 0.4, "You scored "..score.."%, and the pass mark is "..passPercent.."%. Well done!" ,true, guiFinishWindow)
		guiLabelSetHorizontalAlign ( guiFinalPassTextLabel, "center", true)
		
		guiFinalRegisterButton = guiCreateButton ( 0.35 , 0.8 , 0.3, 0.1 , "Continue" , true ,guiFinishWindow)
		
		-- if the player has passed the quiz and clicks on register
		addEventHandler ( "onClientGUIClick", guiFinalRegisterButton,  function(button, state)
			if(button == "left" and state == "up") then
				-- set player date to say they have passed the theory.
				

				initiateDrivingTest()
				-- reset their correct answers
				correctAnswers = 0
				toggleAllControls ( true )
				--cleanup
				destroyElement(guiIntroLabel1)
				destroyElement(guiIntroProceedButton)
				destroyElement(guiIntroWindow)
				destroyElement(guiQuestionLabel)
				destroyElement(guiQuestionAnswer1Radio)
				destroyElement(guiQuestionAnswer2Radio)
				destroyElement(guiQuestionAnswer3Radio)
				destroyElement(guiQuestionWindow)
				destroyElement(guiFinalPassTextLabel)
				destroyElement(guiFinalRegisterButton)
				destroyElement(guiFinishWindow)
				guiIntroLabel1 = nil
				guiIntroProceedButton = nil
				guiIntroWindow = nil
				guiQuestionLabel = nil
				guiQuestionAnswer1Radio = nil
				guiQuestionAnswer2Radio = nil
				guiQuestionAnswer3Radio = nil
				guiQuestionWindow = nil
				guiFinalPassTextLabel = nil
				guiFinalRegisterButton = nil
				guiFinishWindow = nil
				
				correctAnswers = 0
				selection = {}
				
				showCursor(false)
			end
		end, false)
		
	else -- player has failed, 
	
		guiCreateStaticImage (0.35, 0.1, 0.3, 0.2, "fail.png", true, guiFinishWindow)
	
		guiFinalFailLabel = guiCreateLabel(0, 0.3, 1, 0.1, "Sorry, you have not passed this time.", true, guiFinishWindow)
		guiSetFont ( guiFinalFailLabel,"default-bold-small")
		guiLabelSetHorizontalAlign ( guiFinalFailLabel, "center")
		guiLabelSetColor ( guiFinalFailLabel ,255, 0, 0 )
		
		guiFinalFailTextLabel = guiCreateLabel(0, 0.4, 1, 0.4, "You scored "..math.ceil(score).."%, and the pass mark is "..passPercent.."%." ,true, guiFinishWindow)
		guiLabelSetHorizontalAlign ( guiFinalFailTextLabel, "center", true)
		
		guiFinalCloseButton = guiCreateButton ( 0.2 , 0.8 , 0.25, 0.1 , "Close" , true ,guiFinishWindow)
		
		-- if player click the close button
		addEventHandler ( "onClientGUIClick", guiFinalCloseButton,  function(button, state)
			if(button == "left" and state == "up") then
				destroyElement(guiIntroLabel1)
				destroyElement(guiIntroProceedButton)
				destroyElement(guiIntroWindow)
				destroyElement(guiQuestionLabel)
				destroyElement(guiQuestionAnswer1Radio)
				destroyElement(guiQuestionAnswer2Radio)
				destroyElement(guiQuestionAnswer3Radio)
				destroyElement(guiQuestionWindow)
				destroyElement(guiFinalFailTextLabel)
				destroyElement(guiFinalCloseButton)
				destroyElement(guiFinishWindow)
				guiIntroLabel1 = nil
				guiIntroProceedButton = nil
				guiIntroWindow = nil
				guiQuestionLabel = nil
				guiQuestionAnswer1Radio = nil
				guiQuestionAnswer2Radio = nil
				guiQuestionAnswer3Radio = nil
				guiQuestionWindow = nil
				guiFinalFailTextLabel = nil
				guiFinalCloseButton = nil
				guiFinishWindow = nil
				
				selection = {}
				correctAnswers = 0
				
				showCursor(false)
			end
		end, false)
	end
	
end
 
 -- function starts the quiz
 function startLicenceTest()
 
	-- choose a random set of questions
	chooseTestQuestions()
	-- create the question window with question number 1
	createLicenseQuestionWindow(1)
 
 end
 
 
 -- functions chooses the questions to be used for the quiz
 function chooseTestQuestions()
 
	-- loop through selections and make each one a random question
	for i=1, 10 do
		-- pick a random number between 1 and the max number of questions
		local number = math.random(1, NoQuestions)
		
		-- check to see if the question has already been selected
		if(testQuestionAlreadyUsed(number)) then
			repeat -- if it has, keep changing the number until it hasn't
				number = math.random(1, NoQuestions)
			until (testQuestionAlreadyUsed(number) == false)
		end
		
		-- set the question to the random one
		selection[i] = questions[number]
	end
 end
 
 
 -- function returns true if the queston is already used
 function testQuestionAlreadyUsed(number)
 
	local same = 0
 
	-- loop through all the current selected questions
	for i, j in pairs(selection) do
		-- if a selected question is the same as the new question
		if(j[1] == questions[number][1]) then
			same = 1 -- set same to 1
		end
		
	end
	
	-- if same is 1, question already selected to return true
	if(same == 1) then
		return true
	else
		return false
	end
 end

---------------------------------------
------ Practical Driving Test ---------
---------------------------------------
 
testRoute = {
	{ -2180.7978515625, -2268.5712890625, 30.625 },	-- Start, DoL Parking 
	{ -2152.6376953125, -2246.66015625, 30.46875 },	-- San Andreas Boulevard DoL near Exit
	{ -2087.287109375, -2281.611328125, 30.46875 }, -- San Andreas Boulevard DoL Exiting turning left
	{ -2109.0771484375, -2356.0224609375, 30.46875 }, 	-- Constituion Ave
	{ -2141.638671875, -2417.8662109375, 30.46875 }, -- Constituion Ave, turn to St. Lawrence Blvd
	{ -2082.1630859375, -2470.4208984375, 30.46875 }, -- St. Lawrence Blvd
	{ -2138.5419921875, -2528.2626953125, 30.46875 }, 	-- St. Lawrence Blvd, going to Panopticon Ave
	{ -2195.6875, -2482.7646484375, 30.46875 }, 	-- St. Lawrence Blvd, going to Panopticon Ave
	{ -2261.2451171875, -2558.2109375, 31.934959411621 }, 	-- St. Lawrence Blvd, going to Panopticon Ave
	{ -2303.0810546875, -2728.837890625, 43.903518676758 },	-- St. Lawrence Blvd, turning on to Panopticon Ave
	{ -2094.66796875, -2766.6875, 45.012454986572 },	-- Panopticon Ave
	{ -1857.1396484375, -2690.3212890625, 54.088680267334 },	-- Panopticon Ave back on to the opposite side of St. Lawrence Blvd
	{ -1646.2412109375, -2739.7294921875, 46.921875 },		-- St. Lawrence Blvd
	{ -1455.7978515625, -2909.5703125, 46.921875 },	-- Turning on to City Hall Road
	{ -1255.4130859375, -2891.1171875, 60.65714263916 },	-- City Hall Road
	{ -1078.353515625, -2861.6708984375, 67.71875 },	-- City Hall Road
	{ -975.1103515625, -2871.54296875, 66.957054138184 },	-- City Hall Road
	{ -745.2197265625, -2798.2109375, 52.353713989258 },	-- City Hall Road
	{ -466.3935546875, -2812.75390625, 47.441284179688 },	-- City Hall Road
	{ -111.6376953125, -2879.24609375, 39.1796875 },	-- City Hall Road
	{ -41.03125, -2512.1318359375, 35.838073730469 }, 	-- City Hall Road turning towards IGS
	{ -218.658203125, -2307.9970703125, 28.27836227417 }, 	-- 
	{ -320.7861328125, -2097.765625, 27.642507553101 }, 	-- 
	{ -303.1650390625, -1805.927734375, 17.017543792725 }, 	-- IGS
	{ -123.7783203125, -1472.8876953125, 12.8046875 }, 	-- IGS
	{ -27.048828125, -1413.1953125, 11.344366073608 }, -- IGS
	{ -108.69140625, -1480.130859375, 2.6953125 }, 			-- Mulholland parking, Turn to East Vinewood Blvd
	{ -135.1884765625, -1325.615234375, 2.0530714988708 }, 	-- East Vinewood Blvd, turn to Sunset Blvd
	{ -81.7919921875, -1388.634765625, 11.979950904846 }, 	-- Sunset Blvd
	{ -285.16796875, -1643.25390625, 15.457271575928 }, 	-- Sunset Blvd
	{ -313.625, -2235.1806640625, 29.081537246704 }, 	-- Sunset Blvd
	{ -41.14453125, -2598.3134765625, 43.689456939697 }, 	-- Sunset Blvd, Turn to St. Lawrence Blvd
	{ -264.046875, -2813.2158203125, 51.352100372314 }, 	-- St. Lawrence Blvd
	{ -790.5927734375, -2777.7158203125, 73.655807495117 }, 	-- St. Lawrence Blvd, turn to West Broadway
	{ -1079.98046875, -2853.7705078125, 67.71875 }, 	-- West Broadway
	{ -1340.11328125, -2873.7265625, 55.644863128662 }, -- West Broadway
	{ -1669.275390625, -2686.4404296875, 48.661861419678 }, 	-- Interstate 25
	{ -1821.123046875, -2535.3271484375, 53.113906860352 }, 	-- Interstate 25
	{ -1970.376953125, -2543.94140625, 37.837646484375 }, 	-- Interstate 125
	{ -2088.84375, -2453.830078125, 30.46875 }, 	-- Interstate 125
	{ -2185.2919921875, -2359.25, 30.46875 }, -- Interstate 125
	{ -2162.1826171875, -2305.4326171875, 30.46875 }, -- Interstate 125
	{ -2179.197265625, -2279.349609375, 30.46875 }, 	-- Interstate 125
	{ -2183.482421875, -2266.4619140625, 30.625 }, 		-- Interstate 125, turn to Saints Blvd
}

testVehicle = { [410]=true } -- Mananas need to be spawned at the start point.
local vehicleIdUsedToStartTest = nil

local blip = nil
local marker = nil

function initiateDrivingTest()
	triggerServerEvent("theoryComplete", getLocalPlayer())
	local x, y, z = testRoute[1][1], testRoute[1][2], testRoute[1][3]
	blip = createBlip(x, y, z, 0, 2, 0, 255, 0, 255)
	marker = createMarker(x, y, z, "checkpoint", 4, 0, 255, 0, 150) -- start marker.
	addEventHandler("onClientMarkerHit", marker, startDrivingTest)
	
	outputChatBox("#FF9933You are now ready to take your practical driving examination. Collect a DoL test car and begin the route.", 255, 194, 14, true)
	
end

function startDrivingTest(element)
	if element == getLocalPlayer() then
		local vehicle = getPedOccupiedVehicle(getLocalPlayer())
		if not vehicle or not testVehicle[getElementModel(vehicle)] then
			outputChatBox("#FF9933You must be in a DoL test car when passing through the checkpoints.", 255, 0, 0, true ) -- Wrong car type.
		else
			destroyElement(blip)
			destroyElement(marker)
			
			setElementData(getLocalPlayer(), "drivingTest.marker", 2, false)
			vehicleIdUsedToStartTest = getElementData(vehicle, "dbid")

			local x1,y1,z1 = nil -- Setup the first checkpoint
			x1 = testRoute[2][1]
			y1 = testRoute[2][2]
			z1 = testRoute[2][3]
			setElementData(getLocalPlayer(), "drivingTest.checkmarkers", #testRoute, false)

			blip = createBlip(x1, y1 , z1, 0, 2, 255, 0, 255, 255)
			marker = createMarker( x1, y1,z1 , "checkpoint", 4, 255, 0, 255, 150)
				
			addEventHandler("onClientMarkerHit", marker, UpdateCheckpoints)
				
			outputChatBox("#FF9933You will need to complete the route without damaging the test car. Good luck and drive safe.", 255, 194, 14, true)
		end
	end
end

function UpdateCheckpoints(element)
	if (element == localPlayer) then
		local vehicle = getPedOccupiedVehicle(getLocalPlayer())
		if not vehicle or not testVehicle[getElementModel(vehicle)] then
			outputChatBox("You must be in a DoL test car when passing through the check points.", 255, 0, 0) -- Wrong car type.
		elseif getElementData(vehicle, "dbid") ~= vehicleIdUsedToStartTest then
			outputChatBox("You are not using the vehicle you started this test with.", 255, 194, 14)
			outputChatBox("You have failed the practical driving test.", 255, 0, 0)

			destroyElement(blip)
			destroyElement(marker)
			blip = nil
			marker = nil
		else
			destroyElement(blip)
			destroyElement(marker)
			blip = nil
			marker = nil
				
			local m_number = getElementData(getLocalPlayer(), "drivingTest.marker")
			local max_number = getElementData(getLocalPlayer(), "drivingTest.checkmarkers")
			
			if (tonumber(max_number-1) == tonumber(m_number)) then -- if the next checkpoint is the final checkpoint.
				outputChatBox("#FF9933Park your car at the #FF66CCin the parking lot #FF9933to complete the test.", 255, 194, 14, true)
				
				local newnumber = m_number+1
				setElementData(getLocalPlayer(), "drivingTest.marker", newnumber, false)
					
				local x2, y2, z2 = nil
				x2 = testRoute[newnumber][1]
				y2 = testRoute[newnumber][2]
				z2 = testRoute[newnumber][3]
				
				marker = createMarker( x2, y2, z2, "checkpoint", 4, 255, 0, 255, 150)
				blip = createBlip( x2, y2, z2, 0, 2, 255, 0, 255, 255)
				
				
				addEventHandler("onClientMarkerHit", marker, EndTest)
			else
				local newnumber = m_number+1
				setElementData(getLocalPlayer(), "drivingTest.marker", newnumber, false)
						
				local x2, y2, z2 = nil
				x2 = testRoute[newnumber][1]
				y2 = testRoute[newnumber][2]
				z2 = testRoute[newnumber][3]
						
				marker = createMarker( x2, y2, z2, "checkpoint", 4, 255, 0, 255, 150)
				blip = createBlip( x2, y2, z2, 0, 2, 255, 0, 255, 255)
				
				addEventHandler("onClientMarkerHit", marker, UpdateCheckpoints)
			end
		end
	end
end

function EndTest(element)
	if (element == localPlayer) then
		local vehicle = getPedOccupiedVehicle(getLocalPlayer())
		if not vehicle or not testVehicle[getElementModel(vehicle)] then
			outputChatBox("You must be in a DoL test car when passing through the check points.", 255, 0, 0)
		else
			local vehicleHealth = getElementHealth ( vehicle )
			if getElementData(vehicle, "dbid") ~= vehicleIdUsedToStartTest then
				outputChatBox("You are not using the vehicle you started this test with.", 255, 194, 14)
				outputChatBox("You have failed the practical driving test.", 255, 0, 0)
			elseif (vehicleHealth >= 800) then
				----------
				-- PASS --
				----------
				outputChatBox("After inspecting the vehicle we can see no damage.", 255, 194, 14)
				triggerServerEvent("acceptCarLicense", getLocalPlayer())
			else
				----------
				-- Fail --
				----------
				outputChatBox("After inspecting the vehicle we can see that it's damage.", 255, 194, 14)
				outputChatBox("You have failed the practical driving test.", 255, 0, 0)
			end
			
			destroyElement(blip)
			destroyElement(marker)
			blip = nil
			marker = nil
		end
	end
end
