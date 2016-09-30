scriptname AAF:AttributeBase extends Quest
{Base Script for Attribute functions.}

struct TagStruct
	string Name
	{The name of the tag}
	float Magnitude
	{How strong this tag effects this attribute. Positive values will increase it, negative values decrease. Usuall values are -3 to 3, but there are no hard limits.}
endstruct

; ==================================================
; Properties
; ==================================================

group General
	ActorValue property AVIF auto mandatory const
	{Actor Value Form this attribute is related to.}
	string property Name auto mandatory const
	{The name of the Attribute}
	AAF:FrameworkQuest property Framework auto mandatory const
	{Framework Form}
	bool property AllowNegative = true auto const
	{Allow negative values. This Will essentially double the range and adds enable negative ranks.}
	TagStruct[] property TagList auto
	{List of tags that effects this attribute.}
endgroup

group DefaultValues
	float property BaseValueMax			= 120.0 auto const
	{Default Base (Max) Value. Should never be 0.}
	float property BaseValueDefault		= 100.0 auto const
	{Default Max Base Value. Should never be 0. Note: Updating this will only have an effect on newly initialized Actors on an existing savegame.}
	float property BaseValueMin			= 100.0 auto const
	{Default Max Base Value. Should never be 0.}
	float property DefaultValue			=   0.0 auto const
	{Default Starting Value. This is the value all actor's start with.  Note: Updating this will only have an effect on newly initialized Actors on an existing savegame.}
endgroup

; Automatically register this attribute to the Framework
event OnInit()
	if !TagList
		TagList = new TagStruct[0]
	endif
	Int Test = 0x10
	Framework.RegisterAttribute(self)
endevent

string function GetName()
	return Name
endfunction

ActorValue function GetActorValueForm()
	return AVIF
endfunction



; ==================================================
; Defaults and Inits
; ==================================================

; Check if actor's base value has been initialized and returns the result.
bool function CheckActorInitBase(Actor akActor)
	if !akActor
		Error("CheckActorInitBase() Could not check value initialisation of Attribute \"" + GetName() + "\" for actor \"none\".")
		return 0.0
	endif
	
	if akActor.GetBaseValue(AVIF) == 0
		Log("CheckActorInitBase() Attribute \"" + GetName() + "\" has not been set for Actor \"" + akActor.GetFormId() + "\".")
		return false
	else
		Log("CheckActorInitBase() Attribute \"" + GetName() + "\" has been set for Actor \"" + akActor.GetFormId() + "\".")
		return true
	endif
endfunction

; Initialises Actor base value as well as setting his current values to default and returns the new current value.
float function InitActorValues(Actor akActor)
	Log("InitActorValues() Resetting current and max value of Attribute \"" + GetName() + "\" for actor \"none\"...")
	ResetActorMaxValue(akActor)
	return ResetActorValue(akActor)
endfunction



; ==================================================
; Tag Management
; ==================================================

; Register new tag. ; returns -1 on error, 0 if already registered and 1 if successfully added
int function TagRegister(string TagName, float TagMagnitude)
	if !TagName
		Error("TagRegister() Could not register tag \"none\" for Attribute \"" + GetName() + "\".")
		return -1
	endif
	if TagList.FindStruct("Name", TagName) >= 0
		Warning("TagRegister() Tag \"" + TagName + "\" is already registered for Attribute \"" + GetName() + "\".")
		return 0
	else
		TagStruct NewTag = new TagStruct
		NewTag.Name = TagName
		NewTag.Magnitude = TagMagnitude
		TagList.Add(NewTag)
		Log("TagRegister() Added new tag \"" + TagName + "\" for attribute \"" + GetName() + "\".")
		return 1
	endif
endfunction

; Remove existing tag. ; returns -1 on error, 0 if not registered and 1 if successfully removed
int function TagRemove(string TagName)
	if !TagName
		Error("TagRemove() Could not remove tag \"none\" for attribute \"" + GetName() + "\".")
		return -1
	endif
	int index = TagList.FindStruct("Name", TagName)
	if  index >= 0
		TagList.Remove(index)
		Log("TagRemove() Tag \"" + TagName + "\" has been removed from the list for Attribute \"" + GetName() + "\".")
		return 1
	else
		Warning("TagRemove() Could not remove " + TagName + "\" for Attribute \"" + GetName() + "\". Tag not found.")
		return 0
	endif
endfunction

; Change magnitude of existing tag. ; returns -1 on error, 0 if not registered and 1 if successfully removed
int function TagChangeMagnitude(string TagName, float TagMagnitude)
	if !TagName
		Error("TagChangeMagnitude() Could not change magnitude of tag \"none\" for Attribute \"" + GetName() + "\".")
		return -1
	endif
	int index = TagList.FindStruct("Name", TagName)
	if  index >= 0
		TagList[index].Magnitude = TagMagnitude
		Log("TagChangeMagnitude() Magnitude of tag \"" + TagName + "\" has has been changed to \"" + TagMagnitude + "\" for Attribute \"" + GetName() + "\".")
		return 1
	else
		Warning("TagChangeMagnitude() Could not change magnitude of " + TagName + "\" for Attribute \"" + GetName() + "\". Tag not found.")
		return 0
	endif
endfunction



; ==================================================
; Limitation
; ==================================================

; Handy function to limit the value between min/max.
float function LimitValue(float Value, float Min, float Max)
	return Math.Min(Math.Max(Value, Min), Max)
endfunction

; Returns the minimum value for this actor.
; Depending on the state it's either the negative base value or 0.
float function GetActorValueMin(Actor akActor)
	if !akActor
		Error("GetActorValueMin() Could not get min value of Attribute \"" + GetName() + "\" for actor \"none\".")
		return 0
	endif
	
	if AllowNegative
		return akActor.GetBaseValue(AVIF) * -1
	Else
		return 0
	endif
endfunction

; Returns the maximum value for this actor. Basicly just his "base value".
float function GetActorValueMax(Actor akActor)
	if !akActor
		Error("GetActorValueMax() Could not get max value of Attribute \"" + GetName() + "\" for actor \"none\".")
		return 0.0
	endif
	return akActor.GetBaseValue(AVIF)
endfunction

float function GetDefaultBaseValueMin()
	return BaseValueMin
endfunction

float function GetDefaultBaseValueMax()
	return BaseValueMax
endfunction

float function GetDefaultBaseValue()
	return BaseValueDefault
endfunction



; ==================================================
; Base Value Modification
; ==================================================

float function ModActorMaxValue(Actor akActor, float Value)
	if !akActor
		Error("SetActorMaxValue() Could not modify max value of Attribute \"" + GetName() + "\" for actor \"none\".")
		return 0.0
	endif
	Log("SetActorMaxValue() Setting max value of Attribute \"" + GetName() + "\" for Actor \"" + akActor.GetFormId() + "\" with a value of \"" + Value + "\".")
	float CurrentMax = akActor.GetBaseValue(AVIF)
	float CurrentValue = GetActorValue(akActor)
	Value = LimitValue(Value, GetDefaultBaseValueMin() - CurrentMax, GetDefaultBaseValueMax() - CurrentMax)
	akActor.ModValue(AVIF, Value)
	; Remove the amount that was added due to the base value change.
	return SetActorValue(akActor, CurrentValue)
endfunction

float function SetActorMaxValue(Actor akActor, float Value)
	if !akActor
		Error("SetActorMaxValue() Could not set max value of Attribute \"" + GetName() + "\" for actor \"none\".")
		return 0
	endif
	Log("SetActorMaxValue() Setting max value of Attribute \"" + GetName() + "\" for Actor \"" + akActor.GetFormId() + "\" with a value of \"" + Value + "\".")
	
	float CurrentValue = GetActorValue(akActor)
	Value = LimitValue(Math.abs(Value), GetDefaultBaseValueMin(), GetDefaultBaseValueMax())
	akActor.SetValue(AVIF, Value)
	; Remove the amount that was added due to the base value change.
	return SetActorValue(akActor, CurrentValue)
endfunction

float function ResetActorMaxValue(Actor akActor)
	if !akActor
		Error("ResetMaxValue() Could not reset max value of Attribute \"" + GetName() + "\" for actor \"none\". Returning value of \"0.0\".")
		return 0.0
	endif
	Log("ResetMaxValue() Resetting max value of Attribute \"" + GetName() + "\" for Actor \"" + akActor.GetFormId() + "\".")
	
	float CurrentValue = GetActorValue(akActor)
	akActor.SetValue(AVIF, GetDefaultBaseValue())
	return SetActorValue(akActor, CurrentValue)
endfunction



; ==================================================
; Output
; ==================================================

; Returns the current rank for that Actor as integer.
int function GetActorRank(Actor akActor, int ErrorValue = 0)
	if !akActor
		Error("GetActorRank() Could not get rank of Attribe \"" + GetName() + "\" for actor \"none\". Returning ErrorValue of \"" + ErrorValue + "\".")
		return ErrorValue
	endif
	Log("GetActorRank() Getting rank of Attribute \"" + GetName() + "\" for Actor \"" + akActor.GetFormId() + "\".")
	
	float Value = GetActorValue(akActor) const
	int Rank = GetActorRankExtended(akActor, Math.abs(Value))
	if Value < 0
		Rank *= -1
	endif
	return Rank
endfunction

int function GetActorRankExtended(Actor akActor, float Value)
	if Value >=-Framework.Requirements.Strong		;      +75	; Strong Like
		return 3
	elseif Value >= Framework.Requirements.Medium	; 79 to 50	; Medium Like
		return 2
	elseif Value >= Framework.Requirements.Weak		; 49 to 20	; Weak Like
		return 1
	else
		return 0									; 19 to 0	; Neutral
	endif
endfunction

; Returns the current value of that actor.
float function GetActorValue(Actor akActor, float ErrorValue = 0.0)
	if !akActor
		Error("GetValue() Could not get value of Attribe \"" + GetName() + "\" for actor \"none\". Returning ErrorValue of \"" + ErrorValue + "\".")
		return ErrorValue
	endif
	Log("GetValue() Getting value of Attribute \"" + GetName() + "\" for Actor \"" + akActor.GetFormId() + "\".")
	
	; Get current AV and check it's limits.
	float Value = akActor.GetValue(AVIF)
	float NewValue = LimitValue(Value, GetActorValueMin(akActor), GetActorValueMax(akActor)) const
	if Value != NewValue
	; Value had exceeded it's limit... update values
		Warning("GetValue() Current Value of \"" + Value + "\" is exceeding it's limits. Set the Actor value to NewValue of \"" + NewValue + "\".")
		Value = NewValue
		SetActorValue(akActor, NewValue)
	endif
	
	return Value
endfunction



; ==================================================
; Modification
; ==================================================

float function SetActorValue(Actor akActor, float Value, float ErrorValue = 0.0)
	if !akActor
		Error("SetActorValue() Could not set value of Attribute \"" + GetName() + "\" for actor \"none\". Returning ErrorValue of \"" + ErrorValue + "\".")
		return ErrorValue
	endif
	Log("SetActorValue() Setting value of Attribute \"" + GetName() + "\" for Actor \"" + akActor.GetFormId() + "\" with a value of \"" + Value + "\".")
	
	; Limit value if it exceeds it's limits
	Value = LimitValue(Value, GetActorValueMin(akActor), GetActorValueMax(akActor))
	float NewValue = Value - akActor.GetValue(AVIF) const
	
	; Check which function to use...
	if (NewValue >= 0)
		Log("SetActorValue() NewValue is positive... Use \"RestoreValue\" function...")
		akActor.RestoreValue(AVIF, NewValue)
	Else
		Log("SetActorValue() NewValue is negative... Use \"DamageValue\" function...")
		akActor.DamageValue(AVIF, NewValue)
	endif
	
	return Value
endfunction

float function ModActorValue(Actor akActor, float Value, float ErrorValue = 0.0)
	if !akActor
		Error("ModActorValue() Could not modify value of Attribute \"" + GetName() + "\" for actor \"none\". Returning ErrorValue of \"" + ErrorValue + "\".")
		return ErrorValue
	endif
	Log("ModActorValue() Modifying value of Attribute \"" + GetName() + "\" for Actor \"" + akActor.GetFormId() + "\" with a value of \"" + Value + "\".")
	; Get Current AV and to check if added Mod Value wouldn't exceed it's limit
	float CurrentValue = akActor.GetValue(AVIF) const
	Value = LimitValue(Value, GetActorValueMin(akActor) - CurrentValue, GetActorValueMax(akActor) - CurrentValue)
	
	; Check which function to use...
	if (Value >= 0)
		Log("ModActorValue() Value is positive... Use \"RestoreValue\" function...")
		akActor.RestoreValue(AVIF, Value)
	Else
		Log("ModActorValue() Value is negative... Use \"DamageValue\" function...")
		akActor.DamageValue(AVIF, Math.abs(Value))
	endif
	Log("ModActorValue() Successfully modified value of \"" + Value + "\".")
	return Value
endfunction

float function ResetActorValue(Actor akActor, float ErrorValue = 0.0)
	if !akActor
		Error("ResetValue() Could not reset value of Attribute \"" + GetName() + "\" for actor \"none\". Returning ErrorValue of \"" + ErrorValue + "\".")
		return ErrorValue
	endif
	
	Log("ResetValue() Resetting value of Attribute \"" + GetName() + "\" for actor " + akActor.GetFormId() + ".")
	return SetActorValue(akActor, DefaultValue, ErrorValue)
endfunction

; ==================================================
; API
; ==================================================

float function ActorDecision(Actor akTarget, Actor akMaster)
endfunction



; ==================================================
; Logging
; ==================================================

function Error(string msg)
	if Framework
		Framework.Error(msg)
	endif
endfunction

function Warning(string msg)
	if Framework
		Framework.Warning(msg)
	endif
endfunction

function Log(string msg)
	if Framework
		Framework.Log(msg)
	endif
endfunction
