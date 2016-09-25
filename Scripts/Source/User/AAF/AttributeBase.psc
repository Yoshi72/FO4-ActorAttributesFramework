scriptname AAF:AttributeBase extends Quest
{Base Script for Attribute functions.}

struct Tag
	string Name
	{The name of the tag}
	int Magnitude
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
	
	Tag[] property TagList auto
	{List of tags that effects this attribute.}
endgroup

group DefaultValues
	float property BaseValueMax			= 120.0 auto const
	{Default Base (Max) Value. Should never be 0.}
	float property BaseValueDefault		= 100.0 auto const
	{Default Max Base Value. Should never be 0.}
	float property BaseValueMin			= 100.0 auto const
	{Default Max Base Value. Should never be 0.}
	float property DefaultValue			=   0.0 auto const
	{Default Starting Value. This is the value all actor's start with. If you want to start with random values, it's best to overwrite ActorSetDefault() function.}
endgroup

; Automatically register this attribute to the Framework
event OnInit()
	if !TagList
		TagList = new Tag[0]
	endif
	Framework.RegisterAttribute(self)
endevent

string function GetName()
	return Name
endfunction

ActorValue function GetActorValue()
	return AVIF
endfunction



; ==================================================
; Defaults and Inits
; ==================================================

; Check if actor's base value has been initialized and returns the result.
bool function CheckActorBaseInit(Actor akActor)
	if akActor.GetBaseValue(AVIF) == 0
		Log("CheckActorInitalization() Attribute \"" + self.GetFormId() + "\" (" + Name + ") has not been set for actor \"" + akActor.GetFormId() + "\".")
		return false
	else
		Log("CheckActorInitalization() Attribute \"" + self.GetFormId() + "\" (" + Name + ") has been set for actor \"" + akActor.GetFormId() + "\".")
		return true
	endif
endfunction

; Initialises Actor base value as well as setting his current values to default and returns the new current value.
float function ActorInitValues(Actor akActor)
	ActorBaseInit(akActor)
	return ActorSetDefault(akActor)
endfunction

; Initializes the base value and current values
float function ActorBaseInit(Actor akActor)
	akActor.SetValue(AVIF, BaseValueDefault)
	Log("ActorInitalization() Attribute \"" + self.GetFormId() + "\" (" + Name + ") has been reset for actor \"" + akActor.GetFormId() + "\".")
endfunction

; Resets an actor's values back to the defaults.
float function ActorSetDefault(Actor akActor)
	return SetValue(akActor, DefaultValue)
endfunction




; ==================================================
; Tag Management
; ==================================================

; Register new tag. ; returns -1 on error, 0 if already registered and 1 if successfully added
int function RegisterTag(string TagName, int TagMagnitude)
	if !TagName
		Error("RegisterTag() Could not register tag \"none\" for attribute \"" + Name + "\".")
		return -1
	endif
	if TagList.FindStruct("Name", TagName) >= 0
		Warning("RegisterTag() Tag \"" + TagName + "\" is already registered for attribute \"" + Name + "\".")
		return 0
	else
		Tag NewTag = new Tag
		NewTag.Name = TagName
		NewTag.Magnitude = TagMagnitude
		TagList.Add(NewTag)
		Log("RegisterTag() Added new tag \"" + TagName + "\" for attribute \"" + Name + "\".")
		return 1
	endif
endfunction

; Remove existing tag. ; returns -1 on error, 0 if not registered and 1 if successfully removed
int function RemoveTag(string TagName)
	if !TagName
		Error("RemoveTag() Could not remove tag \"none\" for attribute \"" + Name + "\".")
		return -1
	endif
	int index = TagList.FindStruct("Name", TagName)
	if  index >= 0
		TagList.Remove(index)
		Log("RemoveTag() Tag \"" + TagName + "\" is been removed from the list for attribute \"" + Name + "\".")
		return 1
	else
		Warning("RemoveTag() Could not remove " + TagName + "\" for attribute \"" + Name + "\". Tag not found.")
		return 0
	endif
endfunction

; Change magnitude of existing tag. ; returns -1 on error, 0 if not registered and 1 if successfully removed
int function ChangeMagnitude(string TagName, int TagMagnitude)
	if !TagName
		Error("ChangeMagnitude() Could not change magnitude of tag \"none\" for attribute \"" + Name + "\".")
		return -1
	endif
	int index = TagList.FindStruct("Name", TagName)
	if  index >= 0
		TagList[index].Magnitude = TagMagnitude
		Log("ChangeMagnitude() Magnitude for tag \"" + TagName + "\" is has been changed to \"" + TagMagnitude + "\" for attribute \"" + Name + "\".")
		return 1
	else
		Warning("ChangeMagnitude() Could not change magnitude of " + TagName + "\" for attribute \"" + Name + "\". Tag not found.")
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
float function GetMinValue(Actor akActor)
	if !akActor
		return 0
	endif
	
	if AllowNegative
		return akActor.GetBaseValue(AVIF) * -1
	Else
		return 0
	endif
endfunction

; Returns the maximum value for this actor. Basicly just his "base value".
float function GetMaxValue(Actor akActor)
	if !akActor
		return 0
	endif

	return akActor.GetBaseValue(AVIF)
endfunction



; ==================================================
; Base Value Modification
; ==================================================

; Increases the Base (Max) Value for that actor by the passed in amount and returns the new base value.
; Optionally only increases the the base value without increasing the current value.
float function IncreaseMaxValue(Actor akActor, float Value, bool OnlyBase = true)
	if !akActor
		Error("IncreaseMaxValue() Could not increase max value for actor of none.")
		return 0
	endif
	if Value == 0
		Log("IncreaseMaxValue() Base value for actor \"" + akActor.GetFormId() + "\" has not been changed. Passed in value is 0.")
		return akActor.GetBaseValue(AVIF)
	endif
	; Make sure not to exceed the limits
	float CurrentMax = akActor.GetBaseValue(AVIF)
	Value = Math.Min(Math.abs(Value), BaseValueMax - CurrentMax)
	float NewMaxValue = CurrentMax + Value
	akActor.SetValue(AVIF, NewMaxValue)
	if OnlyBase
		; Remove the amount that was added due to the base value change.
		ModValue(akActor, value)
	endif
	return NewMaxValue
endfunction

; Decreases the Base (Max) Value for that actor by the passed in amount and returns the new base value.
; Optionally only decreases the the base value without decreasing the current value.
float function DecreaseMaxValue(Actor akActor, float Value, bool OnlyBase = true)
	if !akActor
		Error("DecreaseMaxValue() Could not decrease max value for actor of none.")
		return 0
	endif
	if Value == 0
		Log("IncreaseMaxValue() Base value for actor \"" + akActor.GetFormId() + "\" has not been changed. Passed in value is 0.")
		return akActor.GetBaseValue(AVIF)
	endif
	; Make sure not to exceed the limits
	float CurrentMax = akActor.GetBaseValue(AVIF)
	Value = Math.Min(Math.abs(Value), CurrentMax - BaseValueMin)
	float NewMaxValue = CurrentMax - Value
	akActor.SetValue(AVIF, NewMaxValue)
	if !OnlyBase
		Log("IncreaseMaxValue() Restore the amount lost due to the base value change.")
		ModValue(akActor, value)
	endif
	return NewMaxValue
endfunction



; ==================================================
; Output
; ==================================================

; Returns the current rank for that Actor as integer.
int function GetRank(Actor akActor)
	float Value = GetValue(akActor) const
	int Rank = GetRankExtended(akActor, Math.abs(Value))
	if Value < 0
		Rank *= -1
	endif
	return Rank
endfunction

int function GetRankExtended(Actor akActor, float Value)
	if Value >=-Framework.Requirements.Strong		;      +75	; Strong Like
		return 3
	elseif Value >= Framework.Requirements.Medium	; 79 to 50	; Medium Like
		return 2
	elseif Value >= Framework.Requirements.Weak		; 49 to 20	; Weak Like
		return 1
	else
		return 0
	endif
endfunction

; Returns the current value of that actor.
float function GetValue(Actor akActor, float OnErrorValue = 0.0)
	if !akActor
		Error("GetValue() Could not get value for actor \"none\". Returning OnErrorValue (" + OnErrorValue + ").")
		return OnErrorValue
	endif
	; Get current AV and limit it.
	float Value = akActor.GetValue(AVIF)
	float NewValue = LimitValue(Value, GetMinValue(akActor), GetMaxValue(akActor)) const
	if Value != NewValue
	; Value had exceeded it's limit... update values
		Value = NewValue
		SetValue(akActor, NewValue)
	endif
	return Value
endfunction



; ==================================================
; Modification
; ==================================================

float function SetValue(Actor akActor, float Value, float OnErrorValue = 0.0)
	if !akActor
		return OnErrorValue
	endif
	; Limit value if it exceeds it's limits
	Value = LimitValue(Value, GetMinValue(akActor), GetMaxValue(akActor))
	float NewValue = Value - akActor.GetValue(AVIF) const
	
	; Check which function to use...
	if (NewValue >= 0)
		akActor.RestoreValue(AVIF, NewValue)
	Else
		akActor.DamageValue(AVIF, NewValue)
	endif
	
	return Value
endfunction

float function ModValue(Actor akActor, float Value, float OnErrorValue = 0.0)
	if !akActor
		return OnErrorValue
	endif
	; Get Current AV and to check if added Mod Value wouldn't exceed it's limit
	float CurrentValue = akActor.GetValue(AVIF) const
	Value = LimitValue(Value, GetMinValue(akActor) - CurrentValue, GetMaxValue(akActor) - CurrentValue)
	
	; Check which function to use...
	if (Value >= 0)
		akActor.RestoreValue(AVIF, Value)
	Else
		akActor.DamageValue(AVIF, Value)
	endif
	
	return Value
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



; ==================================================
; API
; ==================================================

function UNNAMED()

endfunction
