// Pafta panels for Kigae: one rail down the left edge, the sheet's margin. Runs after Kigae's
// prelude, which removed every panel and desktop widget and kept the dock's launchers in
// kigae.launchers. A 16:9 laptop has width to spare and height to save, so the panel stands up.
var rail = new Panel;
rail.location = "left";
rail.height = 48;          // thickness of a vertical panel
rail.floating = false;     // docked: it is the paper margin, flush with the screen edge
rail.hiding = "none";
rail.lengthMode = "fill";

var kickoff = rail.addWidget("org.kde.plasma.kickoff");
kickoff.currentConfigGroup = ["General"];
kickoff.writeConfig("icon", "pafta-north");
kickoff.writeConfig("compactMode", true);
kickoff.writeConfig("showActionButtonCaptions", false);

var tasks = rail.addWidget("org.kde.plasma.icontasks");
tasks.currentConfigGroup = ["General"];
tasks.writeConfig("launchers", kigae.launchers);
tasks.writeConfig("iconSpacing", 1);
tasks.writeConfig("maxStripes", 1);
tasks.writeConfig("indicateAudioStreams", true);

rail.addWidget("org.kde.plasma.panelspacer");
var tray = rail.addWidget("org.kde.plasma.systemtray");
rail.addWidget("org.pafta.railclock");

kigae.tray(tray, { General: { hiddenItems: ["Xwayland Video Bridge", "chrome_status_icon_1@brave", "org.kde.plasma.brightness", "org.kde.plasma.clipboard", "Easy Effects", "org.kde.kdeconnect"] } });

// the title block, in the corner the print leaves for it. The desktop shifts x by +64 and snaps
// to a 16px grid: this lands the box 25px inside the frame's inner rule on both sides (1920x1080)
kigae.desktop("org.pafta.legend", 1456, 768, 340, 256);
