// Copyright (c) 2015 Electric Imp
// This file is licensed under the MIT License
// http://opensource.org/licenses/MIT

// AJAX LED Example - agent code

//////////////////////  ROCKY SETUP  //////////////////////////

#require "Rocky.class.nut:1.0.0"
app <- Rocky();


//////////////////  DEFAULT LED SETTINGS  /////////////////////

led <- {
    color = { red = 0, green = 0, blue = 0 },
    state = 1 //** If LED is cathode common this value will need to change
};


/////////////////////  AGENT DATA STORAGE  /////////////////////

//get settings stored on server
local serverSettings = server.load();

if ("led" in serverSettings) {
    //if server has a stored LED settings then update local settings
    led = serverSettings.led;
} else {
    //else store default settings to server
    server.save({"led" : led});
}

//store new settings locally and on the server
function updateLEDSettings(newSettings) {
    if ("color" in newSettings) led.color = newSettings.color;
    if ("state" in newSettings) led.state = newSettings.state;
    server.save({"led" : led});
}


/////////////////////  DEVICE LISTENER  ///////////////////////

//send device led settings
device.on("getSettings", function(dummy) {
    device.send("color", led.color);
    device.send("state", led.state);
});


//////////////////  ROCKY HTTP HANDELERS  /////////////////////

app.get("/color", function(context) {
    context.send(200, { color = led.color });
});

app.get("/state", function(context) {
    context.send(200, { state = led.state });
});

app.post("/color", function(context) {
    //convert JSON string to squirrel table
    local data = http.jsondecode(context.req.body)
    try {
        // Preflight check
        if (!("color" in data)) throw "Missing param: color";
        if (!("red" in data.color)) throw "Missing param: color.red";
        if (!("green" in data.color)) throw "Missing param: color.green";
        if (!("blue" in data.color)) throw "Missing param: color.blue";

        // if preflight check passed - do things
        device.send("color", data.color); //send color to device
        updateLEDSettings({"color" : data.color}); //update local & server

        // send the response
        context.send({ verb = "POST", color = data.color });
    } catch (ex) {
        context.send(400, ex);
        return;
    }
});

app.post("/state", function(context) {
    //convert JSON string to squirrel table
    local data = http.jsondecode(context.req.body)
    try {
        // Preflight check
        if (!("state" in data)) throw "Missing param: state";
    } catch (ex) {
        context.send(400, ex);
        return;
    }

    // if preflight check passed - do things
    device.send("state", data.state); //send state to device
    updateLEDSettings({"state" : data.state}); //update local & server

    // send the response
    context.send({ verb = "POST", state = led.state });

});