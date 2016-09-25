scriptname AAF:FrameworkQuest extends Quest Conditional

; ==================================================
; Structs
; ==================================================

struct Attribute
	AAF:AttributeBase AV
	ActorValue AVIF
	string Name
endstruct

struct RankRequirements
	float Strong	= 75.0
	float Medium	= 50.0
	float Weak		= 20.0
endstruct



; ==================================================
; Properties
; ==================================================

Attribute[] property AttributeList auto hidden
{A list of all currently registered attributes.}

RankRequirements property Requirements auto
{A list of requirements for the different attribute ranks. Can be used for user configuration later.}

int property LoggingLevel = 1 auto
{The current log level... 0 = off, 1 = errors, 2 = errors + warnings, 3 = all.}

int[] property MutexList auto hidden
{Current list of MutexIds. This proeprty should not be changed manually!}

float property MutexWaitTime = 1.0 auto
{The amount of seconds that should be waited for each mutex cycle. Decrease this if the script is processing values too slowly.}

; Totally stupid check to see if the array is initialized or not.
; Initializes the arrays with 0 elements, otherwise they won't work.
event OnInit()
	if !AttributeList
		AttributeList = new Attribute[0]
	endif
	if !MutexList
		MutexList = new int[0]
	endif
endevent


; ==================================================
; Mutex
; ==================================================

; Starts a new mutex loop and returns the Id after it's finished.
; Returns -1 if the Id couldn't be found in the list (i.e. after the list got cleared). It is recommended to terminate the function that called it if that's the case.
; CAUTION: Always remember to call MutexEnd() at the end of the function, or the framework will be stuck in an infinite loop!
int function MutexStart()
	int MutexId
	if MutexList.length
		MutexId = MutexList[MutexList.length-1]+1
		if MutexId <= 0
			MutexId = 1
		endif
	else
		MutexId = 1
	endif
	MutexList.Add(MutexId)
	while MutexList[0] != MutexId
		if MutexList.Find(MutexId) < 0
			; check if the MutexId is still in cue... if not, return error
			return -1
		endif
		; wait for another check
		Utility.WaitMenuMode(MutexWaitTime)
	endwhile
	return MutexId
endfunction

; Called after all changes had been made to the attributes. Removes the passed in MutexId from the top of the list.
; CAUTION: Do NOT forget to call this function, as this will put the whole framework into an infite loop!
; CAUTION: If the passed in MutexId is NOT the first one in the array, it will clears the list, so all currently waiting functions will terminate!
function MutexEnd(int MutexId)
	if MutexList[0] == MutexId
		MutexList.Remove(0)
	else
		Error("MutexEnd() could not find MutexId.")
		MutexReset()
	endif
endfunction

; Clears the current MutexList. It should terminate all currently waiting function calls, so it should be called only on errors or problems.
function MutexReset()
	Warning("MutexReset() has been called... removing que.")
	MutexList.Clear()
endfunction



; ==================================================
; Registration
; ==================================================

; Register a new Attribute.
; returns -1 for errors, 0 if it's already registered and 1 if successfully registered.
int function RegisterAttribute(AAF:AttributeBase AttributeToAdd)
	; Check the passed in attribute...
	if (!AttributeToAdd)
		Error("RegisterAttribute() Could not register Attribute \"none\"")
		return -1
	elseif (!AttributeToAdd.GetActorValue())
		Error("RegisterAttribute() Could not register Attribute \"" + AttributeToAdd.GetFormID() + "\" with ActorValue \"none\".")
		return -1
	elseif (!AttributeToAdd.GetName())
		Error("RegisterAttribute() Could not register Attribute \"" + AttributeToAdd.GetFormID() + "\" with empty name.")
		return -1
	endif
	
	; Start Mutex
	;int MutexId = MutexStart() const
	
	; Check if an instance of this Attribute has been registered already.
	if IsAttributeRegistered(AttributeToAdd)
		Warning("RegisterAttribute() Attribute \"" + AttributeToAdd.GetFormID() + "\" (" + AttributeToAdd.GetName() + ") already registered.")
		;MutexEnd(MutexId)
		return 0
	elseif IsAttributeRegisteredByActorValue(AttributeToAdd.GetActorValue())
		Warning("RegisterAttribute() Could not register Attribute \"" + AttributeToAdd.GetFormID() + "\" (" + AttributeToAdd.GetName() + "). An Attribute with the same name is ActorValue is registered.")
		;MutexEnd(MutexId)
		return 0
	elseif IsAttributeRegisteredByName(AttributeToAdd.GetName())
		Warning("RegisterAttribute() Could not register Attribute \"" + AttributeToAdd.GetFormID() + "\" (" + AttributeToAdd.GetName() + "). An Attribute with the same name is already registered.")
		;MutexEnd(MutexId)
		return 0
	else
	; Everything is looks good, register new attribute...
		Attribute NewAttribute = new Attribute
		NewAttribute.AV = AttributeToAdd
		NewAttribute.Name = AttributeToAdd.GetName()
		NewAttribute.AVIF = AttributeToAdd.GetActorValue()
		AttributeList.Add(NewAttribute)
		Log("RegisterAttribute() Successfully registered Attribute \"" + NewAttribute.AV.GetFormID() + "\" (" + NewAttribute.Name + ").")
		;MutexEnd(MutexId)
		return 1
	endif
endfunction



; ==================================================
; Registration Removal
; ==================================================

int function UnregisterAttribute(AAF:AttributeBase AttributeToRemove)
	if (!AttributeToRemove)
		Error("UnregisterAttribute() Could not unregister Attribute \"none\"")
		return -1
	endif
	AttributeList.Remove(AttributeList.FindStruct("AV", AttributeToRemove))
endfunction

int function UnregisterAttributeByName(string AttributeNameToRemove)
	if (!AttributeNameToRemove)
		Error("UnregisterAttribute() Could not unregister Attribute with name \"none\"")
		return -1
	endif
	AttributeList.Remove(AttributeList.FindStruct("Name", AttributeNameToRemove))
endfunction

int function UnregisterAttributeByActorValue(ActorValue AttributeActorValueToRemove)
	if (!AttributeActorValueToRemove)
		Error("UnregisterAttribute() Could not unregister Attribute with ActorValue \"none\"")
		return -1
	endif
	AttributeList.Remove(AttributeList.FindStruct("AVIF", AttributeActorValueToRemove))
endfunction



; ==================================================
; Registration Checks
; ==================================================

bool function IsAttributeRegistered(AAF:AttributeBase AttributeToCheck)
	if (AttributeList.Findstruct("AV", AttributeToCheck) >= 0)
		Log("IsAttributeRegistered() Attribute \"" + AttributeToCheck.GetFormID() + "\" (" + AttributeToCheck.GetName() + ") is registered.")
		return true
	else
		Log("IsAttributeRegistered() Attribute \"" + AttributeToCheck.GetFormID() + "\" (" + AttributeToCheck.GetName() + ") is not registered.")
		return false
	endif
endfunction

bool function IsAttributeRegisteredByActorValue(ActorValue ActorValueToCheck)
	if (AttributeList.Findstruct("AVIF", ActorValueToCheck) >= 0)
		Log("IsAttributeRegisteredByActorValue() An Attribute with the ActorValue of \"" + ActorValueToCheck.GetFormID() + "\" is registered.")
		return true
	else
		Log("IsAttributeRegisteredByActorValue() An Attribute with the ActorValue of \"" + ActorValueToCheck.GetFormID() + "\" is not registered.")
		return false
	endif
endfunction

bool function IsAttributeRegisteredByName(String NameToCheck)
	if (AttributeList.Findstruct("Name", NameToCheck) >= 0)
		Log("IsAttributeRegisteredByName() An Attribute with the name of \"" + NameToCheck + "\" is registered.")
		return true
	else
		Log("IsAttributeRegisteredByName() An Attribute with the name of \"" + NameToCheck + "\" is registered.")
		return false
	endif
endfunction



; ==================================================
; Name Update
; ==================================================

; Update the name of an Attribute.
; returns -1 for errors, 1 if successfully registered
int function UpdateAttributeName(AAF:AttributeBase AttributeToChange)
	if (!AttributeToChange)
		Error("UpdateAttributeName() Attribute name not changed. AttributeToChange is \"none\".")
		return -1
	elseif (!AttributeToChange.GetName())
		Error("UpdateAttributeName() Could not chang Attribute name for \"" + AttributeToChange.GetFormID() + "\". Name is \"none\".")
		return -1
	endif
	
	int MutexId = MutexStart() const
	if (AttributeList.Findstruct("Name", AttributeToChange.GetName()) >= 0)
		Error("UpdateAttributeName() Could not change Attribute name for \"" + AttributeToChange.GetFormID() + "\" (" + AttributeToChange.GetName() + "). Name is already exist. Maybe the name has already been changed?")
		MutexEnd(MutexId)
		return -1
	else
		int AttributeIndex = AttributeList.Findstruct("AV", AttributeToChange) const
		if (AttributeIndex < 0)
			Warning("UpdateAttributeName() Could not change Attribute name for \"" + AttributeToChange.GetFormID() + "\" (" + AttributeToChange.GetName() + "). Attribute not registered.")
			MutexEnd(MutexId)
			return 0
		else
			Log("UpdateAttributeName() Has changed Attribute name for \"" + AttributeToChange.GetFormID() + "\" (" + AttributeList[AttributeIndex].Name + ") to \"" + AttributeToChange.GetName() + "\".")
			AttributeList[AttributeIndex].Name = AttributeToChange.GetName()
			MutexEnd(MutexId)
			return 1
		endif
	endif
endfunction

int function UpdateAttributeNameByName(String AttributeName)
	return UpdateAttributeName(GetAttributeByName(AttributeName))
endfunction

int function UpdateAttributeNameByActorValue(ActorValue AttributeActorValue)
	return UpdateAttributeName(GetAttributeByActorValue(AttributeActorValue))
endfunction



; ==================================================
; ActorValue Update
; ==================================================

int function UpdateActorValue(AAF:AttributeBase AttributeToChange)
	if (!AttributeToChange)
		Error("UpdateActorValue() Could not update ActorValue for attribute \"none\"")
		return -1
	elseif (!AttributeToChange.AVIF)
		Error("UpdateActorValue() Could not update ActorValue for attribute \"" + AttributeToChange.GetFormID() + "\" (" + AttributeToChange.GetName() + ") with empty name.")
		return -1
	endif
	
	int MutexId = MutexStart() const
	if (AttributeList.Findstruct("AV", AttributeToChange) >= 0)
		Warning("RegisterAttribute() Attribute \"" + AttributeToChange.GetFormID() + "\" (" + AttributeToChange.GetName() + ") already registered.")
		MutexEnd(MutexId)
		return 0
	elseif (AttributeList.Findstruct("Name", AttributeToChange.GetName()) >= 0)
		Error("RegisterAttribute() Could not register Attribute \"" + AttributeToChange.GetFormID() + "\" (" + AttributeToChange.GetName() + "). A different Attribute with the same name is registered.")
		MutexEnd(MutexId)
		return -1
	endif
endfunction

int function UpdateActorValueByName(String AttributeName)
	UpdateActorValue(GetAttributeByName(AttributeName))
endfunction

int function UpdateActorValueByActorValue(ActorValue AttributeActorValue)
	UpdateActorValue(GetAttributeByActorValue(AttributeActorValue))
endfunction



; ==================================================
; Get Attribute
; ==================================================

; Returns the Attribute by Name
AAF:AttributeBase function GetAttributeByName(String AttributeName)
	if !AttributeName
		Error("GetAttributeByName() Could not find attribute with name \"none\".")
		return none
	endif
	int Position = AttributeList.FindStruct("Name", AttributeName)
	if Position >= 0
		Log("GetAttributeByName() Found attribute with name \"" + AttributeName + "\".")
		return AttributeList[Position].AV
	else
		Warning("GetAttributeByName() Could not find attribute with name \"none\".")
		return none
	endif
endfunction

; Returns the Attribute by ActorValue
AAF:AttributeBase function GetAttributeByActorValue(ActorValue AttributeActorValue)
	if !AttributeActorValue
		Error("GetAttributeByActorValue() Could not find attribute for ActorValue \"none\".")
		return none
	endif
	int Position = AttributeList.FindStruct("AVIF", AttributeActorValue)
	if Position >= 0
		Log("GetAttributeByActorValue() Could not find attribute with name \"none\".")
		return AttributeList[Position].AV
	else
		Warning("GetAttributeByActorValue() Could not find attribute with name \"none\".")
		return none
	endif
endfunction



; ==================================================
; Initialisation
; ==================================================

; TODO
int function ActorInitializationIfNeeded(Actor akActor, AAF:AttributeBase AV)
	if !AV
		Error("ActorInitializationIfNeeded() Could not register Attribute \"none\"")
		return -1
	elseif !akActor
		Error("ActorInitializationIfNeeded() Could not register Attribute for actor \"none\"")
		return -1
	endif
	if !AV.CheckActorBaseInit(akActor)
		AV.ActorBaseInit(akActor)
		return 1
	else
		return 0
	endif
endfunction

float function ActorResetToDefault(Actor akActor, AAF:AttributeBase AV)
	int MutexId = MutexStart() const
	float NewValue = AV.ActorSetDefault(akActor)
	MutexEnd(MutexId)
	return NewValue
endfunction

float function ActorResetToDefaultByName(Actor akActor, String AttributeName)
	return ActorResetToDefault(akActor, GetAttributeByName(AttributeName))
endfunction

float function ActorResetToDefaultByActorValue(Actor akActor, ActorValue AttributeActorValue)
	return ActorResetToDefault(akActor, GetAttributeByActorValue(AttributeActorValue))
endfunction

; ==================================================
; Get Attribute
; ==================================================

float function GetAttributeValue(Actor akActor, AAF:AttributeBase AV, float OnErrorValue = 0.0)
	if !AV
		Error("GetAttributeValue() Could not get value for Attribute \"none\"")
		return OnErrorValue
	elseif !akActor
		Error("GetAttributeValue() Could not get Attribute value for actor \"none\"")
		return OnErrorValue
	endif
	ActorInitializationIfNeeded(akActor, AV)
	return AV.GetValue(akActor, OnErrorValue)
endfunction

float function GetAttributeValueByName(Actor akActor, String AttributeName, float OnErrorValue = 0.0)
	return GetAttributeValue(akActor, GetAttributeByName(AttributeName), OnErrorValue = 0.0)
endfunction

float function GetAttributeValueByActorValue(Actor akActor, ActorValue AttributeActorValue, float OnErrorValue = 0.0)
	return GetAttributeValue(akActor, GetAttributeByActorValue(AttributeActorValue), OnErrorValue = 0.0)
endfunction


; ==================================================
; Set Attribute
; ==================================================

; Set the Attribute value for that actor and returns the value it had been set to (which can be different then the one passed in)
float function SetAttributeValue(Actor akActor, AAF:AttributeBase AV, float Value, float OnErrorValue = 0.0)
	if !AV
		Error("SetAttributeValue() Could not set value for Attribute \"none\"")
		return OnErrorValue
	elseif !akActor
		Error("SetAttributeValue() Could not set Attribute value for actor \"none\"")
		return OnErrorValue
	endif
	ActorInitializationIfNeeded(akActor, AV)
	int MutexId = MutexStart() const
	float NewValue = AV.SetValue(akActor, Value, OnErrorValue)
	MutexEnd(MutexId)
	return NewValue
endfunction

; Set the Attribute value for that Attribute name. Returns the value it had been set to (which can be different then the one passed in)
float function SetAttributeValueByName(Actor akActor, string AttributeName, float Value, float OnErrorValue = 0.0)
	return SetAttributeValue(akActor, GetAttributeByName(AttributeName), Value, OnErrorValue)
endfunction

float function SetAttributeValueByActorValue(Actor akActor, ActorValue AttributeActorValue, float Value, float OnErrorValue = 0.0)
	return SetAttributeValue(akActor, GetAttributeByActorValue(AttributeActorValue), Value, OnErrorValue)
endfunction



; ==================================================
; Mod Attribute
; ==================================================

; Modify the Attribute value for that actor and returns the value it had been modified with (can be different then the one passed in)
float function ModAttributeValue(Actor akActor, AAF:AttributeBase AV, float Value, float OnErrorValue = 0.0)
	if !AV
		Error("ModAttributeValue() Could not modify value for Attribute \"none\"")
		return OnErrorValue
	elseif !akActor
		Error("ModAttributeValue() Could not modify Attribute value for actor \"none\"")
		return OnErrorValue
	endif
	ActorInitializationIfNeeded(akActor, AV)
	int MutexId = MutexStart() const
	float NewValue = AV.ModValue(akActor, Value, OnErrorValue)
	MutexEnd(MutexID)
	return NewValue
endfunction

float function ModAttributeValueByName(Actor akActor, string AttributeName, float Value, float OnErrorValue = 0.0)
	return ModAttributeValueByName(akActor, GetAttributeByName(AttributeName), Value, OnErrorValue = 0.0)
endfunction

float function ModAttributeValueByActorValue(Actor akActor, ActorValue AttributeActorValue, float Value, float OnErrorValue = 0.0)
	return ModAttributeValueByName(akActor, GetAttributeByActorValue(AttributeActorValue), Value, OnErrorValue = 0.0)
endfunction

; ==================================================
; Debug
; ==================================================

; Function to display the number of registered attributes and their names as MessageBox
; Only for debugging
function ListAttributes()
	int i = 0
	string msg = ""
	while i < AttributeList.length
		msg += i + ": " + AttributeList[i].Name + "\n"
		i += 1
	endwhile
	Debug.MessageBox("There are now a total of " + AttributeList.length + " registered.\n" + msg)
endfunction

; Only fires an error message if log level is >= 1
function Error(string msg)
	if LoggingLevel >= 1
		;Game.Error("ERROR: " + msg)
		Debug.MessageBox("Error: " + msg)
	endif
endfunction

; Only fires an warning message if log level is >= 2
function Warning(string msg)
	if LoggingLevel >= 2
		;Game.Warning("WARNING: " + msg)
		Debug.MessageBox("WARNING: " + msg)
	endif
endfunction

; Only fires an notification message if log level is >= 3
function Log(string msg)
	if LoggingLevel >= 3
		Debug.Notification("LOGGING: " + msg)
	endif
endfunction
