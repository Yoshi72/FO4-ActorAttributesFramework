scriptname AAF:FrameworkQuest extends Quest Conditional
{Main Framework for handling Actor Attributes.}

; ==================================================
; Structs
; ==================================================

struct AttributeStruct
	AAF:AttributeBase QUST
	ActorValue AVIF
	string Name
endstruct

struct RequirementsStruct
	float Weak		= 20.0
	float Medium	= 50.0
	float Strong	= 75.0
endstruct

struct AttributeCache
	AAF:AttributeBase QUST
	float Value1 = 0.0
	float Value2 = 0.0
endstruct



; ==================================================
; Properties
; ==================================================

AttributeStruct[] property AttributeList auto hidden
{A list of all currently registered attributes.}

RequirementsStruct property Requirements auto
{A list of requirements for the different attribute ranks. Can be used for user configuration later.}

int property LoggingLevel = 1 auto
{The current log level... 0 = off, 1 = errors, 2 = errors + warnings, 3 = all.}

int[] property MutexList auto hidden
{Current list of MutexIds. This property should not be changed manually!}

float property MutexWaitTime = 1.0 auto
{The amount of seconds that should be waited for each mutex cycle. Decrease this if the script is processing values too slowly.}

; Totally stupid check to see if the array is initialized or not.
; Initializes the arrays with 0 elements, otherwise they won't work.
event OnInit()
	if !AttributeList
		AttributeList = new AttributeStruct[0]
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
		MutexId = MutexList[MutexList.length-1] + 1
		if MutexId <= 0
			MutexId = 1
		endif
	else
		MutexId = 1
	endif
	Log("MutexStart() Added a new function call to the que with MutexId of " + MutexId + ".")
	MutexList.Add(MutexId)
	while MutexList[0] != MutexId
		if MutexList.Find(MutexId) < 0
			Error("MutexStart() Could not find MutexId of " + MutexId + ".")
			return -1
		endif
		; wait for another check
		Utility.WaitMenuMode(MutexWaitTime)
	endwhile
	Log("MutexStart() Successfully executed... Returning created MutexId")
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
	Warning("MutexReset() has been called... Resetting the list.")
	MutexList.Clear()
endfunction



; ==================================================
; Registration
; ==================================================

; Register a new Attribute.
; returns -1 for errors, 0 if it's already registered and 1 if successfully registered.
int function AttributeRegister(AAF:AttributeBase AttributeToAdd)
	; Check the passed in attribute...
	if (!AttributeToAdd)
		Error("RegisterAttribute() Could not register Attribute \"none\"")
		return -1
	elseif (!AttributeToAdd.GetActorValueForm())
		Error("RegisterAttribute() Could not register Attribute \"" + AttributeToAdd.GetFormID() + "\" with ActorValue \"none\".")
		return -1
	elseif (!AttributeToAdd.GetName())
		Error("RegisterAttribute() Could not register Attribute \"" + AttributeToAdd.GetFormID() + "\" with empty name.")
		return -1
	endif
	
	; Start Mutex
	;int MutexId = MutexStart() const
	
	; Check if an instance of this Attribute has been registered already.
	if AttributeIsRegistered(AttributeToAdd)
		Warning("RegisterAttribute() Attribute \"" + AttributeToAdd.GetFormID() + "\" (" + AttributeToAdd.GetName() + ") already registered.")
		;MutexEnd(MutexId)
		return 0
	elseif AttributeIsRegisteredByActorValue(AttributeToAdd.GetActorValueForm())
		Warning("RegisterAttribute() Could not register Attribute \"" + AttributeToAdd.GetFormID() + "\" (" + AttributeToAdd.GetName() + "). An Attribute with the same ActorValue is registered.")
		;MutexEnd(MutexId)
		return 0
	elseif AttributeIsRegisteredByName(AttributeToAdd.GetName())
		Warning("RegisterAttribute() Could not register Attribute \"" + AttributeToAdd.GetFormID() + "\" (" + AttributeToAdd.GetName() + "). An Attribute with the same name is already registered.")
		;MutexEnd(MutexId)
		return 0
	else
	; Everything is looks good, register new attribute...
		AttributeStruct NewAttribute = new AttributeStruct
		NewAttribute.QUST = AttributeToAdd
		NewAttribute.Name = AttributeToAdd.GetName()
		NewAttribute.AVIF = AttributeToAdd.GetActorValueForm()
		AttributeList.Add(NewAttribute)
		Log("RegisterAttribute() Successfully registered Attribute \"" + NewAttribute.QUST.GetFormID() + "\" (" + NewAttribute.Name + ").")
		;MutexEnd(MutexId)
		return 1
	endif
endfunction



; ==================================================
; Registration Checks
; ==================================================

bool function AttributeIsRegistered(AAF:AttributeBase AttributeToCheck)
	if (AttributeList.Findstruct("QUST", AttributeToCheck) >= 0)
		Log("AttributeIsRegistered() Attribute \"" + AttributeToCheck.GetFormID() + "\" (" + AttributeToCheck.GetName() + ") is registered.")
		return true
	else
		Log("AttributeIsRegistered() Attribute \"" + AttributeToCheck.GetFormID() + "\" (" + AttributeToCheck.GetName() + ") is not registered.")
		return false
	endif
endfunction

bool function AttributeIsRegisteredByActorValue(ActorValue ActorValueToCheck)
	if (AttributeList.Findstruct("AVIF", ActorValueToCheck) >= 0)
		Log("AttributeIwRegisteredByActorValue() An Attribute with the ActorValue of \"" + ActorValueToCheck.GetFormID() + "\" is registered.")
		return true
	else
		Log("AttributeIwRegisteredByActorValue() No Attribute with the ActorValue of \"" + ActorValueToCheck.GetFormID() + "\" is registered.")
		return false
	endif
endfunction

bool function AttributeIsRegisteredByName(String NameToCheck)
	if (AttributeList.Findstruct("Name", NameToCheck) >= 0)
		Log("AttributeIsRegisteredByName() An Attribute with the name of \"" + NameToCheck + "\" is registered.")
		return true
	else
		Log("AttributeIsRegisteredByName() No Attribute with the name of \"" + NameToCheck + "\" is registered.")
		return false
	endif
endfunction



; ==================================================
; Registration Removal
; ==================================================

int function AttributeRemove(AAF:AttributeBase AttributeToRemove)
	if (!AttributeToRemove)
		Error("AttributeRemove() Could not unregister Attribute \"none\"")
		return -1
	endif
	int Index = AttributeList.FindStruct("QUST", AttributeToRemove)
	if Index < 0
		Warning("AttributeRemove() Could not uregister Attribute \"" + AttributeToRemove.GetName() + "\". Attribute is not registered.")
		return 0
	else
		AttributeList.Remove(Index)
		Log("AttributeRemove() Successfully unregistered Attribute \"" + AttributeToRemove.GetName() + "\".")
		return 1
	endif
endfunction

int function AttributeRemoveByActorValue(ActorValue AttributeActorValue)
	if (!AttributeActorValue)
		Error("AttributeRemoveByName() Could not unregister Attribute with Actorvalue \"none\"")
		return -1
	endif
	int Index = AttributeList.FindStruct("AVIF", AttributeActorValue)
	if Index < 0
		Warning("AttributeRemoveByName() Could not uregister Attribute \"" + AttributeActorValue.GetFormId() + "\". Attribute is not registered.")
		return 0
	else
		AttributeList.Remove(Index)
		Log("AttributeRemoveByName() Successfully unregistered Attribute \"" + AttributeActorValue + "\".")
		return 1
	endif
endfunction

int function AttributeRemoveByName(string AttributeName)
	if (!AttributeName)
		Error("AttributeRemoveByName() Could not unregister Attribute with name \"none\"")
		return -1
	endif
	int Index = AttributeList.FindStruct("Name", AttributeName)
	if Index < 0
		Warning("AttributeRemoveByName() Could not uregister Attribute \"" + AttributeName + "\". Attribute is not registered.")
		return 0
	else
		AttributeList.Remove(Index)
		Log("AttributeRemoveByName() Successfully unregistered Attribute \"" + AttributeName + "\".")
		return 1
	endif
endfunction



; ==================================================
; Attribute Tags
; ==================================================

int function AttributeTagRegister(AAF:AttributeBase Attribute, string TagName, float TagMagnitude)
	if !Attribute
		Error("AttributeTagRegister() Failed to register tag. Parameter for Attribute is \"none\".")
		return -1
	elseif !TagName
		Error("AttributeTagRegister() Failed to register tag. Parameter for TagName is empty.")
		return -1
	elseif !TagMagnitude
		Error("AttributeTagRegister() Failed to register tag. Parameter for TagMagnitude is 0.")
		return -1
	endif
	Log("AttributeTagRegister() Ragister tag \"" + TagName + "\" for Attribute \"" + Attribute.GetName() + "\" with magnitude of " + TagMagnitude + ".")
	return AttributeList[AttributeList.FindStruct("QUST", Attribute)].QUST.TagRegister(TagName, TagMagnitude)
endfunction

int function AttributeTagRemove(AAF:AttributeBase Attribute, string TagName)
	if !Attribute
		Error("AttributeTagRemove() Failed to remove tag. Parameter for Attribute is \"none\".")
		return -1
	elseif !TagName
		Error("AttributeTagRemove() Failed to remove tag. Parameter for TagName is empty.")
		return -1
	endif
	Log("AttributeTagRemove() Remove tag \"" + TagName + "\" of Attribute \"" + Attribute.GetName() + "\".")
	return AttributeList[AttributeList.FindStruct("QUST", Attribute)].QUST.TagRemove(TagName)
endfunction

int function AttributeTagChangeMagnitude(AAF:AttributeBase Attribute, string TagName, float TagMagnitude)
	if !Attribute
		Error("AttributeTagChangeMagnitude() Failed to change magnitude. Parameter for Attribute is \"none\".")
		return -1
	elseif !TagName
		Error("AttributeTagChangeMagnitude() Failed to change magnitude. Parameter for TagName is empty.")
		return -1
	elseif !TagMagnitude
		Error("AttributeTagChangeMagnitude() Failed to change magnitude. Parameter for TagMagnitude is 0.")
		return -1
	endif
	Log("AttributeTagChangeMagnitude() Change magnitude of tag \"" + TagName + "\" for Attribute \"" + Attribute.GetName() + "\" to " + TagMagnitude + ".")
	return AttributeList[AttributeList.FindStruct("QUST", Attribute)].QUST.TagChangeMagnitude(TagName, TagMagnitude)
endfunction



; ==================================================
; Name Update
; ==================================================

; Update the name of an Attribute.
; returns -1 for errors, 1 if successfully registered
int function UpdateAttributeName(AAF:AttributeBase AttributeToChange)
	if (!AttributeToChange)
		Error("UpdateAttributeName() Failed to change Attribute name. AttributeToChange is \"none\".")
		return -1
	elseif (!AttributeToChange.GetName())
		Error("UpdateAttributeName() Failed to change Attribute name for \"" + AttributeToChange.GetFormID() + "\". Name it has no name.")
		return -1
	endif
	
	int MutexId = MutexStart() const
	if (AttributeList.Findstruct("Name", AttributeToChange.GetName()) >= 0)
		Error("UpdateAttributeName() Failed to change Attribute name for \"" + AttributeToChange.GetFormID() + "\" (" + AttributeToChange.GetName() + "). Name is already exist. Maybe the name has already been changed?")
		MutexEnd(MutexId)
		return -1
	else
		int AttributeIndex = AttributeList.Findstruct("QUST", AttributeToChange) const
		if (AttributeIndex < 0)
			Warning("UpdateAttributeName() Failed to change Attribute name for \"" + AttributeToChange.GetFormID() + "\" (" + AttributeToChange.GetName() + "). Attribute not registered.")
			MutexEnd(MutexId)
			return 0
		else
			Log("UpdateAttributeName() Changing Attribute name for \"" + AttributeToChange.GetFormID() + "\" (" + AttributeList[AttributeIndex].Name + ") to \"" + AttributeToChange.GetName() + "\".")
			AttributeList[AttributeIndex].Name = AttributeToChange.GetName()
			MutexEnd(MutexId)
			return 1
		endif
	endif
endfunction

int function UpdateAttributeNameByActorValue(ActorValue AttributeActorValue)
	return UpdateAttributeName(GetAttributeByActorValue(AttributeActorValue))
endfunction

int function UpdateAttributeNameByName(String AttributeName)
	return UpdateAttributeName(GetAttributeByName(AttributeName))
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
	if (AttributeList.Findstruct("QUST", AttributeToChange) >= 0)
		Warning("UpdateActorValue() Attribute \"" + AttributeToChange.GetFormID() + "\" (" + AttributeToChange.GetName() + ") already registered.")
		MutexEnd(MutexId)
		return 0
	elseif (AttributeList.Findstruct("Name", AttributeToChange.GetName()) >= 0)
		Error("UpdateActorValue() Could not register Attribute \"" + AttributeToChange.GetFormID() + "\" (" + AttributeToChange.GetName() + "). A different Attribute with the same name is registered.")
		MutexEnd(MutexId)
		return -1
	endif
endfunction

int function UpdateActorValueByActorValue(ActorValue AttributeActorValue)
	UpdateActorValue(GetAttributeByActorValue(AttributeActorValue))
endfunction

int function UpdateActorValueByName(String AttributeName)
	UpdateActorValue(GetAttributeByName(AttributeName))
endfunction



; ==================================================
; Get Attribute
; ==================================================

; Returns the Attribute by ActorValue
AAF:AttributeBase function GetAttributeByActorValue(ActorValue AttributeActorValue)
	if !AttributeActorValue
		Error("GetAttributeByActorValue() Could not find attribute for ActorValue \"none\".")
		return none
	endif
	int Position = AttributeList.FindStruct("AVIF", AttributeActorValue)
	if Position >= 0
		Log("GetAttributeByActorValue() Could not find attribute with name \"none\".")
		return AttributeList[Position].QUST
	else
		Warning("GetAttributeByActorValue() Could not find attribute with name \"none\".")
		return none
	endif
endfunction

; Returns the Attribute by Name
AAF:AttributeBase function GetAttributeByName(String AttributeName)
	if !AttributeName
		Error("GetAttributeByName() Could not find attribute with name \"none\".")
		return none
	endif
	int Position = AttributeList.FindStruct("Name", AttributeName)
	if Position >= 0
		Log("GetAttributeByName() Found attribute with name \"" + AttributeName + "\".")
		return AttributeList[Position].QUST
	else
		Warning("GetAttributeByName() Could not find attribute with name \"none\".")
		return none
	endif
endfunction



; ==================================================
; Initialisation
; ==================================================

; TODO
int function ActorInitializationIfNeeded(AAF:AttributeBase QUST, Actor akActor)
	if !QUST
		Error("ActorInitializationIfNeeded() Could not register Attribute \"none\"")
		return -1
	elseif !akActor
		Error("ActorInitializationIfNeeded() Could not register Attribute for actor \"none\"")
		return -1
	endif
	if !QUST.CheckActorInitBase(akActor)
		QUST.InitActorValues(akActor)
		return 1
	else
		return 0
	endif
endfunction



; ==================================================
; Reset Actor Max Value
; ==================================================

float function ResetActorMaxValue(AAF:AttributeBase QUST, Actor akActor)
	int MutexId = MutexStart() const
	float NewValue = QUST.ResetActorMaxValue(akActor)
	MutexEnd(MutexId)
	return NewValue
endfunction

float function ResetActorMaxValueByActorValue(ActorValue AttributeActorValue, Actor akActor)
	return ResetActorMaxValue(GetAttributeByActorValue(AttributeActorValue), akActor)
endfunction

float function ResetActorMaxValueByName(String AttributeName,Actor akActor)
	return ResetActorMaxValue(GetAttributeByName(AttributeName),akActor)
endfunction



; ==================================================
; Reset Actor Current Value
; ==================================================

float function ResetActorValue(AAF:AttributeBase QUST, Actor akActor)
	int MutexId = MutexStart() const
	float NewValue = QUST.ResetActorValue(akActor)
	MutexEnd(MutexId)
	return NewValue
endfunction

float function ResetActorValueByActorValue(ActorValue AttributeActorValue, Actor akActor)
	return ResetActorValue(GetAttributeByActorValue(AttributeActorValue), akActor)
endfunction

float function ResetActorValueByName(String AttributeName, Actor akActor)
	return ResetActorValue(GetAttributeByName(AttributeName), akActor)
endfunction



; ==================================================
; Get Attribute
; ==================================================

float function GetAttributeValue(AAF:AttributeBase QUST, Actor akActor, float OnErrorValue = 0.0)
	if !QUST
		Error("GetAttributeValue() Could not get value for Attribute \"none\"")
		return OnErrorValue
	elseif !akActor
		Error("GetAttributeValue() Could not get Attribute value for actor \"none\"")
		return OnErrorValue
	endif
	ActorInitializationIfNeeded(akActor, QUST)
	return QUST.GetActorValue(akActor, OnErrorValue)
endfunction

float function GetAttributeValueByActorValue(ActorValue AttributeActorValue, Actor akActor, float OnErrorValue = 0.0)
	return GetAttributeValue(GetAttributeByActorValue(AttributeActorValue), akActor, OnErrorValue = 0.0)
endfunction

float function GetAttributeValueByName(String AttributeName, Actor akActor, float OnErrorValue = 0.0)
	return GetAttributeValue(GetAttributeByName(AttributeName), akActor, OnErrorValue = 0.0)
endfunction



; ==================================================
; Get Attribute Actor Value Min
; ==================================================

float function GetActorValueMin(AAF:AttributeBase QUST, Actor akActor)
	if !QUST
		Error("GetActorValueMin() Could not get min value for Attribute \"none\"")
		return 0.0
	elseif !akActor
		Error("GetActorValueMin() Could not get min value for actor \"none\"")
		return 0.0
	endif
	;ActorInitializationIfNeeded(akActor, QUST)
	return QUST.GetActorValueMin(akActor)
endfunction

float function GetActorValueMinByActorValue(Actor akActor, ActorValue AttributeActorValue)
	return GetActorValueMin(GetAttributeByActorValue(AttributeActorValue), akActor)
endfunction

float function GetActorValueMinByName(Actor akActor, String AttributeName)
	return GetActorValueMin(GetAttributeByName(AttributeName), akActor)
endfunction



; ==================================================
; Get Attribute Actor Value Max
; ==================================================

float function GetActorValueMax(AAF:AttributeBase QUST, Actor akActor)
	if !QUST
		Error("GetActorValueMax() Could not get Max value for Attribute \"none\"")
		return 0.0
	elseif !akActor
		Error("GetActorValueMax() Could not get Max value for actor \"none\"")
		return 0.0
	endif
	;ActorInitializationIfNeeded(akActor, QUST)
	return QUST.GetActorValueMax(akActor)
endfunction

float function GetActorValueMaxByActorValue(Actor akActor, ActorValue AttributeActorValue)
	return GetActorValueMax(GetAttributeByActorValue(AttributeActorValue), akActor)
endfunction

float function GetActorValueMaxByName(Actor akActor, String AttributeName)
	return GetActorValueMax(GetAttributeByName(AttributeName), akActor)
endfunction



; ==================================================
; Get Attribute Default Base Value Min
; ==================================================

float function GetAttributeDefaultBaseValueMin(AAF:AttributeBase QUST)
	if !QUST
		Error("GetAttributeBaseValueMin() Could not get Minx base value for Attribute \"none\"")
		return 0.0
	endif
	;ActorInitializationIfNeeded(akActor, QUST)
	return QUST.GetDefaultBaseValueMin()
endfunction

float function GetAttributeDefaultBaseValueMinByActorValue(ActorValue AttributeActorValue)
	return GetAttributeDefaultBaseValueMin(GetAttributeByActorValue(AttributeActorValue))
endfunction

float function GetAttributeDefaultBaseValueMinByName(String AttributeName)
	return GetAttributeDefaultBaseValueMin(GetAttributeByName(AttributeName))
endfunction



; ==================================================
; Get Attribute Default Base Value Max
; ==================================================

float function GetAttributeDefaultBaseValueMax(AAF:AttributeBase QUST)
	if !QUST
		Error("GetAttributeBaseValueMax() Could not get maxx base value for Attribute \"none\"")
		return 0.0
	endif
	;ActorInitializationIfNeeded(akActor, QUST)
	return QUST.GetDefaultBaseValueMax()
endfunction

float function GetAttributeDefaultBaseValueMaxByActorValue(ActorValue AttributeActorValue)
	return GetAttributeDefaultBaseValueMax(GetAttributeByActorValue(AttributeActorValue))
endfunction

float function GetAttributeDefaultBaseValueMaxByName(String AttributeName)
	return GetAttributeDefaultBaseValueMax(GetAttributeByName(AttributeName))
endfunction



; ==================================================
; Get Attribute Default Base Value
; ==================================================

float function GetAttributeDefaultBaseValue(AAF:AttributeBase QUST)
	if !QUST
		Error("GetAttributeBaseValue() Could not get x base value for Attribute \"none\"")
		return 0.0
	endif
	;ActorInitializationIfNeeded(akActor, QUST)
	return QUST.GetDefaultBaseValue()
endfunction

float function GetAttributeDefaultBaseValueByActorValue(ActorValue AttributeActorValue)
	return GetAttributeDefaultBaseValue(GetAttributeByActorValue(AttributeActorValue))
endfunction

float function GetAttributeDefaultBaseValueByName(String AttributeName)
	return GetAttributeDefaultBaseValue(GetAttributeByName(AttributeName))
endfunction



; ==================================================
; Get Attribute Actor Value Min
; ==================================================

float function GetAttributeValueMin(AAF:AttributeBase QUST)
	if !QUST
		Error("GetAttributeBaseValueMin() Could not get min base value for Attribute \"none\"")
		return 0.0
	endif
	;ActorInitializationIfNeeded(akActor, QUST)
	return QUST.GetDefaultBaseValueMin()
endfunction

float function GetAttributeActorValueMinByActorValue(ActorValue AttributeActorValue)
	return GetAttributeActorValueMin(GetAttributeByActorValue(AttributeActorValue))
endfunction

float function GetAttributeActorValueMinByName(String AttributeName)
	return GetAttributeActorValueMin(GetAttributeByName(AttributeName))
endfunction



; ==================================================
; Get Attribute Actor Value Max
; ==================================================

float function GetAttributeActorValueMax(AAF:AttributeBase QUST)
	if !QUST
		Error("GetAttributeBaseValueMax() Could not get Max base value for Attribute \"none\"")
		return 0.0
	endif
	;ActorInitializationIfNeeded(akActor, QUST)
	return QUST.GetActorValueMax()
endfunction

float function GetAttributeActorValueMaxByActorValue(ActorValue AttributeActorValue)
	return GetAttributeActorValueMax(GetAttributeByActorValue(AttributeActorValue))
endfunction

float function GetAttributeActorValueMaxByName(String AttributeName)
	return GetAttributeActorValueMax(GetAttributeByName(AttributeName))
endfunction



; ==================================================
; Mod Actor Max Value
; ==================================================

float function ModAttributeActorMaxValue(AAF:AttributeBase QUST, Actor akActor, float Value)
	if !QUST
		Error("GetAttributeBaseValueMin() Could not get min base value for Attribute \"none\"")
		return 0.0
	endif
	;ActorInitializationIfNeeded(akActor, QUST)
	return QUST.ModActorMaxValue(Value)
endfunction

float function ModAttributeActorMaxValueByActorValue(ActorValue AttributeActorValue, Actor akActor, float Value)
	return ModAttributeActorMaxValue(GetAttributeByActorValue(AttributeActorValue), akActor, Value)
endfunction

float function ModAttributeActorMaxValueByName(String AttributeName, Actor akActor, float Value)
	return ModAttributeActorMaxValue(GetAttributeByName(AttributeName), akActor, Value)
endfunction



; ==================================================
; Set Actor Max Value
; ==================================================

float function SetAttributeActorMaxValue(AAF:AttributeBase QUST, Actor akActor, float Value)
	if !QUST
		Error("GetAttributeBaseValueMin() Could not get min base value for Attribute \"none\"")
		return 0.0
	endif
	;ActorInitializationIfNeeded(akActor, QUST)
	return QUST.SetActorMaxValue(Value)
endfunction

float function SetAttributeActorMaxValueByActorValue(ActorValue AttributeActorValue, Actor akActor, float Value)
	return SetAttributeActorMaxValue(GetAttributeByActorValue(AttributeActorValue), akActor, Value)
endfunction

float function SetAttributeActorMaxValueByName(String AttributeName, Actor akActor, float Value)
	return SetAttributeActorMaxValue(GetAttributeByName(AttributeName), akActor, Value)
endfunction



; ==================================================
; Set Attribute
; ==================================================

; Set the Attribute value for that actor and returns the value it had been set to (which can be different then the one passed in)
float function SetActorValue(AAF:AttributeBase QUST, Actor akActor, float Value, float OnErrorValue = 0.0)
	if !QUST
		Error("SetAttributeValue() Could not set value for Attribute \"none\"")
		return OnErrorValue
	elseif !akActor
		Error("SetAttributeValue() Could not set Attribute value for actor \"none\"")
		return OnErrorValue
	endif
	ActorInitializationIfNeeded(akActor, QUST)
	int MutexId = MutexStart() const
	float NewValue = QUST.SetValue(akActor, Value, OnErrorValue)
	MutexEnd(MutexId)
	return NewValue
endfunction

float function SetActorValueByActorValue(ActorValue AttributeActorValue, Actor akActor, float Value, float OnErrorValue = 0.0)
	return SetActorValue(GetAttributeByActorValue(AttributeActorValue), akActor, Value, OnErrorValue)
endfunction

; Set the Attribute value for that Attribute name. Returns the value it had been set to (which can be different then the one passed in)
float function SetActorValueByName(string AttributeName, Actor akActor, float Value, float OnErrorValue = 0.0)
	return SetActorValue(GetAttributeByName(AttributeName), akActor, Value, OnErrorValue)
endfunction



; ==================================================
; Mod Attribute
; ==================================================

; Modify the Attribute value for that actor and returns the value it had been modified with (can be different then the one passed in)
float function ModActorValue(AAF:AttributeBase QUST, Actor akActor, float Value, float OnErrorValue = 0.0)
	if !QUST
		Error("ModAttributeValue() Could not modify value for Attribute \"none\"")
		return OnErrorValue
	elseif !akActor
		Error("ModAttributeValue() Could not modify Attribute value for actor \"none\"")
		return OnErrorValue
	endif
	ActorInitializationIfNeeded(akActor, QUST)
	int MutexId = MutexStart() const
	float NewValue = QUST.ModValue(akActor, Value, OnErrorValue)
	MutexEnd(MutexID)
	return NewValue
endfunction

float function ModActorValueByActorValue(ActorValue AttributeActorValue, Actor akActor, float Value, float OnErrorValue = 0.0)
	return ModActorValue(GetAttributeByActorValue(AttributeActorValue), akActor, Value, OnErrorValue = 0.0)
endfunction

float function ModActorValueByName(string AttributeName, Actor akActor, float Value, float OnErrorValue = 0.0)
	return ModActorValue(GetAttributeByName(AttributeName), akActor, Value, OnErrorValue = 0.0)
endfunction



; ==================================================
; Mod Attribute
; ==================================================

; Modify the Attribute value for that actor and returns the value it had been modified with (can be different then the one passed in)
float function ResetActorValue(AAF:AttributeBase QUST, Actor akActor, float Value)
	if !QUST
		Error("ModAttributeValue() Could not modify value for Attribute \"none\"")
		return OnErrorValue
	elseif !akActor
		Error("ModAttributeValue() Could not modify Attribute value for actor \"none\"")
		return OnErrorValue
	endif
	ActorInitializationIfNeeded(akActor, QUST)
	int MutexId = MutexStart() const
	float NewValue = QUST.ModValue(akActor)
	MutexEnd(MutexID)
	return NewValue
endfunction

float function ResetActorValueByActorValue(ActorValue AttributeActorValue, Actor akActor)
	return ResetActorValue(GetAttributeByActorValue(AttributeActorValue), akActor)
endfunction

float function ResetActorValueByName(string AttributeName, Actor akActor)
	return ResetActorValue(GetAttributeByName(AttributeName), akActor)
endfunction



; ==================================================
; Decisions
; ==================================================

function ProcessDecision(Actor TargetActor, Actor MasterActor, int decision, string[] DecisionTags, int[] DecisionMagnitudes)

endfunction

;/function ProcessAction(Actor TargetActor, Actor MasterActor = none, string[] DecisionTags, int[] DecisionMagnitudes)
	AttributeCache[] Cache = new AttributeCache[AttributeList.length]
	int Index = 0
	while Index < AttributeList.length
		Cache[Index].QUST = AttributeList[Index].QUST
	endwhile
	
	while Index < Cache.length
		;Cache[Index] = Cache[Index].QUST.ProcessAction(Cache, TargetActor, MasterActor, DecisionTags, DecisionMagnitudes)
	endwhile
	
	while Index < Cache.length
		;Cache[Index].QUST.ModAttribute()
	endwhile
endfunction
/;

;function ProcessSingleAction(AAF:AttributeBase[] Attribute, Actor TargetActor, Actor MasterActor = none, string[] DecisionTags, int[] DecisionMagnitudes)

;endfunction

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
