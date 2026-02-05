# Server Command List

> [!NOTE]
> This curated list contains commands categorized by system. Debug and internal commands have been hidden.

## Admin & Management

### admin-system
- /fakeme
- /getkey
- /gmlounge
- /setserverpassword *(Aliases: /setserverpw)*
- /setx
- /setxy
- /setxyz
- /setxz
- /sety
- /setz

### anticheat
- /mods

### bans
- /accountban *(Aliases: /banaccount)*
- /banip *(Aliases: /ipban)*
- /banserial *(Aliases: /serialban)*
- /findalts2 *(Aliases: /findalts)*
- /findban *(Aliases: /showban)*
- /findip
- /findserial
- /pban *(Aliases: /sban)*
- /soban *(Aliases: /oban)*
- /unban

### duty
- /duty

### monitor
- /monitor
- /omonitor
- /omonitor2

### report
- /acceptreport *(Aliases: /ar)*
- /ara
- /changereport *(Aliases: /cp)*
- /cks
- /closeallreports *(Aliases: /car)*
- /closereport *(Aliases: /cr)*
- /dropreport *(Aliases: /dr)*
- /endreport *(Aliases: /er)*
- /falsereport *(Aliases: /fr)*
- /getsavedreports
- /reportinfo *(Aliases: /ri)*
- /reportlazyfix
- /reports
- /setsavedreports
- /showadminreports
- /transferreport *(Aliases: /tr)*
- /ur
- /ur

### s_item_admin.lua:addCommandHandler("gotoitem", gotoItem, false, false)item-system
- /convertworld

### s_spikes.lua:addCommandHandler("aremovespikes", AdminRemovingSpikes)superman
- /superman

### s_surf.lua:addCommandHandler ( "setwave", scriptWave )admin-system
- /check

## Vehicles

### carshop-system
- /refreshcarshops *(Aliases: /restartcarshops)*

### tow-system
- /impoundbike
- /resettowbackup
- /towtruck
- /unimpound

### vehicle
- /avehpos *(Aliases: /apark)*
- /detach
- /doors
- /fvehpos *(Aliases: /fpark)*
- /lock
- /makecivveh
- /makeveh
- /sell
- /toggleautopark
- /togwindow
- /vehpos *(Aliases: /park)*
- /yearday

### vehicle-handling-editor
- /editvehicle *(Aliases: /editveh)*

### vehicle-interiors
- /windows

### vehicle-library
- /getenginetype
- /givevctadmin
- /setenginetype
- /vehiclelibrary *(Aliases: /vehlib)*

### vehicle_fuel
- /deletefuelped *(Aliases: /delfuelped, /deletefuel, /delfuel)*
- /gotofuelnpc *(Aliases: /gotofuelped, /gotofuel)*
- /makefuelnpc *(Aliases: /makefuelped, /makefuel)*
- /nearbyfuels *(Aliases: /nearbynpcs)*

### vehicle_manager
- /addupgrade
- /blowveh
- /checkvehicle *(Aliases: /checkveh)*
- /clearvehicleinventory *(Aliases: /clearvehinv)*
- /deleteupgrade *(Aliases: /delupgrade)*
- /deletevehicle *(Aliases: /delveh)*
- /delnearbyvehicles *(Aliases: /delnearbyvehs)*
- /delthisveh
- /entervehicle *(Aliases: /entercar, /enterveh)*
- /findvehid
- /fixveh
- /fixvehs
- /fixvehvis
- /flip
- /fuelveh
- /fuelvehs
- /getcolor
- /getsdt *(Aliases: /getdt, /gdt)*
- /getsll *(Aliases: /gsll)*
- /getveh *(Aliases: /getcar)*
- /getvehweight
- /gotocar *(Aliases: /gotoveh)*
- /nearbyvehicles *(Aliases: /nearbyvehs)*
- /oldcar
- /reloadvehicle *(Aliases: /reloadveh)*
- /removevehicle *(Aliases: /removeveh)*
- /removevehicles *(Aliases: /removevehs)*
- /resetdt
- /resetsll
- /resetupgrades
- /respawnall
- /respawnciv
- /respawndistrict
- /respawnint
- /respawnstop
- /respawnveh
- /restorevehicle *(Aliases: /restoreveh)*
- /sdt
- /sendtoveh
- /sendvehto *(Aliases: /sendcar, /sendveh)*
- /setbulletproof *(Aliases: /setdamageproof, /sbp, /sdp)*
- /setcarhp
- /setcolor
- /setodometer *(Aliases: /setmilage)*
- /setpaintjob
- /setvariant
- /setvehiclefaction *(Aliases: /setvehfaction)*
- /setvehicleplate *(Aliases: /setvehplate)*
- /setvehtint
- /setwheelstate
- /sll
- /switchseat
- /thiscar
- /togplate
- /togreg
- /togvin
- /unflip
- /unlockcivcars
- /veh
- /vehicles *(Aliases: /vehs)*

## Factions & Jobs

### factions
- /cleanupDuty
- /convertFactions
- /convertfactionranks
- /dutyadmin
- /faction
- /gettax
- /govlicense
- /removefaction
- /renamefaction *(Aliases: /showfactions, /makefaction, /delfaction, /factions)*
- /respawnfaction
- /setbudget
- /setfaction
- /setfactionleader
- /setfactionmoney
- /setfactionrank
- /setincometax
- /settax
- /setwelfare
- /showfactionplayers

### job-system
- /cj
- /myjob
- /quitjob *(Aliases: /endjob)*

### job-system-trucker
- /addtruckerjobmarker
- /aordersupplies
- /checkactiveroutes
- /deljob
- /deltruckmarker
- /fetchActualOrders
- /ordersupplies
- /respawntrucks
- /setjob
- /setjoblevel
- /showActualOrders
- /showAllTruckMarkers
- /skiproute

### mdc
- /makemdcaccount
- /refreshpilotlicenses
- /removeduplicatedaccounts *(Aliases: /convertmdcaccounts)*

### pd-system
- /apb
- /dispatch
- /emp
- /fingerprint
- /jailtime
- /newapb
- /pdcodes
- /release
- /speedmode
- /switchmode
- /ticket
- /togglecarflashers
- /togglelaser *(Aliases: /toglaser)*
- /togglesirens

### prison-system
- /arrest
- /intercom
- /jailtime

### s_airgates.lua:addCommandHandler("clearcallsign", removeTempCallsign)sfia
- /maps

### s_apb.lua:addCommandHandler("delapb", delAPB)pd-system
- /backup

### s_taxi_job.lua:addCommandHandler("taxilight", toggleTaxiLight, false, false)job-system-trucker
- /clearallmarkers

### sapt-system
- /busann
- /ibisadmin

### sfia
- /atcvision
- /refreshvmat
- /setcallsign

## Property & Interiors

### Interior
- /getpos

### elevator-system
- /addelevator *(Aliases: /adde)*
- /addlift
- /aelevator *(Aliases: /adde2)*
- /delelevator *(Aliases: /dele)*
- /delelevatorsfrominterior *(Aliases: /delefromint)*
- /dellift
- /delnearbyelevators *(Aliases: /delnearbye)*
- /fixnearbyelevators *(Aliases: /fixnearbye)*
- /nearbyelevators *(Aliases: /nearbye)*
- /nearbylifts
- /toggleelevator *(Aliases: /togglee)*
- /togglelift

### gate-manager
- /delgate
- /gate
- /gates
- /gotogate
- /nearbygates
- /newgate
- /showgatedistance

### interior-manager
- /checkinterior *(Aliases: /checkint)*
- /interiors *(Aliases: /ints)*
- /setintfaction
- /setinttomyfaction

### interior_load
- /forcepickupspawn
- /stopfakerot

### interior_system
- /addinterior *(Aliases: /addnewint, /addint)*
- /antifall *(Aliases: /falling, /goup)*
- /cancelremovedeletedints
- /cancelremoveforsaleints
- /delinterior *(Aliases: /delint)*
- /delnearbyinteriors *(Aliases: /delnearbyints)*
- /delthisinterior *(Aliases: /delthisint)*
- /forcesell *(Aliases: /fsell)*
- /getinteriorid *(Aliases: /getintid)*
- /getinteriorprice *(Aliases: /getintprice)*
- /getinteriortype *(Aliases: /getinttype)*
- /gotohouse *(Aliases: /gotoint)*
- /gotointi
- /interiorsettings *(Aliases: /intsettings, /intset)*
- /movesafe
- /nearbyinteriors *(Aliases: /nearbyints)*
- /reloadinterior *(Aliases: /reloadint)*
- /removedeletedinteriors *(Aliases: /removedeletedints)*
- /removeforsaleinteriors *(Aliases: /removeforsaleints)*
- /removeinterior *(Aliases: /removeint)*
- /restoreinterior *(Aliases: /restoreint)*
- /sell
- /sellproperty *(Aliases: /unrent)*
- /setcamint *(Aliases: /getcamint)*
- /setinterioraddress *(Aliases: /setintaddress)*
- /setinteriorentrance *(Aliases: /setintentrance)*
- /setinteriorexit *(Aliases: /setintexit)*
- /setinteriorid *(Aliases: /setintid)*
- /setinteriorname *(Aliases: /setintname)*
- /setinteriorprice *(Aliases: /setintprice)*
- /setinteriortype *(Aliases: /setinttype)*
- /toggleinterior *(Aliases: /togint)*

### object-browser
- /obj

### object-interaction
- /deletelastdebugmodel

### object-system
- /reloadinterior

### official-interiors
- /listinteriors *(Aliases: /listints)*

### s_migrations.lua:addCommandHandler("convertshopgenerics", commandConvertGenerics)object-browser
- /objbrowser

## General & Roleplay

### ItemCreator
- /itemlist *(Aliases: /items)*

### account
- /clearchat
- /loginto

### c_hud.lua:addCommandHandler ( "limitfps", fpsFunction ) -- Attach the setfps command to fpsFunction function.hud
- /convert

### chat-system
- /GlobalOOC *(Aliases: /ooc)*
- /ME *(Aliases: /Me)*
- /airportpa
- /airradio *(Aliases: /air)*
- /ame *(Aliases: /ado)*
- /bigears
- /bigearsf
- /bu
- /charity
- /department *(Aliases: /dep)*
- /district
- /do
- /donator *(Aliases: /dchat, /don)*
- /endinterview
- /f5 *(Aliases: /f3, /f1, /f4, /f2, /f)*
- /fl2 *(Aliases: /fl1, /fl4, /fl3, /fl5, /fl)*
- /fmt
- /gms
- /gooc
- /gov
- /highlight *(Aliases: /focus)*
- /hospitalpa
- /hq
- /ignore
- /ignorelist
- /interview
- /medical *(Aliases: /med)*
- /mir
- /mt
- /pa
- /pay
- /pm
- /radio *(Aliases: /rlow, /r)*
- /ss *(Aliases: /u)*
- /st
- /status
- /stogooc *(Aliases: /togooc)*
- /togglea *(Aliases: /toga)*
- /togglead *(Aliases: /togad)*
- /togglebusinesschat *(Aliases: /togglebusiness, /togbusiness)*
- /toggledonatorchat *(Aliases: /toggledchat, /toggledon)*
- /togglef5 *(Aliases: /togglef2, /togglef4, /togglef1, /togglef3, /togglef, /togf3, /togf5, /togf2, /togf4, /togf1, /togf)*
- /togglefaction3 *(Aliases: /togglefaction4, /togglefaction5, /togglefaction1, /togglefaction2, /togglefaction, /togfaction3, /togfaction2, /togfaction1, /togfaction5, /togfaction4, /togfaction)*
- /toggleg *(Aliases: /togg)*
- /togglenews *(Aliases: /tognews)*
- /toggleooc
- /togglepm *(Aliases: /togpm)*
- /toggleradio
- /togglestaff *(Aliases: /togglest, /togst)*
- /togglevct *(Aliases: /togvct)*
- /toggov
- /toggovooc *(Aliases: /toggooc)*
- /tuneradio
- /uat *(Aliases: /l)*
- /vct *(Aliases: /v)*

### global
- /changewarnstyle

### hud
- /admins *(Aliases: /staff, /gms)*
- /staff
- /stats
- /toggleOverlay *(Aliases: /togOverlay)*

### item-system
- /breathtest
- /changelock
- /combinemoney
- /convertitem
- /delallitems
- /delitem
- /delitemsfromint
- /delnearbyitems
- /issuebadge
- /moveitem
- /nearbyitems
- /showinv
- /sortmoney
- /writenote

### phone
- /addphone
- /call
- /deletead *(Aliases: /delad)*
- /delphone
- /fcall
- /freezead
- /hangup
- /listadverts *(Aliases: /listads, /adverts, /ads)*
- /loudspeaker
- /nearbyphones
- /phonebook
- /pickup
- /plow *(Aliases: /p)*
- /setphonebookname *(Aliases: /setphonebook, /setpbname)*
- /show911
- /togglephone
- /unfreezead
- /writephonelogs

### s_chance-luck.lua:addCommandHandler("flipcoin", oocCoin)chat-system
- /showdata

### s_peds.lua:addCommandHandler("givemefakename", giveFakeName)phone
- /pickup

### s_split_item.lua:addCommandHandler("splits",listSplittable, false, false )item-system
- /togpick

### social
- /addfriend

## Other

### LSFD
- /cancelfire
- /randomfire

### Player
- /911
- /adminduty *(Aliases: /aduty)*
- /agivelicense *(Aliases: /givelicense, /agl)*
- /aheal
- /atakelicense *(Aliases: /takelicense, /atl)*
- /atp
- /aunblindfold
- /auncuff
- /aunmask
- /bury
- /changename
- /charitygc
- /checkskin
- /ck
- /clearwhois
- /dellanguage
- /delplayeritem *(Aliases: /takeitem)*
- /disappear
- /disarm
- /dtp
- /earthquake
- /eject
- /extendmaxchar
- /forceapp *(Aliases: /fa)*
- /freconnect *(Aliases: /frec)*
- /freeze
- /gduty *(Aliases: /sduty)*
- /getforumstwofactorkey
- /gethere *(Aliases: /sendto)*
- /getid *(Aliases: /id)*
- /givegamecoins *(Aliases: /givegamecoin, /givegc)*
- /giveitem
- /givemoney
- /givemoveitem
- /givepeditem
- /givesuperman
- /goto
- /gotoplace
- /gunmaker
- /hideadmin
- /ho
- /hw
- /issuepilotcertificate *(Aliases: /issuepilotcert, /issuepilot, /issuepc)*
- /jailed
- /makeammo
- /makegeneric
- /makegun
- /marry
- /movebody *(Aliases: /moveck)*
- /nudge
- /oforceapp *(Aliases: /ofa)*
- /oldpilot
- /pingcheck *(Aliases: /ping)*
- /playthenoise
- /pmute
- /recon
- /resetaccount
- /resetcharacter
- /resetpos
- /rs
- /seefar
- /setage
- /setarmor
- /setdateofbirth *(Aliases: /setdob)*
- /setdimension *(Aliases: /setdim)*
- /setgender
- /setheight
- /sethp
- /setinterior *(Aliases: /setint)*
- /setintlimit
- /setlanguage *(Aliases: /setlang)*
- /setmoney
- /setrace
- /setskin
- /setvehlimit
- /sjail *(Aliases: /jail)*
- /skick *(Aliases: /pkick)*
- /slap
- /sojail *(Aliases: /ojail)*
- /sopunish *(Aliases: /opunish)*
- /spunish *(Aliases: /punish)*
- /supervise
- /takemoney
- /togmytag
- /tps
- /unck
- /unforceapp *(Aliases: /unfa)*
- /unfreeze
- /unjail
- /unrecovery
- /weaponchart *(Aliases: /gunchart, /gunlist, /gunids)*

### Resources
- /reloadacl
- /resstate
- /restartgatekeepers
- /restartres
- /startres
- /stopres

### acpanel
- /acp

### animation-system
- /aim
- /anim
- /animations *(Aliases: /animlist, /animhelp, /anims)*
- /animselect
- /animstop
- /bat
- /beg
- /bitchslap
- /carchat
- /cheer
- /copaway
- /copcome
- /copleft
- /copstop
- /cover
- /cpr
- /crack
- /cry
- /dance
- /daps
- /dive
- /drag
- /drink
- /fall
- /fallfront
- /fu
- /grabbottle
- /gsign
- /hailtaxi
- /handsup
- /heil
- /idle
- /kickballs
- /kiss
- /laugh
- /lay
- /lean
- /lightup
- /mourn
- /piss
- /puke
- /rap
- /scratch
- /shake
- /shocked
- /shove
- /sit
- /slapass
- /smoke
- /smokelean
- /startrace
- /stopanim *(Aliases: /stopani)*
- /strip
- /think
- /tired
- /wait
- /walk2 *(Aliases: /walk)*
- /wank
- /what
- /win

### apbbox
- /apblist

### apps
- /applications

### artifacts
- /removeartifacts *(Aliases: /myartifacts)*

### attach
- /toggleattach *(Aliases: /togattach)*

### auction
- /expireauctions

### bank
- /addatm
- /atmfast
- /delatm
- /iamtester
- /nearbyatms

### beeperFD
- /alarm

### bmxpier
- /adddomain
- /cancelrace

### bus
- /startbus

### business-system
- /setbiznote

### c_elections.lua:addCommandHandler("electionmanager", electionManager)elections
- /electionvotes

### c_glue.lua:addCommandHandler("glue",glue)gps
- /gps

### camera-system
- /addspeedcam
- /delspeedcam
- /nearbyspeedcams
- /setradius

### cargo
- /sailship

### carradio
- /getstations
- /radios
- /setvol

### chance-system
- /chance
- /luck

### client
- /guied
- /redo
- /undo

### client.lua:addCommandHandler("tree", togTree)realtime-system
- /settime

### clothes
- /flushskins
- /skininfo *(Aliases: /getskin, /gskin)*

### commands
- /helpcmds *(Aliases: /cmds, /help)*
- /report

### computers-system
- /ctl+alt+del

### datetime
- /now

### datetime_s.lua:addCommandHandler("now", getNow)description
- /ed

### description
- /editdescription

### driveby
- /Previous driveby weapon *(Aliases: /Next driveby weapon)*

### easter
- /spawneastereggs

### es-system
- /acceptcarry
- /assist
- /bill
- /carry
- /denycarry
- /examine
- /heal
- /prescribe
- /recovery
- /recoverytime
- /resetassist
- /revive
- /showkills

### event-system
- /aaddclubpoi
- /aclubrotstyle
- /adelclubrot
- /aloadclubrot
- /astartclubrot
- /astopclubrot
- /baskethelp
- /dropball
- /passball
- /pickball
- /shootball
- /sprules

### f10-settings
- /togglechatbubbles *(Aliases: /togglehud)*

### fakevideo
- /setdxtestmode

### fastrope
- /fastrope

### fishing
- /fish
- /stopfishing

### forums
- /gmschool
- /resetdrunk
- /setdrunklevel

### freecam
- /freecam

### freecam-tv
- /tv

### golf
- /golf
- /resetgolf

### heligrab
- /forcedrop *(Aliases: /hanginfo)*

### help
- /helpme

### hide_in_car_s.lua:addCommandHandler( 'hide', hideInCar, false, false )realism
- /indicator_left

### insurance
- /insurance

### k9dog
- /dogs
- /k9
- /k9attack *(Aliases: /k9status, /dogadd)*

### ladder_truck
- /fixladder
- /lc

### language-system
- /fre *(Aliases: /en, /ws)*

### leo-impound
- /fixlanes
- /rtMoveImpoundsToNewLot
- /scripterCreateLot
- /unimp

### license-system
- /showlicenses
- /weaponlicenses

### login-panel
- /showc

### lottery-system
- /checkjackpot
- /checknumber

### map_load
- /loadmaps

### map_manager
- /convert_all_map_files *(Aliases: /exportinteriormap, /exportexteriormap)*
- /maps

### mods
- /showfps

### motd
- /motd

### npc
- /checksupplies
- /checksupply
- /deleteshop *(Aliases: /delshop)*
- /delnearbyshops *(Aliases: /delnearbynpcs)*
- /forceupdateshopwage
- /gotoshop
- /makeshop
- /moveshop *(Aliases: /movenpc)*
- /nearbyshops *(Aliases: /nearbynpcs)*
- /reloadshop *(Aliases: /reloadped, /reloadnpc)*
- /renameshop *(Aliases: /renamenpc, /renameped)*
- /resetshopwage
- /saveshopconfigs
- /showallcustomshops

### opm
- /opm
- /opm

### paintball
- /resetleaderboard *(Aliases: /paintballmarkers, /resetlobby)*

### payday
- /forcepayday
- /forcepaydayall
- /timesaved

### paynspray-system
- /delpaynspray
- /makepaynspray
- /nearbypaynsprays

### ped-system
- /fuelped
- /hidemyid
- /makeped
- /ped

### photographer
- /photoheli
- /totalvalue

### pool
- /reallocatePlayerElementPools

### pool_c.lua:addCommandHandler("poolsize", showsize)pool
- /poolsize

### ramp-system
- /addramp
- /delramp
- /gotoramp
- /moveramp
- /nearbyramps

### realism
- /cockpit *(Aliases: /fp)*
- /createemitter
- /cruisecontrol *(Aliases: /cc)*
- /delemitter
- /handbrake *(Aliases: /kickstand, /anchor)*
- /indicator_both
- /indicator_right
- /nearbycks
- /nearbyemitters
- /passjoint
- /sacmaraces
- /seatbelt *(Aliases: /belt)*
- /setwalk
- /switchhand
- /throwaway
- /toggleradar
- /unhook *(Aliases: /detach)*
- /walklist

### realtime-system
- /setgametime

### restrictedfrequency
- /addfreq
- /delfreq
- /freqs
- /restrictfreqs *(Aliases: /rf)*

### roadblock-system
- /delallroadblocks *(Aliases: /delallrbs)*
- /delroadblock *(Aliases: /delrb)*
- /nearbyrbs *(Aliases: /nearbyrb)*
- /rbs

### s_camera_pd_commands.lua:addCommandHandler("togglespeedcam", toggleTrafficCam)cargo
- /shipping

### s_clubtec.lua:addCommandHandler("tempvsspawn", tempVidSysSpawn, false, true)computers-system
- /browser

### s_emitters.lua:addCommandHandler("delemitters", delEmitters)realism
- /setwalkingstyle

### s_tag_system.lua:addCommandHandler("settag", setTag)texture-system
- /texlist

### saveplayer-system
- /saveall *(Aliases: /saveme)*

### selfck-system
- /cancelck
- /cka
- /ckd
- /selfck

### server
- /perfbrowse *(Aliases: /ipb)*
- /report
- /unregister *(Aliases: /register)*
- /whowas

### shader_snow_ground
- /groundsnow

### sittablechairs
- /stand

### snakecam
- /snakecam

### snow
- /sdensity *(Aliases: /swspeed, /salpha, /swdir)*
- /snowsettings *(Aliases: /ssettings, /snowhelp, /shelp)*
- /ssize *(Aliases: /snow)*

### spike-system
- /removespikes
- /throwspikes

### staff_manager
- /staffs

### sweeper
- /dumpload
- /startjob

### tag-system
- /delnearbytag
- /nearbytags

### teleport.lua:addCommandHandler("setyz", setYZ)advertisements
- /ads

### toll
- /toll
- /tolllock

### weapon
- /getmode
- /updatelocalguns

### weather-system
- /eta
- /etanow
- /getweather
- /resetfw *(Aliases: /setfw, /fw)*
- /sf
- /shh
- /srl
- /st
- /sw
- /swb
- /swh
- /swl
- /swr
- /swv

### widgets
- /report

### xmas
- /fixsanta
- /forcesanta
- /howlongsanta

