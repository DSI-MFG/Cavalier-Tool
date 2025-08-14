var dsiDebug = false;

/*///////////////////////////////////////////////////////////////////////////////////////////////

                          ──────────────────────────────────────────
                          ─████████████───██████████████─██████████─
                          ─██        ████─██          ██─██      ██─
                          ─██  ████    ██─██  ██████████─████  ████─
                          ─██  ██──██  ██─██  ██───────────██  ██───
                          ─██  ██──██  ██─██  ██████████───██  ██───
                          ─██  ██──██  ██─██          ██───██  ██───
                          ─██  ██──██  ██─██████████  ██───██  ██───
                          ─██  ██──██  ██─────────██  ██───██  ██───
                          ─██  ████    ██─██████████  ██─████  ████─
                          ─██        ████─██          ██─██      ██─
                          ─████████████───██████████████─██████████─
                          ──────────────────────────────────────────
///////////////////////////////////////////////////////////////////////////////////////////////*/
// DSI: Post Header

customer = "Cavalier Tool"; // customer name
oem = "OKUMA"; // oem name
model = "LB3000MYW"; // model number
control = "OPS300"; // control name
vendor = "DSI";
vendorUrl = "http://www.dsi-mfg.com";
legal = "Copyright (C) 2012-2025 by Autodesk, Inc.";
certificationLevel = 2;
minimumRevision = 45917; // Minimum post kernel revision
dsiPostVersion = "1.0"; // DSI post version
//***************************

postDescription = [oem, model].join(" "); // post description
longDescription = [
  postDescription,
  "Post Processor with",
  control,
  "Control",
].join(" "); // long description

///////////////////////////////////////////////////////////////////////////////////////////////

///////////////////////////////////////////////////////////////////////////////
//                        MANUAL NC COMMANDS
//
// The following ACTION commands are supported by this post.
//
//     partEject                  - Manually eject the part
//     usePolarInterpolation      - Force Polar interpolation mode for next operation (usePolarMode is deprecated but still supported)
//     usePolarCoordinates        - Force Polar coordinates for the next operation (useXZCMode is deprecated but still supported)
//
///////////////////////////////////////////////////////////////////////////////

extension = "min";
programNameIsInteger = false;
setCodePage("ascii");

capabilities = CAPABILITY_MILLING | CAPABILITY_TURNING;
tolerance = spatial(0.002, MM);

minimumChordLength = spatial(0.25, MM);
minimumCircularRadius = spatial(0.01, MM);
maximumCircularRadius = spatial(1000, MM);
minimumCircularSweep = toRad(0.01);
maximumCircularSweep = toRad(90); // reduced sweep to break up circular moves on quadrant boundaries
allowHelicalMoves = true;
allowedCircularPlanes = undefined; // allow any circular motion
allowSpiralMoves = false;
allowFeedPerRevolutionDrilling = true;
highFeedrate = unit == IN ? 100 : 2500;

// user-defined properties
properties = {
  safeStartAllOperations: {
    title: "Safe start all operations",
    description: "Forces restart for all operations",
    group: "_customer",
    type: "boolean",
    value: true,
    scope: "post",
  },
  gotSecondarySpindle: {
    title: "Got secondary spindle",
    description: "Specifies if the machine has a secondary spindle.",
    group: "configuration",
    type: "boolean",
    value: true,
    scope: "post",
    visible: false,
  },
  xAxisMinimum: {
    title: "X-axis minimum limit",
    description: "Defines the lower limit of X-axis travel as a radius value.",
    group: "configuration",
    type: "spatial",
    range: [-99999, 0],
    value: 31,
    scope: "post",
    visible: false,
  },
  usePartCatcher: {
    title: "Use part catcher",
    description: "Specifies whether part catcher code should be output.",
    group: "configuration",
    type: "boolean",
    value: true,
    scope: "post",
  },
  gotChipConveyor: {
    title: "Got chip conveyor",
    description: "Specifies whether to use a chip conveyor.",
    group: "configuration",
    type: "boolean",
    presentation: "yesno",
    value: false,
    scope: "post",
  },
  maxTool: {
    title: "Max tool number",
    description: "Defines the maximum tool number.",
    group: "configuration",
    type: "integer",
    range: [0, 999999999],
    value: 12,
    scope: "post",
  },
  maxToolOffset: {
    title: "Max tool offset number",
    description: "Defines the maximum tool offset number.",
    group: "configuration",
    type: "integer",
    range: [0, 999999999],
    value: 96,
    scope: "post",
  },
  maximumSpindleSpeed: {
    title: "Max spindle speed",
    description: "Defines the maximum spindle speed allowed by your machines.",
    group: "configuration",
    type: "integer",
    range: [0, 999999999],
    value: 6000,
    scope: "post",
  },
  showSequenceNumbers: {
    title: "Use sequence numbers",
    description:
      "'Yes' outputs sequence numbers on each block, 'Only on tool change' outputs sequence numbers on tool change blocks only, and 'No' disables the output of sequence numbers.",
    group: "formats",
    type: "enum",
    values: [
      { title: "Yes", id: "true" },
      { title: "No", id: "false" },
      { title: "Only on tool change", id: "toolChange" },
    ],
    value: "toolChange",
    scope: "post",
  },
  sequenceNumberStart: {
    title: "Start sequence number",
    description: "The number at which to start the sequence numbers.",
    group: "formats",
    type: "integer",
    value: 1,
    scope: "post",
  },
  sequenceNumberIncrement: {
    title: "Sequence number increment",
    description:
      "The amount by which the sequence number is incremented by in each block.",
    group: "formats",
    type: "integer",
    value: 1,
    scope: "post",
  },
  useRadius: {
    title: "Radius arcs",
    description:
      "If yes is selected, arcs are outputted using radius values rather than IJK.",
    group: "preferences",
    type: "boolean",
    value: false,
    scope: "post",
  },
  useCycles: {
    title: "Use cycles",
    description: "Specifies if canned drilling cycles should be used.",
    group: "preferences",
    type: "boolean",
    value: true,
    scope: "post",
  },
  optionalStop: {
    title: "Optional stop",
    description:
      "Outputs optional stop code during when necessary in the code.",
    group: "preferences",
    type: "boolean",
    value: true,
    scope: "post",
  },
  useParametricFeed: {
    title: "Parametric feed",
    description:
      "Specifies the feed value that should be output using a Q value.",
    group: "preferences",
    type: "boolean",
    value: false,
    scope: "post",
  },
  autoEject: {
    title: "Auto eject",
    description:
      "Specifies whether the part should automatically eject at the end of a program.",
    group: "preferences",
    type: "boolean",
    value: false,
    scope: "post",
  },
  useTailStock: {
    title: "Use tailstock",
    description: "Specifies whether to use the tailstock or not.",
    group: "configuration",
    type: "boolean",
    presentation: "yesno",
    value: false,
    scope: "post",
  },
  homePositionX: {
    title: "X home position in radius",
    description: "X home position specified in radius.",
    group: "homePositions",
    type: "spatial",
    value: 20,
    scope: "post",
  },
  homePositionY: {
    title: "Y home position",
    description: "Y home position.",
    group: "homePositions",
    type: "spatial",
    value: 0,
    scope: "post",
  },
  homePositionZ: {
    title: "Z home position",
    description: "Z home position.",
    group: "homePositions",
    type: "spatial",
    value: 5,
    scope: "post",
  },
  homePositionW: {
    title: "W home position",
    description: "W home position.",
    group: "homePositions",
    type: "spatial",
    value: 30,
    scope: "post",
  },
  mainZHome: {
    title: "Main spindle VSZOZ",
    description: "The initial VSZOZ position for the main spindle",
    group: "_customer",
    type: "spatial",
    value: 13.4765,
    scope: "post",
  },
  subZHome: {
    title: "Sub spindle VSZOZ",
    description: "The initial VSZOZ position for the sub spindle",
    group: "_customer",
    type: "spatial",
    value: 13.4765,
    scope: "post",
  },
  transferUseTorque: {
    title: "Stock-transfer torque control",
    description: "Use torque control for stock transfer.",
    group: "preferences",
    type: "boolean",
    value: false,
    scope: "post",
  },
  optimizeCAxisSelect: {
    title: "Optimize C axis selection",
    description: "Optimizes the output of enable/disable C-axis codes.",
    group: "preferences",
    type: "boolean",
    value: false,
    scope: "post",
  },
  useSimpleThread: {
    title: "Use simple threading cycle",
    description:
      "Enable to output G33 simple threading cycle, disable to output G71 standard threading cycle.",
    group: "preferences",
    type: "boolean",
    value: false,
    scope: "post",
  },
  useYAxisForDrilling: {
    title: "Position in Y for axial drilling",
    description:
      "Positions in Y for axial drilling options when it can instead of using the C-axis.",
    group: "preferences",
    type: "boolean",
    value: false,
    scope: "post",
  },
  separateWordsWithSpace: {
    title: "Separate words with space",
    description: "Adds spaces between words if 'yes' is selected.",
    group: "formats",
    type: "boolean",
    value: true,
    scope: "post",
  },
  showNotes: {
    title: "Show notes",
    description: "Writes operation notes as comments in the outputted code.",
    group: "formats",
    type: "boolean",
    value: false,
    scope: "post",
  },
  writeTools: {
    title: "Write tool list",
    description: "Output a tool list in the header of the code.",
    group: "formats",
    type: "boolean",
    value: true,
    scope: "post",
  },
  useShortestDirection: {
    title: "Use C-axis shortest direction code",
    description:
      "Specifies that an M960 should be used to control the C-axis direction instead of the M15/M16 directional codes.",
    group: "multiAxis",
    type: "boolean",
    value: false,
    scope: "post",
  },
  loadMonitoring: {
    title: "Load monitoring",
    description:
      "A value that enables which axes should be monitored.  1 = X, 2 = Z, 3 = XZ, etc.",
    group: "preferences",
    type: "integer",
    range: [0, 1013],
    value: 0,
    scope: "post",
  },
};

// wcs definiton
wcsDefinitions = {
  useZeroOffset: false,
  wcs: [{ name: "Standard", format: "#", range: [1, 1] }],
};

var singleLineCoolant = false; // specifies to output multiple coolant codes in one line rather than in separate lines
// samples:
// {id: COOLANT_THROUGH_TOOL, on: 88, off: 89}
// {id: COOLANT_THROUGH_TOOL, on: [8, 88], off: [9, 89]}
// {id: COOLANT_THROUGH_TOOL, turret1:{on: [8, 88], off:[9, 89]}, turret2:{on:88, off:89}}
// {id: COOLANT_THROUGH_TOOL, spindle1:{on: [8, 88], off:[9, 89]}, spindle2:{on:88, off:89}}
// {id: COOLANT_THROUGH_TOOL, spindle1t1:{on: [8, 88], off:[9, 89]}, spindle1t2:{on:88, off:89}}
// {id: COOLANT_THROUGH_TOOL, on: "M88 P3 (myComment)", off: "M89"}
var coolants = [
  { id: COOLANT_FLOOD, on: 8 },
  { id: COOLANT_MIST },
  { id: COOLANT_THROUGH_TOOL, on: 143, off: 142 },
  {
    id: COOLANT_AIR,
    spindle1: { on: 51, off: 50 },
    spindle2: { on: 288, off: 289 },
  },
  { id: COOLANT_AIR_THROUGH_TOOL },
  { id: COOLANT_SUCTION },
  { id: COOLANT_FLOOD_MIST },
  { id: COOLANT_FLOOD_THROUGH_TOOL },
  { id: COOLANT_OFF, off: 9 },
];

var permittedCommentChars = " ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789.,=_-/";
var mainSpindleAxisName = ["SP=", 1]; // axis name, axis number (number is used for eg. SETMS(VALUE));
var subSpindleAxisName = ["SP=", 2]; // axis name, axis number (number is used for eg. SETMS(VALUE));
//var liveToolSpindleAxisName = ["C1", 1]; // axis name, axis number (number is used for eg. SETMS(VALUE));

var gFormat = createFormat({ prefix: "G", decimals: 0 });
var mFormat = createFormat({ prefix: "M", decimals: 0 });
var spatialFormat = createFormat({
  decimals: unit == MM ? 3 : 4,
  type: FORMAT_REAL,
});
var integerFormat = createFormat({ decimals: 0 });
var xFormat = createFormat({
  decimals: unit == MM ? 3 : 4,
  type: FORMAT_REAL,
  scale: 2,
}); // diameter mode
var yFormat = createFormat({ decimals: unit == MM ? 3 : 4, type: FORMAT_REAL });
var zFormat = createFormat({ decimals: unit == MM ? 3 : 4, type: FORMAT_REAL });
var rFormat = createFormat({ decimals: unit == MM ? 3 : 4, type: FORMAT_REAL }); // radius
var abcFormat = createFormat({ decimals: 3, type: FORMAT_REAL, scale: DEG });
var bFormat = createFormat({
  prefix: "(B=",
  suffix: ")",
  decimals: 3,
  type: FORMAT_REAL,
  scale: DEG,
});
var cFormat = createFormat({ decimals: 3, type: FORMAT_REAL, scale: DEG });
var fpmFormat = createFormat({
  decimals: unit == MM ? 2 : 3,
  type: FORMAT_REAL,
});
var fprFormat = createFormat({
  type: FORMAT_REAL,
  decimals: unit == MM ? 3 : 4,
  minimum: unit == MM ? 0.001 : 0.0001,
});
var feedFormat = fpmFormat;
var pitchFormat = createFormat({ decimals: 6, type: FORMAT_REAL });
var toolFormat = createFormat({ decimals: 0, minDigitsLeft: 4 });
var tool1Format = createFormat({ decimals: 0, minDigitsLeft: 6 });
var rpmFormat = createFormat({ decimals: 0 });
var secFormat = createFormat({ decimals: 2, type: FORMAT_REAL }); // seconds - range 0.001-99999.999
var dwellFormat = createFormat({ prefix: "F", decimals: 2, type: FORMAT_REAL }); // seconds - range 0.001-99999.999
var taperFormat = createFormat({ decimals: 1, scale: DEG });
var oFormat = createFormat({ decimals: 0, minDigitsLeft: 4 });
var natFormat = createFormat({ minDigitsLeft: 2, prefix: "NAT" });

var xOutput = createOutputVariable({ prefix: "X" }, xFormat);
var yOutput = createOutputVariable({ prefix: "Y" }, yFormat);
var zOutput = createOutputVariable({ prefix: "Z" }, zFormat);
var wOutput = createOutputVariable({ prefix: "W" }, zFormat);
var aOutput = createOutputVariable({ prefix: "A" }, abcFormat);
var bOutput = createOutputVariable({}, bFormat);
var cOutput = createOutputVariable({ prefix: "C", cyclicLimit: 360 }, cFormat);
var feedOutput = createOutputVariable({ prefix: "F" }, feedFormat);
var pitchOutput = createOutputVariable(
  { prefix: "F", control: CONTROL_FORCE },
  pitchFormat
);
var sOutput = createOutputVariable(
  { prefix: "S", control: CONTROL_FORCE },
  rpmFormat
);
var sbOutput = createOutputVariable(
  { prefix: "SB=", control: CONTROL_FORCE },
  rpmFormat
);
var maxSpeedOutput = createOutputVariable(
  { prefix: "S", control: CONTROL_FORCE },
  rpmFormat
);
var eOutput = createOutputVariable(
  { prefix: "E", control: CONTROL_FORCE },
  secFormat
);
var rOutput = createOutputVariable(
  { prefix: "R", control: CONTROL_FORCE },
  rFormat
);

// circular output
var iOutput = createOutputVariable(
  { prefix: "I", control: CONTROL_NONZERO },
  spatialFormat
);
var jOutput = createOutputVariable(
  { prefix: "J", control: CONTROL_NONZERO },
  spatialFormat
);
var kOutput = createOutputVariable(
  { prefix: "K", control: CONTROL_NONZERO },
  spatialFormat
);

var gMotionModal = createOutputVariable({}, gFormat); // modal group 1 // G0-G3, ...
var gPlaneModal = createOutputVariable(
  {
    onchange: function () {
      gMotionModal.reset();
    },
  },
  gFormat
); // modal group 2 // G17-19
var gFeedModeModal = createOutputVariable({}, gFormat); // modal group 5 // G98-99
var gSpindleModeModal = createOutputVariable({}, gFormat); // modal group 5 // G96-97
var gSpindleModal = createOutputVariable({}, mFormat); // M176/177 SPINDLE MODE
var gAbsIncModal = createOutputVariable({}, gFormat); // modal group 6 // G90-91
var gCycleModal = createOutputVariable({}, gFormat); // modal group 9 // G81, ...
var gPolarModal = createOutputVariable({}, gFormat); // G137, G136
var gYaxisModal = createOutputVariable({}, gFormat);
var cAxisBrakeModal = createOutputVariable({}, mFormat);
var mInterferModal = createOutputVariable({}, mFormat);
var cAxisEngageModal = createOutputVariable({}, mFormat);
var cAxisDirectionModal = createOutputVariable({}, mFormat);
var gSelectSpindleModal = createOutputVariable({}, gFormat);
var tailStockModal = createOutputVariable({}, mFormat);

// fixed settings
var firstFeedParameter = 100;
var airCleanChuck = true; // use air to clean off chuck at part transfer and part eject

// defined in defineMachine
var turret1GotYAxis;
var turret2GotYAxis;
var turret1GotBAxis;
var gotYAxis;
var yAxisMinimum;
var yAxisMaximum;
var xAxisMinimum;
var gotBAxis;
var bAxisIsManual;
var gotMultiTurret;
var gotPolarInterpolation;
var gotSecondarySpindle;
var gotDoorControl;
var maximumSpindleSpeedLive;

var WARNING_TURRET_UNSPECIFIED = 0;

var SPINDLE_MAIN = 0;
var SPINDLE_SUB = 1;
var SPINDLE_LIVE = 2;

var POSX = 0;
var POXY = 1;
var POSZ = 2;
var NEGZ = -2;

var TRANSFER_PHASE = 0;
var TRANSFER_SPEED = 1;
var TRANSFER_STOP = 2;

// getSpindle parameters
var TOOL = false;
var PART = true;

// collected state
var sequenceNumber;
var currentWorkOffset;
var optionalSection = false;
var forceSpindleSpeed = false;
var activeMovements; // do not use by default
var currentFeedId;
var previousSpindle = SPINDLE_MAIN;
var activeSpindle = SPINDLE_MAIN;
var partCutoff = false;
var reverseTap = false;
var showSequenceNumbers;
var forcePolarCoordinates = false; // forces Polar coordinates output, activated by Action:usePolarCoordinates
var forcePolarInterpolation = false; // force Polar interpolation, activated by Action:usePolarInterpolation
var tapping = false;
var ejectRoutine = false;
var bestABC = undefined;
var lastSpindleMode = undefined;
var lastSpindleSpeed = 0;
var lastSpindleDirection = undefined;
var operationNeedsSafeStart = false; // used to convert blocks to optional for safeStartAllOperations
var vlmon; // load monitoring variable
var previousMaximumSpeed = 0;
var tempSpindle = undefined;

var machineState = {
  isTurningOperation: undefined,
  liveToolIsActive: undefined,
  cAxisIsEngaged: undefined,
  machiningDirection: undefined,
  mainSpindleIsActive: undefined,
  subSpindleIsActive: undefined,
  mainSpindleBrakeIsActive: undefined,
  subSpindleBrakeIsActive: undefined,
  tailstockIsActive: false,
  usePolarInterpolation: false,
  usePolarCoordinates: false,
  axialCenterDrilling: false,
  currentBAxisOrientationTurning: new Vector(0, 0, 0),
  mainChuckIsClamped: undefined,
  subChuckIsClamped: undefined,
  spindlesAreAttached: false,
  spindlesAreSynchronized: false,
  stockTransferIsActive: false,
  cAxesAreSynchronized: false,
  feedPerRevolution: undefined,
};

/** G/M codes setup */
function getCode(code, spindle) {
  switch (code) {
    case "PART_CATCHER_ON":
      return 77;
    case "PART_CATCHER_OFF":
      return 76;
    case "TAILSTOCK_ON":
      machineState.tailstockIsActive = true;
      return 21;
    case "TAILSTOCK_OFF":
      machineState.tailstockIsActive = false;
      return 20;
    case "SET_SPINDLE_FRAME":
      break;
    case "ENABLE_Y_AXIS":
      setRadiusDiameterMode("radius");
      return 138;
    case "DISABLE_Y_AXIS":
      setRadiusDiameterMode("diameter");
      return 136;
    case "ENABLE_C_AXIS":
      machineState.cAxisIsEngaged = true;
      return 110;
    case "DISABLE_C_AXIS":
      machineState.cAxisIsEngaged = false;
      return 109;
    case "POLAR_INTERPOLATION_ON":
      return 137;
    case "POLAR_INTERPOLATION_OFF":
      return 136;
    case "ENABLE_MILLING":
      return 271;
    case "ENABLE_TURNING":
      return 270;
    case "STOP_SPINDLE":
      switch (spindle) {
        case SPINDLE_MAIN:
          machineState.mainSpindleIsActive = false;
          return 5;
        case SPINDLE_SUB:
          machineState.subSpindleIsActive = false;
          return 5;
        case SPINDLE_LIVE:
          machineState.liveToolIsActive = false;
          return 12;
      }
      break;
    case "ORIENT_SPINDLE":
      return spindle == SPINDLE_MAIN ? 19 : 239;
    case "START_SPINDLE_CW":
      switch (spindle) {
        case SPINDLE_MAIN:
          machineState.mainSpindleIsActive = true;
          machineState.subSpindleIsActive = false;
          machineState.liveToolIsActive = false;
          return 3;
        case SPINDLE_SUB:
          machineState.mainSpindleIsActive = false;
          machineState.subSpindleIsActive = true;
          machineState.liveToolIsActive = false;
          return 3;
        case SPINDLE_LIVE:
          machineState.mainSpindleIsActive = false;
          machineState.subSpindleIsActive = false;
          machineState.liveToolIsActive = true;
          return 13;
      }
      break;
    case "START_SPINDLE_CCW":
      switch (spindle) {
        case SPINDLE_MAIN:
          machineState.mainSpindleIsActive = true;
          machineState.subSpindleIsActive = false;
          machineState.liveToolIsActive = false;
          return 4;
        case SPINDLE_SUB:
          machineState.mainSpindleIsActive = false;
          machineState.subSpindleIsActive = true;
          machineState.liveToolIsActive = false;
          return 4;
        case SPINDLE_LIVE:
          machineState.mainSpindleIsActive = false;
          machineState.subSpindleIsActive = false;
          machineState.liveToolIsActive = true;
          return 14;
      }
      break;
    case "FEED_MODE_UNIT_REV":
      machineState.feedPerRevolution = true;
      return 95;
    case "FEED_MODE_UNIT_MIN":
      machineState.feedPerRevolution = false;
      return 94;
    case "CONSTANT_SURFACE_SPEED_ON":
      return 96;
    case "CONSTANT_SURFACE_SPEED_OFF":
      return 97;
    case "AUTO_AIR_ON":
      break;
    case "AUTO_AIR_OFF":
      break;
    case "LOCK_MULTI_AXIS":
      return 147;
    case "UNLOCK_MULTI_AXIS":
      return 146;
    case "C_AXIS_CW":
      return 15;
    case "C_AXIS_CCW":
      return 16;
    case "CLAMP_CHUCK":
      return spindle == SPINDLE_MAIN ? 83 : 248;
    case "UNCLAMP_CHUCK":
      return spindle == SPINDLE_MAIN ? 84 : 249;
    case "SPINDLE_SYNCHRONIZATION_PHASE":
      break;
    case "SPINDLE_SYNCHRONIZATION_SPEED":
      return 151;
    case "SPINDLE_SYNCHRONIZATION_OFF":
      return 150;
    case "IGNORE_SPINDLE_ORIENTATION":
      return 210;
    case "TORQUE_LIMIT_ON":
      return 29;
    case "TORQUE_LIMIT_OFF":
      return 28;
    case "TORQUE_SKIP_ON":
      return 22;
    case "SELECT_SPINDLE":
      switch (spindle) {
        case SPINDLE_MAIN:
          return 140;
        case SPINDLE_SUB:
          return 141;
      }
      break;
    case "RIGID_TAPPING":
      break;
    case "INTERNAL_INTERLOCK_ON":
      return spindle == SPINDLE_MAIN ? 185 : 247;
    case "INTERNAL_INTERLOCK_OFF":
      return spindle == SPINDLE_MAIN ? 184 : 246;
    case "INTERFERENCE_CHECK_OFF":
      break;
    case "INTERFERENCE_CHECK_ON":
      break;
    case "CYCLE_PART_EJECTOR":
      break;
    case "AIR_BLAST_ON":
      return spindle == SPINDLE_MAIN ? 51 : 288;
    case "AIR_BLAST_OFF":
      return spindle == SPINDLE_MAIN ? 50 : 289;
    default:
      error(localize("Command " + code + " is not defined."));
      return 0;
  }
  return 0;
}

/**  Returns the desired tolerance for the given section in MM.*/
function getTolerance() {
  var t1 = toPreciseUnit(tolerance, MM);
  var t2 = getParameter("operation:tolerance", t1);
  t1 = t1 > 0 ? Math.min(t1, t2) : t2;
  return unit == IN ? t1 * 25.4 : t1;
}

/**
  Outputs the C-axis direction code.
*/
function setCAxisDirection(previous, current) {
  if (!getProperty("useShortestDirection")) {
    var delta = current - previous;

    if ((delta < 0 && delta > -Math.PI) || delta > Math.PI) {
      writeBlock(
        cAxisDirectionModal.format(getCode("C_AXIS_CCW", getSpindle(PART)))
      );
    } else if (abcFormat.getResultingValue(delta) != 0) {
      writeBlock(
        cAxisDirectionModal.format(getCode("C_AXIS_CW", getSpindle(PART)))
      );
    }
  }
}

function formatSequenceNumber() {
  if (sequenceNumber > 99999) {
    sequenceNumber = getProperty("sequenceNumberStart");
  }
  var seqno = "N" + sequenceNumber;
  sequenceNumber += getProperty("sequenceNumberIncrement");
  return seqno;
}

/**
  Writes the specified block.
*/
function writeBlock() {
  var text = formatWords(arguments);
  if (!text) {
    return;
  }
  var seqno = "";
  var opskip = "";
  if (showSequenceNumbers == "true") {
    seqno = formatSequenceNumber();
  }
  if (optionalSection || skipBlocks) {
    opskip = "/";
  }

  if (text) {
    writeWords(opskip, seqno, text);
  }
  if (getProperty("showSequenceNumbers") == "toolChange") {
    showSequenceNumbers = "false";
  }
}

function formatComment(text) {
  return (
    "(" +
    String(
      filterText(String(text).toUpperCase(), permittedCommentChars)
    ).replace(/[()]/g, "") +
    ")"
  );
}

/**
  Output a comment.
*/
function writeComment(text) {
  writeln(formatComment(text));
}

function getB(abc, section) {
  if (section.spindle == SPINDLE_PRIMARY) {
    return abc.y;
  } else {
    return Math.PI - abc.y;
  }
}

function writeCommentSeqno(text) {
  writeln(formatSequenceNumber() + formatComment(text));
}

function formatTool(tool, cancelCompensation) {
  var compensationOffset = tool.isTurningTool()
    ? tool.compensationOffset
    : tool.lengthOffset;
  var toolNumber;
  var offset1;
  var offset2;
  if (cancelCompensation) {
    offset1 = 0;
    offset2 = 0;
  } else if (tool.isTurningTool()) {
    offset1 = compensationOffset;
    offset2 = compensationOffset;
  } else {
    offset1 = tool.diameterOffset;
    offset2 = tool.lengthOffset;
  }
  if (getProperty("maxToolOffset") > 99) {
    toolNumber =
      "T" + tool1Format.format(compensationOffset * 1000 + tool.number);
  } else {
    toolNumber =
      "T" + tool1Format.format(offset1 * 10000 + tool.number * 100 + offset2);
  }
  return toolNumber;
}

var skipBlocks = false;
function writeStartBlocks(isRequired, code) {
  var safeSkipBlocks = skipBlocks;
  if (!isRequired) {
    if (!getProperty("safeStartAllOperations", false)) {
      return; // when safeStartAllOperations is disabled, dont output code and return
    }
    // if values are not required, but safe start is enabled - write following blocks as optional
    skipBlocks = true;
  }
  code(); // writes out the code which is passed to this function as an argument
  skipBlocks = safeSkipBlocks; // restore skipBlocks value
}

function defineMachine() {
  gotSecondarySpindle = getProperty("gotSecondarySpindle");
  gotMultiTurret = false;
  turret1GotYAxis = true;
  turret2GotYAxis = false;
  yAxisMinimum = toPreciseUnit(-45, MM); // specifies the minimum range for the Y-axis
  yAxisMaximum = toPreciseUnit(70, MM); // specifies the maximum range for the Y-axis
  xAxisMinimum = getProperty("xAxisMinimum"); // specifies the maximum range for the X-axis (RADIUS MODE VALUE)
  gotBAxis = false; // B-axis always requires customization to match the machine specific functions for doing rotations
  bAxisIsManual = true; // B-axis is manually set and not programmable
  gotPolarInterpolation = true; // specifies if the machine has XY polar interpolation capabilities
  gotDoorControl = false;

  // define B-axis
  if (gotBAxis) {
    if (bAxisIsManual) {
      bFormat.setPrefix("(B=");
      bFormat.setSuffix(")");
      bOutput.setFormat(bFormat);
    } else {
      bFormat.setPrefix("B");
      bFormat.setSuffix("");
      bOutput.setFormat(bFormat);
    }
  }
}

function activateMachine(section) {
  // TCP setting
  operationSupportsTCP = false;

  // handle multiple turrets
  var turret = 1;
  if (gotMultiTurret) {
    turret = section.getTool().turret;
    if (turret == 0) {
      warningOnce(
        localize("Turret has not been specified. Using Turret 1 as default."),
        WARNING_TURRET_UNSPECIFIED
      );
      turret = 1; // upper turret as default
    }
    turret = turret == undefined ? 1 : turret;
    switch (turret) {
      case 1:
        gotYAxis = turret1GotYAxis;
        gotBAxis = turret1GotBAxis;
        break;
      case 2:
        gotYAxis = turret2GotYAxis;
        gotBAxis = false;
        break;
      default:
        error(subst(localize("Turret %1 is not supported"), turret));
        return turret;
    }
  } else {
    gotYAxis = turret1GotYAxis;
  }

  // disable unsupported rotary axes output
  if (!gotYAxis) {
    yOutput.disable();
  }
  aOutput.disable();

  // define machine configuration
  var bAxis;
  var cAxis;
  if (section.getSpindle() == SPINDLE_PRIMARY) {
    bAxis = createAxis({
      coordinate: 1,
      table: false,
      axis: [0, -1, 0],
      range: [-0.001, 90.001],
      preference: 0,
      tcp: true,
    });
    cAxis = createAxis({
      coordinate: 2,
      table: true,
      axis: [0, 0, 1],
      cyclic: true,
      range: [0, 360],
      preference: 0,
      tcp: operationSupportsTCP,
    });
  } else {
    bAxis = createAxis({
      coordinate: 1,
      table: false,
      axis: [0, -1, 0],
      range: [-0.001, 180.001],
      preference: 0,
      tcp: true,
    });
    cAxis = createAxis({
      coordinate: 2,
      table: true,
      axis: [0, 0, 1],
      cyclic: true,
      range: [0, 360],
      preference: 0,
      tcp: operationSupportsTCP,
    });
  }
  if (gotBAxis) {
    machineConfiguration = new MachineConfiguration(bAxis, cAxis);
    bOutput.enable();
  } else {
    machineConfiguration = new MachineConfiguration(cAxis);
    bOutput.disable();
  }

  // define spindle axis
  if (!gotBAxis || bAxisIsManual || turret == 2) {
    if (
      getMachiningDirection(section) == MACHINING_DIRECTION_AXIAL &&
      !section.isMultiAxis()
    ) {
      machineConfiguration.setSpindleAxis(new Vector(0, 0, 1));
    } else {
      machineConfiguration.setSpindleAxis(new Vector(1, 0, 0));
    }
  } else {
    machineConfiguration.setSpindleAxis(new Vector(1, 0, 0)); // set the spindle axis depending on B0 orientation
  }

  // define linear axes limits
  var xAxisMaximum = 10000; // don't check X-axis maximum limit
  yAxisMinimum = gotYAxis ? yAxisMinimum : 0;
  yAxisMaximum = gotYAxis ? yAxisMaximum : 0;
  var xAxis = createAxis({
    actuator: "linear",
    coordinate: 0,
    table: true,
    axis: [1, 0, 0],
    range: [xAxisMinimum, xAxisMaximum],
  });
  var yAxis = createAxis({
    actuator: "linear",
    coordinate: 1,
    table: true,
    axis: [0, 1, 0],
    range: [yAxisMinimum, yAxisMaximum],
  });
  var zAxis = createAxis({
    actuator: "linear",
    coordinate: 2,
    table: true,
    axis: [0, 0, 1],
    range: [-100000, 100000],
  });
  machineConfiguration.setAxisX(xAxis);
  machineConfiguration.setAxisY(yAxis);
  machineConfiguration.setAxisZ(zAxis);

  // enable retract/reconfigure
  safeRetractDistance = unit == IN ? 1 : 25; // additional distance to retract out of stock, can be overridden with a property
  safeRetractFeed = unit == IN ? 20 : 500; // retract feed rate
  safePlungeFeed = unit == IN ? 10 : 250; // plunge feed rate
  var stockExpansion = new Vector(
    toPreciseUnit(0.1, IN),
    toPreciseUnit(0.1, IN),
    toPreciseUnit(0.1, IN)
  ); // expand stock XYZ values
  machineConfiguration.enableMachineRewinds();
  machineConfiguration.setSafeRetractDistance(safeRetractDistance);
  machineConfiguration.setSafeRetractFeedrate(safeRetractFeed);
  machineConfiguration.setSafePlungeFeedrate(safePlungeFeed);
  machineConfiguration.setRewindStockExpansion(stockExpansion);

  // multi-axis feedrates
  machineConfiguration.setMultiAxisFeedrate(
    operationSupportsTCP ? FEED_FPM : FEED_FPM, // FEED_INVERSE_TIME,
    99999, // maximum output value for dpm feed rates
    DPM_COMBINATION, // INVERSE_MINUTES/INVERSE_SECONDS or DPM_COMBINATION/DPM_STANDARD
    0.5, // tolerance to determine when the DPM feed has changed
    unit == MM ? 1.0 : 1.0 // ratio of rotary accuracy to linear accuracy for DPM calculations
  );

  machineConfiguration.setVendor("OKUMA");
  machineConfiguration.setModel("LB3000");
  setMachineConfiguration(machineConfiguration);
  if (section.isMultiAxis()) {
    section.optimizeMachineAnglesByMachine(machineConfiguration, OPTIMIZE_AXIS);
  }

  return turret;
}

function onOpen() {
  if (getProperty("useRadius")) {
    maximumCircularSweep = toRad(90); // avoid potential center calculation errors for CNC
  }

  // Copy certain properties into global variables
  showSequenceNumbers = getProperty("showSequenceNumbers");

  // define machine
  defineMachine();
  turret1GotBAxis = gotBAxis;
  activeTurret = activateMachine(getSection(0));

  yOutput.disable();
  gPolarModal.format(getCode("DISABLE_Y_AXIS", true));

  if (highFeedrate <= 0) {
    error(
      localize(
        "You must set 'highFeedrate' because axes are not synchronized for rapid traversal."
      )
    );
    return;
  }

  if (!getProperty("separateWordsWithSpace")) {
    setWordSeparator("");
  }

  sequenceNumber = getProperty("sequenceNumberStart");

  // Select the active spindle
  if (getProperty("gotSecondarySpindle")) {
    writeBlock(
      gSelectSpindleModal.format(
        getCode("SELECT_SPINDLE", getSection(0).spindle)
      )
    ); // cannot use getSpindle since there is not an active section
  }
  writeBlock(
    gFormat.format(270),
    getSection(0).spindle == SPINDLE_MAIN ? "SP=1" : "SP=2"
  );
  writeBlock(
    gSelectSpindleModal.format(getCode("SELECT_SPINDLE", getSection(0).spindle))
  );
  gSelectSpindleModal.reset();
  writeBlock("CLEAR");
  writeBlock("DRAW");
  writeln("");
  if (programComment) {
    writeln(formatComment(programComment));
  }

  writeHeader();
  //writeBlock(gAbsIncModal.format(90), gCycleModal.format(80));
  //if (getProperty("useShortestDirection")) {
  //  writeBlock(mFormat.format(960));
  //}

  onCommand(COMMAND_CLOSE_DOOR);

  //if (getProperty("gotChipConveyor")) {
  //  onCommand(COMMAND_START_CHIP_TRANSPORT);
  //}
  var vszoz =
    getSection(0).spindle == SPINDLE_MAIN
      ? getProperty("mainZHome")
      : getProperty("subZHome");
  writeBlock("VSZOZ=", vszoz, formatComment("PART LOCATION"));

  var mTool = getSection(0).getTool();
  var maximumSpindleSpeed =
    mTool.maximumSpindleSpeed > 0
      ? Math.min(mTool.maximumSpindleSpeed, getProperty("maximumSpindleSpeed"))
      : getProperty("maximumSpindleSpeed");
  if (maximumSpindleSpeed > 0) {
    writeBlock(gFormat.format(50), maxSpeedOutput.format(maximumSpindleSpeed));
    previousMaximumSpeed = maximumSpindleSpeed;
    writeln("");
  }

  // automatically eject part at end of program
  if (getProperty("autoEject")) {
    ejectRoutine = true;
  }
}

function onComment(message) {
  writeComment(message);
}

/** Force output of X, Y, and Z. */
function forceXYZ() {
  xOutput.reset();
  yOutput.reset();
  zOutput.reset();
}

/** Force output of A, B, and C. */
function forceABC() {
  aOutput.reset();
  bOutput.reset();
  cOutput.reset();
}

function forceFeed() {
  currentFeedId = undefined;
  feedOutput.reset();
}

/** Force output of X, Y, Z, A, B, C, and F on next output. */
function forceAny() {
  forceXYZ();
  forceABC();
  forceFeed();
}

function forceUnlockMultiAxis() {
  cAxisBrakeModal.reset();
}

function forceModals() {
  if (arguments.length == 0) {
    // reset all modal variables listed below
    if (typeof gMotionModal != "undefined") {
      gMotionModal.reset();
    }
    if (typeof gPlaneModal != "undefined") {
      gPlaneModal.reset();
    }
    if (typeof gAbsIncModal != "undefined") {
      gAbsIncModal.reset();
    }
    if (typeof gFeedModeModal != "undefined") {
      gFeedModeModal.reset();
    }
  } else {
    for (var i in arguments) {
      arguments[i].reset(); // only reset the modal variable passed to this function
    }
  }
}

function FeedContext(id, description, feed) {
  this.id = id;
  this.description = description;
  this.feed = feed;
}

function formatFeedMode(mode) {
  var fMode =
    mode == FEED_PER_REVOLUTION || tapping
      ? getCode("FEED_MODE_UNIT_REV")
      : getCode("FEED_MODE_UNIT_MIN");
  if (fMode) {
    feedFormat = mode == FEED_PER_REVOLUTION ? fprFormat : fpmFormat;
    feedOutput.setFormat(feedFormat);
  }
  return gFeedModeModal.format(fMode);
}

function getFeed(f) {
  if (
    currentSection.feedMode != FEED_PER_REVOLUTION &&
    machineState.feedPerRevolution
  ) {
    f /= spindleSpeed;
  }
  if (activeMovements) {
    var feedContext = activeMovements[movement];
    if (feedContext != undefined) {
      if (!feedFormat.areDifferent(feedContext.feed, f)) {
        if (feedContext.id == currentFeedId) {
          return ""; // nothing has changed
        }
        forceFeed();
        currentFeedId = feedContext.id;
        return "F=V" + (firstFeedParameter + feedContext.id);
      }
    }
    currentFeedId = undefined; // force Q feed next time
  }
  return feedOutput.format(f); // use feed value
}

function initializeActiveFeeds() {
  activeMovements = new Array();
  var movements = currentSection.getMovements();
  var feedPerRev = currentSection.feedMode == FEED_PER_REVOLUTION;

  var id = 0;
  var activeFeeds = new Array();
  if (hasParameter("operation:tool_feedCutting")) {
    if (
      movements &
      ((1 << MOVEMENT_CUTTING) |
        (1 << MOVEMENT_LINK_TRANSITION) |
        (1 << MOVEMENT_EXTENDED))
    ) {
      var feedContext = new FeedContext(
        id,
        localize("Cutting"),
        feedPerRev
          ? getParameter("operation:tool_feedCuttingRel")
          : getParameter("operation:tool_feedCutting")
      );
      activeFeeds.push(feedContext);
      activeMovements[MOVEMENT_CUTTING] = feedContext;
      if (!hasParameter("operation:tool_feedTransition")) {
        activeMovements[MOVEMENT_LINK_TRANSITION] = feedContext;
      }
      activeMovements[MOVEMENT_EXTENDED] = feedContext;
    }
    ++id;
    if (movements & (1 << MOVEMENT_PREDRILL)) {
      feedContext = new FeedContext(
        id,
        localize("Predrilling"),
        feedPerRev
          ? getParameter("operation:tool_feedCuttingRel")
          : getParameter("operation:tool_feedCutting")
      );
      activeMovements[MOVEMENT_PREDRILL] = feedContext;
      activeFeeds.push(feedContext);
    }
    ++id;
  }

  if (hasParameter("operation:finishFeedrate")) {
    if (movements & (1 << MOVEMENT_FINISH_CUTTING)) {
      var finishFeedrateRel;
      if (hasParameter("operation:finishFeedrateRel")) {
        finishFeedrateRel = getParameter("operation:finishFeedrateRel");
      } else if (hasParameter("operation:finishFeedratePerRevolution")) {
        finishFeedrateRel = getParameter(
          "operation:finishFeedratePerRevolution"
        );
      }
      var feedContext = new FeedContext(
        id,
        localize("Finish"),
        feedPerRev
          ? finishFeedrateRel
          : getParameter("operation:finishFeedrate")
      );
      activeFeeds.push(feedContext);
      activeMovements[MOVEMENT_FINISH_CUTTING] = feedContext;
    }
    ++id;
  } else if (hasParameter("operation:tool_feedCutting")) {
    if (movements & (1 << MOVEMENT_FINISH_CUTTING)) {
      var feedContext = new FeedContext(
        id,
        localize("Finish"),
        feedPerRev
          ? getParameter("operation:tool_feedCuttingRel")
          : getParameter("operation:tool_feedCutting")
      );
      activeFeeds.push(feedContext);
      activeMovements[MOVEMENT_FINISH_CUTTING] = feedContext;
    }
    ++id;
  }

  if (hasParameter("operation:tool_feedEntry")) {
    if (movements & (1 << MOVEMENT_LEAD_IN)) {
      var feedContext = new FeedContext(
        id,
        localize("Entry"),
        feedPerRev
          ? getParameter("operation:tool_feedEntryRel")
          : getParameter("operation:tool_feedEntry")
      );
      activeFeeds.push(feedContext);
      activeMovements[MOVEMENT_LEAD_IN] = feedContext;
    }
    ++id;
  }

  if (hasParameter("operation:tool_feedExit")) {
    if (movements & (1 << MOVEMENT_LEAD_OUT)) {
      var feedContext = new FeedContext(
        id,
        localize("Exit"),
        feedPerRev
          ? getParameter("operation:tool_feedExitRel")
          : getParameter("operation:tool_feedExit")
      );
      activeFeeds.push(feedContext);
      activeMovements[MOVEMENT_LEAD_OUT] = feedContext;
    }
    ++id;
  }

  if (hasParameter("operation:noEngagementFeedrate")) {
    if (movements & (1 << MOVEMENT_LINK_DIRECT)) {
      var feedContext = new FeedContext(
        id,
        localize("Direct"),
        feedPerRev
          ? getParameter("operation:noEngagementFeedrateRel")
          : getParameter("operation:noEngagementFeedrate")
      );
      activeFeeds.push(feedContext);
      activeMovements[MOVEMENT_LINK_DIRECT] = feedContext;
    }
    ++id;
  } else if (
    hasParameter("operation:tool_feedCutting") &&
    hasParameter("operation:tool_feedEntry") &&
    hasParameter("operation:tool_feedExit")
  ) {
    if (movements & (1 << MOVEMENT_LINK_DIRECT)) {
      var feedContext = new FeedContext(
        id,
        localize("Direct"),
        Math.max(
          feedPerRev
            ? getParameter("operation:tool_feedCuttingRel")
            : getParameter("operation:tool_feedCutting"),
          feedPerRev
            ? getParameter("operation:tool_feedEntryRel")
            : getParameter("operation:tool_feedEntry"),
          feedPerRev
            ? getParameter("operation:tool_feedExitRel")
            : getParameter("operation:tool_feedExit")
        )
      );
      activeFeeds.push(feedContext);
      activeMovements[MOVEMENT_LINK_DIRECT] = feedContext;
    }
    ++id;
  }

  if (hasParameter("operation:reducedFeedrate")) {
    if (movements & (1 << MOVEMENT_REDUCED)) {
      var feedContext = new FeedContext(
        id,
        localize("Reduced"),
        feedPerRev
          ? getParameter("operation:reducedFeedrateRel")
          : getParameter("operation:reducedFeedrate")
      );
      activeFeeds.push(feedContext);
      activeMovements[MOVEMENT_REDUCED] = feedContext;
    }
    ++id;
  }

  if (hasParameter("operation:tool_feedRamp")) {
    if (
      movements &
      ((1 << MOVEMENT_RAMP) |
        (1 << MOVEMENT_RAMP_HELIX) |
        (1 << MOVEMENT_RAMP_PROFILE) |
        (1 << MOVEMENT_RAMP_ZIG_ZAG))
    ) {
      var feedContext = new FeedContext(
        id,
        localize("Ramping"),
        feedPerRev
          ? getParameter("operation:tool_feedRampRel")
          : getParameter("operation:tool_feedRamp")
      );
      activeFeeds.push(feedContext);
      activeMovements[MOVEMENT_RAMP] = feedContext;
      activeMovements[MOVEMENT_RAMP_HELIX] = feedContext;
      activeMovements[MOVEMENT_RAMP_PROFILE] = feedContext;
      activeMovements[MOVEMENT_RAMP_ZIG_ZAG] = feedContext;
    }
    ++id;
  }
  if (hasParameter("operation:tool_feedPlunge")) {
    if (movements & (1 << MOVEMENT_PLUNGE)) {
      var feedContext = new FeedContext(
        id,
        localize("Plunge"),
        feedPerRev
          ? getParameter("operation:tool_feedPlungeRel")
          : getParameter("operation:tool_feedPlunge")
      );
      activeFeeds.push(feedContext);
      activeMovements[MOVEMENT_PLUNGE] = feedContext;
    }
    ++id;
  }
  if (true) {
    // high feed
    if (
      movements & (1 << MOVEMENT_HIGH_FEED) ||
      highFeedMapping != HIGH_FEED_NO_MAPPING
    ) {
      var feed;
      if (
        hasParameter("operation:highFeedrateMode") &&
        getParameter("operation:highFeedrateMode") != "disabled"
      ) {
        feed = getParameter("operation:highFeedrate");
      } else {
        feed = this.highFeedrate;
      }
      var feedContext = new FeedContext(id, localize("High Feed"), feed);
      activeFeeds.push(feedContext);
      activeMovements[MOVEMENT_HIGH_FEED] = feedContext;
      activeMovements[MOVEMENT_RAPID] = feedContext;
    }
    ++id;
  }
  if (hasParameter("operation:tool_feedTransition")) {
    if (movements & (1 << MOVEMENT_LINK_TRANSITION)) {
      var feedContext = new FeedContext(
        id,
        localize("Transition"),
        getParameter("operation:tool_feedTransition")
      );
      activeFeeds.push(feedContext);
      activeMovements[MOVEMENT_LINK_TRANSITION] = feedContext;
    }
    ++id;
  }

  for (var i = 0; i < activeFeeds.length; ++i) {
    var feedContext = activeFeeds[i];
    writeBlock(
      "V" +
        (firstFeedParameter + feedContext.id) +
        "=" +
        feedFormat.format(feedContext.feed),
      formatComment(feedContext.description)
    );
  }
}

var currentWorkPlaneABC = undefined;

function forceWorkPlane() {
  currentWorkPlaneABC = undefined;
}

function setWorkPlane(abc) {
  // milling only

  if (!machineConfiguration.isMultiAxisConfiguration()) {
    return; // ignore
  }

  if (
    !(
      currentWorkPlaneABC == undefined ||
      abcFormat.areDifferent(abc.x, currentWorkPlaneABC.x) ||
      abcFormat.areDifferent(abc.y, currentWorkPlaneABC.y) ||
      abcFormat.areDifferent(abc.z, currentWorkPlaneABC.z)
    )
  ) {
    return; // no change
  }

  onCommand(COMMAND_UNLOCK_MULTI_AXIS);

  writeBlock(
    gMotionModal.format(0),
    conditional(
      machineConfiguration.isMachineCoordinate(0),
      aOutput.format(abc.x)
    ),
    conditional(
      machineConfiguration.isMachineCoordinate(1),
      bFormat.format(abc.y)
    ),
    conditional(
      machineConfiguration.isMachineCoordinate(2),
      cOutput.format(abc.z)
    )
  );
  if (!isDrillingCycle(true)) {
    onCommand(COMMAND_LOCK_MULTI_AXIS);
  }

  currentWorkPlaneABC = new Vector(abc);
  setCurrentDirection(abc);
}

function getBestABC(section) {
  // try workplane orientation
  var abc = section.getABCByPreference(
    machineConfiguration,
    section.workPlane,
    getCurrentDirection(),
    C,
    PREFER_CLOSEST,
    ENABLE_ALL
  );
  if (section.doesToolpathFitWithinLimits(machineConfiguration, abc)) {
    return abc;
  }
  var currentABC = new Vector(abc);

  // quadrant boundaries are the preferred solution
  var quadrants = [0, 90, 180, 270];
  for (var i = 0; i < quadrants.length; ++i) {
    abc.setZ(toRad(quadrants[i]));
    if (section.doesToolpathFitWithinLimits(machineConfiguration, abc)) {
      abc = machineConfiguration.remapToABC(abc, currentABC);
      abc = machineConfiguration.remapABC(abc);
      return abc;
    }
  }

  // attempt to find soultion at fixed angle rotations
  var maxTries = 60; // every 6 degrees
  var delta = (Math.PI * 2) / maxTries;
  var angle = delta;
  for (var i = 0; i < maxTries - 1; i++) {
    abc.setZ(angle);
    if (section.doesToolpathFitWithinLimits(machineConfiguration, abc)) {
      abc = machineConfiguration.remapToABC(abc, currentABC);
      abc = machineConfiguration.remapABC(abc);
      return abc;
    }
    angle += delta;
  }
  return abc;
}

function getWorkPlaneMachineABC(section, workPlane) {
  var W = workPlane; // map to global frame

  var abc;
  if (machineState.isTurningOperation && gotBAxis) {
    var both = machineConfiguration.getABCByDirectionBoth(workPlane.forward);
    abc = both[0];
    if (both[0].z != 0) {
      abc = both[1];
    }
  } else {
    abc = bestABC
      ? bestABC
      : section.getABCByPreference(
          machineConfiguration,
          W,
          getCurrentDirection(),
          C,
          PREFER_CLOSEST,
          ENABLE_RESET
        );
  }

  var direction = machineConfiguration.getDirection(abc);
  if (!isSameDirection(direction, W.forward)) {
    error(localize("Orientation not supported."));
  }

  if (machineState.isTurningOperation && gotBAxis && !bAxisIsManual) {
    // remapABC can change the B-axis orientation
    if (abc.z != 0) {
      error(
        localize(
          "Could not calculate a B-axis turning angle within the range of the machine."
        )
      );
    }
  }

  var tcp = false;
  if (tcp) {
    setRotation(W); // TCP mode
  } else {
    var O = machineConfiguration.getOrientation(abc);
    var R = machineConfiguration.getRemainingOrientation(abc, W);
    setRotation(R);
  }

  if (machineState.usePolarCoordinates) {
    // set C-axis to initial polar coordinate position
    var initialPosition = getFramePosition(section.getInitialPosition());
    var polarPosition = getPolarCoordinates(initialPosition, abc);
    abc.setZ(polarPosition.second.z);
  }
  return abc;
}

var bAxisOrientationTurning = new Vector(0, 0, 0);

function setSpindleOrientationTurning() {
  var J; // cutter orientation
  var R; // cutting quadrant
  var leftHandTool =
    hasParameter("operation:tool_hand") &&
    (getParameter("operation:tool_hand") == "L" ||
      getParameter("operation:tool_holderType") == 0);
  if (hasParameter("operation:machineInside")) {
    if (getParameter("operation:machineInside") == 0) {
      R = currentSection.spindle == SPINDLE_PRIMARY ? 3 : 4;
    } else {
      R = currentSection.spindle == SPINDLE_PRIMARY ? 2 : 1;
    }
  } else {
    if (
      (hasParameter("operation-strategy") &&
        getParameter("operation-strategy") == "turningFace") ||
      (hasParameter("operation-strategy") &&
        getParameter("operation-strategy") == "turningPart")
    ) {
      R = currentSection.spindle == SPINDLE_PRIMARY ? 3 : 4;
    } else {
      error(
        subst(
          localize(
            'Failed to identify spindle orientation for operation "%1".'
          ),
          getOperationComment()
        )
      );
      return;
    }
  }
  if (leftHandTool) {
    J = currentSection.spindle == SPINDLE_PRIMARY ? 2 : 1;
  } else {
    J = currentSection.spindle == SPINDLE_PRIMARY ? 1 : 2;
  }
  writeComment(
    "Post processor is not customized, add code for cutter orientation and cutting quadrant here if needed."
  );
}

var bAxisOrientationTurning = new Vector(0, 0, 0);

function getBAxisOrientationTurning(section) {
  // THIS CODE IS NOT TESTED.
  var toolAngle = hasParameter("operation:tool_angle")
    ? getParameter("operation:tool_angle")
    : 0;
  var toolOrientation = section.toolOrientation;
  if (toolAngle && toolOrientation != 0) {
    // error(localize("You cannot use tool angle and tool orientation together in operation " + "\"" + (getParameter("operation-comment")) + "\""));
  }

  var angle = toRad(toolAngle) + toolOrientation;

  var axis = new Vector(0, 1, 0);
  var mappedAngle;
  if (bAxisIsManual) {
    mappedAngle = 0; // manual b-axis used for milling only
  } else {
    mappedAngle =
      currentSection.spindle == SPINDLE_PRIMARY
        ? Math.PI / 2 - angle
        : Math.PI / 2 - angle;
  }
  var mappedWorkplane = new Matrix(axis, mappedAngle);
  var abc = getWorkPlaneMachineABC(section, mappedWorkplane);
  return abc;
}

function getSpindle(whichSpindle) {
  // safety conditions
  if (getNumberOfSections() == 0) {
    return SPINDLE_MAIN;
  }
  if (getCurrentSectionId() < 0) {
    if (machineState.liveToolIsActive && whichSpindle == TOOL) {
      return SPINDLE_LIVE;
    } else {
      return getSection(getNumberOfSections() - 1).spindle;
    }
  }

  // Turning is active or calling routine requested which spindle part is loaded into
  if (
    machineState.isTurningOperation ||
    machineState.axialCenterDrilling ||
    whichSpindle == PART
  ) {
    return currentSection.spindle;
    //Milling is active
  } else {
    return SPINDLE_LIVE;
  }
}

function getSecondarySpindle() {
  var spindle = getSpindle(PART);
  return spindle == SPINDLE_MAIN ? SPINDLE_SUB : SPINDLE_MAIN;
}

function isPerpto(a, b) {
  return Math.abs(Vector.dot(a, b)) < 1e-7;
}

function onSectionSpecialCycle() {
  if (!isFirstSection()) {
    activateMachine(currentSection);
  }
}

function onSection() {
  // Detect machine configuration
  var currentTurret = isFirstSection()
    ? activeTurret
    : activateMachine(currentSection);

  // Define Machining modes
  tapping = isTappingCycle();
  var forceSectionRestart =
    getProperty("safeStartAllOperations") ||
    (optionalSection && !currentSection.isOptional());
  optionalSection = currentSection.isOptional();
  bestABC = undefined;
  setCurrentDirection(
    isFirstSection() ? new Vector(0, 0, 0) : getCurrentDirection()
  );

  machineState.isTurningOperation = currentSection.getType() == TYPE_TURNING;
  if (machineState.isTurningOperation && gotBAxis) {
    bAxisOrientationTurning = getBAxisOrientationTurning(currentSection);
  }
  var insertToolCall =
    isToolChangeNeeded(
      "number",
      "compensationOffset",
      "diameterOffset",
      "lengthOffset"
    ) ||
    forceSectionRestart ||
    machineState.stockTransferIsActive;
  var newWorkOffset = isNewWorkOffset() || forceSectionRestart;
  var newWorkPlane =
    isNewWorkPlane() ||
    forceSectionRestart ||
    (machineState.isTurningOperation &&
      abcFormat.areDifferent(
        bAxisOrientationTurning.x,
        machineState.currentBAxisOrientationTurning.x
      )) ||
    abcFormat.areDifferent(
      bAxisOrientationTurning.y,
      machineState.currentBAxisOrientationTurning.y
    ) ||
    abcFormat.areDifferent(
      bAxisOrientationTurning.z,
      machineState.currentBAxisOrientationTurning.z
    );
  var retracted = false; // specifies that the tool has been retracted to the safe plane

  partCutoff = getParameter("operation-strategy", "") == "turningPart";
  operationNeedsSafeStart =
    getProperty("safeStartAllOperations") && !isFirstSection();

  var yAxisWasEnabled =
    !machineState.usePolarCoordinates &&
    !machineState.usePolarInterpolation &&
    machineState.liveToolIsActive;
  updateMachiningMode(currentSection); // sets the needed machining mode to machineState (usePolarInterpolation, usePolarCoordinates, axialCenterDrilling)

  // Get the active spindle
  var newSpindle = true;
  tempSpindle = getSpindle(TOOL);
  if (isFirstSection()) {
    previousSpindle = tempSpindle;
  }
  newSpindle = tempSpindle != previousSpindle;

  // End the previous section if a new tool is selected
  if (
    !isFirstSection() &&
    insertToolCall &&
    !(machineState.stockTransferIsActive && partCutoff)
  ) {
    if (machineState.stockTransferIsActive) {
      writeBlock(
        mFormat.format(
          getCode("SPINDLE_SYNCHRONIZATION_OFF", getSpindle(PART))
        ),
        formatComment("UNSYNC SPINDLES")
      );
    } else {
      if (previousSpindle == SPINDLE_LIVE) {
        onCommand(COMMAND_STOP_SPINDLE);
        forceUnlockMultiAxis();
        if (tempSpindle != SPINDLE_LIVE) {
          writeBlock(
            gPlaneModal.format(getCode("ENABLE_TURNING", getSpindle(PART)))
          );
        } else {
          onCommand(COMMAND_UNLOCK_MULTI_AXIS);
          if (
            tempSpindle != SPINDLE_LIVE &&
            !getProperty("optimizeCAxisSelect")
          ) {
            cAxisEngageModal.reset();
            writeBlock(
              cAxisEngageModal.format(
                getCode("DISABLE_C_AXIS", getSpindle(PART))
              )
            );
          }
        }
      }
      onCommand(COMMAND_COOLANT_OFF);
    }
    if (!machineState.stockTransferIsActive) {
      writeRetract(X);
      writeRetract(Z);
    }
    // cancel tool length compensation
    if (
      !isFirstSection() &&
      insertToolCall &&
      !(currentSection.getType() == TYPE_TURNING)
    ) {
      // writeBlock(formatTool(getPreviousSection().getTool(), true)); // may cause collision
    }

    // cancel load monitoring
    if (
      !isFirstSection() &&
      insertToolCall &&
      getProperty("loadMonitoring") != 0
    ) {
      writeln("VLMON[" + vlmon + "]=0");
      writeln(mFormat.format(215));
    }
    if (insertToolCall) {
      onCommand(COMMAND_STOP_SPINDLE);
      gSelectSpindleModal.reset();
    }
    if (getProperty("optionalStop")) {
      onCommand(COMMAND_OPTIONAL_STOP);
      gMotionModal.reset();
    }
  }
  // Consider part cutoff as stockTransfer operation
  if (!(machineState.stockTransferIsActive && partCutoff)) {
    machineState.stockTransferIsActive = false;
  }
  writeln("");
  // Output the operation description
  if (getProperty("showSequenceNumbers") == "toolChange" && insertToolCall) {
    if (gotSecondarySpindle) {
      writeComment(getParameter("operation-comment", ""));
      writeBlock(natFormat.format(sequenceNumber));
    }
  } else {
    writeComment(getParameter("operation-comment", ""));
    writeBlock(natFormat.format(sequenceNumber));
  }
  sequenceNumber += getProperty("sequenceNumberIncrement");

  if (isFirstSection() || newSpindle) {
    if (machineState.isTurningOperation) {
      writeBlock(
        gPlaneModal.format(getCode("ENABLE_TURNING", getSpindle(PART))),
        getSpindleID(getSpindle(PART))
      );
    } else {
      writeBlock(
        gPlaneModal.format(getCode("ENABLE_MILLING", getSpindle(PART))),
        getSpindleID(getSpindle(PART))
      );
    }
    // Select the active spindle
  }
  if (getProperty("gotSecondarySpindle")) {
    writeBlock(
      gSelectSpindleModal.format(getCode("SELECT_SPINDLE", getSpindle(PART)))
    );
  }
  // activate Y-axis
  if (
    gotYAxis &&
    getSpindle(TOOL) == SPINDLE_LIVE &&
    !machineState.usePolarInterpolation &&
    !machineState.usePolarCoordinates
  ) {
    writeBlock(gPolarModal.format(getCode("ENABLE_Y_AXIS", true)));
    yOutput.enable();
  }

  // Position all axes at home
  if (
    (insertToolCall && !machineState.stockTransferIsActive) ||
    operationNeedsSafeStart
  ) {
    var isRequired = insertToolCall && !machineState.stockTransferIsActive;
    writeStartBlocks(isRequired, function () {
      /*
        if (getProperty("gotSecondarySpindle")) {
          writeBlock(gMotionModal.format(0), gFormat.format(28), gFormat.format(53), "B" + abcFormat.format(0)); // retract Sub Spindle if applicable
        }
    */
      gMotionModal.reset();
      writeRetract(X, Z);

      // Stop the spindle
      if (newSpindle) {
        onCommand(COMMAND_STOP_SPINDLE);
      }
    });
  }

  var wcsOut = "";
  if (getSection(0).getSpindle() != currentSection.getSpindle()) {
    var vszoz =
      getSpindle(PART) == SPINDLE_MAIN
        ? getProperty("mainZHome")
        : getProperty("subZHome");
    writeBlock("VSZOZ=", vszoz, formatComment("PART LOCATION"));
  }
  /*
  if (insertToolCall) { // force work offset when changing tool
    currentWorkOffset = undefined;
  }

  if (currentSection.workOffset != currentWorkOffset) {
    forceWorkPlane();
    wcsOut = currentSection.wcs;
    currentWorkOffset = currentSection.workOffset;
  }
 */

  // Get active feedrate mode
  if (insertToolCall) {
    forceModals();
  }
  var feedMode = formatFeedMode(currentSection.feedMode);

  // calculate rotary angles
  var abc = new Vector(0, 0, 0);
  if (machineConfiguration.isMultiAxisConfiguration()) {
    if (machineState.isTurningOperation) {
      if (gotBAxis && currentTurret != 2) {
        cancelTransformation();
        // handle B-axis support for turning operations here
        abc = bAxisOrientationTurning;
      } else {
        abc = getWorkPlaneMachineABC(currentSection, currentSection.workPlane);
      }
    } else {
      if (currentSection.isMultiAxis() || isPolarModeActive()) {
        forceWorkPlane();
        cancelTransformation();
        // onCommand(COMMAND_UNLOCK_MULTI_AXIS);
        abc = currentSection.isMultiAxis()
          ? currentSection.getInitialToolAxisABC()
          : getCurrentDirection();
      } else {
        abc = getWorkPlaneMachineABC(currentSection, currentSection.workPlane);
      }
    }
  } else {
    // pure 3D
    var remaining = currentSection.workPlane;
    if (!isSameDirection(remaining.forward, new Vector(0, 0, 1))) {
      error(localize("Tool orientation is not supported by the CNC machine."));
      return;
    }
    setRotation(remaining);
  }

  // Live Spindle is active
  if (tempSpindle == SPINDLE_LIVE) {
    if (insertToolCall || wcsOut || feedMode || operationNeedsSafeStart) {
      var isRequired = insertToolCall || wcsOut || feedMode;
      writeStartBlocks(isRequired, function () {
        forceUnlockMultiAxis();
        onCommand(COMMAND_UNLOCK_MULTI_AXIS);
        var plane;
        switch (machineState.machiningDirection) {
          case MACHINING_DIRECTION_AXIAL:
            plane = getG17Code();
            break;
          case MACHINING_DIRECTION_RADIAL:
            plane = 19;
            break;
          case MACHINING_DIRECTION_INDEXING:
            plane = getG17Code();
            break;
          default:
            error(
              subst(
                localize(
                  "Unsupported machining direction for operation " +
                    '"' +
                    "%1" +
                    '"' +
                    "."
                ),
                getOperationComment()
              )
            );
            return;
        }
        gPlaneModal.reset();
        if (!getProperty("optimizeCAxisSelect")) {
          cAxisEngageModal.reset();
        }
        // writeBlock(wcsOut, mFormat.format(getCode("SET_SPINDLE_FRAME", getSpindle(PART))));
        writeBlock(
          feedMode,
          gPlaneModal.format(plane),
          cAxisEngageModal.format(getCode("ENABLE_C_AXIS", getSpindle(PART)))
        );
        //writeBlock(gMotionModal.format(0), gFormat.format(28), "H" + abcFormat.format(0)); // unwind c-axis
        if (
          !machineState.usePolarInterpolation &&
          !machineState.usePolarCoordinates &&
          !currentSection.isMultiAxis()
        ) {
          onCommand(COMMAND_LOCK_MULTI_AXIS);
        }
      });
    }

    // Turning is active
  } else {
    if (
      (insertToolCall || wcsOut || feedMode) &&
      !machineState.stockTransferIsActive
    ) {
      // forceUnlockMultiAxis();
      // writeBlock(cAxisEngageModal.format(getCode("UNLOCK_MULTI_AXIS", getSpindle(PART))));
      gPlaneModal.reset();
      if (!getProperty("optimizeCAxisSelect")) {
        cAxisEngageModal.reset();
      }
      // writeBlock(wcsOut, mFormat.format(getSpindle(PART) == SPINDLE_SUB ? 83 : 80));
      writeBlock(feedMode, gPlaneModal.format(18));
    } else {
      writeBlock(feedMode);
    }
  }

  // Write out maximum spindle speed
  var maximumSpindleSpeed =
    tool.maximumSpindleSpeed > 0
      ? Math.min(tool.maximumSpindleSpeed, getProperty("maximumSpindleSpeed"))
      : getProperty("maximumSpindleSpeed");
  if (
    maximumSpindleSpeed > 0 &&
    currentSection.getTool().getSpindleMode() == SPINDLE_CONSTANT_SURFACE_SPEED
  ) {
    if (
      /*insertToolCall || */ rpmFormat.areDifferent(
        maximumSpindleSpeed,
        previousMaximumSpeed
      ) &&
      !machineState.stockTransferIsActive
    ) {
      writeBlock(
        gFormat.format(50),
        maxSpeedOutput.format(maximumSpindleSpeed)
      );
      previousMaximumSpeed = maximumSpindleSpeed;
    }
  } else {
    //previousMaximumSpeed = 0; // reset for RPM spindle speeds
  }

  // Write out notes
  if (getProperty("showNotes") && hasParameter("notes")) {
    var notes = getParameter("notes");
    if (notes) {
      var lines = String(notes).split("\n");
      var r1 = new RegExp("^[\\s]+", "g");
      var r2 = new RegExp("[\\s]+$", "g");
      for (line in lines) {
        var comment = lines[line].replace(r1, "").replace(r2, "");
        if (comment) {
          writeComment(comment);
        }
      }
    }
  }

  if (insertToolCall || operationNeedsSafeStart) {
    writeStartBlocks(insertToolCall, function () {
      forceWorkPlane();
      cAxisEngageModal.reset();
      retracted = insertToolCall;
      onCommand(COMMAND_COOLANT_OFF);

      if (tool.compensationOffset > getProperty("maxToolOffset")) {
        error(localize("Compensation offset is out of range."));
        return;
      }
      if (tool.lengthOffset > getProperty("maxToolOffset")) {
        error(localize("Compensation offset is out of range."));
        return;
      }
      if (tool.number > getProperty("maxTool")) {
        warning(localize("Tool number exceeds maximum value."));
      }

      if (tool.number == 0) {
        error(localize("Tool number cannot be 0"));
        return;
      }

      gMotionModal.reset();
      //if (getProperty("showSequenceNumbers") == "toolChange") {
      //  showSequenceNumbers = "true";
      //}

      writeBlock(formatTool(tool, false));
      if (tool.comment) {
        writeComment(tool.comment);
      }

      // Turn on coolant
      setCoolant(tool.coolant);
      //if (!machineState.spindlesAreAttached && machineState.isTurningOperation) {
      //  writeBlock(
      //    mFormat.format(883),
      //    mFormat.format(getCode("IGNORE_SPINDLE_ORIENTATION")),
      //    mFormat.format(getCode("SPINDLE_SYNCHRONIZATION_SPEED")),
      //  );
      //}

      // enable load monitoring
      if (getProperty("loadMonitoring") != 0) {
        vlmon = tool.number;
        writeln("VLMON[" + vlmon + "]=" + getProperty("loadMonitoring"));
        writeln(mFormat.format(216));
      }
    });
  }

  // Activate part catcher for part cutoff section
  if (
    getProperty("usePartCatcher") &&
    partCutoff &&
    currentSection.partCatcher
  ) {
    engagePartCatcher(true);
  }

  // command stop for manual tool change, useful for quick change live tools
  if (insertToolCall && tool.manualToolChange) {
    onCommand(COMMAND_STOP);
    writeComment("MANUAL TOOL CHANGE TO " + formatTool(tool, false));
  }

  // Engage tailstock
  if (getProperty("useTailStock")) {
    if (
      machineState.axialCenterDrilling ||
      getSpindle(PART) == SPINDLE_SUB ||
      (getSpindle(TOOL) == SPINDLE_LIVE &&
        machineState.machiningDirection == MACHINING_DIRECTION_AXIAL)
    ) {
      if (currentSection.tailstock) {
        warning(
          localize(
            "Tail stock is not supported for secondary spindle or Z-axis milling."
          )
        );
      }
      if (machineState.tailstockIsActive) {
        writeBlock(
          tailStockModal.format(getCode("TAILSTOCK_OFF", SPINDLE_MAIN))
        );
      }
    } else {
      writeBlock(
        tailStockModal.format(
          currentSection.tailstock
            ? getCode("TAILSTOCK_ON", SPINDLE_MAIN)
            : getCode("TAILSTOCK_OFF", SPINDLE_MAIN)
        )
      );
    }
  }

  // Output spindle codes
  if (newSpindle) {
    // select spindle if required
  }

  var forceRPMMode = false;
  var spindleChanged =
    tool.type != TOOL_PROBE &&
    !machineState.stockTransferIsActive &&
    (insertToolCall ||
      forceSpindleSpeed ||
      isSpindleSpeedDifferent() ||
      newSpindle);
  if (spindleChanged || operationNeedsSafeStart) {
    forceSpindleSpeed = false;
    if (machineState.isTurningOperation || machineState.axialCenterDrilling) {
      if (spindleSpeed > maximumSpindleSpeed) {
        warning(
          subst(
            localize('Spindle speed exceeds maximum value for operation "%1".'),
            getOperationComment()
          )
        );
      }
    } else {
      if (spindleSpeed > 6000) {
        warning(
          subst(
            localize('Spindle speed exceeds maximum value for operation "%1".'),
            getOperationComment()
          )
        );
      }
    }

    // Turn spindle on
    forceRPMMode = tool.getSpindleMode() == SPINDLE_CONSTANT_SURFACE_SPEED;
    writeStartBlocks(spindleChanged, function () {
      startSpindle(
        false,
        true,
        getFramePosition(currentSection.getInitialPosition())
      );
    });
  }

  forceAny();
  gMotionModal.reset();

  if (currentSection.isMultiAxis()) {
    writeBlock(
      gMotionModal.format(0),
      aOutput.format(abc.x),
      bOutput.format(abc.y),
      cOutput.format(abc.z)
    );
    forceWorkPlane();
    cancelTransformation();
  } else {
    if (machineState.isTurningOperation || machineState.axialCenterDrilling) {
      if (gotBAxis) {
        bOutput.reset();
        writeBlock(
          gMotionModal.format(0),
          bOutput.format(getB(abc, currentSection))
        );
        machineState.currentBAxisOrientationTurning = abc;
      }
    } else if (
      !machineState.usePolarCoordinates &&
      !machineState.usePolarInterpolation
    ) {
      setWorkPlane(abc);
    }
  }

  // enable Polar coordinates mode
  if (machineState.usePolarCoordinates && tool.type != TOOL_PROBE) {
    if (polarCoordinatesDirection == undefined) {
      error(
        localize(
          "Polar coordinates axis direction to maintain must be defined as a vector - x,y,z."
        )
      );
      return;
    }
    setPolarCoordinates(true);
  }

  forceAny();

  gMotionModal.reset();
  var initialPosition = getFramePosition(currentSection.getInitialPosition());

  if (
    insertToolCall ||
    retracted ||
    tool.getSpindleMode() == SPINDLE_CONSTANT_SURFACE_SPEED ||
    operationNeedsSafeStart
  ) {
    var isRequired =
      insertToolCall ||
      retracted ||
      tool.getSpindleMode() == SPINDLE_CONSTANT_SURFACE_SPEED;
    writeStartBlocks(isRequired, function () {
      // gPlaneModal.reset();
      gMotionModal.reset();
      if (machineState.usePolarCoordinates) {
        var polarPosition = getPolarCoordinates(initialPosition, abc);
        setCAxisDirection(cOutput.getCurrent(), polarPosition.second.z);
        writeBlock(
          gMotionModal.format(0),
          zOutput.format(polarPosition.first.z)
        );
        writeBlock(
          gMotionModal.format(0),
          xOutput.format(polarPosition.first.x),
          conditional(gotYAxis, yOutput.format(0)),
          cOutput.format(polarPosition.second.z)
        );
      } else if (machineState.usePolarInterpolation) {
        var polarPosition = getPolarCoordinates(initialPosition, abc);
        writeBlock(
          gMotionModal.format(0),
          zOutput.format(polarPosition.first.z)
        );
        writeBlock(
          gMotionModal.format(0),
          xOutput.format(polarPosition.first.x),
          conditional(gotYAxis, yOutput.format(0))
        );
      } else {
        writeBlock(gMotionModal.format(0), zOutput.format(initialPosition.z));
        writeBlock(
          gMotionModal.format(0),
          xOutput.format(initialPosition.x),
          yOutput.format(0)
        );
      }
    });
  } else if (
    (machineState.usePolarCoordinates || machineState.usePolarInterpolation) &&
    yAxisWasEnabled
  ) {
    if (gotYAxis && yOutput.isEnabled()) {
      writeBlock(gMotionModal.format(0), yOutput.format(0));
    }
  }
  if (operationNeedsSafeStart) {
    forceXYZ();
  }

  // enable SFM spindle speed
  if (forceRPMMode) {
    startSpindle(false, false);
  }

  if (machineState.usePolarInterpolation) {
    setPolarInterpolation(true); // enable polar interpolation mode
  }

  if (getProperty("useParametricFeed") && !isDrillingCycle(true)) {
    if (
      !insertToolCall &&
      activeMovements &&
      getCurrentSectionId() > 0 &&
      getPreviousSection().getPatternId() == currentSection.getPatternId() &&
      currentSection.getPatternId() != 0
    ) {
      // use the current feeds
    } else {
      initializeActiveFeeds();
    }
  } else {
    activeMovements = undefined;
  }

  previousSpindle = tempSpindle;
  activeSpindle = tempSpindle;

  if (false) {
    // DEBUG
    for (var key in machineState) {
      writeComment(key + " : " + machineState[key]);
    }
    writeComment("Tapping = " + tapping);
    // writeln("(" + (getMachineConfigurationAsText(machineConfiguration)) + ")");
  }
}

var MACHINING_DIRECTION_AXIAL = 0;
var MACHINING_DIRECTION_RADIAL = 1;
var MACHINING_DIRECTION_INDEXING = 2;

function getMachiningDirection(section) {
  var forward = section.workPlane.forward;
  if (section.isMultiAxis()) {
    forward = section.getGlobalInitialToolAxis();
    forward = Math.abs(forward.z) < 1e-7 ? new Vector(1, 0, 0) : forward; // radial multi-axis operation
  }
  if (isSameDirection(forward, new Vector(0, 0, 1))) {
    return MACHINING_DIRECTION_AXIAL;
  } else if (Vector.dot(forward, new Vector(0, 0, 1)) < 1e-7) {
    return MACHINING_DIRECTION_RADIAL;
  } else {
    return MACHINING_DIRECTION_INDEXING;
  }
}

function updateMachiningMode(section) {
  machineState.axialCenterDrilling = false; // reset
  machineState.usePolarInterpolation = false; // reset
  machineState.usePolarCoordinates = false; // reset

  machineState.machiningDirection = getMachiningDirection(section);

  if (section.getType() == TYPE_MILLING && !section.isMultiAxis()) {
    if (machineState.machiningDirection == MACHINING_DIRECTION_AXIAL) {
      if (isDrillingCycle(section, false)) {
        // drilling axial
        machineState.axialCenterDrilling = isAxialCenterDrilling(section, true);
        if (
          !machineState.axialCenterDrilling &&
          !isAxialCenterDrilling(section, false)
        ) {
          // several holes not on XY center
          // bestABC = section.getABCByPreference(machineConfiguration, section.workPlane, getCurrentDirection(), C, PREFER_CLOSEST, ENABLE_RESET | ENABLE_LIMITS);
          bestABC = getBestABC(section);
          bestABC = section.doesToolpathFitWithinLimits(
            machineConfiguration,
            bestABC
          )
            ? bestABC
            : undefined;
          if (!getProperty("useYAxisForDrilling") || bestABC == undefined) {
            machineState.usePolarCoordinates = true;
          }
        }
      } else {
        // milling
        // Use new operation property for polar milling
        if (
          currentSection.machiningType &&
          currentSection.machiningType == MACHINING_TYPE_POLAR
        ) {
          // Choose correct polar mode depending on machine capabilities
          if (gotPolarInterpolation && !forcePolarCoordinates) {
            forcePolarInterpolation = true;
          } else {
            forcePolarCoordinates = true;
          }

          // Update polar coordinates direction according to operation property
          polarCoordinatesDirection = currentSection.polarDirection;
        }
        if (gotPolarInterpolation && forcePolarInterpolation) {
          // polar mode is requested by user
          machineState.usePolarInterpolation = true;
          bestABC = undefined;
        } else if (forcePolarCoordinates) {
          // Polar coordinate mode is requested by user
          machineState.usePolarCoordinates = true;
          bestABC = undefined;
        } else {
          //bestABC = section.getABCByPreference(machineConfiguration, section.workPlane, getCurrentDirection(), C, PREFER_CLOSEST, ENABLE_RESET | ENABLE_LIMITS);
          bestABC = getBestABC(section);
          bestABC = section.doesToolpathFitWithinLimits(
            machineConfiguration,
            bestABC
          )
            ? bestABC
            : undefined;
          if (bestABC == undefined) {
            // toolpath does not match XY ranges, enable interpolation mode
            if (gotPolarInterpolation) {
              machineState.usePolarInterpolation = true;
            } else {
              machineState.usePolarCoordinates = true;
            }
          }
        }
      }
    } else if (machineState.machiningDirection == MACHINING_DIRECTION_RADIAL) {
      // G19 plane
      var range = section.getOptimizedBoundingBox(
        machineConfiguration,
        machineConfiguration.getABC(section.workPlane)
      );
      var yAxisWithinLimits =
        machineConfiguration
          .getAxisY()
          .getRange()
          .isWithin(yFormat.getResultingValue(range.lower.y)) &&
        machineConfiguration
          .getAxisY()
          .getRange()
          .isWithin(yFormat.getResultingValue(range.upper.y));
      if (!gotYAxis) {
        if (!section.isMultiAxis() && !yAxisWithinLimits) {
          error(
            subst(
              localize(
                'Y-axis motion is not possible without a Y-axis for operation "%1".'
              ),
              getOperationComment()
            )
          );
          return;
        }
      } else {
        if (!yAxisWithinLimits) {
          error(
            subst(
              localize(
                'Toolpath exceeds the maximum ranges for operation "%1".'
              ),
              getOperationComment()
            )
          );
          return;
        }
      }
      // C-coordinates come from setWorkPlane or is within a multi axis operation, we cannot use the C-axis for non wrapped toolpathes (only multiaxis works, all others have to be into XY range)
    } else {
      // usePolarCoordinates & usePolarInterpolation is only supported for axial machining, keep false
    }
  } else {
    // turning or multi axis, keep false
  }

  if (machineState.axialCenterDrilling) {
    cOutput.disable();
  } else {
    cOutput.enable();
  }

  var checksum = 0;
  checksum += machineState.usePolarInterpolation ? 1 : 0;
  checksum += machineState.usePolarCoordinates ? 1 : 0;
  checksum += machineState.axialCenterDrilling ? 1 : 0;
  validate(checksum <= 1, localize("Internal post processor error."));
}

function getOperationComment() {
  var operationComment =
    hasParameter("operation-comment") && getParameter("operation-comment");
  return operationComment;
}

function setRadiusDiameterMode(mode) {
  if (mode == "diameter") {
    xFormat.setScale(2);
  } else {
    xFormat.setScale(1);
  }
  xOutput.setFormat(xFormat);
}

function setPolarInterpolation(activate) {
  if (activate) {
    setCAxisDirection(cOutput.getCurrent(), 0);
    cOutput.enable();
    cOutput.reset();
    writeBlock(
      gPolarModal.format(getCode("POLAR_INTERPOLATION_ON", getSpindle(PART))),
      cOutput.format(0)
    ); // command for polar interpolation
    writeBlock(gPlaneModal.format(getG17Code()));
    yOutput.setPrefix("Y");
    yOutput.enable(); // required for G12.1
    cOutput.disable();
    setRadiusDiameterMode("radius");
  } else {
    writeBlock(
      gPolarModal.format(getCode("POLAR_INTERPOLATION_OFF", getSpindle(PART)))
    );
    yOutput.setPrefix("Y");
    yOutput.disable();
    cOutput.enable();
    setRadiusDiameterMode("diameter");
    if (currentWorkPlaneABC != undefined) {
      currentWorkPlaneABC.z = Number.POSITIVE_INFINITY;
    }
  }
}

/** Output block to do safe retract and/or move to home position. */
function writeRetract() {
  if (arguments.length == 0) {
    error(localize("No axis specified for writeRetract()."));
    return;
  }
  var words = []; // store all retracted axes in an array
  for (var i = 0; i < arguments.length; ++i) {
    let instances = 0; // checks for duplicate retract calls
    for (var j = 0; j < arguments.length; ++j) {
      if (arguments[i] == arguments[j]) {
        ++instances;
      }
    }
    if (instances > 1) {
      // error if there are multiple retract calls for the same axis
      error(localize("Cannot retract the same axis twice in one line"));
      return;
    }
    switch (arguments[i]) {
      case X:
        xOutput.reset();
        words.push(xOutput.format(getProperty("homePositionX")));
        break;
      case Y:
        yOutput.reset();
        words.push(yOutput.format(getProperty("homePositionY")));
        break;
      case Z:
        zOutput.reset();
        words.push(zOutput.format(getProperty("homePositionZ")));
        break;
      default:
        error(localize("Bad axis specified for writeRetract()."));
        return;
    }
  }
  if (words.length > 0) {
    writeBlock(gMotionModal.format(0), words); // retract
  }
}

function onDwell(seconds) {
  if (seconds > 9999.99) {
    warning(localize("Dwelling time is out of range."));
  }
  writeBlock(gFormat.format(4), dwellFormat.format(seconds));
}

var pendingRadiusCompensation = -1;

function onRadiusCompensation() {
  pendingRadiusCompensation = radiusCompensation;
}

var resetFeed = false;

function getHighfeedrate(radius) {
  if (currentSection.feedMode == FEED_PER_REVOLUTION) {
    if (toDeg(radius) <= 0) {
      radius = toPreciseUnit(0.1, MM);
    }
    var rpm = spindleSpeed; // rev/min
    if (
      currentSection.getTool().getSpindleMode() ==
      SPINDLE_CONSTANT_SURFACE_SPEED
    ) {
      var O = 2 * Math.PI * radius; // in/rev
      rpm = tool.surfaceSpeed / O; // in/min div in/rev => rev/min
    }
    return highFeedrate / rpm; // in/min div rev/min => in/rev
  }
  return highFeedrate;
}

function onRapid(_x, _y, _z) {
  var x = xOutput.format(_x);
  var y = yOutput.format(_y);
  var z = zOutput.format(_z);
  if (x || y || z) {
    var useG1 =
      ((x ? 1 : 0) + (y ? 1 : 0) + (z ? 1 : 0) > 1 ||
        machineState.usePolarInterpolation) &&
      !isCannedCycle;
    // axes are not synchronized
    if (useG1) {
      var highFeed = machineState.usePolarInterpolation
        ? toPreciseUnit(1500, MM)
        : getHighfeedrate(_x);
      if (x) {
        xOutput.reset();
      }
      if (y) {
        yOutput.reset();
      }
      if (z) {
        zOutput.reset();
      }
      onExpandedLinear(_x, _y, _z, highFeed);
    } else {
      writeBlock(gMotionModal.format(0), x, y, z);
    }
  }
}

function onLinear(_x, _y, _z, feed) {
  if (isSpeedFeedSynchronizationActive()) {
    resetFeed = true;
    var threadPitch = getParameter("operation:threadPitch");
    var threadsPerInch = 1.0 / threadPitch; // per mm for metric
    var startXYZ = getCurrentPosition();
    var deltaX = spatialFormat.getResultingValue(_x - startXYZ.x);
    // Force X and Z output on G31 lines
    forceXYZ();
    writeBlock(
      gMotionModal.format(31),
      xOutput.format(_x),
      yOutput.format(_y),
      zOutput.format(_z),
      iOutput.format(deltaX),
      pitchOutput.format(1 / threadsPerInch)
    );
    return;
  }
  if (resetFeed) {
    resetFeed = false;
    forceFeed();
  }
  var x = xOutput.format(_x);
  var y = yOutput.format(_y);
  var z = zOutput.format(_z);
  if (x || y || z) {
    var linearCode = machineState.usePolarInterpolation && (x || y) ? 101 : 1;
    if (pendingRadiusCompensation >= 0) {
      pendingRadiusCompensation = -1;
      if (machineState.isTurningOperation) {
        writeBlock(gPlaneModal.format(18));
      } else if (
        isSameDirection(currentSection.workPlane.forward, new Vector(0, 0, 1))
      ) {
        writeBlock(gPlaneModal.format(getG17Code()));
      } else if (
        Vector.dot(currentSection.workPlane.forward, new Vector(0, 0, 1)) < 1e-7
      ) {
        writeBlock(gPlaneModal.format(19));
      } else {
        error(
          localize("Tool orientation is not supported for radius compensation.")
        );
        return;
      }
      switch (radiusCompensation) {
        case RADIUS_COMPENSATION_LEFT:
          writeBlock(
            gMotionModal.format(linearCode),
            gFormat.format(41),
            x,
            y,
            z,
            getFeed(feed)
          );
          break;
        case RADIUS_COMPENSATION_RIGHT:
          writeBlock(
            gMotionModal.format(linearCode),
            gFormat.format(42),
            x,
            y,
            z,
            getFeed(feed)
          );
          break;
        default:
          writeBlock(
            gMotionModal.format(linearCode),
            gFormat.format(40),
            x,
            y,
            z,
            getFeed(feed)
          );
      }
    } else {
      writeBlock(gMotionModal.format(linearCode), x, y, z, getFeed(feed));
    }
  }
}

function onRapid5D(_x, _y, _z, _a, _b, _c) {
  if (pendingRadiusCompensation >= 0) {
    error(
      localize("Radius compensation mode cannot be changed at rapid traversal.")
    );
    return;
  }

  setCAxisDirection(cOutput.getCurrent(), _c);

  var x = xOutput.format(_x);
  var y = yOutput.format(_y);
  var z = zOutput.format(_z);
  var a = aOutput.format(_a);
  var b = bOutput.format(_b);
  var c = cOutput.format(_c);
  if (x || y || z || a || b || c) {
    var useG1 =
      (x ? 1 : 0) +
        (y ? 1 : 0) +
        (z ? 1 : 0) +
        (a ? 1 : 0) +
        (b ? 1 : 0) +
        (c ? 1 : 0) >
      1;
    var gCode = useG1 ? 1 : 0;
    var f = useG1
      ? getFeed(
          machineState.usePolarInterpolation
            ? toPreciseUnit(1500, MM)
            : getHighfeedrate(_x)
        )
      : "";
    writeBlock(gMotionModal.format(gCode), x, y, z, a, b, c, f);
    if (!useG1) {
      forceFeed();
    }
  }
}

function onLinear5D(_x, _y, _z, _a, _b, _c, feed) {
  var compCode = undefined;
  if (pendingRadiusCompensation >= 0) {
    if (isPolarModeActive()) {
      pendingRadiusCompensation = -1;
      switch (radiusCompensation) {
        case RADIUS_COMPENSATION_LEFT:
          compCode = gFormat.format(41);
          break;
        case RADIUS_COMPENSATION_RIGHT:
          compCode = gFormat.format(42);
          break;
        default:
          compCode = gFormat.format(40);
      }
    } else {
      error(
        localize(
          "Radius compensation cannot be activated/deactivated for 5-axis move."
        )
      );
    }
  }

  setCAxisDirection(cOutput.getCurrent(), _c);

  var x = xOutput.format(_x);
  var y = yOutput.format(_y);
  var z = zOutput.format(_z);
  var a = aOutput.format(_a);
  var b = bOutput.format(_b);
  var c = cOutput.format(_c);

  if (x || y || z || a || b || c) {
    writeBlock(gMotionModal.format(1), x, y, z, a, b, c, getFeed(feed));
  }
}

// Start of Polar coordinates
var defaultPolarCoordinatesDirection = new Vector(1, 0, 0); // default direction for polar interpolation
var polarCoordinatesDirection = defaultPolarCoordinatesDirection; // vector to maintain tool at while in polar interpolation
var polarSpindleAxisSave;
function setPolarCoordinates(mode) {
  if (!mode) {
    // turn off polar mode if required
    if (isPolarModeActive()) {
      deactivatePolarMode();
      if (gotBAxis) {
        machineConfiguration.setSpindleAxis(polarSpindleAxisSave);
        bOutput.enable();
      }
      // setPolarFeedMode(false);
      if (currentWorkPlaneABC != undefined) {
        currentWorkPlaneABC.z = Number.POSITIVE_INFINITY;
      }
    }
    polarCoordinatesDirection = defaultPolarCoordinatesDirection; // reset when deactivated
    return;
  }

  var direction = polarCoordinatesDirection;

  // determine the rotary axis to use for Polar coordinates
  var axis = undefined;
  if (machineConfiguration.getAxisV().isEnabled()) {
    if (
      Vector.dot(
        machineConfiguration.getAxisV().getAxis(),
        currentSection.workPlane.getForward()
      ) != 0
    ) {
      axis = machineConfiguration.getAxisV();
    }
  }
  if (axis == undefined && machineConfiguration.getAxisU().isEnabled()) {
    if (
      Vector.dot(
        machineConfiguration.getAxisU().getAxis(),
        currentSection.workPlane.getForward()
      ) != 0
    ) {
      axis = machineConfiguration.getAxisU();
    }
  }
  if (axis == undefined) {
    error(
      localize(
        "Polar coordinates require an active rotary axis be defined in direction of workplane normal."
      )
    );
  }

  // calculate directional vector from initial position
  if (direction == undefined) {
    error(
      localize("Polar coordinates initiated without a directional vector.")
    );
    return;
  }

  // activate polar coordinates
  // setPolarFeedMode(true); // enable multi-axis feeds for polar mode

  if (gotBAxis) {
    polarSpindleAxisSave = machineConfiguration.getSpindleAxis();
    machineConfiguration.setSpindleAxis(new Vector(0, 0, 1));
    bOutput.disable();
  }
  activatePolarMode(getTolerance(), 0, direction);
  var polarPosition = getPolarPosition(
    currentSection.getInitialPosition().x,
    currentSection.getInitialPosition().y,
    currentSection.getInitialPosition().z
  );
  setCurrentPositionAndDirection(polarPosition);
}

function getPolarCoordinates(position, abc) {
  var reset = false;
  var current = getCurrentDirection();
  if (!isPolarModeActive()) {
    setCurrentDirection(abc);
    var tempPolarCoordinatesDirection =
      currentSection.machiningType &&
      currentSection.machiningType == MACHINING_TYPE_POLAR
        ? currentSection.polarDirection
        : polarCoordinatesDirection;
    activatePolarMode(getTolerance() / 2, 0, tempPolarCoordinatesDirection);
    reset = true;
  }
  var polarPosition = getPolarPosition(position.x, position.y, position.z);
  if (reset) {
    deactivatePolarMode();
    setCurrentDirection(current);
  }
  return polarPosition;
}
// End of polar coordinates

function onCircular(clockwise, cx, cy, cz, x, y, z, feed) {
  var directionCode = clockwise ? 2 : 3;
  directionCode +=
    machineState.usePolarCoordinates || machineState.usePolarInterpolation
      ? 100
      : 0;

  if (getSpindle(TOOL) == SPINDLE_LIVE) {
    if (machineState.machiningDirection == MACHINING_DIRECTION_AXIAL) {
      if (getCircularPlane() != PLANE_XY) {
        linearize(tolerance);
        return;
      }
    } else {
      if (getCircularPlane() != PLANE_YZ) {
        linearize(tolerance);
        return;
      }
    }
  }
  var toler = getTolerance();

  if (isSpeedFeedSynchronizationActive()) {
    error(
      localize(
        "Speed-feed synchronization is not supported for circular moves."
      )
    );
    return;
  }

  if (pendingRadiusCompensation >= 0) {
    error(
      localize(
        "Radius compensation cannot be activated/deactivated for a circular move."
      )
    );
    return;
  }

  var start = getCurrentPosition();

  if (isFullCircle()) {
    if (
      getProperty("useRadius") ||
      isHelical() ||
      machineState.usePolarInterpolation
    ) {
      // radius mode does not support full arcs
      linearize(toler);
      return;
    }
    switch (getCircularPlane()) {
      case PLANE_XY:
        xOutput.reset();
        yOutput.reset();
        writeBlock(
          gPlaneModal.format(getG17Code()),
          gMotionModal.format(directionCode),
          iOutput.format(cx - start.x),
          jOutput.format(cy - start.y),
          getFeed(feed)
        );
        break;
      case PLANE_ZX:
        if (machineState.usePolarInterpolation) {
          linearize(tolerance);
          return;
        }
        zOutput.reset();
        xOutput.reset();
        writeBlock(
          gPlaneModal.format(18),
          gMotionModal.format(directionCode),
          iOutput.format(cx - start.x),
          kOutput.format(cz - start.z),
          getFeed(feed)
        );
        break;
      case PLANE_YZ:
        if (machineState.usePolarInterpolation) {
          linearize(tolerance);
          return;
        }
        yOutput.reset();
        zOutput.reset();
        writeBlock(
          gPlaneModal.format(19),
          gMotionModal.format(directionCode),
          jOutput.format(cy - start.y),
          kOutput.format(cz - start.z),
          getFeed(feed)
        );
        break;
      default:
        linearize(toler);
    }
  } else if (!getProperty("useRadius") && !machineState.usePolarInterpolation) {
    if (
      isHelical() &&
      (getCircularSweep() < toRad(30) || getHelicalPitch() > 10)
    ) {
      // avoid G112 issue
      linearize(toler);
      return;
    }
    switch (getCircularPlane()) {
      case PLANE_XY:
        xOutput.reset();
        yOutput.reset();
        writeBlock(
          gPlaneModal.format(getG17Code()),
          gMotionModal.format(directionCode),
          xOutput.format(x),
          yOutput.format(y),
          zOutput.format(z),
          iOutput.format(cx - start.x),
          jOutput.format(cy - start.y),
          getFeed(feed)
        );
        break;
      case PLANE_ZX:
        if (machineState.usePolarInterpolation) {
          linearize(tolerance);
          return;
        }
        zOutput.reset();
        xOutput.reset();
        writeBlock(
          gPlaneModal.format(18),
          gMotionModal.format(directionCode),
          xOutput.format(x),
          yOutput.format(y),
          zOutput.format(z),
          iOutput.format(cx - start.x),
          kOutput.format(cz - start.z),
          getFeed(feed)
        );
        break;
      case PLANE_YZ:
        if (machineState.usePolarInterpolation) {
          linearize(tolerance);
          return;
        }
        yOutput.reset();
        zOutput.reset();
        writeBlock(
          gPlaneModal.format(19),
          gMotionModal.format(directionCode),
          xOutput.format(x),
          yOutput.format(y),
          zOutput.format(z),
          jOutput.format(cy - start.y),
          kOutput.format(cz - start.z),
          getFeed(feed)
        );
        break;
      default:
        linearize(toler);
    }
  } else {
    // use radius mode
    if (
      isHelical() &&
      (getCircularSweep() < toRad(30) ||
        getHelicalPitch() > 10 ||
        machineState.usePolarInterpolation)
    ) {
      linearize(toler);
      return;
    }
    var r = getCircularRadius();
    if (toDeg(getCircularSweep()) > 180 + 1e-9) {
      linearize(toler);
      return;
    }
    switch (getCircularPlane()) {
      case PLANE_XY:
        xOutput.reset();
        yOutput.reset();
        writeBlock(
          gPlaneModal.format(getG17Code()),
          gMotionModal.format(directionCode),
          xOutput.format(x),
          yOutput.format(y),
          zOutput.format(z),
          "L" + rFormat.format(r),
          getFeed(feed)
        );
        break;
      case PLANE_ZX:
        if (machineState.usePolarInterpolation) {
          linearize(tolerance);
          return;
        }
        zOutput.reset();
        xOutput.reset();
        writeBlock(
          gPlaneModal.format(18),
          gMotionModal.format(directionCode),
          xOutput.format(x),
          yOutput.format(y),
          zOutput.format(z),
          "L" + rFormat.format(r),
          getFeed(feed)
        );
        break;
      case PLANE_YZ:
        if (machineState.usePolarInterpolation) {
          linearize(tolerance);
          return;
        }
        yOutput.reset();
        zOutput.reset();
        writeBlock(
          gPlaneModal.format(19),
          gMotionModal.format(directionCode),
          xOutput.format(x),
          yOutput.format(y),
          zOutput.format(z),
          "L" + rFormat.format(r),
          getFeed(feed)
        );
        break;
      default:
        linearize(toler);
    }
  }
}

var chuckMachineFrame;
var chuckSubPosition;
function getSecondaryPullMethod(type) {
  var pullMethod = {};

  // determine if pull operation, spindle return, or both
  pullMethod.pull = false;
  pullMethod.home = false;

  switch (type) {
    case "secondary-spindle-pull":
      pullMethod.pullPosition = chuckSubPosition + cycle.pullingDistance;
      pullMethod.machineFrame = chuckMachineFrame;
      pullMethod.unclampMode = "keep-clamped";
      pullMethod.pull = true;
      break;
    case "secondary-spindle-return":
      pullMethod.pullPosition = cycle.feedPosition;
      pullMethod.machineFrame = cycle.useMachineFrame;
      pullMethod.unclampMode = cycle.unclampMode;

      // pull part only (when offset!=0), Return secondary spindle to home (when offset=0)
      var feedDis = 0;
      if (pullMethod.machineFrame) {
        if (hasParameter("operation:feedPlaneHeight_direct")) {
          // Inventor
          feedDis = getParameter("operation:feedPlaneHeight_direct");
        } else if (hasParameter("operation:feedPlaneHeightDirect")) {
          // HSMWorks
          feedDis = getParameter("operation:feedPlaneHeightDirect");
        }
        feedPosition = feedDis;
      } else if (hasParameter("operation:feedPlaneHeight_offset")) {
        // Inventor
        feedDis = getParameter("operation:feedPlaneHeight_offset");
      } else if (hasParameter("operation:feedPlaneHeightOffset")) {
        // HSMWorks
        feedDis = getParameter("operation:feedPlaneHeightOffset");
      }

      // Transfer part to secondary spindle
      if (pullMethod.unclampMode != "keep-clamped") {
        pullMethod.pull = feedDis != 0;
        pullMethod.home = true;
      } else {
        // pull part only (when offset!=0), Return secondary spindle to home (when offset=0)
        pullMethod.pull = feedDis != 0;
        pullMethod.home = !pullMethod.pull;
      }
      break;
  }
  return pullMethod;
}

var wAxisTorqueUpper = 30;
var wAxisTorqueMiddle = 25;
var wAxisTorqueLower = 5;

function onCycle() {
  if (typeof isSubSpindleCycle == "function" && isSubSpindleCycle(cycleType)) {
    if (!gotSecondarySpindle) {
      error(localize("Secondary spindle is not available."));
    }
    if (tempSpindle == SPINDLE_LIVE) {
      setRadiusDiameterMode("radius");
    }
    if (!machineState.stockTransferIsActive) {
      writeRetract(X);
      onCommand(COMMAND_STOP_SPINDLE);
      if (tempSpindle == SPINDLE_LIVE) {
        onCommand(COMMAND_UNLOCK_MULTI_AXIS);
        writeBlock(mFormat.format(109));
      }
      onCommand(COMMAND_COOLANT_OFF);
      onCommand(COMMAND_OPTIONAL_STOP);
    }
    writeln("");
    var comment = getParameter("operation-comment", "");
    if (comment) {
      writeComment(comment);
    }

    // Start of stock transfer operation(s)
    if (!machineState.stockTransferIsActive) {
      if (tempSpindle == SPINDLE_LIVE) {
        onCommand(COMMAND_UNLOCK_MULTI_AXIS);
        writeBlock(mFormat.format(109));
      }
      writeBlock(mFormat.format(9));
      onCommand(COMMAND_OPTIONAL_STOP);
      //if (cycle.stopSpindle) {
      //  writeBlock(mFormat.format(getCode("ENABLE_C_AXIS", getSpindle(PART))));
      //  onCommand(COMMAND_UNLOCK_MULTI_AXIS);
      //  writeBlock(gMotionModal.format(0), cOutput.format(0));
      //  onCommand(COMMAND_LOCK_MULTI_AXIS);
      //  // writeBlock(mFormat.format(getCode("DISABLE_C_AXIS", getSpindle(PART)))); // cannot disable C-axis when it's locked
      //}
      gFeedModeModal.reset();
      var feedMode;
      if (currentSection.feedMode == FEED_PER_REVOLUTION) {
        feedMode = gFeedModeModal.format(
          getCode("FEED_MODE_UNIT_REV", getSpindle(TOOL))
        );
      } else {
        feedMode = gFeedModeModal.format(
          getCode("FEED_MODE_UNIT_MIN", getSpindle(TOOL))
        );
      }
    }

    switch (cycleType) {
      case "secondary-spindle-grab":
        if (currentSection.partCatcher) {
          engagePartCatcher(true);
        }
        writeBlock(
          mFormat.format(
            getCode("INTERNAL_INTERLOCK_ON", getSecondarySpindle())
          ),
          formatComment("SUB CHUCK INTERLOCK RELEASE ON")
        );
        writeBlock(
          mFormat.format(getCode("INTERNAL_INTERLOCK_ON", getSpindle(PART))),
          formatComment("MAIN CHUCK INTERLOCK RELEASE ON")
        );
        writeBlock(
          mFormat.format(
            getCode("SPINDLE_SYNCHRONIZATION_SPEED", getSpindle(PART))
          ),
          formatComment("SPINDLE SYNC-MAIN IS MASTER")
        );
        writeBlock(
          mFormat.format(976),
          formatComment("W-AXIS TURRET INTERLOCK RELEASE ON")
        );
        writeBlock(
          mFormat.format(getCode("UNCLAMP_CHUCK", getSecondarySpindle())),
          formatComment("UNCLAMP OPPOSITE SPINDLE")
        );
        onDwell(cycle.dwell);
        gSpindleModeModal.reset();

        if (cycle.stopSpindle) {
          // no spindle rotation
          // do nothing
        } else {
          // spindle rotation
          var transferCodes = getSpindleTransferCodes();

          // Write out maximum spindle speed
          if (transferCodes.spindleMode == SPINDLE_CONSTANT_SURFACE_SPEED) {
            var maximumSpindleSpeed =
              transferCodes.maximumSpindleSpeed > 0
                ? Math.min(
                    transferCodes.maximumSpindleSpeed,
                    getProperty("maximumSpindleSpeed")
                  )
                : getProperty("maximumSpindleSpeed");
            writeBlock(
              gFormat.format(50),
              maxSpeedOutput.format(maximumSpindleSpeed)
            );
          }
          // write out spindle speed
          var _spindleSpeed;
          var spindleMode;
          if (transferCodes.spindleMode == SPINDLE_CONSTANT_SURFACE_SPEED) {
            _spindleSpeed =
              transferCodes.surfaceSpeed * (unit == MM ? 1 / 1000.0 : 1 / 12.0);
            spindleMode = getCode(
              "CONSTANT_SURFACE_SPEED_ON",
              getSpindle(PART)
            );
          } else {
            _spindleSpeed = cycle.spindleSpeed;
            spindleMode = getCode(
              "CONSTANT_SURFACE_SPEED_OFF",
              getSpindle(PART)
            );
          }
          writeBlock(
            gSpindleModeModal.format(spindleMode),
            sOutput.format(_spindleSpeed),
            mFormat.format(transferCodes.direction)
          );
          writeBlock(
            mFormat.format(
              getCode("SPINDLE_SYNCHRONIZATION_SPEED", getSpindle(PART))
            ),
            formatComment("SYNCHRONIZED ROTATION ON")
          );
          writeBlock(
            mFormat.format(
              getCode("IGNORE_SPINDLE_ORIENTATION", getSpindle(PART))
            ),
            formatComment("IGNORE SPINDLE ORIENTATION")
          );
        }

        gMotionModal.reset();
        var upperZ = getParameter("stock-upper-z");
        writeBlock(gMotionModal.format(0), wOutput.format(cycle.feedPosition));
        if (getProperty("transferUseTorque")) {
          writeBlock(
            gFormat.format(getCode("TORQUE_LIMIT_ON", getSpindle(PART))),
            "PW=" + integerFormat.format(wAxisTorqueUpper)
          );
          writeBlock(
            gFormat.format(getCode("TORQUE_SKIP_ON", getSpindle(PART))),
            wOutput.format(cycle.chuckPosition),
            "D" + zFormat.format(cycle.feedPosition - cycle.chuckPosition),
            "L" + zFormat.format(cycle.feedPosition - upperZ),
            getFeed(cycle.feedrate),
            "PW=" + integerFormat.format(wAxisTorqueMiddle)
          );
          writeBlock(
            gFormat.format(getCode("TORQUE_LIMIT_ON", getSpindle(PART))),
            "PW=" + integerFormat.format(wAxisTorqueLower)
          );
          writeBlock(
            gFormat.format(getCode("TORQUE_LIMIT_OFF", getSpindle(PART)))
          );
        } else {
          gFeedModeModal.reset();
          writeBlock(
            gFeedModeModal.format(
              getCode("FEED_MODE_UNIT_MIN", getSpindle(TOOL))
            )
          );
          writeBlock(
            gMotionModal.format(1),
            wOutput.format(cycle.chuckPosition),
            getFeed(cycle.feedrate)
          );
          onDwell(cycle.dwell);
        }
        writeBlock(
          mFormat.format(getCode("CLAMP_CHUCK", getSecondarySpindle())),
          formatComment("CLAMP SUB SPINDLE")
        );
        onDwell(cycle.dwell);
        chuckMachineFrame = cycle.useMachineFrame;
        chuckSubPosition = cycle.chuckPosition;
        machineState.stockTransferIsActive = true;
        break;
      case "secondary-spindle-return":
      case "secondary-spindle-pull":
        var pullMethod = getSecondaryPullMethod(cycleType);
        if (!machineState.stockTransferIsActive) {
          if (pullMethod.pull) {
            error(
              localize("The part must be chucked prior to a pull operation.")
            );
            return;
          }
        }

        // bar pull
        if (pullMethod.pull) {
          writeBlock(
            mFormat.format(getCode("UNCLAMP_CHUCK", getSpindle(PART))),
            formatComment("UNCLAMP MAIN CHUCK")
          );
          onDwell(cycle.dwell);
          writeBlock(
            gMotionModal.format(1),
            wOutput.format(pullMethod.pullPosition),
            getFeed(cycle.feedrate),
            formatComment("BAR PULL")
          );
          writeBlock(
            "VSZOZ=",
            zFormat.format(getProperty("mainZHome") + pullMethod.pullPosition),
            formatComment("PART LOCATION SHIFT")
          );
          machineState.spindlesAreAttached = true;
        }

        // move subspindle to home
        if (pullMethod.home) {
          machineState.spindlesAreAttached = false;
          if (pullMethod.unclampMode == "unclamp-secondary") {
            // simple bar pulling operation
            writeBlock(
              mFormat.format(getCode("CLAMP_CHUCK", getSpindle(PART))),
              formatComment("CLAMP MAIN CHUCK")
            );
            onDwell(cycle.dwell);
            writeBlock(
              mFormat.format(getCode("UNCLAMP_CHUCK", getSecondarySpindle())),
              formatComment("UNCLAMP SUB CHUCK")
            );
            onDwell(cycle.dwell);
          }
          writeBlock(
            gMotionModal.format(0),
            wOutput.format(getProperty("homePositionW")),
            formatComment("SUB SPINDLE RETURN")
          );
          writeBlock(
            mFormat.format(getCode("INTERNAL_INTERLOCK_OFF", getSpindle(PART))),
            formatComment("MAIN CHUCK INTERLOCK RELEASE OFF")
          );
          writeBlock(
            mFormat.format(
              getCode("INTERNAL_INTERLOCK_OFF", getSecondarySpindle())
            ),
            formatComment("SUB CHUCK INTERLOCK RELEASE OFF")
          );
        } else {
          writeBlock(
            mFormat.format(getCode("CLAMP_CHUCK", getSpindle(PART))),
            formatComment("CLAMP MAIN CHUCK")
          );
          onDwell(cycle.dwell);
        }
        machineState.stockTransferIsActive = true;
        break;
    }
  }

  if (cycleType == "stock-transfer") {
    warning(
      localize(
        "Stock transfer is not supported. Required machine specific customization."
      )
    );
    return;
  }
}

var isCannedCycle = false;
function onCyclePath() {
  saveShowSequenceNumbers = showSequenceNumbers;
  var verticalPasses;
  if (cycle.profileRoughingCycle == 0) {
    verticalPasses = false;
  } else if (cycle.profileRoughingCycle == 1) {
    verticalPasses = true;
  } else {
    error(localize("Unsupported passes type."));
    return;
  }
  isCannedCycle = true;
  // buffer all paths and stop feeds being output
  feedOutput.disable();
  showSequenceNumbers = "false";
  redirectToBuffer();
  writeBlock(
    "NAT" + getCurrentSectionId() + " " + (verticalPasses ? "G82" : "G81")
  );
  gMotionModal.reset();
  xOutput.reset();
  zOutput.reset();
}

function onCyclePathEnd() {
  writeBlock(gFormat.format(80));
  showSequenceNumbers = saveShowSequenceNumbers; // reset property to initial state
  feedOutput.enable();
  var cyclePath = String(getRedirectionBuffer()).split(EOL); // get cycle path from buffer
  closeRedirection();
  for (line in cyclePath) {
    // remove empty elements
    if (cyclePath[line] == "") {
      cyclePath.splice(line);
    }
  }

  // output cycle data
  switch (cycleType) {
    case "turning-canned-rough":
      writeBlock(
        gFormat.format(85),
        "NAT" +
          getCurrentSectionId() +
          " D" +
          spatialFormat.format(cycle.depthOfCut) +
          " U" +
          xFormat.format(Math.abs(cycle.xStockToLeave)) +
          " W" +
          spatialFormat.format(Math.abs(cycle.zStockToLeave)) +
          " " +
          getFeed(cycle.cutfeedrate)
      );
      break;
    default:
      error(localize("Unsupported turning canned cycle."));
  }

  for (var i = 0; i < cyclePath.length; ++i) {
    if (i == 0) {
      writeln(cyclePath[i]);
    } else {
      writeBlock(cyclePath[i]); // output cycle path
    }
    showSequenceNumbers = saveShowSequenceNumbers; // reset property to initial state
    isCannedCycle = false;
  }
}

function getCommonCycle(x, y, z, r) {
  if (machineState.usePolarCoordinates) {
    var polarPosition = getPolarPosition(x, y, z);
    setCurrentPositionAndDirection(polarPosition);
    // setCAxisDirection(cOutput.getCurrent(), currentC); // causes extra hole to be drilled & manual recommends using a single direction for accuracy
    xOutput.reset();
    zOutput.reset();
    cOutput.reset();
    return [
      xOutput.format(polarPosition.first.x),
      cOutput.format(polarPosition.second.z),
      zOutput.format(polarPosition.first.z),
      conditional(
        r != 0,
        (gPlaneModal.getCurrent() == 17 ? "K" : "I") + spatialFormat.format(r)
      ),
    ];
  } else {
    return [
      xOutput.format(x),
      yOutput.format(y),
      zOutput.format(z),
      conditional(
        r != 0,
        (gPlaneModal.getCurrent() == 17 ? "K" : "I") + spatialFormat.format(r)
      ),
    ];
  }
}

function writeCycleClearance(plane, clearance) {
  if (true) {
    onCycleEnd();
    switch (plane) {
      case 17:
        writeBlock(gMotionModal.format(0), zOutput.format(clearance));
        break;
      case 18:
        writeBlock(gMotionModal.format(0), yOutput.format(clearance));
        break;
      case 19:
        writeBlock(gMotionModal.format(0), xOutput.format(clearance));
        break;
      default:
        error(localize("Unsupported drilling orientation."));
        return;
    }
  }
}

var threadStart;
var threadEnd;
function moveToThreadStart(x, y, z) {
  var cuttingAngle = 0;
  if (hasParameter("operation:infeedAngle")) {
    cuttingAngle = getParameter("operation:infeedAngle");
  }
  if (cuttingAngle != 0) {
    var zz;
    if (isFirstCyclePoint()) {
      threadStart = getCurrentPosition();
      threadEnd = new Vector(x, y, z);
    } else {
      var zz =
        threadStart.z -
        Math.abs(threadEnd.x - x) * Math.tan(toRad(cuttingAngle));
      writeBlock(gMotionModal.format(0), zOutput.format(zz));
      threadStart.setZ(zz);
      threadEnd = new Vector(x, y, z);
    }
  }
}

var skipThreading = false;
function onCyclePoint(x, y, z) {
  if (!getProperty("useCycles") || currentSection.isMultiAxis()) {
    expandCyclePoint(x, y, z);
    return;
  }

  var plane = gPlaneModal.getCurrent();
  if (
    isSameDirection(currentSection.workPlane.forward, new Vector(0, 0, 1)) ||
    isSameDirection(currentSection.workPlane.forward, new Vector(0, 0, -1))
  ) {
    plane = 17; // XY plane
  } else if (
    Vector.dot(currentSection.workPlane.forward, new Vector(0, 0, 1)) < 1e-7
  ) {
    plane = 19; // YZ plane
  } else {
    expandCyclePoint(x, y, z);
    return;
  }

  switch (cycleType) {
    case "thread-turning":
      if (skipThreading) {
        // HSM outputs multiple cycles for multi-start threading
        return;
      }
      var numberOfThreads = 1;
      if (
        hasParameter("operation:doMultipleThreads") &&
        getParameter("operation:doMultipleThreads") != 0
      ) {
        numberOfThreads = getParameter("operation:numberOfThreads");
      }
      if (
        getProperty("useSimpleThread") &&
        !(
          hasParameter("operation:doMultipleThreads") &&
          getParameter("operation:doMultipleThreads") != 0
        )
      ) {
        moveToThreadStart(x, y, z);
        gCycleModal.reset();
        zOutput.reset();
        writeBlock(
          gCycleModal.format(33),
          xOutput.format(x - cycle.incrementalX),
          zOutput.format(z),
          iOutput.format(cycle.incrementalX),
          pitchOutput.format(cycle.pitch)
        );
      } else {
        if (isLastCyclePoint()) {
          var threadHeight = getParameter("operation:threadDepth");
          var firstDepthOfCut = cycle.firstPassDepth
            ? cycle.firstPassDepth
            : threadHeight - Math.abs(getCyclePoint(0).x - x);
          var cuttingAngle = 0;
          if (hasParameter("operation:infeedAngle")) {
            cuttingAngle = getParameter("operation:infeedAngle");
          }

          var threadInfeedMode = "constant";
          if (hasParameter("operation:infeedMode")) {
            threadInfeedMode = getParameter("operation:infeedMode");
          }
          var infeedModeCode = 0;
          var threadCuttingMode = 0;
          if (threadInfeedMode == "reduced") {
            threadCuttingMode = 32;
            infeedModeCode = 75;
          } else if (threadInfeedMode == "constant") {
            threadCuttingMode = 32;
            infeedModeCode = 73;
          } else if (threadInfeedMode == "alternate") {
            threadCuttingMode = 33;
            infeedModeCode = 75;
          } else {
            error(localize("Unsupported Infeed Mode."));
            return;
          }

          writeBlock(
            gCycleModal.format(71),
            xOutput.format(x),
            zOutput.format(z),
            // "A" + taperFormat.format(Math.atan2(cycle.incrementalX, cycle.incrementalZ * -1)), // taper angle instead of I
            conditional(
              cuttingAngle != 0,
              "B" + zFormat.format(cuttingAngle * 2)
            ),
            "D" + xFormat.format(firstDepthOfCut),
            "H" + xFormat.format(threadHeight), // output as diameter
            iOutput.format(cycle.incrementalX),
            conditional(numberOfThreads > 1, "Q" + numberOfThreads),
            feedOutput.format(cycle.pitch),
            mFormat.format(threadCuttingMode),
            mFormat.format(infeedModeCode)
          );
          skipThreading = numberOfThreads != 0;
        }
      }
      return;
  }

  var lockCode = "";

  var rapto = 0;
  if (isFirstCyclePoint()) {
    // first cycle point
    rapto = cycle.clearance - cycle.retract;

    var P = !cycle.dwell ? 0 : clamp(1, cycle.dwell, 99999999); // in seconds

    switch (cycleType) {
      case "drilling":
        writeCycleClearance(plane, cycle.clearance);
        xOutput.reset();
        zOutput.reset();
        writeBlock(
          gCycleModal.format(machineState.axialCenterDrilling ? 74 : 181),
          getCommonCycle(x, y, z, rapto),
          "D" + spatialFormat.format(cycle.depth + cycle.retract - cycle.stock),
          getFeed(cycle.feedrate)
        );
        break;
      case "counter-boring":
        writeCycleClearance(plane, cycle.clearance);
        xOutput.reset();
        zOutput.reset();
        writeBlock(
          gCycleModal.format(machineState.axialCenterDrilling ? 74 : 182),
          getCommonCycle(x, y, z, rapto),
          "D" + spatialFormat.format(cycle.depth + cycle.retract - cycle.stock),
          conditional(P > 0, eOutput.format(P)),
          getFeed(cycle.feedrate)
        );
        break;
      case "deep-drilling":
        writeCycleClearance(plane, cycle.clearance);
        xOutput.reset();
        zOutput.reset();
        writeBlock(
          gCycleModal.format(machineState.axialCenterDrilling ? 74 : 183),
          getCommonCycle(x, y, z, rapto),
          "D" + spatialFormat.format(cycle.incrementalDepth),
          "L" + spatialFormat.format(cycle.incrementalDepth),
          conditional(P > 0, eOutput.format(P)),
          getFeed(cycle.feedrate)
        );
        break;
      case "chip-breaking":
        writeCycleClearance(plane, cycle.clearance);
        xOutput.reset();
        zOutput.reset();
        writeBlock(
          gCycleModal.format(machineState.axialCenterDrilling ? 74 : 183),
          getCommonCycle(x, y, z, rapto),
          "D" + spatialFormat.format(cycle.incrementalDepth),
          conditional(
            cycle.accumulatedDepth > 0,
            "L" + spatialFormat.format(cycle.accumulatedDepth)
          ),
          conditional(P > 0, eOutput.format(P)),
          getFeed(cycle.feedrate)
        );
        break;
      case "tapping":
      case "right-tapping":
      case "left-tapping":
        writeCycleClearance(plane, cycle.clearance);
        xOutput.reset();
        zOutput.reset();
        reverseTap = tool.type == TOOL_TAP_LEFT_HAND;
        if (machineState.axialCenterDrilling) {
          if (P != 0) {
            expandCyclePoint(x, y, z);
          } else {
            writeCycleClearance(plane, cycle.retract);
            writeBlock(
              gCycleModal.format(reverseTap ? 78 : 77),
              getCommonCycle(x, y, z, 0),
              getFeed(cycle.feedrate)
            );
            onCommand(COMMAND_START_SPINDLE);
          }
        } else {
          writeCycleClearance(plane, cycle.clearance);
          writeBlock(
            gCycleModal.format(184),
            getCommonCycle(x, y, z, rapto),
            "D" +
              spatialFormat.format(cycle.depth + cycle.retract - cycle.stock),
            conditional(P > 0, eOutput.format(P)),
            getFeed(cycle.feedrate)
          );
        }
        break;
      case "reaming":
      case "boring":
        if (
          feedFormat.getResultingValue(cycle.feedrate) !=
          feedFormat.getResultingValue(cycle.retractFeedrate)
        ) {
          expandCyclePoint(x, y, z);
          break;
        }
        writeCycleClearance(plane, cycle.clearance);
        xOutput.reset();
        zOutput.reset();
        writeBlock(
          gCycleModal.format(machineState.axialCenterDrilling ? 74 : 189),
          getCommonCycle(x, y, z, rapto),
          "D" + spatialFormat.format(cycle.depth + cycle.retract - cycle.stock),
          conditional(P > 0, eOutput.format(P)),
          getFeed(cycle.feedrate)
        );
        break;
      default:
        expandCyclePoint(x, y, z);
    }
  } else {
    // position to subsequent cycle points
    if (cycleExpanded) {
      expandCyclePoint(x, y, z);
    } else {
      var step = 0;
      if (cycleType == "chip-breaking" || cycleType == "deep-drilling") {
        step = cycle.incrementalDepth;
      }
      writeBlock(getCommonCycle(x, y, z, rapto, false), lockCode);
    }
  }
}

function onCycleEnd() {
  if (!cycleExpanded && !machineState.stockTransferIsActive) {
    writeBlock(gCycleModal.format(180));
    gMotionModal.reset();
  }
  skipThreading = true;
}

function onPassThrough(text) {
  var commands = String(text).split(",");
  for (text in commands) {
    writeBlock(commands[text]);
  }
}

function onParameter(name, value) {
  var invalid = false;
  switch (name) {
    case "action":
      if (String(value).toUpperCase() == "PARTEJECT") {
        ejectRoutine = true;
      } else if (
        String(value).toUpperCase() == "USEPOLARMODE" ||
        String(value).toUpperCase() == "USEPOLARINTERPOLATION"
      ) {
        forcePolarInterpolation = true;
        forcePolarCoordinates = false;
      } else if (
        String(value).toUpperCase() == "USEXZCMODE" ||
        String(value).toUpperCase() == "USEPOLARCOORDINATES"
      ) {
        forcePolarCoordinates = true;
        forcePolarInterpolation = false;
      } else {
        invalid = true;
      }
  }
  if (invalid) {
    error(localize("Invalid action parameter: ") + value);
    return;
  }
}

var currentCoolantMode = COOLANT_OFF;
var currentCoolantTurret = 1;
var coolantOff = undefined;
var isOptionalCoolant = false;
var forceCoolant = false;

function setCoolant(coolant, turret) {
  var coolantCodes = getCoolantCodes(coolant, turret);
  if (Array.isArray(coolantCodes)) {
    if (singleLineCoolant) {
      skipBlock = isOptionalCoolant;
      writeBlock(coolantCodes.join(getWordSeparator()));
    } else {
      for (var c in coolantCodes) {
        skipBlock = isOptionalCoolant;
        writeBlock(coolantCodes[c]);
      }
    }
    return undefined;
  }
  return coolantCodes;
}

function getCoolantCodes(coolant, turret) {
  turret = gotMultiTurret ? (turret == undefined ? 1 : turret) : 1;
  isOptionalCoolant = false;
  var multipleCoolantBlocks = new Array(); // create a formatted array to be passed into the outputted line
  if (!coolants) {
    error(localize("Coolants have not been defined."));
  }
  if (tool.type == TOOL_PROBE) {
    // avoid coolant output for probing
    coolant = COOLANT_OFF;
  }
  if (coolant == currentCoolantMode && turret == currentCoolantTurret) {
    if (
      typeof operationNeedsSafeStart != "undefined" &&
      operationNeedsSafeStart &&
      coolant != COOLANT_OFF
    ) {
      isOptionalCoolant = true;
    } else if (!forceCoolant || coolant == COOLANT_OFF) {
      return undefined; // coolant is already active
    }
  }
  if (
    coolant != COOLANT_OFF &&
    currentCoolantMode != COOLANT_OFF &&
    coolantOff != undefined &&
    !forceCoolant &&
    !isOptionalCoolant
  ) {
    if (Array.isArray(coolantOff)) {
      for (var i in coolantOff) {
        multipleCoolantBlocks.push(coolantOff[i]);
      }
    } else {
      multipleCoolantBlocks.push(coolantOff);
    }
  }
  forceCoolant = false;

  var m;
  var coolantCodes = {};
  for (var c in coolants) {
    // find required coolant codes into the coolants array
    if (coolants[c].id == coolant) {
      var localCoolant = parseCoolant(coolants[c], turret);
      localCoolant =
        typeof localCoolant == "undefined" ? coolants[c] : localCoolant;
      coolantCodes.on = localCoolant.on;
      if (localCoolant.off != undefined) {
        coolantCodes.off = localCoolant.off;
        break;
      } else {
        for (var i in coolants) {
          if (coolants[i].id == COOLANT_OFF) {
            coolantCodes.off = localCoolant.off;
            break;
          }
        }
      }
    }
  }
  if (coolant == COOLANT_OFF) {
    m = !coolantOff ? coolantCodes.off : coolantOff; // use the default coolant off command when an 'off' value is not specified
  } else {
    coolantOff = coolantCodes.off;
    m = coolantCodes.on;
  }

  if (!m) {
    onUnsupportedCoolant(coolant);
    m = 9;
  } else {
    if (Array.isArray(m)) {
      for (var i in m) {
        multipleCoolantBlocks.push(m[i]);
      }
    } else {
      multipleCoolantBlocks.push(m);
    }
    currentCoolantMode = coolant;
    currentCoolantTurret = turret;
    for (var i in multipleCoolantBlocks) {
      if (typeof multipleCoolantBlocks[i] == "number") {
        multipleCoolantBlocks[i] = mFormat.format(multipleCoolantBlocks[i]);
      }
    }
    return multipleCoolantBlocks; // return the single formatted coolant value
  }
  return undefined;
}

function parseCoolant(coolant, turret) {
  var localCoolant;
  if (getSpindle(TOOL) == SPINDLE_MAIN) {
    localCoolant = turret == 1 ? coolant.spindle1t1 : coolant.spindle1t2;
    localCoolant =
      typeof localCoolant == "undefined" ? coolant.spindle1 : localCoolant;
  } else if (getSpindle(TOOL) == SPINDLE_LIVE) {
    localCoolant = turret == 1 ? coolant.spindleLivet1 : coolant.spindleLivet2;
    localCoolant =
      typeof localCoolant == "undefined" ? coolant.spindleLive : localCoolant;
  } else {
    localCoolant = turret == 1 ? coolant.spindle2t1 : coolant.spindle2t2;
    localCoolant =
      typeof localCoolant == "undefined" ? coolant.spindle2 : localCoolant;
  }
  localCoolant =
    typeof localCoolant == "undefined"
      ? turret == 1
        ? coolant.turret1
        : coolant.turret2
      : localCoolant;
  localCoolant = typeof localCoolant == "undefined" ? coolant : localCoolant;
  return localCoolant;
}

function isSpindleSpeedDifferent() {
  var areDifferent = false;
  if (isFirstSection()) {
    areDifferent = true;
  }
  if (lastSpindleDirection != tool.clockwise) {
    areDifferent = true;
  }
  if (tool.getSpindleMode() == SPINDLE_CONSTANT_SURFACE_SPEED) {
    var _spindleSpeed =
      tool.surfaceSpeed * (unit == MM ? 1 / 1000.0 : 1 / 12.0);
    if (
      lastSpindleMode != SPINDLE_CONSTANT_SURFACE_SPEED ||
      rpmFormat.areDifferent(lastSpindleSpeed, _spindleSpeed)
    ) {
      areDifferent = true;
    }
  } else {
    if (
      lastSpindleMode != SPINDLE_CONSTANT_SPINDLE_SPEED ||
      rpmFormat.areDifferent(lastSpindleSpeed, spindleSpeed)
    ) {
      areDifferent = true;
    }
  }
  return areDifferent;
}

function onSpindleSpeed(spindleSpeed) {
  var current =
    getSpindle(TOOL) == SPINDLE_LIVE
      ? sbOutput.getCurrent()
      : sOutput.getCurrent();
  if (rpmFormat.areDifferent(spindleSpeed, current) || forceSpindleSpeed) {
    // avoid redundant output of spindle speed
    startSpindle(false, false);
    forceSpindleSpeed = false;
  }
}

function startSpindle(tappingMode, forceRPMMode, initialPosition) {
  var spindleDir;
  var _spindleSpeed;
  var spindleMode;

  gSpindleModeModal.reset();

  if (getSpindle(PART) == SPINDLE_SUB && !gotSecondarySpindle) {
    error(localize("Secondary spindle is not available."));
    return;
  }

  if (false /*tappingMode*/) {
    spindleDir = mFormat.format(getCode("RIGID_TAPPING", getSpindle(TOOL)));
  } else {
    spindleDir = mFormat.format(
      tool.clockwise
        ? getCode("START_SPINDLE_CW", getSpindle(TOOL))
        : getCode("START_SPINDLE_CCW", getSpindle(TOOL))
    );
  }

  var maximumSpindleSpeed =
    tool.maximumSpindleSpeed > 0
      ? Math.min(tool.maximumSpindleSpeed, getProperty("maximumSpindleSpeed"))
      : getProperty("maximumSpindleSpeed");
  if (tool.getSpindleMode() == SPINDLE_CONSTANT_SURFACE_SPEED) {
    _spindleSpeed = tool.surfaceSpeed * (unit == MM ? 1 / 1000.0 : 1 / 12.0);
    if (forceRPMMode) {
      // RPM mode is forced until move to initial position
      if (xFormat.getResultingValue(initialPosition.x) == 0) {
        _spindleSpeed = maximumSpindleSpeed;
      } else {
        _spindleSpeed = Math.min(
          (_spindleSpeed * (unit == MM ? 1000.0 : 12.0)) /
            (Math.PI * Math.abs(initialPosition.x * 2)),
          maximumSpindleSpeed
        );
      }
      spindleMode = getCode("CONSTANT_SURFACE_SPEED_OFF", getSpindle(TOOL));
    } else {
      spindleMode = getCode("CONSTANT_SURFACE_SPEED_ON", getSpindle(TOOL));
    }
  } else {
    _spindleSpeed = spindleSpeed;
    spindleMode = getCode("CONSTANT_SURFACE_SPEED_OFF", getSpindle(TOOL));
  }

  var scode =
    getSpindle(TOOL) == SPINDLE_LIVE
      ? sbOutput.format(_spindleSpeed)
      : sOutput.format(_spindleSpeed);
  if (machineState.isTurningOperation) {
    writeBlock(gSpindleModeModal.format(spindleMode), scode, spindleDir);
  } else {
    writeBlock(scode, spindleDir);
  }
  // wait for spindle here if required

  lastSpindleMode = tool.getSpindleMode();
  lastSpindleSpeed = _spindleSpeed;
  lastSpindleDirection = tool.clockwise;
}

function onCommand(command) {
  switch (command) {
    case COMMAND_COOLANT_OFF:
      setCoolant(COOLANT_OFF);
      break;
    case COMMAND_COOLANT_ON:
      setCoolant(tool.coolant);
      break;
    case COMMAND_LOCK_MULTI_AXIS:
      writeBlock(
        cAxisBrakeModal.format(getCode("LOCK_MULTI_AXIS", getSpindle(PART)))
      );
      break;
    case COMMAND_UNLOCK_MULTI_AXIS:
      writeBlock(
        cAxisBrakeModal.format(getCode("UNLOCK_MULTI_AXIS", getSpindle(PART)))
      );
      break;
    case COMMAND_START_CHIP_TRANSPORT:
      writeBlock(mFormat.format(244));
      break;
    case COMMAND_STOP_CHIP_TRANSPORT:
      writeBlock(mFormat.format(243));
      break;
    case COMMAND_OPEN_DOOR:
      if (gotDoorControl) {
        writeBlock(mFormat.format(208)); // optional
      }
      break;
    case COMMAND_CLOSE_DOOR:
      if (gotDoorControl) {
        writeBlock(mFormat.format(209)); // optional
      }
      break;
    case COMMAND_BREAK_CONTROL:
      break;
    case COMMAND_TOOL_MEASURE:
      break;
    case COMMAND_ACTIVATE_SPEED_FEED_SYNCHRONIZATION:
      break;
    case COMMAND_DEACTIVATE_SPEED_FEED_SYNCHRONIZATION:
      break;
    case COMMAND_STOP:
      writeBlock(mFormat.format(0));
      forceSpindleSpeed = true;
      forceCoolant = true;
      break;
    case COMMAND_OPTIONAL_STOP:
      writeBlock(mFormat.format(1));
      forceSpindleSpeed = true;
      forceCoolant = true;
      break;
    case COMMAND_END:
      writeBlock(mFormat.format(2));
      break;
    case COMMAND_STOP_SPINDLE:
      writeBlock(mFormat.format(getCode("STOP_SPINDLE", activeSpindle)));
      forceSpindleSpeed = true;
      break;
    case COMMAND_ORIENTATE_SPINDLE:
      if (machineState.isTurningOperation || machineState.axialCenterDrilling) {
        writeBlock(mFormat.format(getCode("ORIENT_SPINDLE", getSpindle(PART))));
      } else {
        error(
          localize("Spindle orientation is not supported for live tooling.")
        );
        return;
      }
      forceSpindleSpeed = true;
      break;
    case COMMAND_START_SPINDLE:
      onCommand(
        tool.clockwise
          ? COMMAND_SPINDLE_CLOCKWISE
          : COMMAND_SPINDLE_COUNTERCLOCKWISE
      );
      return;
    case COMMAND_SPINDLE_CLOCKWISE:
      writeBlock(mFormat.format(getCode("START_SPINDLE_CW", getSpindle(TOOL))));
      break;
    case COMMAND_SPINDLE_COUNTERCLOCKWISE:
      writeBlock(
        mFormat.format(getCode("START_SPINDLE_CCW", getSpindle(TOOL)))
      );
      break;
    // case COMMAND_CLAMP: // add support for clamping
    // case COMMAND_UNCLAMP: // add support for clamping
    default:
      onUnsupportedCommand(command);
  }
}

/** Get synchronization/transfer code based on part cutoff spindle direction. */
function getSpindleTransferCodes() {
  var tool = currentSection.getTool();
  var transferCodes = {
    direction: tool.clockwise
      ? getCode("START_SPINDLE_CW", getSpindle(PART))
      : getCode("START_SPINDLE_CCW", getSpindle(PART)),
    spindleMode: SPINDLE_CONSTANT_SPINDLE_SPEED,
    surfaceSpeed: tool.surfaceSpeed,
    maximumSpindleSpeed: tool.maximumSpindleSpeed,
  };
  var numberOfSections = getNumberOfSections();
  for (var i = getNextSection().getId(); i < numberOfSections; ++i) {
    var section = getSection(i);
    if (
      section.getParameter("operation-strategy") ==
        "turningSecondarySpindleReturn" ||
      section.getParameter("operation-strategy") ==
        "turningSecondarySpindlePull"
    ) {
      continue;
    } else if (
      section.getType() != TYPE_TURNING ||
      section.spindle != SPINDLE_MAIN
    ) {
      break;
    } else if (section.getType() == TYPE_TURNING) {
      var tool = section.getTool();
      transferCodes.spindleMode = tool.getSpindleMode();
      transferCodes.surfaceSpeed = tool.surfaceSpeed;
      transferCodes.maximumSpindleSpeed = tool.maximumSpindleSpeed;
      transferCodes.spindleDirection = tool.clockwise;
      break;
    }
  }
  return transferCodes;
}

function getG17Code() {
  return machineState.usePolarInterpolation ? 17 : 17;
}

function ejectPart() {
  writeln("");
  if (getProperty("showSequenceNumbers") == "toolChange") {
    writeCommentSeqno(localize("PART EJECT"));
  } else {
    writeComment(localize("PART EJECT"));
  }
  gMotionModal.reset();
  // writeBlock(gMotionModal.format(0), gFormat.format(28), gFormat.format(53), "B" + abcFormat.format(0)); // retract bar feeder
  writeRetract(X); // Position all axes to home position
  writeRetract(Z);
  writeBlock(mFormat.format(getCode("UNLOCK_MULTI_AXIS", getSpindle(PART))));
  if (!getProperty("optimizeCAxisSelect")) {
    cAxisEngageModal.reset();
  }
  writeBlock(
    gFeedModeModal.format(getCode("FEED_MODE_UNIT_MIN", getSpindle(TOOL))),
    // gFormat.format(53 + currentWorkOffset),
    // gPlaneModal.format(getG17Code()),
    cAxisEngageModal.format(getCode("DISABLE_C_AXIS", getSpindle(PART)))
  );
  // setCoolant(COOLANT_THROUGH_TOOL);
  gSpindleModeModal.reset();
  writeBlock(
    gSpindleModeModal.format(
      getCode("CONSTANT_SURFACE_SPEED_OFF", getSpindle(PART))
    ),
    sOutput.format(50),
    mFormat.format(getCode("START_SPINDLE_CW", getSpindle(PART)))
  );
  // writeBlock(mFormat.format(getCode("INTERLOCK_BYPASS", getSpindle(PART))));
  if (getProperty("usePartCatcher")) {
    writeBlock(mFormat.format(getCode("PART_CATCHER_ON", getSpindle(PART))));
  }
  writeBlock(mFormat.format(getCode("UNCLAMP_CHUCK", getSpindle(PART))));
  onDwell(1.5);
  // writeBlock(mFormat.format(getCode("CYCLE_PART_EJECTOR")));
  // onDwell(0.5);
  if (getProperty("usePartCatcher")) {
    writeBlock(mFormat.format(getCode("PART_CATCHER_OFF", getSpindle(PART))));
    onDwell(1.1);
  }

  // clean out chips
  /*
  if (airCleanChuck) {
    writeBlock(mFormat.format(getCode("COOLANT_AIR_ON", getSpindle(PART))));
    onDwell(2.5);
    writeBlock(mFormat.format(getCode("COOLANT_AIR_OFF", getSpindle(PART))));
  }
*/
  writeBlock(mFormat.format(getCode("STOP_SPINDLE", getSpindle(PART))));
  // setCoolant(COOLANT_OFF);
  writeComment(localize("END OF PART EJECT"));
  writeln("");
}

function engagePartCatcher(engage) {
  if (getProperty("usePartCatcher")) {
    if (engage) {
      // engage part catcher
      writeBlock(
        mFormat.format(getCode("PART_CATCHER_ON", true)),
        formatComment(localize("PART CATCHER ON"))
      );
    } else {
      // disengage part catcher
      onCommand(COMMAND_COOLANT_OFF);
      writeBlock(
        mFormat.format(getCode("PART_CATCHER_OFF", true)),
        formatComment(localize("PART CATCHER OFF"))
      );
    }
  }
}

function onSectionEnd() {
  if (machineState.usePolarInterpolation) {
    setPolarInterpolation(false); // disable polar interpolation mode
  }

  if (isPolarModeActive()) {
    setPolarCoordinates(false); // disable Polar coordinates mode
  }

  // deactivate Y-axis
  if (gotYAxis && yOutput.isEnabled()) {
    writeBlock(gMotionModal.format(0), yOutput.format(0));
    writeBlock(gPolarModal.format(getCode("DISABLE_Y_AXIS", true)));
    yOutput.disable();
  }

  // cancel SFM mode to preserve spindle speed
  if (
    tool.getSpindleMode() == SPINDLE_CONSTANT_SURFACE_SPEED &&
    !machineState.stockTransferIsActive
  ) {
    startSpindle(
      false,
      true,
      getFramePosition(currentSection.getFinalPosition())
    );
  }

  if (
    getProperty("usePartCatcher") &&
    partCutoff &&
    currentSection.partCatcher
  ) {
    engagePartCatcher(false);
  }

  // Add tool call without offset to cancel tool compensation
  if (!isLastSection()) {
    writeBlock(formatTool(tool, true));
  }

  if (
    getCurrentSectionId() + 1 >= getNumberOfSections() ||
    tool.number != getNextSection().getTool().number
  ) {
    onCommand(COMMAND_BREAK_CONTROL);
  }
  operationNeedsSafeStart = false; // reset for next section

  forcePolarCoordinates = false;
  forcePolarInterpolation = false;
  partCutoff = false;
  forceAny();
  skipThreading = false;
}

function onClose() {
  var liveTool = getSpindle(TOOL) == SPINDLE_LIVE;
  optionalSection = false;
  if (machineState.stockTransferIsActive) {
    writeBlock(
      mFormat.format(getCode("SPINDLE_SYNCHRONIZATION_OFF", getSpindle(PART))),
      formatComment("SYNCHRONIZED ROTATION OFF")
    );
  } else {
    onCommand(COMMAND_STOP_SPINDLE);
    setCoolant(COOLANT_OFF);
  }

  writeln("");

  if (getProperty("gotChipConveyor")) {
    onCommand(COMMAND_STOP_CHIP_TRANSPORT);
  }
  if (machineState.tailstockIsActive) {
    writeBlock(mFormat.format(getCode("TAILSTOCK_OFF", SPINDLE_MAIN)));
  }

  gMotionModal.reset();
  if (gotSecondarySpindle) {
    // writeBlock(gMotionModal.format(0), gFormat.format(28), gFormat.format(53), "B" + abcFormat.format(0)); // retract Sub Spindle if applicable
  }

  var vszoz =
    getSection(0).spindle == SPINDLE_MAIN
      ? getProperty("mainZHome")
      : getProperty("subZHome");
  writeBlock("VSZOZ=", vszoz, formatComment("PART LOCATION"));

  // Move to home position
  writeRetract(X);
  writeRetract(Z);
  writeBlock(
    mFormat.format(getCode("UNCLAMP_CHUCK", getSecondarySpindle())),
    formatComment("UNCLAMP SUBSPINDLE")
  );
  onDwell(1);
  writeBlock(
    gFormat.format(0),
    wOutput.format(getProperty("homePositionW")),
    formatComment("SUB SPINDLE RETURN")
  );

  writeBlock(gPlaneModal.format(getCode("ENABLE_TURNING"), getSpindle(PART)));

  // cancel load monitoring
  if (getProperty("loadMonitoring") != 0) {
    writeln("VLMON[" + vlmon + "]=0");
    writeln(mFormat.format(215));
  }

  // Automatically eject part
  if (ejectRoutine) {
    ejectPart();
  }

  writeln("");
  onCommand(COMMAND_OPEN_DOOR);
  writeBlock(mFormat.format(30)); // stop program, spindle stop, coolant off
}

//////////////////////////////////////////// DSI UTILS //////////////////////////////////////////////
var headerFormat = createFormat({
  decimals: unit == MM ? 3 : 4,
  forceDecimal: true,
});

const setLengthRight = (string, length) => {
  let _string = string.slice(0, length);
  while (_string.length < length) {
    _string = " " + _string;
  }
  return _string;
};

const setLengthLeft = (string, length) => {
  let _string = string.slice(0, length);
  while (_string.length < length) {
    _string = _string + " ";
  }
  return _string;
};

const getTitleById = (property, valueId) => {
  var propertyValues = property.values;
  if (propertyValues) {
    var selectedValue = _.find(propertyValues, function (value) {
      return value.id === valueId;
    });
    if (selectedValue) {
      return selectedValue.title;
    }
  }
  return null;
};

function customEnumWithTitles(start, end, prefix) {
  prefix = prefix || "R"; // Fallback for undefined prefix
  var arr = [];
  arr.push({ title: "AUTO", id: "AUTO" });
  for (var i = start; i <= end; i++) {
    arr.push({
      title: prefix + i,
      id: String(i),
    });
  }
  return arr;
}

// DSI: Tool Table
function writeToolTable() {
  var numberOfSections = getNumberOfSections();
  var sections = {};
  for (var i = 0; i < numberOfSections; ++i) {
    var section = getSection(i);
    var tool = section.getTool();
    sections[tool.number] = section;
  }

  writeln("");
  writeComment("------TOOL LIST------");
  writeComment(
    "NO.                                      ID    DIAMETER   TIP RAD   STICKOUT "
  );
  writeComment(
    "----------------------------------------------------------------------------"
  );

  // dump tool information
  var tools = getToolTable();
  if (tools.getNumberOfTools() > 0) {
    for (var i = 0; i < tools.getNumberOfTools(); ++i) {
      var tool = tools.getTool(i);
      writeComment(writeToolFormat(tool, sections[tool.number]));
    }
  }
  writeComment(
    "----------------------------------------------------------------------------"
  );

  writeln("");
}

function writeToolFormat(tool, section) {
  var _no = 5;
  var _id = 37;
  var _diameter = 11;
  var _tipRad = 9;
  var _stickout = 10;
  var toolTable = [];
  var toolNumber = "T" + toolFormat.format(tool.number);
  var description = tool.description;
  var type = getToolTypeName(tool.type);
  var noseRadius = tool.isTurningTool()
    ? headerFormat.format(tool.noseRadius)
    : headerFormat.format(tool.cornerRadius);
  var diameter = headerFormat.format(tool.diameter);
  var bodyLength = headerFormat.format(tool.bodyLength);
  var toolVendor = tool.vendor;

  toolTable.push(setLengthLeft(toolNumber, _no));
  if (tool.description) {
    toolTable.push(setLengthRight(description, _id));
  } else {
    toolTable.push(setLengthRight(type, _id));
  }
  if (tool.isTurningTool()) {
    if (isTurningSpecialType(type, section)) {
      var shankData = getShankData(tool, section);
      var shankLength = shankData.shankLength;
      var shankDiameter = shankData.shankDiameter;
      toolTable.push(setLengthRight(shankDiameter, _diameter));
      toolTable.push(setLengthRight(noseRadius, _tipRad));
      toolTable.push(setLengthRight(shankLength, _stickout));
    } else {
      toolTable.push(setLengthRight(diameter, _diameter));
      tool.noseRadius
        ? toolTable.push(setLengthRight(noseRadius, _tipRad))
        : null;
      toolTable.push(setLengthRight(bodyLength, _stickout));
    }
  } else {
    toolTable.push(setLengthRight(diameter, _diameter));
    tool.noseRadius
      ? toolTable.push(setLengthRight(noseRadius, _tipRad))
      : null;
    toolTable.push(setLengthRight(bodyLength, _stickout));
  }
  return toolTable.join(" ");
}

function getShankData(tool, section) {
  var shankLength = "";
  var shankDiameter = "";
  if (tool.isTurningTool()) {
    shankLength = spatialFormat.format(
      parseFloat(section.getParameter("operation:tool_holderOverallLength", 0))
    );

    shankDiameter = spatialFormat.format(
      parseFloat(section.getParameter("operation:tool_shankWidth", 0))
    );
  }
  return { shankLength: shankLength, shankDiameter: shankDiameter };
}

function isTurningSpecialType(type, section) {
  return (
    type == "boring turning" ||
    type == "thread turning" ||
    (type == "groove turning" &&
      section.getParameter("operation:machineInside") == "1")
  );
}

// DSI: Program Header
function getHeader() {
  const date = new Date();
  const formattedDateTime = (d) => {
    const z = (n) => (n < 10 ? `0${n}` : n);
    const h = d.getHours();
    return `${d.toLocaleDateString()} AT ${h % 12 || 12}:${z(d.getMinutes())} ${
      h < 12 ? "AM" : "PM"
    }`;
  };

  const programHeaderName = getGlobalParameter("job-description");
  const partName = getGlobalParameter("document-path");
  const programDate = formattedDateTime(date);
  const programmedBy = getGlobalParameter("username");

  const header = [
    ["PROGRAM NAME", programHeaderName],
    ["PART NAME", partName],
    ["PROGRAM DATE", programDate],
    ["PROGRAMMED by", programmedBy],
    ["POST VERSION", dsiPostVersion + "." + minimumRevision],
  ];
  return header.forEach((line) => writeComment(line.join(": ")));
}

function writeHeader() {
  getHeader();
  if (getProperty("writeTools")) {
    writeToolTable();
  }
}

var bufferPassThrough = true;
var manualNC = [];
function onManualNC(command, value) {
  if (command == COMMAND_PASS_THROUGH && bufferPassThrough) {
    manualNC.push({ command: command, value: value });
  } else {
    expandManualNC(command, value);
  }
}

function executeManualNC(command) {
  if (manualNC.length > 0) {
    writeln("");
    writeComment("MANUAL NC COMMANDS");
  }
  for (var i = 0; i < manualNC.length; ++i) {
    if (!command || command == manualNC[i].command) {
      expandManualNC(manualNC[i].command, manualNC[i].value);
    }
  }
  for (var i = manualNC.length - 1; i >= 0; --i) {
    if (!command || command == manualNC[i].command) {
      manualNC.splice(i, 1);
    }
  }
}

groupDefinitions = {
  dsi: { title: "POST CREATED BY www.DSI-MFG.com", order: 0 },
  _customer: { title: `${customer}`, order: 1 },
  postControl: { title: "Post Processor Features", order: 2 },
  preferences: { title: "Control Features", order: 3, collapsed: true },
  documentation: { title: "Documentation", order: 4, collapsed: true },
  formats: { title: "Formatting", order: 5, collapsed: true },
  probing: { title: "Probing", order: 6, collapsed: true },
  multiAxis: { title: "Multi axis", order: 7, collapsed: true },
  homePositions: { title: "Home Positions", order: 8, collapsed: true },
};

// DSI
properties.dsiSupport = {
  title: "For support contact",
  description: "",
  group: "dsi",
  type: "enum",
  values: [{ title: "support@dsi-mfg.com", id: "" }],
  value: "",
  scope: "post",
};
properties.dsiPhone = {
  title: "Phone",
  description: "",
  group: "dsi",
  type: "enum",
  values: [{ title: "1 (833) 374-4634", id: "" }],
  value: "",
  scope: "post",
};
properties.postManual = {
  title: "Post Manual Link",
  description: "Link to the post manual",
  group: "dsi",
  type: "enum",
  values: [{ title: "Post Manual", id: "" }],
  value: "",
  scope: "post",
  visible: false, // Chnage this to true if there is a post manual
};

function writeDebug(_text) {
  if (dsiDebug) {
    writeComment("DEBUG - " + _text);
    log("DEBUG - " + _text);
  }
}

function getSpindleID(spindle) {
  return spindle == SPINDLE_MAIN ? "SP=1" : "SP=2";
}
