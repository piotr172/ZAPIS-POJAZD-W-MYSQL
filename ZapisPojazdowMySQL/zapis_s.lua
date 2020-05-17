--@author:piotr172 

local SQL_LOGIN=""  --login do bazy danych
local SQL_PASSWD=""  --hasło do bazy danych
local SQL_DB=""  --baza danych
local SQL_HOST=""  --host bazy danych
local SQL_PORT=tonumber(get("port") or 3306)  --port(standardowo 3306)
local root = getRootElement()

local SQL

local function connect()  --łączy z bazą danych
	SQL = mysql_connect(SQL_HOST, SQL_LOGIN, SQL_PASSWD, SQL_DB, SQL_PORT)
	if (not SQL) then
		outputServerLog("BRAK POLACZENIA Z BAZA DANYCH!")
	else
		mysql_query(SQL,"SET NAMES utf8")
	end

end

addEventHandler("onResourceStart",getResourceRootElement(),function()  --po właczeniu skryptu wysyła do funkcji która łaczy się z bazą danych
	connect()
end)

function esc(value)
	return mysql_escape_string(SQL,value)
end

function pobierzTabeleWynikow(query)
	local result=mysql_query(SQL,query)
	if (not result) then 
		outputDebugString("mysql_query failed: (" .. mysql_errno(SQL) .. ") " .. mysql_error(SQL)) -- Show the reason
		return nil 
	end
	local tabela={}
	for result,row in mysql_rows_assoc(result) do
		table.insert(tabela,row)
	end
	mysql_free_result(result)
	return tabela
end

function pobierzWyniki(query)
	local result=mysql_query(SQL,query)
	if (not result) then return nil end
	row = mysql_fetch_assoc(result)
	mysql_free_result(result)
	return row
end


function zapytanie(query)
	local result=mysql_query(SQL,query)
	if (result) then mysql_free_result(result) end
	return
end

function insertID()
	return mysql_insert_id(SQL)
end

--pobiera pojazdy z bazy danych i wysyła dane do funkcji tworzącej pojazdy
function veh_init()
    local pojazdy=pobierzTabeleWynikow("select id,wlasciciel,model,xyz,rot,frozen,hp,ca,cb,cc,przebieg,paliwo,upgrades,wheelstates,opis,panelstates,doorstate from auta")
    for i,v in ipairs(pojazdy) do
	veh_create(v)
    end
end


--tworzenie pojazdu
function veh_create(v)
	v.xyz=split(v.xyz,",")
	v.rot=split(v.rot,",")
	local veh = createVehicle(v.model, v.xyz[1], v.xyz[2], v.xyz[3])  --tworzy pojazd na kordach odczytanych z bazy
	setElementRotation(veh, v.rot[1],v.rot[2], v.rot[3]) --nadaje rotacje
	setVehicleColor(veh, v.ca, v.cb, v.cc) --nadaje kolor 
	setElementHealth(veh,v.hp) --nadaje hp
	setElementData(veh, "pojazd_id", v.id) --nadaje date odpowiedzialną za ID pojazdu
	setElementData(veh, "pojazd_owner", v.wlasciciel) --nadaje date odpowiedzialną własciciela pojazdu
	setElementData(veh, "pojazd_paliwo", v.paliwo or 50) --nadaje date odpowiedzialną za paliwo pojazdu
	setElementData(veh, "pojazd_przebieg", v.przebieg or 0) --nadaje date odpowiedzialną za przebieg pojazdu
	if (v.opis and type(v.opis)=="string") then
	    setElementData(veh,"pojazd_opis", v.opis) --nadaje date odpowiedzialną za opis pojazdu
	end
	setVehicleEngineState ( veh, false )
	setElementFrozen(veh, tonumber(v.frozen)>0) 
	--koła
	v.wheelstates=split(v.wheelstates,",")
	setVehicleWheelStates(veh, unpack(v.wheelstates))
	--uszkodzone czesci
	if (v.panelstates~="0,0,0,0,0,0,0") then
    	v.panelstates=split(v.panelstates,",")
		for i,v in ipairs(v.panelstates) do
		  setVehiclePanelState(veh,i-1, tonumber(v))
		end
	else
    	v.panelstates=split(v.panelstates,",")
	end
	--uszkodzone drzwi
		if (v.doorstate~="0,0,0,0,0,0,0") then
    	v.doorstate=split(v.doorstate,",")
		for i,v in ipairs(v.doorstate) do
		  setVehicleDoorState(veh,i-1, tonumber(v))
		end
	else
    	v.doorstate=split(v.doorstate,",")
	end
	--tuning
	if (v.upgrades and type(v.upgrades)=="string") then
		v.upgrades=split(v.upgrades,",")
		for i,v in ipairs(v.upgrades) do
			addVehicleUpgrade(veh, tonumber(v))
		end
	end
	end

	
--sprawda czy gracz jest włascicielem pojazdu
function StartEnter(player, seat, jacked)
  if seat == 0 then
  local pojazd_owner = getElementData(source, "pojazd_owner")
  local account = getPlayerAccount(player)
  local name = getAccountName(account)
	if not (pojazd_owner and account and name == pojazd_owner) then
	outputChatBox("Nie masz kluczyków do tego pojazdu.", player, 255, 255, 255, true)
	cancelEvent()
	end
  end
end
addEventHandler ("onVehicleStartEnter", resourceRoot, StartEnter)


--zapis pojazdu
function veh_save(vehicle)
    local id=getElementData(vehicle, "pojazd_id") --sprawdza id pojazdu
	if id then  --gdy auto posiada ID skrypt leci dalej i zapisuje pojazd
    local x,y,z=getElementPosition(vehicle) --sprawdza kordy pojazdu
    local rx,ry,rz=getElementRotation(vehicle) --sprawdza rotacje pojazdu
    local hp=getElementHealth(vehicle) --sprawdza hp pojazdu
	local wlasciciel=getElementData(vehicle,"pojazd_owner") --sprawdza date odpowiedzialną za wlasciciela(czy nie zmienił się on)
	local paliwo=getElementData(vehicle,"pojazd_paliwo") --sprawdza date odpowiedzialną za paliwo
	local przebieg=getElementData(vehicle,"pojazd_przebieg") or 0 --sprawdza date odpowiedzialną za przebieg
	local frozen= isElementFrozen(vehicle) and 1 or 0 --sprawdza czy pojazd jest na recznym(zamrozony)
	local opis=getElementData(vehicle,"pojazd_opis") --sprawdza date odpowiedzialną za opis
	if (opis and string.len(opis)>=3) then 
	    opis='' .. esc(opis) .. ''
	else
	    opis=""
	end
	
    local wheelstates=table.concat({getVehicleWheelStates(vehicle)},",") --sprawdza stan kół
	--sprawdza stan czesci pojazdu
	local panelstates={}
	for i=0,6 do
	  table.insert(panelstates, getVehiclePanelState(vehicle,i))
	end
	panelstates=table.concat(panelstates,",")
	--sprawdza stan drzwi pojazdu
	local doorstate={}
	for i=0,5 do
	  table.insert(doorstate, getVehicleDoorState(vehicle,i))
	end
	doorstate=table.concat(doorstate,",")
	local ca,cb,cc = getVehicleColor(vehicle,true) --sprawdza kolor pojazdu
	--sprawdza tuning pojazdu
	local vehUpgrades=getVehicleUpgrades(vehicle)
	if not vehUpgrades then vehUpgrades={} end
	local upgrades=esc(table.concat(vehUpgrades,","))
	-- zapisuje pojazd do bazy danych
    local query=string.format("UPDATE auta SET przebieg='%.2f',wlasciciel='%s',upgrades='%s',xyz='%.2f,%.2f,%.2f',rot='%.2f,%.2f,%.2f',hp='%d',frozen='%d',ca='%d',cb='%d',cc='%d',wheelstates='%s',panelstates='%s',doorstate='%s',opis='%s',paliwo='%.3f' WHERE id='%d'",
	przebieg,wlasciciel,upgrades,x,y,z,rx,ry,rz,hp, frozen,
	ca,cb,cc,esc(wheelstates), esc(panelstates),esc(doorstate), opis,paliwo,id)
	zapytanie(query)
end
end

--pobiera wszytskie pojazdy z mapy i wysyła ich dane do funkcji zapisujacej pojazdy
function veh_saveall()
    local pojazdy=getElementsByType("vehicle",resourceRoot)
    for i,v in ipairs(pojazdy) do
	veh_save(v)
    end
end
setTimer(veh_saveall, 5*60*1000, 0) --timer zapisuje co 5 minut wszystkie pojazdy z mapy(5=co ile minut zapis)

--komenda do zapisu pojazdu
function zapiszveh(plr)
local acc = getAccountName (getPlayerAccount(plr))
    if isObjectInACLGroup ("user."..acc, aclGetGroup ("Admin")) then
	veh_saveall()
	outputChatBox("** Zapisano pojazdy.", plr, 255, 255, 255, true)
	end
end
addCommandHandler("zapiszpojazdy", zapiszveh)

addEventHandler("onResourceStart",resourceRoot, veh_init)  --po starcie skryptu tworzy pojazdy na mapie
addEventHandler("onResourceStop",resourceRoot, veh_saveall)  --po zatrzymaniu skryptu tworzy pojazdy na mapie

-- zapisuje pojazd z którego wyszedł gracz( nie wszytskie tylko ten jeden pojazd)
addEventHandler("onVehicleExit", resourceRoot, function(plr,seat)
	if (seat==0) then
	    setVehicleEngineState ( source, false )
	end
	veh_save(source)
    end)

--komenda tworzenia nowych pojazdów do bazy danych(tworzy na mapie oraz od razu zapisuje do bazy)
function stworzveh(player, cmd, model, wlasciciel)
local acc = getAccountName (getPlayerAccount(player))
	local model = tonumber(model)
        if model and wlasciciel then
		    if isObjectInACLGroup ("user."..acc, aclGetGroup ("Admin")) then
                local x, y, z = getElementPosition(player)
                local rx, ry, rz = getElementRotation(player)
                local veh = createVehicle(model, x, y, z)
				setVehicleColor(veh, 16777215, 16777215, 16777215) 
				setElementPosition(player,x,y,z+2)
				local id=insertID()
				local query=string.format("INSERT INTO auta SET id='%d',model='%d', wlasciciel='%s',xyz='%.2f,%.2f,%.2f',rot='0,0,0',frozen='1'",
				id,model,wlasciciel,x,y,z)
				zapytanie(query)
				setElementFrozen(veh,true)
				setVehicleEngineState(veh,false)
				setElementData(veh,"pojazd_id",id)
				setElementData(veh,"pojazd_paliwo", 100)
				setElementData(veh,"pojazd_przebieg", 0)
				setElementData(veh,"pojazd_owner", wlasciciel)
				setElementData(veh,"pojazd_opis", "")
			end
        else
        outputChatBox("Wpisz /stworz [id-pojazdu] [wlasciciel]", player, 255, 255, 255, true)
        end
	end

addCommandHandler("stworzpojazd", stworzveh)