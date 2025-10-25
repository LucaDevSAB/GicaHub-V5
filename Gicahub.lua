// 🌌 Gica Auto-Pet Finder – Cloud-API für "Los Combinasion"
const express = require("express");
const app = express();
const port = 3000;

// 🔹 Gesuchtes Pet
const TARGET_PET = "Los Combinasion";
const TARGET_ALIASES = ["loscombinasion","los_combinasion","pet001"];

// 🔹 Key-Schutz – Jeder Nutzer bekommt seinen eigenen Key
const VALID_KEYS = ["Luca123","Anna456","Max789"];

// 🔹 Simulierte Server mit zufälliger Verteilung von Pets
const OTHER_PETS = ["GoldenDragon","FluffyCat","RainbowDog","MysticFox","MysticRabbit"];
function generateServers() {
    const servers = [];
    for(let i=1;i<=25;i++){
        let pets = [];
        if(Math.random()<0.15) pets.push(TARGET_PET);
        OTHER_PETS.forEach(pet=>{if(Math.random()<0.5) pets.push(pet)});
        servers.push({id:"server_"+i,pets:pets});
    }
    return servers;
}

// 🔹 Flexible Vergleichsfunktion für Target Pet
function matchTarget(pet){
    if(!pet) return false;
    const normalized = pet.toLowerCase().replace(/\s|_/g,"");
    if(normalized === TARGET_PET.toLowerCase().replace(/\s|_/g,"")) return true;
    for(const alias of TARGET_ALIASES){
        if(normalized===alias.toLowerCase()) return true;
    }
    return false;
}

// 🔹 API Endpoint
app.get("/checkPet",(req,res)=>{
    const queryPet = req.query.pet;
    const key = req.query.key;

    if(!key || !VALID_KEYS.includes(key)){
        return res.json({success:false,message:"❌ Ungültiger Key",found:false});
    }

    if(!matchTarget(queryPet)){
        return res.json({success:false,message:"❌ Nur Los Combinasion wird unterstützt",found:false});
    }

    const servers = generateServers();
    const foundServer = servers.find(s=>s.pets.includes(TARGET_PET));

    if(foundServer){
        console.log(`✅ ${TARGET_PET} gefunden auf ${foundServer.id}`);
        res.json({success:true,found:true,server:foundServer.id,message:`${TARGET_PET} gefunden auf ${foundServer.id}`});
    } else {
        console.log("🔁 Kein Treffer – Suche läuft weiter...");
        res.json({success:true,found:false,message:"Kein Server mit Los Combinasion gefunden"});
    }
});

// 🔹 Server starten
app.listen(port,"0.0.0.0",()=>{
    console.log(`🚀 API läuft auf http://localhost:${port}`);
    console.log(`🔹 Test: http://localhost:${port}/checkPet?pet=Los%20Combinasion&key=Luca123`);
});
