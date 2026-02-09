local localPlayer = getLocalPlayer()

guiIntroLabel1B = nil
guiIntroProceedButtonB = nil
guiIntroWindowB = nil
guiQuestionLabelB = nil
guiQuestionAnswer1RadioB = nil
guiQuestionAnswer2RadioB = nil
guiQuestionAnswer3RadioB = nil
guiQuestionWindowB = nil
guiFinalPassTextLabelB = nil
guiFinalFailTextLabelB = nil
guiFinalRegisterButtonB = nil
guiFinalCloseButtonB = nil
guiFinishWindowB = nil

-- variable for the max number of possible questions
local NoQuestions = 10
local NoQuestionToAnswer = 7
local correctAnswers = 0
local passPercent = 80
		
selection = {}

-- functon makes the intro window for the quiz
function createlicenseBikeTestIntroWindow()
	showCursor(true)
	local screenwidth, screenheight = guiGetScreenSize ()
	
	local Width = 450
	local Height = 200
	local X = (screenwidth - Width)/2
	local Y = (screenheight - Height)/2
	
	guiIntroWindowB = guiCreateWindow ( X , Y , Width , Height , "Bike Theory Test" , false )
	
	guiCreateStaticImage (0.35, 0.1, 0.3, 0.2, "banner.png", true, guiIntroWindowB)
	
	guiIntroLabel1B = guiCreateLabel(0, 0.3,1, 0.5, [[You will now proceed with the motorcycle theory test. You will
be given seven questions based on basic driving theory. You must score
a minimum of 80 percent to pass.

Good luck.]], true, guiIntroWindowB)
	
	guiLabelSetHorizontalAlign ( guiIntroLabel1B, "center", true )
	guiSetFont ( guiIntroLabel1B,"default-bold-small")
	
	guiIntroProceedButtonB = guiCreateButton ( 0.4 , 0.75 , 0.2, 0.1 , "Start Test" , true ,guiIntroWindowB)
	
	addEventHandler ( "onClientGUIClick", guiIntroProceedButtonB,  function(button, state)
		if(button == "left" and state == "up") then
		
			-- start the quiz and hide the intro window
			startLicenceBikeTest()
			guiSetVisible(guiIntroWindowB, false)
		
		end
	end, false)
	
end

-- done bike up to here

-- function create the question window
function createBikeLicenseQuestionWindow(number)

	local screenwidth, screenheight = guiGetScreenSize ()
	
	local Width = 450
	local Height = 200
	local X = (screenwidth - Width)/2
	local Y = (screenheight - Height)/2
	
	-- create the window
	guiQuestionWindowB = guiCreateWindow ( X , Y , Width , Height , "Question "..number.." of "..NoQuestionToAnswer , false )
	
	guiQuestionLabelB = guiCreateLabel(0.1, 0.2, 0.9, 0.2, selection[number][1], true, guiQuestionWindowB)
	guiSetFont ( guiQuestionLabelB,"default-bold-small")
	guiLabelSetHorizontalAlign ( guiQuestionLabelB, "left", true)
	
	
	if not(selection[number][2]== "nil") then
		guiQuestionAnswer1RadioB = guiCreateRadioButton(0.1, 0.4, 0.9,0.1, selection[number][2], true,guiQuestionWindowB)
	end
	
	if not(selection[number][3] == "nil") then
		guiQuestionAnswer2RadioB = guiCreateRadioButton(0.1, 0.5, 0.9,0.1, selection[number][3], true,guiQuestionWindowB)
	end
	
	if not(selection[number][4]== "nil") then
		guiQuestionAnswer3RadioB = guiCreateRadioButton(0.1, 0.6, 0.9,0.1, selection[number][4], true,guiQuestionWindowB)
	end
	
	-- if there are more questions to go, then create a "next question" button
	if(number < NoQuestionToAnswer) then
		guiQuestionNextButtonB = guiCreateButton ( 0.4 , 0.75 , 0.2, 0.1 , "Next Question" , true ,guiQuestionWindowB)
		
		addEventHandler ( "onClientGUIClick", guiQuestionNextButtonB,  function(button, state)
			if(button == "left" and state == "up") then
				
				local selectedAnswer = 0
			
				-- check all the radio buttons and seleted the selectedAnswer variabe to the answer that has been selected
				if(guiRadioButtonGetSelected(guiQuestionAnswer1RadioB)) then
					selectedAnswer = 1
				elseif(guiRadioButtonGetSelected(guiQuestionAnswer2RadioB)) then
					selectedAnswer = 2
				elseif(guiRadioButtonGetSelected(guiQuestionAnswer3RadioB)) then
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
					guiSetVisible(guiQuestionWindowB, false)
					createBikeLicenseQuestionWindow(number+1)
				end
			end
		end, false)
		
	else
		guiQuestionSumbitButtonB = guiCreateButton ( 0.4 , 0.75 , 0.3, 0.1 , "Submit Answers" , true ,guiQuestionWindowB)
		
		-- handler for when the player clicks submit
		addEventHandler ( "onClientGUIClick", guiQuestionSumbitButtonB,  function(button, state)
			if(button == "left" and state == "up") then
				
				local selectedAnswer = 0
			
				-- check all the radio buttons and seleted the selectedAnswer variabe to the answer that has been selected
				if(guiRadioButtonGetSelected(guiQuestionAnswer1RadioB)) then
					selectedAnswer = 1
				elseif(guiRadioButtonGetSelected(guiQuestionAnswer2RadioB)) then
					selectedAnswer = 2
				elseif(guiRadioButtonGetSelected(guiQuestionAnswer3RadioB)) then
					selectedAnswer = 3
				elseif(guiRadioButtonGetSelected(guiQuestionAnswer4RadioB)) then
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
					guiSetVisible(guiQuestionWindowB, false)
					createBikeTestFinishWindow()


				end
			end
		end, false)
	end
end


-- funciton create the window that tells the
function createBikeTestFinishWindow()

	local score = math.floor((correctAnswers/NoQuestionToAnswer)*100)

	local screenwidth, screenheight = guiGetScreenSize ()
		
	local Width = 450
	local Height = 200
	local X = (screenwidth - Width)/2
	local Y = (screenheight - Height)/2
		
	-- create the window
	guiFinishWindowB = guiCreateWindow ( X , Y , Width , Height , "End of test.", false )
	
	if(score >= passPercent) then
	
		guiCreateStaticImage (0.35, 0.1, 0.3, 0.2, "pass.png", true, guiFinishWindowB)
	
		guiFinalPassLabelB = guiCreateLabel(0, 0.3, 1, 0.1, "Congratulations! You have passed this section of the test.", true, guiFinishWindowB)
		guiSetFont ( guiFinalPassLabelB,"default-bold-small")
		guiLabelSetHorizontalAlign ( guiFinalPassLabelB, "center")
		guiLabelSetColor ( guiFinalPassLabelB ,0, 255, 0 )
		
		guiFinalPassTextLabelB = guiCreateLabel(0, 0.4, 1, 0.4, "You scored "..score.."%, and the pass mark is "..passPercent.."%. Well done!" ,true, guiFinishWindowB)
		guiLabelSetHorizontalAlign ( guiFinalPassTextLabelB, "center", true)
		
		guiFinalRegisterButtonB = guiCreateButton ( 0.35 , 0.8 , 0.3, 0.1 , "Continue" , true ,guiFinishWindowB)
		
		-- if the player has passed the quiz and clicks on register
		addEventHandler ( "onClientGUIClick", guiFinalRegisterButtonB,  function(button, state)
			if(button == "left" and state == "up") then
				-- set player date to say they have passed the theory.
				

				initiateBikeTest()
				-- reset their correct answers
				correctAnswers = 0
				toggleAllControls ( true )
				--cleanup
				destroyElement(guiIntroLabel1B)
				destroyElement(guiIntroProceedButtonB)
				destroyElement(guiIntroWindowB)
				destroyElement(guiQuestionLabelB)
				destroyElement(guiQuestionAnswer1RadioB)
				destroyElement(guiQuestionAnswer2RadioB)
				destroyElement(guiQuestionAnswer3RadioB)
				destroyElement(guiQuestionWindowB)
				destroyElement(guiFinalPassTextLabelB)
				destroyElement(guiFinalRegisterButtonB)
				destroyElement(guiFinishWindowB)
				guiIntroLabel1B = nil
				guiIntroProceedButtonB = nil
				guiIntroWindowB = nil
				guiQuestionLabelB = nil
				guiQuestionAnswer1RadioB = nil
				guiQuestionAnswer2RadioB = nil
				guiQuestionAnswer3RadioB = nil
				guiQuestionWindowB = nil
				guiFinalPassTextLabelB = nil
				guiFinalRegisterButtonB = nil
				guiFinishWindowB = nil
				
				correctAnswers = 0
				selection = {}
				
				showCursor(false)
			end
		end, false)
		
	else -- player has failed, 
	
		guiCreateStaticImage (0.35, 0.1, 0.3, 0.2, "fail.png", true, guiFinishWindowB)
	
		guiFinalFailLabelB = guiCreateLabel(0, 0.3, 1, 0.1, "Sorry, you have not passed this time.", true, guiFinishWindowB)
		guiSetFont ( guiFinalFailLabelB,"default-bold-small")
		guiLabelSetHorizontalAlign ( guiFinalFailLabelB, "center")
		guiLabelSetColor ( guiFinalFailLabelB ,255, 0, 0 )
		
		guiFinalFailTextLabelB = guiCreateLabel(0, 0.4, 1, 0.4, "You scored "..math.ceil(score).."%, and the pass mark is "..passPercent.."%." ,true, guiFinishWindowB)
		guiLabelSetHorizontalAlign ( guiFinalFailTextLabelB, "center", true)
		
		guiFinalCloseButtonB = guiCreateButton ( 0.2 , 0.8 , 0.25, 0.1 , "Close" , true ,guiFinishWindowB)
		
		-- if player click the close button
		addEventHandler ( "onClientGUIClick", guiFinalCloseButtonB,  function(button, state)
			if(button == "left" and state == "up") then
				destroyElement(guiIntroLabel1B)
				destroyElement(guiIntroProceedButtonB)
				destroyElement(guiIntroWindowB)
				destroyElement(guiQuestionLabelB)
				destroyElement(guiQuestionAnswer1RadioB)
				destroyElement(guiQuestionAnswer2RadioB)
				destroyElement(guiQuestionAnswer3RadioB)
				destroyElement(guiQuestionWindowB)
				destroyElement(guiFinalPassTextLabelB)
				destroyElement(guiFinalRegisterButtonB)
				destroyElement(guiFinishWindowB)
				guiIntroLabel1B = nil
				guiIntroProceedButtonB = nil
				guiIntroWindowB = nil
				guiQuestionLabelB = nil
				guiQuestionAnswer1RadioB = nil
				guiQuestionAnswer2RadioB = nil
				guiQuestionAnswer3RadioB = nil
				guiQuestionWindowB = nil
				guiFinalPassTextLabelB = nil
				guiFinalRegisterButtonB = nil
				guiFinishWindowB = nil
				
				selection = {}
				correctAnswers = 0
				
				showCursor(false)
			end
		end, false)
	end
	
end
 
 -- function starts the quiz
 function startLicenceBikeTest()
 
	-- choose a random set of questions
	chooseBikeTestQuestions()
	-- create the question window with question number 1
	createBikeLicenseQuestionWindow(1)
 
 end
 
 
 -- functions chooses the questions to be used for the quiz
 function chooseBikeTestQuestions()
 
	-- loop through selections and make each one a random question
	for i=1, 10 do
		-- pick a random number between 1 and the max number of questions
		local number = math.random(1, NoQuestions)
		
		-- check to see if the question has already been selected
		if(testBikeQuestionAlreadyUsed(number)) then
			repeat -- if it has, keep changing the number until it hasn't
				number = math.random(1, NoQuestions)
			until (testBikeQuestionAlreadyUsed(number) == false)
		end
		
		-- set the question to the random one
		selection[i] = questionsBike[number]
	end
 end
 
 
 -- function returns true if the queston is already used
 function testBikeQuestionAlreadyUsed(number)
 
	local same = 0
 
	-- loop through all the current selected questions
	for i, j in pairs(selection) do
		-- if a selected question is the same as the new question
		if(j[1] == questionsBike[number][1]) then
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
 
testBikeRoute = {
	{ -2183.189453125, -2265.8271484375, 30.625 },	-- Start, DoL Parking 
	{ -2165.2900390625, -2261.4990234375, 30.46875 }, -- DoL exit, turning right
	{ -2135.33203125, -2243.181640625, 30.46875 }, -- Headed towards Governors office
	{ -2122.3095703125, -2273.0751953125, 30.46875 }, -- Riding towards Idlewood
	{ -2165.3466796875, -2327.439453125, 30.47654914856 }, -- ^^
	{ -2169.681640625, -2394.2548828125, 30.46875 }, -- Turning towards PD
	{ -2116.7216796875, -2442.6650390625, 30.46875 }, -- ^^
	{ -2172.5625, -2501.583984375, 30.46875 }, -- Stop at PD, turn right
	{ -2193.453125, -2474.478515625, 30.46875 }, -- Stop at SAN, turn left
	{ -2129.689453125, -2394.3251953125, 30.46875 }, -- ^^
	{ -2132.376953125, -2329.3505859375, 30.46875 }, -- End of SAN, behind PD turn left
	{ -2206.2529296875, -2270.6455078125, 30.46875 }, -- Heading past PD
	{ -2253.04296875, -2206.8671875, 33.548603057861 }, -- Next to PD
	{ -2102.3359375, -2077.7783203125, 63.131042480469 }, -- At intersection on commerce
	{ -2012.59765625, -1892.7265625, 45.816951751709 }, -- Stop @ St. Lawrence, turn right
	{ -1842.34375, -1740.1416015625, 29.143316268921 }, -- Turn left towards ASH @ speed cam
	{ -1691.1025390625, -1650.837890625, 36.2578125 }, -- ^^
	{ -1524.5732421875, -1610.904296875, 38.062236785889 }, -- Next to ASH
	{ -1297.685546875, -1706.732421875, 45.755138397217 }, -- Heading down the road
	{ -1182.9697265625, -1873.2158203125, 74.384178161621 }, -- ^^
	{ -979.5771484375, -1928.013671875, 80.289237976074 }, -- Turn right at Vinyl Countdown
	{ -1118.6826171875, -2189.8916015625, 32.697891235352 }, -- ^^
	{ -1184.591796875, -2493.8076171875, 61.960754394531 }, -- Heading towards Dillimore
	{ -1053.044921875, -2613.2158203125, 79.331687927246 }, -- ^^
	{ -851.9189453125, -2536.7568359375, 88.40576171875 }, -- Turn left @ Dillimore road
	{ -700.3095703125, -2352.392578125, 39.783023834229 }, -- ^^
	{ -563.841796875, -2339.8173828125, 27.713062286377 }, -- Going towards Bank
	{ -450.78125, -2257.693359375, 46.331977844238 }, -- ^^
	{ -334.4462890625, -2258.2783203125, 39.294803619385 }, -- Turn left at bank
	{ -288.1767578125, -2288.1396484375, 30.280052185059 }, -- ^^
	{ -161.0927734375, -2441.8828125, 34.851142883301 }, -- Going towards Beach
	{ -177.7744140625, -2580.345703125, 35.957523345947 }, -- ^^
	{ -179.146484375, -2725.869140625, 34.790260314941 }, -- ^^
	{ -210.4072265625, -2822.3955078125, 44.822731018066 }, -- Turn left into road
	{ -406.20703125, -2774.36328125, 65.324813842773 }, -- ^^
	{ -787.041015625, -2775.5498046875, 73.828323364258 }, -- End of road, turn left
	{ -1078.3251953125, -2853.271484375, 67.71875 }, -- ^^
	{ -1285.4375, -2867.2275390625, 60.909370422363 }, -- Heading back towards DoL
	{ -1579.3466796875, -2760.4775390625, 48.276065826416 }, -- ^^
	{ -1285.4375, -2867.2275390625, 60.909370422363 }, -- Heading back towards DoL
	{ -1579.3466796875, -2760.4775390625, 48.276065826416 }, -- ^^
	{ -1778.64453125, -2562.083984375, 54.062202453613 }, -- turn right towards DoL
	{ -1970.064453125, -2544.884765625, 37.888076782227 }, -- ^^
	{ -2128.5458984375, -2421.8916015625, 30.46875 }, -- Turn left towards DoL
	{ -2187.3896484375, -2362.4287109375, 30.46875 }, -- ^^
	{ -2163.2607421875, -2304.3447265625, 30.46875 }, -- Turn right into DoL
	{ -2179.45703125, -2280.4013671875, 30.46875 }, -- ^^
	{ -2183.8955078125, -2266.3828125, 30.625 },	-- DoL End road
}

testBike = { [468]=true } -- Mananas need to be spawned at the start point.
local vehicleIdUsedToStartTest = nil

local blip = nil
local marker = nil

function initiateBikeTest()
	triggerServerEvent("theoryBikeComplete", getLocalPlayer())
	local x, y, z = testBikeRoute[1][1], testBikeRoute[1][2], testBikeRoute[1][3]
	blip = createBlip(x, y, z, 0, 2, 0, 255, 0, 255)
	marker = createMarker(x, y, z, "checkpoint", 4, 0, 255, 0, 150) -- start marker.
	addEventHandler("onClientMarkerHit", marker, startBikeTest)
	
	outputChatBox("#FF9933You are now ready to take your practical driving examination. Collect a DoL test bike and begin the route.", 255, 194, 14, true)
	
end

function startBikeTest(element)
	if element == getLocalPlayer() then
		local vehicle = getPedOccupiedVehicle(getLocalPlayer())
		if not vehicle or not testBike[getElementModel(vehicle)] then
			outputChatBox("#FF9933You must be riding a DoL test bike when passing through the checkpoints.", 255, 0, 0, true ) -- Wrong  type.
		else
			destroyElement(blip)
			destroyElement(marker)
			
			setElementData(getLocalPlayer(), "drivingTest.marker", 2, false)
			vehicleIdUsedToStartTest = getElementData(vehicle, "dbid")

			local x1,y1,z1 = nil -- Setup the first checkpoint
			x1 = testBikeRoute[2][1]
			y1 = testBikeRoute[2][2]
			z1 = testBikeRoute[2][3]
			setElementData(getLocalPlayer(), "drivingTest.checkmarkers", #testBikeRoute, false)

			blip = createBlip(x1, y1 , z1, 0, 2, 255, 0, 255, 255)
			marker = createMarker( x1, y1,z1 , "checkpoint", 4, 255, 0, 255, 150)
				
			addEventHandler("onClientMarkerHit", marker, UpdateBikeCheckpoints)
				
			outputChatBox("#FF9933You will need to complete the route without damaging the test bike. Good luck and drive safe.", 255, 194, 14, true)
		end
	end
end

function UpdateBikeCheckpoints(element)
	if (element == localPlayer) then
		local vehicle = getPedOccupiedVehicle(getLocalPlayer())
		if not vehicle or not testBike[getElementModel(vehicle)] then
			outputChatBox("You must be on a DoL test bike when passing through the check points.", 255, 0, 0) -- Wrong car type.
		elseif getElementData(vehicle, "dbid") ~= vehicleIdUsedToStartTest then
			outputChatBox("You are not using the bike you started this test with.", 255, 194, 14)
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
				outputChatBox("#FF9933Park your bike at the #FF66CCin the parking lot #FF9933to complete the test.", 255, 194, 14, true)
				
				local newnumber = m_number+1
				setElementData(getLocalPlayer(), "drivingTest.marker", newnumber, false)
					
				local x2, y2, z2 = nil
				x2 = testBikeRoute[newnumber][1]
				y2 = testBikeRoute[newnumber][2]
				z2 = testBikeRoute[newnumber][3]
				
				marker = createMarker( x2, y2, z2, "checkpoint", 4, 255, 0, 255, 150)
				blip = createBlip( x2, y2, z2, 0, 2, 255, 0, 255, 255)
				
				
				addEventHandler("onClientMarkerHit", marker, EndBikeTest)
			else
				local newnumber = m_number+1
				setElementData(getLocalPlayer(), "drivingTest.marker", newnumber, false)
						
				local x2, y2, z2 = nil
				x2 = testBikeRoute[newnumber][1]
				y2 = testBikeRoute[newnumber][2]
				z2 = testBikeRoute[newnumber][3]
						
				marker = createMarker( x2, y2, z2, "checkpoint", 4, 255, 0, 255, 150)
				blip = createBlip( x2, y2, z2, 0, 2, 255, 0, 255, 255)
				
				addEventHandler("onClientMarkerHit", marker, UpdateBikeCheckpoints)
			end
		end
	end
end

function EndBikeTest(element)
	if (element == localPlayer) then
		local vehicle = getPedOccupiedVehicle(getLocalPlayer())
		if not vehicle or not testBike[getElementModel(vehicle)] then
			outputChatBox("You must be on a DoL test bike when passing through the check points.", 255, 0, 0)
		else
			local vehicleHealth = getElementHealth ( vehicle )
			if getElementData(vehicle, "dbid") ~= vehicleIdUsedToStartTest then
				outputChatBox("You are not using the bike you started this test with.", 255, 194, 14)
				outputChatBox("You have failed the practical driving test.", 255, 0, 0)
			elseif (vehicleHealth >= 800) then
				----------
				-- PASS --
				----------
				outputChatBox("After inspecting the vehicle we can see no damage.", 255, 194, 14)
				triggerServerEvent("acceptBikeLicense", getLocalPlayer())
			
			else
				----------
				-- Fail --
				----------
				outputChatBox("After inspecting the vehicle we can see that it's damage.", 255, 194, 14)
				outputChatBox("You have failed the practical driving test.", 255, 0, 0)
			end
			
			destroyElement(blip)
			destroyElement(marker)
			triggerServerEvent('takeBackHelmet', localPlayer)
			blip = nil
			marker = nil
		end
	end
end
